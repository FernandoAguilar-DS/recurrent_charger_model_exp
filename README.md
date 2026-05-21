# Netflix Recurrent Charge — SeqNN v1.9.0

Sistema de predicción de **timing de intentos de cobro recurrente** para Netflix (o cualquier merchant configurable). El modelo predice **cuántos días faltan al próximo intento de cobro** por usuario, para que CRM pueda enviar recordatorios proactivos antes del cargo y reducir declines por fondos insuficientes y cascadas de retry.

> **Stack:** BigQuery + Python (PyTorch, Polars, scikit-learn) en Vertex AI Workbench (T4 GPU).

---

## Contenido del repo

| Archivo | Descripción |
|---|---|
| `query_recurrent_charger_v_6_0_0.sql` | Query BigQuery event-level que construye la tabla de entrenamiento. Cada fila = 1 attempt (approved o rejected) con sus features rolling y el target `days_to_next_attempt`. |
| `seqnn_recurrent_charge_v1_9_0.ipynb` | Pipeline end-to-end: carga, limpieza, secuencias, entrenamiento de 5 arquitecturas con dual head, calibración, ensemble, gates GO/NO-GO y Action Cards para CRM. |

---

## 1. Pipeline SQL (`query_recurrent_charger_v_6_0_0.sql`)

### Diseño

Modelo **event-level**: cada fila es un intento de cobro, no una semana. Esto elimina la grilla semanal, el aliasing temporal y la duplicación de targets que existían en versiones previas.

- **Target:** `days_to_next_attempt` — gap en días al siguiente intento del mismo usuario contra el merchant objetivo.
- **Censura:** intentos sin siguiente evento dentro de la ventana quedan como NULL → manejados como censurados en el notebook.

### Parámetros configurables (`DECLARE`)

```sql
DECLARE target_merchant_keyword     STRING DEFAULT 'googleone';  -- 'nflx', 'spotify', etc.
DECLARE target_merchant_label       STRING DEFAULT 'Target_Merchant';
DECLARE target_horizon_days         INT64  DEFAULT 60;
DECLARE cohort_max_days_since_last  INT64  DEFAULT 150;
DECLARE lookback_months             INT64  DEFAULT 12;
DECLARE exp_start                   DATE   DEFAULT DATE '2025-01-01';
DECLARE exp_end                     DATE   DEFAULT DATE '2026-05-08';
```

### Pasos

1. **Parámetros y bounds** — ventana temporal con buffer de 365 días previos a `exp_start`.
2. **Base unificada de transacciones** — UNION de approved + rejected COF, normalización del merchant, flag `card_on_file`, día del mes, monto en MXN.
3. **Agregaciones diarias por usuario** — attempts / approvals / rejects por día.
4. **Features rolling event-level** — ventanas `7d / 14d / 30d` (end-exclusive respecto al evento actual para evitar leakage): `attempts_*`, `approvals_*`, `rejects_*`, además de `last_attempt_date`, `last_approval_date`, `last_reject_date`.
5. **Cohorte** — usuarios con `days_since_last_attempt ≤ cohort_max_days_since_last`.
6. **Target** — para cada evento se calcula `days_to_next_attempt` con `LEAD()` particionado por usuario.

### Output

Tabla BigQuery (ej. `recurrent_charger_netflix_merchant_v5_0_1`) con una fila por intento y columnas de features + target. El notebook consume esta tabla vía `SELECT *`.

---

## 2. Pipeline de modelado (`seqnn_recurrent_charge_v1_9_0.ipynb`)

### Arquitectura general

```
BigQuery  →  Polars (cache parquet)  →  filter_retries  →  align_targets
        →  build_sequences (lookback=8)  →  StandardScaler
        →  5 modelos (dual head)  →  Temperature Scaling  →  Ensemble calibrado
        →  Gates GO/NO-GO  →  Action Cards CRM
```

### Modelos entrenados (5 × dual head)

Todos exponen dos cabezas: clasificación de **bucket** + regresión de **días**.

| Modelo | Configuración |
|---|---|
| GRU | hidden=128, layers=4, dropout=0.4 |
| RNN | hidden=128, layers=4, dropout=0.4 |
| LSTM | hidden=128, layers=4, dropout=0.4 |
| TCN | channels=[64,128,256,128], kernel=4, dropout=0.1 |
| DEEP_GRU | hidden=256, layers=4, dropout=0.4, drop_path=0.1 (Pre-LN + residual + DropPath + TemporalAttention) |

### Bucket encoding adaptativo

10 buckets sobre `days_to_next_attempt`:

```
edges = [0, 1, 2, 3, 4, 5, 7, 14, 30]
buckets = [≥30d/censored, [0,1), [1,2), [2,3), [3,4), [4,5), [5,7), [7,14), [14,30), [30,∞)]
```

### Loss compuesta

- **Bucket head:** CrossEntropy o Focal Loss con `class_weights` (inverse-frequency, power=0.85), `label_smoothing=0.1`.
- **Multitask aux:** `y_3d / y_7d / y_14d / y_30d` (binarios), peso 0.3.
- **Regresión (`fc_days`):** Huber loss.
- **Ordinal asimétrico:** penalización extra `α=2.0` a predicciones **tardías** vs reales (un recordatorio tarde no sirve; uno temprano sí).
- **Grad clipping:** `max_norm=1.0`.

### Calibración

**Temperature scaling** post-hoc (Guo et al. 2017): se busca T óptimo en validación minimizando NLL, y se aplica a las probabilidades de test. El dict `temperatures` se persiste a disco — antes solo vivía en RAM y bloqueaba la inferencia de kernel fresco.

### Ensemble calibrado

Promedio de las probabilidades calibradas de los 5 modelos + grid search del quantile decoder `q` sobre validación. El mejor entre `[ensemble, mejor individual]` queda como `predictions_final`.

### Gates GO/NO-GO

Doble gate:

1. **Absoluto:** `MAE ≤ 5.0d`, `p90 ≤ 12.0d`, `MAE_modelo / MAE_baseline ≤ 0.85`.
2. **Competitivo vs constante:** el modelo debe ganarle a un predictor `np.full(N, k)` en **MAE** y **Bucket Accuracy**. Sin esto, GO no se otorga aunque pase el gate absoluto.

Resultado se persiste en `gate_final_v1_9_0.json`.

### Action Cards (CRM)

Segmentación accionable sobre el test set (template, no inferencia productiva):

| Predicted days | Acción |
|---|---|
| ≤ 14d (y no abstención) | `send_reminder` |
| 15–30d | `monitor` |
| > 30d o abstención | `no_action` |

La política de abstención usa un clasificador LogReg que estima `P(censored)`.

---

## 3. Setup

### Dependencias

```bash
pip install polars torch scikit-learn scipy joblib google-cloud-bigquery pyarrow
```

Una vez corrido, congelar con `pip freeze > requirements.txt` para reproducibilidad exacta.

### Variables de entorno

Autenticación de BigQuery vía `gcloud auth application-default login` o service account con permisos de lectura sobre el proyecto y dataset configurados en `CONFIG`:

```python
'project': 'spin-aip-singularity-data-sb',
'dataset': 'Test_predictions_MLOps_30D_model',
'table':   'recurrent_charger_netflix_merchant_v5_0_1',
```

### Reproducibilidad

- `SEED = 42` global (Python, NumPy, PyTorch, CUDA).
- Splits temporales 80/10/10 estrictamente no solapados.
- `StandardScaler` y winsorización fiteados **solo en train**.

---

## 4. Cómo correrlo

1. **Generar/refrescar la tabla de features**

   ```bash
   bq query --use_legacy_sql=false < query_recurrent_charger_v_6_0_0.sql
   ```

   Ajustar los `DECLARE` al inicio del archivo si se quiere cambiar de merchant o de ventana experimental.

2. **Correr el notebook** `seqnn_recurrent_charge_v1_9_0.ipynb` de arriba hacia abajo. La primera corrida cachea la query en `data_1/reminders_netflix_cache.parquet`; las siguientes leen de cache. Para forzar refresh:

   ```python
   FORCE_REFRESH_CACHE = True
   ```

---

## 5. Artefactos producidos

Todos en `artifacts_v1_9_0/`:

- `model_<NAME>.pt` — pesos de cada arquitectura entrenada.
- `scaler.pkl` — `StandardScaler` fiteado en train.
- `temperatures.joblib` — T óptimo por modelo (calibración).
- `inference_state.pkl` — bundle para inferencia de kernel fresco (features, decoder, política de abstención).
- `gate_final_v1_9_0.json` — métricas y decisión GO/NO-GO.
- `business_metrics.json` — comparativa de métricas de negocio por modelo.
- `action_cards_v1_5_6.json` — segmentos CRM con conteos y decisiones.

---

## 6. Métricas reportadas

| Métrica | Objetivo | Significado |
|---|---|---|
| **MAE** (días) | < 5.0 | Error absoluto medio en días al próximo intento. |
| **p90 error** | < 12.0 | Cola del error: 90% de las predicciones tienen error ≤ este valor. |
| **Late %** | ≤ 30% | Fracción de predicciones que llegarían **tarde** (predicho > real). |
| **EWR @ 7d** | ≥ 40% | Early Warning Rate: % de eventos reales a 1–7d que el modelo identificó como ≤ 7d. |
| **Coverage @ 7d** | ≥ 50% | % de predicciones con error ≤ 7d. |
| **ECE** | < 0.10 | Expected Calibration Error del clasificador de buckets. |
| **C-index** | > 0.70 | Concordance Index: calidad del ranking entre usuarios. |
| **Bucket Accuracy** | > naive | Accuracy del clasificador, requerida también contra constante. |

---

## 7. Estructura del notebook

```
 0. Setup (env, imports, semillas)
 1. CONFIG
 2. Data Pipeline (BigQuery → Polars + cache)
 3-4. Limpieza, filter_retries, align_targets
 5. Construcción de HMM_FEATURES
 6-9. Validaciones anti-leakage, bucket encoding, build_sequences
10. Dataset + DataLoaders
11. Arquitecturas (5 × dual head)
12-14. Losses, training loop, early stopping
15-16. Evaluación + métricas de negocio
17. Temperature Scaling + persistencia
18. Ensemble calibrado (fuente de verdad)
19. Política de abstención
20. Gate GO/NO-GO (absoluto + competitivo)
21. Action Cards CRM
22. Bundle de inferencia + checklist de reproducibilidad
```

---

## 8. Notas de versión

**v1.9.0** — refactor de housekeeping sobre `v1.8.2`. Un solo camino de ejecución, sin celdas deprecadas, sin shadowing de funciones, sin referencias hacia adelante.

Fixes destacados:
- `compute_loss` unificada (antes había dos `compute_loss_v2` con cuerpos distintos).
- `temperatures` persistido a disco (antes solo en RAM → inferencia de kernel fresco era imposible sin re-entrenar).
- Gate competitivo vs constante añadido (antes el gate absoluto podía decir GO contra un baseline que perdía vs `np.full(N, k)`).
- `HMM_FEATURES` se construye una sola vez en la Sección 5.
- Abstención unificada en una sola `abstention_mask`.
- Splits alineados a 80/10/10.

> Diagnósticos (SHAP, Captum, permutation importance, fases experimentales) se sacaron del núcleo. Conviene moverlos a un `diagnostics.ipynb` aparte.

---

## 9. Limitaciones conocidas

- El target `days_to_next_attempt` excluye intentos del **mismo merchant**; cobros de otros merchants no entran al modelo.
- Cobertura de censura asimétrica entre splits puede inflar la métrica de validación vs test.
- El scoring de Action Cards corre sobre el test set offline: **no** es inferencia productiva per-user.
- Features de resolución 1–3 días (`balance_yesterday`, `had_deposit_yesterday`, `attempts_1d`, `rejects_1d`, `hours_since_last_attempt`) están pendientes de upstream SQL.

---

## Licencia

Uso interno — SPIN.
