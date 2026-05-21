{\rtf1\ansi\ansicpg1252\cocoartf2869
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red248\green148\blue205;\red0\green0\blue0;\red238\green240\blue241;
\red120\green162\blue246;\red255\green255\blue255;\red153\green212\blue166;\red246\green124\blue48;\red226\green229\blue232;
}
{\*\expandedcolortbl;;\cssrgb\c98431\c66275\c83922;\cssrgb\c0\c0\c0;\cssrgb\c94510\c95294\c95686;
\cssrgb\c54118\c70588\c97255;\cssrgb\c100000\c100000\c100000;\cssrgb\c65882\c85490\c70980;\cssrgb\c98039\c56471\c24314;\cssrgb\c90980\c91765\c92941;
}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- RECURRENT CHARGE MODEL - GENERIC TARGET MERCHANT - v5.0 EVENT-LEVEL\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- CAMBIO FUNDAMENTAL: Cada fila = 1 attempt event (approved o rejected)\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- Target: days_to_next_attempt (gap time entre intentos consecutivos)\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- Elimina: grilla semanal, aliasing temporal, duplicaci\'f3n de targets\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- CONFIGURACI\'d3N\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 DECLARE\cf4 \strokec4  \cf6 \strokec6 target_merchant_keyword\cf4 \strokec4  \cf5 \strokec5 STRING\cf4 \strokec4  \cf5 \strokec5 DEFAULT\cf4 \strokec4  \cf7 \strokec7 'googleone'\cf4 \strokec4 ; \cf2 \strokec2 -- Cambiar por 'nflx', 'spotify', etc.\cf4 \cb1 \strokec4 \
\cf5 \cb3 \strokec5 DECLARE\cf4 \strokec4  \cf6 \strokec6 target_merchant_label\cf4 \strokec4  \cf5 \strokec5 STRING\cf4 \strokec4  \cf5 \strokec5 DEFAULT\cf4 \strokec4  \cf7 \strokec7 'Target_Merchant'\cf4 \strokec4 ;\cb1 \
\
\cf5 \cb3 \strokec5 DECLARE\cf4 \strokec4  \cf6 \strokec6 target_horizon_days\cf4 \strokec4  \cf5 \strokec5 INT64\cf4 \strokec4  \cf5 \strokec5 DEFAULT\cf4 \strokec4  \cf8 \strokec8 60\cf4 \strokec4 ;\cb1 \
\cf5 \cb3 \strokec5 DECLARE\cf4 \strokec4  \cf6 \strokec6 cohort_max_days_since_last\cf4 \strokec4  \cf5 \strokec5 INT64\cf4 \strokec4  \cf5 \strokec5 DEFAULT\cf4 \strokec4  \cf8 \strokec8 150\cf4 \strokec4 ;\cb1 \
\cf5 \cb3 \strokec5 DECLARE\cf4 \strokec4  \cf6 \strokec6 lookback_months\cf4 \strokec4  \cf5 \strokec5 INT64\cf4 \strokec4  \cf5 \strokec5 DEFAULT\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4 ;\cb1 \
\cf5 \cb3 \strokec5 DECLARE\cf4 \strokec4  \cf6 \strokec6 exp_start\cf4 \strokec4  \cf5 \strokec5 DATE\cf4 \strokec4  \cf5 \strokec5 DEFAULT\cf4 \strokec4  \cf5 \strokec5 DATE\cf4 \strokec4  \cf7 \strokec7 '2025-01-01'\cf4 \strokec4 ;\cb1 \
\cf5 \cb3 \strokec5 DECLARE\cf4 \strokec4  \cf6 \strokec6 exp_end\cf4 \strokec4    \cf5 \strokec5 DATE\cf4 \strokec4  \cf5 \strokec5 DEFAULT\cf4 \strokec4  \cf5 \strokec5 DATE\cf4 \strokec4  \cf7 \strokec7 '2026-05-08'\cf4 \strokec4 ;\cb1 \
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 1: PAR\'c1METROS Y BOUNDS\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 WITH\cf4 \strokec4  \cf6 \strokec6 params\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 CURRENT_DATE\cf9 \strokec9 (\cf7 \strokec7 'America/Mexico_City'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 today\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 exp_start\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 365\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 start_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 exp_end\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 end_date\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 bounds\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 today\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 start_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 end_date\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 params\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 2: BASE UNIFICADA DE TRANSACCIONES (APPROVED + REJECTED COF)\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 txn_raw\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf2 \strokec2 -- APROBADAS\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 status_type\cf4 \strokec4 ,\cb1 \
\cb3     \cf7 \strokec7 'approved'\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 source_table\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 tx.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 tx.transactionIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 tx.transactionDate\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 d_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 TIMESTAMP\cf9 \strokec9 (\cf6 \strokec6 tx.transactionDate\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 ts_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SAFE_CAST\cf9 \strokec9 (\cf6 \strokec6 tx.transactionAmount\cf4 \strokec4  \cf9 \strokec9 /\cf4 \strokec4  \cf8 \strokec8 100\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 NUMERIC\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 amount_mxn\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CAST\cf9 \strokec9 (\cf5 \strokec5 ROUND\cf9 \strokec9 (\cf5 \strokec5 SAFE_CAST\cf9 \strokec9 (\cf6 \strokec6 tx.transactionAmount\cf4 \strokec4  \cf9 \strokec9 /\cf4 \strokec4  \cf8 \strokec8 100\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 NUMERIC\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 *\cf4 \strokec4  \cf8 \strokec8 100\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf5 \strokec5 INT64\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 amount_cents\cf4 \strokec4 ,\cb1 \
\cb3     \cf2 \strokec2 -- Estandarizaci\'f3n de variantes del merchant\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 CASE\cf4 \strokec4  \cb1 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LOWER\cf9 \strokec9 (\cf5 \strokec5 REPLACE\cf9 \strokec9 (\cf6 \strokec6 m.xMerchand_name\cf4 \strokec4 , \cf7 \strokec7 ' '\cf4 \strokec4 , \cf7 \strokec7 ''\cf9 \strokec9 ))\cf4 \strokec4  \cf5 \strokec5 LIKE\cf4 \strokec4  \cf5 \strokec5 CONCAT\cf9 \strokec9 (\cf7 \strokec7 '%'\cf4 \strokec4 , \cf6 \strokec6 target_merchant_keyword\cf4 \strokec4 , \cf7 \strokec7 '%'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 target_merchant_label\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 ELSE\cf4 \strokec4  \cf6 \strokec6 m.xMerchand_name\cf4 \strokec4  \cb1 \
\cb3     \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 merchant_name\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 m.xMerchand_code\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 merchant_code\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 IF\cf9 \strokec9 (\cf6 \strokec6 tx.bVirtual_card\cf4 \strokec4 , \cf7 \strokec7 'Virtual'\cf4 \strokec4 , \cf7 \strokec7 'F\'edsica'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 tipo_tarjeta\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 tx.xCard_last_four_digits\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 ot.xOperation_code\cf4 \strokec4  \cf5 \strokec5 IN\cf4 \strokec4  \cf9 \strokec9 (\cf7 \strokec7 '010'\cf4 \strokec4 ,\cf7 \strokec7 '011'\cf4 \strokec4 ,\cf7 \strokec7 '012'\cf4 \strokec4 ,\cf7 \strokec7 '0100'\cf4 \strokec4 ,\cf7 \strokec7 '0101'\cf4 \strokec4 ,\cf7 \strokec7 '0102'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 card_on_file\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 EXTRACT\cf9 \strokec9 (\cf6 \strokec6 DAY\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 tx.transactionDate\cf9 \strokec9 ))\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 day_of_month\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CAST\cf9 \strokec9 (\cf5 \strokec5 NULL\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf5 \strokec5 STRING\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 decline_code\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 `spin-dp-trusted-prod.spin_transaction.tbl_fact_transaction`\cf4 \strokec4  \cf6 \strokec6 tx\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 `spin-dp-trusted-prod.spin_transaction.TT_SDE_MERCHAND`\cf4 \strokec4  \cf6 \strokec6 m\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 m.iMerchand_id\cf4 \strokec4  = \cf6 \strokec6 tx.iMerchand_id\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 `spin-datalake-prd-trusted.spin_prod_transaction.TT_SDE_OPERATION_TYPE`\cf4 \strokec4  \cf6 \strokec6 ot\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 ot.iOperation_type\cf4 \strokec4  = \cf6 \strokec6 tx.iOperation_type\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 CROSS\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 params\cf4 \strokec4  \cf6 \strokec6 p\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WHERE\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 NOT\cf4 \strokec4  \cf6 \strokec6 tx.isReversedFlag\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 tx.transactionTypeIdentifier\cf4 \strokec4  = \cf8 \strokec8 30\cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 -- Filtro robusto para encontrar variantes ignorando espacios y may\'fasculas/min\'fasculas\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 LOWER\cf9 \strokec9 (\cf5 \strokec5 REPLACE\cf9 \strokec9 (\cf6 \strokec6 m.xMerchand_name\cf4 \strokec4 , \cf7 \strokec7 ' '\cf4 \strokec4 , \cf7 \strokec7 ''\cf9 \strokec9 ))\cf4 \strokec4  \cf5 \strokec5 LIKE\cf4 \strokec4  \cf5 \strokec5 CONCAT\cf9 \strokec9 (\cf7 \strokec7 '%'\cf4 \strokec4 , \cf6 \strokec6 target_merchant_keyword\cf4 \strokec4 , \cf7 \strokec7 '%'\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 tx.transactionDate\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 p.start_date\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_ADD\cf9 \strokec9 (\cf6 \strokec6 p.end_date\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf6 \strokec6 target_horizon_days\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\
\cb3   \cf5 \strokec5 UNION\cf4 \strokec4  \cf5 \strokec5 ALL\cf4 \cb1 \strokec4 \
\
\cb3   \cf2 \strokec2 -- RECHAZADAS (Fondos insuficientes + COF)\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf7 \strokec7 'Rejected'\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 status_type\cf4 \strokec4 ,\cb1 \
\cb3     \cf7 \strokec7 'rejected'\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 source_table\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 r.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 r.transactionIdentifier_hk\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 transactionIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 r.dEvent_date\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 d_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 TIMESTAMP\cf9 \strokec9 (\cf6 \strokec6 r.dEvent_date\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 ts_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SAFE_CAST\cf9 \strokec9 (\cf6 \strokec6 r.nTransaction_amount\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 NUMERIC\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 amount_mxn\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CAST\cf9 \strokec9 (\cf5 \strokec5 ROUND\cf9 \strokec9 (\cf5 \strokec5 SAFE_CAST\cf9 \strokec9 (\cf6 \strokec6 r.nTransaction_amount\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 NUMERIC\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 *\cf4 \strokec4  \cf8 \strokec8 100\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf5 \strokec5 INT64\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 amount_cents\cf4 \strokec4 ,\cb1 \
\cb3     \cf2 \strokec2 -- Estandarizaci\'f3n de variantes del merchant\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 CASE\cf4 \strokec4  \cb1 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LOWER\cf9 \strokec9 (\cf5 \strokec5 REPLACE\cf9 \strokec9 (\cf6 \strokec6 r.xMerchant_Name\cf4 \strokec4 , \cf7 \strokec7 ' '\cf4 \strokec4 , \cf7 \strokec7 ''\cf9 \strokec9 ))\cf4 \strokec4  \cf5 \strokec5 LIKE\cf4 \strokec4  \cf5 \strokec5 CONCAT\cf9 \strokec9 (\cf7 \strokec7 '%'\cf4 \strokec4 , \cf6 \strokec6 target_merchant_keyword\cf4 \strokec4 , \cf7 \strokec7 '%'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 target_merchant_label\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 ELSE\cf4 \strokec4  \cf6 \strokec6 r.xMerchant_Name\cf4 \strokec4  \cb1 \
\cb3     \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 merchant_name\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 r.xMerchant_code\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 merchant_code\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 IF\cf9 \strokec9 (\cf6 \strokec6 r.bVirtual_card\cf4 \strokec4 , \cf7 \strokec7 'Virtual'\cf4 \strokec4 , \cf7 \strokec7 'F\'edsica'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 tipo_tarjeta\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 RIGHT\cf9 \strokec9 (\cf6 \strokec6 r.xCard_number\cf4 \strokec4 , \cf8 \strokec8 4\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 xCard_last_four_digits\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 r.xPos_entry_mode\cf4 \strokec4  \cf5 \strokec5 IN\cf4 \strokec4  \cf9 \strokec9 (\cf7 \strokec7 '010'\cf4 \strokec4 ,\cf7 \strokec7 '011'\cf4 \strokec4 ,\cf7 \strokec7 '012'\cf4 \strokec4 ,\cf7 \strokec7 '0100'\cf4 \strokec4 ,\cf7 \strokec7 '0101'\cf4 \strokec4 ,\cf7 \strokec7 '0102'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 card_on_file\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 EXTRACT\cf9 \strokec9 (\cf6 \strokec6 DAY\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 r.dEvent_date\cf9 \strokec9 ))\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 day_of_month\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 rr.xRejected_reason_cve\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 decline_code\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 `spin-dp-trusted-prod.spin_transaction.TT_SDE_REJECTED_TRANSACTION`\cf4 \strokec4  \cf6 \strokec6 r\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 `spin-dp-trusted-prod.spin_catalogs.TT_SDE_REJECTED_REASON`\cf4 \strokec4  \cf6 \strokec6 rr\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 r.iRejected_reason_id\cf4 \strokec4  = \cf6 \strokec6 rr.iRejected_reason_id\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 CROSS\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 params\cf4 \strokec4  \cf6 \strokec6 p\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WHERE\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 r.userIdentifier\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 rr.xRejected_reason_cve\cf4 \strokec4  = \cf7 \strokec7 'ISUFFOPENTOBUY'\cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 -- Filtro robusto para encontrar variantes ignorando espacios y may\'fasculas/min\'fasculas\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 LOWER\cf9 \strokec9 (\cf5 \strokec5 REPLACE\cf9 \strokec9 (\cf6 \strokec6 r.xMerchant_Name\cf4 \strokec4 , \cf7 \strokec7 ' '\cf4 \strokec4 , \cf7 \strokec7 ''\cf9 \strokec9 ))\cf4 \strokec4  \cf5 \strokec5 LIKE\cf4 \strokec4  \cf5 \strokec5 CONCAT\cf9 \strokec9 (\cf7 \strokec7 '%'\cf4 \strokec4 , \cf6 \strokec6 target_merchant_keyword\cf4 \strokec4 , \cf7 \strokec7 '%'\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 r.dEvent_date\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 p.start_date\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 p.end_date\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- Agregar attempt_id para de-duplicaci\'f3n\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 txn_with_id\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 *\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 TO_HEX\cf9 \strokec9 (\cf5 \strokec5 MD5\cf9 \strokec9 (\cf5 \strokec5 CONCAT\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf6 \strokec6 userIdentifier\cf4 \strokec4 , \cf7 \strokec7 ''\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 CAST\cf9 \strokec9 (\cf6 \strokec6 transactionIdentifier\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf5 \strokec5 STRING\cf9 \strokec9 )\cf4 \strokec4 , \cf7 \strokec7 ''\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 CAST\cf9 \strokec9 (\cf6 \strokec6 d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf5 \strokec5 STRING\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 CAST\cf9 \strokec9 (\cf6 \strokec6 amount_cents\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf5 \strokec5 STRING\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf6 \strokec6 xCard_last_four_digits\cf4 \strokec4 , \cf7 \strokec7 ''\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf6 \strokec6 merchant_code\cf4 \strokec4 , \cf7 \strokec7 ''\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3       \cf6 \strokec6 status_type\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )))\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 attempt_id\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 txn_raw\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WHERE\cf4 \strokec4  \cf6 \strokec6 merchant_name\cf4 \strokec4  = \cf6 \strokec6 target_merchant_label\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 card_on_file\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 amount_cents\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 xCard_last_four_digits\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- De-duplicar (mantener primer intento por attempt_id)\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 target_cof\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \strokec4  \cf9 \strokec9 *\cf4 \strokec4  \cf5 \strokec5 EXCEPT\cf9 \strokec9 (\cf6 \strokec6 rn\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3       \cf9 \strokec9 *\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 ROW_NUMBER\cf9 \strokec9 ()\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 attempt_id\cf4 \strokec4  \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 ts_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 rn\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 txn_with_id\cf4 \cb1 \strokec4 \
\cb3   \cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WHERE\cf4 \strokec4  \cf6 \strokec6 rn\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 3: ATTEMPT-DAY (colapsar m\'faltiples intentos del mismo d\'eda)\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 attempt_day\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 d_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 ts_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 xCard_last_four_digits\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 amount_cents\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 amount_mxn\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 merchant_code\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 tipo_tarjeta\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 day_of_month\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 status_type\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 decline_code\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 attempts_in_day\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 approvals_in_day\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 rejects_in_day\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 IF\cf9 \strokec9 (\cf6 \strokec6 approvals_in_day\cf4 \strokec4  \cf9 \strokec9 >\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4 , \cf5 \strokec5 TRUE\cf4 \strokec4 , \cf5 \strokec5 FALSE\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 day_has_approval\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 ROW_NUMBER\cf9 \strokec9 ()\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 userIdentifier\cf4 \strokec4  \cb1 \
\cb3       \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 d_txn\cf4 \strokec4 , \cf6 \strokec6 ts_txn\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 attempt_seq\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3       \cf6 \strokec6 nc\cf4 \strokec4 .\cf9 \strokec9 *\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 COUNT\cf9 \strokec9 (*)\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 nc.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 nc.d_txn\cf4 \strokec4 , \cf6 \strokec6 nc.xCard_last_four_digits\cf4 \strokec4 , \cf6 \strokec6 nc.amount_cents\cf4 \cb1 \strokec4 \
\cb3       \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 attempts_in_day\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 nc.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 nc.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 nc.d_txn\cf4 \strokec4 , \cf6 \strokec6 nc.xCard_last_four_digits\cf4 \strokec4 , \cf6 \strokec6 nc.amount_cents\cf4 \cb1 \strokec4 \
\cb3       \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 approvals_in_day\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 nc.status_type\cf4 \strokec4  = \cf7 \strokec7 'Rejected'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 nc.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 nc.d_txn\cf4 \strokec4 , \cf6 \strokec6 nc.xCard_last_four_digits\cf4 \strokec4 , \cf6 \strokec6 nc.amount_cents\cf4 \cb1 \strokec4 \
\cb3       \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 rejects_in_day\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 ROW_NUMBER\cf9 \strokec9 ()\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 nc.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 nc.d_txn\cf4 \strokec4 , \cf6 \strokec6 nc.xCard_last_four_digits\cf4 \strokec4 , \cf6 \strokec6 nc.amount_cents\cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 nc.ts_txn\cf4 \cb1 \strokec4 \
\cb3       \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 day_rn\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 target_cof\cf4 \strokec4  \cf6 \strokec6 nc\cf4 \cb1 \strokec4 \
\cb3   \cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WHERE\cf4 \strokec4  \cf6 \strokec6 day_rn\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 4: TARGET \'97 GAP TIME (inter-arrival entre attempt-days)\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 event_with_target\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 ad\cf4 \strokec4 .\cf9 \strokec9 *\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 next_attempt_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.ts_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 next_attempt_ts\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.status_type\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 next_attempt_status\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 ,\cb1 \
\cb3       \cf6 \strokec6 ad.d_txn\cf4 \strokec4 ,\cb1 \
\cb3       \cf6 \strokec6 DAY\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_to_next_attempt\cf4 \strokec4 ,\cb1 \
\cb3     \cb1 \
\cb3     \cf5 \strokec5 LAG\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 prev_attempt_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf6 \strokec6 ad.d_txn\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 LAG\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 ,\cb1 \
\cb3       \cf6 \strokec6 DAY\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_since_prev_attempt\cf4 \strokec4 ,\cb1 \
\cb3     \cb1 \
\cb3     \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_approved\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 next_approval_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_approved\cf4 \strokec4 ,\cb1 \
\cb3       \cf6 \strokec6 ad.d_txn\cf4 \strokec4 ,\cb1 \
\cb3       \cf6 \strokec6 DAY\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_to_next_approval\cf4 \strokec4 ,\cb1 \
\cb3     \cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \cb1 \strokec4 \
\cb3            \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 , \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf6 \strokec6 target_horizon_days\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_observed\cf4 \strokec4 ,\cb1 \
\cb3     \cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \cb1 \strokec4 \
\cb3            \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 , \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf6 \strokec6 target_horizon_days\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 THEN\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 , \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 ELSE\cf4 \strokec4  \cf6 \strokec6 target_horizon_days\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 time_to_event_days\cf4 \strokec4 ,\cb1 \
\cb3     \cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \cb1 \strokec4 \
\cb3            \cf5 \strokec5 OR\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 , \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 >\cf4 \strokec4  \cf6 \strokec6 target_horizon_days\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 THEN\cf4 \strokec4  \cf5 \strokec5 TRUE\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 ELSE\cf4 \strokec4  \cf5 \strokec5 FALSE\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 is_censored\cf4 \strokec4 ,\cb1 \
\cb3     \cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 , \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf8 \strokec8 3\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 y_3d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 , \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf8 \strokec8 7\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 y_7d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 , \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf8 \strokec8 14\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 y_14d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 ad.d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf6 \strokec6 w_user\cf4 \strokec4 , \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf8 \strokec8 30\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 y_30d\cf4 \cb1 \strokec4 \
\cb3     \cb1 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 attempt_day\cf4 \strokec4  \cf6 \strokec6 ad\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WINDOW\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 w_user\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 ad.userIdentifier\cf4 \strokec4  \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 ad.ts_txn\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 w_approved\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 ad.userIdentifier\cf4 \strokec4  \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 ad.d_txn\cf4 \strokec4 , \cf6 \strokec6 ad.ts_txn\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 approved_events\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 d_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 LEAD\cf9 \strokec9 (\cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 userIdentifier\cf4 \strokec4  \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 next_approval_date_clean\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 attempt_day\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WHERE\cf4 \strokec4  \cf6 \strokec6 day_has_approval\cf4 \strokec4  = \cf5 \strokec5 TRUE\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 5: DAILY USER AGGREGATES\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 daily_user_agg\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 d_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNT\cf9 \strokec9 (*)\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 attempts_d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 approvals_d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 status_type\cf4 \strokec4  = \cf7 \strokec7 'Rejected'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 rejects_d\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 target_cof\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 GROUP\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 userIdentifier\cf4 \strokec4 , \cf6 \strokec6 d_txn\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 6: FEATURES ROLLING A NIVEL EVENTO\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 event_target_features\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.ts_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_ts\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 6\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.attempts_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 attempts_7d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 6\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.approvals_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 approvals_7d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 6\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.rejects_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 rejects_7d\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 13\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.attempts_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 attempts_14d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 13\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.approvals_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 approvals_14d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 13\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.rejects_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 rejects_14d\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 29\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.attempts_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 attempts_30d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 29\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.approvals_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 approvals_30d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 29\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.rejects_d\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 rejects_30d\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 MAX\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 last_attempt_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 MAX\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 dua.approvals_d\cf4 \strokec4  \cf9 \strokec9 >\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 last_approval_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 MAX\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 dua.rejects_d\cf4 \strokec4  \cf9 \strokec9 >\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 last_reject_date\cf4 \cb1 \strokec4 \
\
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 event_with_target\cf4 \strokec4  \cf6 \strokec6 evt\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 daily_user_agg\cf4 \strokec4  \cf6 \strokec6 dua\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 dua.userIdentifier\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf9 \strokec9 >=\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 29\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 dua.d_txn\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 GROUP\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.d_txn\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.ts_txn\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 7: RACHAS DE RECHAZO (30d antes del evento)\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 event_reject_streaks\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 MAX\cf9 \strokec9 (\cf6 \strokec6 streak_length\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 max_reject_streak_30d\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 event_with_target\cf4 \strokec4  \cf6 \strokec6 evt\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3       \cf6 \strokec6 userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3       \cf6 \strokec6 grp\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 COUNT\cf9 \strokec9 (*)\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 streak_length\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 MIN\cf9 \strokec9 (\cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 streak_start\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 MAX\cf9 \strokec9 (\cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 streak_end\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 FROM\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3         \cf6 \strokec6 userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3         \cf6 \strokec6 d_txn\cf4 \strokec4 ,\cb1 \
\cb3         \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf6 \strokec6 d_txn\cf4 \strokec4 , \cf5 \strokec5 DATE\cf4 \strokec4  \cf7 \strokec7 '1970-01-01'\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cb1 \
\cb3           \cf9 \strokec9 -\cf4 \strokec4  \cf5 \strokec5 ROW_NUMBER\cf9 \strokec9 ()\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 userIdentifier\cf4 \strokec4  \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 grp\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 daily_user_agg\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 WHERE\cf4 \strokec4  \cf6 \strokec6 rejects_d\cf4 \strokec4  \cf9 \strokec9 >\cf4 \strokec4  \cf8 \strokec8 0\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 GROUP\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 userIdentifier\cf4 \strokec4 , \cf6 \strokec6 grp\cf4 \cb1 \strokec4 \
\cb3   \cf9 \strokec9 )\cf4 \strokec4  \cf6 \strokec6 streaks\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 streaks.userIdentifier\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 streaks.streak_end\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 streaks.streak_start\cf4 \strokec4  \cf9 \strokec9 >=\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 29\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 GROUP\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 8: INTERVALOS Y REGULARIDAD\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 target_payment_intervals\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 payment_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 LAG\cf9 \strokec9 (\cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 userIdentifier\cf4 \strokec4  \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 prev_payment_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf6 \strokec6 d_txn\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 LAG\cf9 \strokec9 (\cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 OVER\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 PARTITION\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 userIdentifier\cf4 \strokec4  \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 d_txn\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3       \cf6 \strokec6 DAY\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 payment_gap_days\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 target_cof\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WHERE\cf4 \strokec4  \cf6 \strokec6 status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 event_regularity\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNT\cf9 \strokec9 (\cf6 \strokec6 tpi.payment_gap_days\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 n_intervals\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 STDDEV\cf9 \strokec9 (\cf6 \strokec6 tpi.payment_gap_days\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 payment_interval_stddev\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 AVG\cf9 \strokec9 (\cf6 \strokec6 tpi.payment_gap_days\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 payment_interval_avg\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 MAX\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cb1 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 tpi.payment_date\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cb1 \
\cb3       \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 tpi.payment_gap_days\cf4 \strokec4  \cb1 \
\cb3     \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 last_payment_gap\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 event_with_target\cf4 \strokec4  \cf6 \strokec6 evt\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 target_payment_intervals\cf4 \strokec4  \cf6 \strokec6 tpi\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 tpi.userIdentifier\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 tpi.payment_date\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 tpi.payment_date\cf4 \strokec4  \cf9 \strokec9 >=\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 tpi.payment_gap_days\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 GROUP\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 9: FEATURES HIST\'d3RICOS DEL TARGET MERCHANT\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 event_target_history\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_date\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 MAX\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.d_txn\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 na.d_txn\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 last_payment_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 MAX\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.d_txn\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 na.d_txn\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_since_last_payment\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 ARRAY_AGG\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.d_txn\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 na.amount_mxn\cf4 \strokec4  \cf5 \strokec5 END\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 IGNORE\cf4 \strokec4  \cf5 \strokec5 NULLS\cf4 \strokec4  \cf5 \strokec5 ORDER\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 na.d_txn\cf4 \strokec4  \cf5 \strokec5 DESC\cf4 \strokec4  \cf5 \strokec5 LIMIT\cf4 \strokec4  \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )[\cf5 \strokec5 SAFE_OFFSET\cf9 \strokec9 (\cf8 \strokec8 0\cf9 \strokec9 )]\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 plan_amount\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 APPROX_TOP_COUNT\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 na.day_of_month\cf4 \strokec4  \cf5 \strokec5 END\cf4 \strokec4 , \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )[\cf5 \strokec5 SAFE_OFFSET\cf9 \strokec9 (\cf8 \strokec8 0\cf9 \strokec9 )]\cf4 \strokec4 .\cf6 \strokec6 value\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 billing_day_of_month\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 1\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m1\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 2\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m2\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 3\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m3\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 4\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m4\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 5\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m5\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 6\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m6\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.card_on_file\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 1\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m1\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.card_on_file\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 2\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m2\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.card_on_file\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 3\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m3\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.card_on_file\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 4\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m4\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.card_on_file\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 5\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m5\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.card_on_file\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 6\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m6\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_total_12m\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf8 \strokec8 6\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_total_6m\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNTIF\cf9 \strokec9 (\cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf8 \strokec8 3\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_total_3m\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 COUNT\cf9 \strokec9 (\cf5 \strokec5 DISTINCT\cf4 \strokec4  \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 na.status_type\cf4 \strokec4  = \cf7 \strokec7 'Approved'\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 na.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_months_active\cf4 \cb1 \strokec4 \
\
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 event_with_target\cf4 \strokec4  \cf6 \strokec6 evt\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 target_cof\cf4 \strokec4  \cf6 \strokec6 na\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 na.userIdentifier\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.d_txn\cf4 \strokec4  \cf9 \strokec9 >=\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 na.d_txn\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 GROUP\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 10: LIQUIDEZ ROLLING\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 general_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 tx.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 tx.transactionDate\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 txn_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SAFE_CAST\cf9 \strokec9 (\cf6 \strokec6 tx.transactionAmount\cf4 \strokec4  \cf9 \strokec9 /\cf4 \strokec4  \cf8 \strokec8 100\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 NUMERIC\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 amount\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 tt.transactionType\cf4 \strokec4  \cf5 \strokec5 IN\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3         \cf7 \strokec7 'CARD_ATM_WITHDRAWAL'\cf4 \strokec4 , \cf7 \strokec7 'CASH_OUT_AT_MERCHANT'\cf4 \strokec4 , \cf7 \strokec7 'CASH_OUT_AT_OXXO'\cf4 \strokec4 ,\cb1 \
\cb3         \cf7 \strokec7 'CASH_OUT_WITH_CARD_AT_OXXO'\cf4 \strokec4 , \cf7 \strokec7 'CARD_PURCHASE'\cf4 \strokec4 , \cf7 \strokec7 'GIFT_CARD_PURCHASE'\cf4 \strokec4 ,\cb1 \
\cb3         \cf7 \strokec7 'IN_APP_PURCHASE_BILLPAYMENT'\cf4 \strokec4 , \cf7 \strokec7 'IN_APP_PURCHASE_TAE'\cf4 \strokec4 , \cf7 \strokec7 'PUBLIC_TRANSPORT_CHARGE'\cf4 \strokec4 ,\cb1 \
\cb3         \cf7 \strokec7 'QR_MERCHANT_PAYMENT'\cf4 \strokec4 , \cf7 \strokec7 'P2P_TRANSFER_SOURCE'\cf4 \strokec4 , \cf7 \strokec7 'P2P_TRANSFER_SOURCE_CARD'\cf4 \strokec4 ,\cb1 \
\cb3         \cf7 \strokec7 'P2P_TRANSFER_SOURCE_CLABE'\cf4 \strokec4 , \cf7 \strokec7 'TRANSFER_TO_CARD'\cf4 \strokec4 , \cf7 \strokec7 'TRANSFER_TO_CLABE'\cf4 \strokec4 ,\cb1 \
\cb3         \cf7 \strokec7 'CASH_OUT_REMITTANCE'\cf4 \cb1 \strokec4 \
\cb3       \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf7 \strokec7 'outflow'\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 ELSE\cf4 \strokec4  \cf7 \strokec7 'inflow'\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 flow_type\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 `spin-dp-trusted-prod.spin_transaction.tbl_fact_transaction`\cf4 \strokec4  \cf6 \strokec6 tx\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 INNER\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 SELECT\cf4 \strokec4  \cf5 \strokec5 DISTINCT\cf4 \strokec4  \cf6 \strokec6 userIdentifier\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 target_cof\cf9 \strokec9 )\cf4 \strokec4  \cf6 \strokec6 eu\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 tx.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 eu.userIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 `spin-dp-trusted-prod.spin_catalogs.tbl_dim_transaction_type`\cf4 \strokec4  \cf6 \strokec6 tt\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 tx.transactionTypeIdentifier\cf4 \strokec4  = \cf6 \strokec6 tt.transactionTypeIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 CROSS\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 params\cf4 \strokec4  \cf6 \strokec6 p\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 WHERE\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf6 \strokec6 tx.isReversedFlag\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 CAST\cf9 \strokec9 (\cf6 \strokec6 tx.transactionTypeIdentifier\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf5 \strokec5 STRING\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 IN\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf7 \strokec7 '30'\cf4 \strokec4 ,\cf7 \strokec7 '44'\cf4 \strokec4 ,\cf7 \strokec7 '46'\cf4 \strokec4 ,\cf7 \strokec7 '22'\cf4 \strokec4 ,\cf7 \strokec7 '68'\cf4 \strokec4 ,\cf7 \strokec7 '33'\cf4 \strokec4 ,\cf7 \strokec7 '14'\cf4 \strokec4 ,\cf7 \strokec7 '70'\cf4 \strokec4 ,\cf7 \strokec7 '50'\cf4 \strokec4 ,\cf7 \strokec7 '6'\cf4 \strokec4 ,\cf7 \strokec7 '28'\cf4 \strokec4 ,\cf7 \strokec7 '61'\cf4 \strokec4 ,\cf7 \strokec7 '15'\cf4 \strokec4 ,\cf7 \strokec7 '2'\cf4 \strokec4 ,\cf7 \strokec7 '36'\cf4 \strokec4 ,\cf7 \strokec7 '24'\cf4 \strokec4 ,\cf7 \strokec7 '26'\cf4 \strokec4 ,\cf7 \strokec7 '58'\cf4 \strokec4 ,\cf7 \strokec7 '1'\cf4 \strokec4 ,\cf7 \strokec7 '3'\cf4 \strokec4 ,\cf7 \strokec7 '31'\cf4 \strokec4 ,\cf7 \strokec7 '53'\cf4 \strokec4 ,\cf7 \strokec7 '55'\cf4 \strokec4 ,\cf7 \strokec7 '76'\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 tx.transactionDate\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 p.start_date\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 p.end_date\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 event_flow_features\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_date\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 gt.txn_date\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 6\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 inflow_7d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 gt.txn_date\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 6\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 outflow_7d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 gt.txn_date\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 13\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 inflow_14d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 gt.txn_date\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 13\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 outflow_14d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 gt.txn_date\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 29\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 inflow_30d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 gt.txn_date\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 29\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 outflow_30d\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m1\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 2\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m2\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 3\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m3\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 4\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m4\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 5\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m5\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 6\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m6\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m1\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 2\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m2\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 3\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m3\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 4\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m4\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 5\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m5\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  = \cf8 \strokec8 6\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m6\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf8 \strokec8 6\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 inflow_total_6m\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 inflow_total_12m\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf8 \strokec8 6\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 outflow_total_6m\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'outflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 outflow_total_12m\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf9 \strokec9 -\cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 net_flow_12m\cf4 \strokec4 ,\cb1 \
\
\cb3     \cf5 \strokec5 SAFE_DIVIDE\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf8 \strokec8 3\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3       \cf5 \strokec5 NULLIF\cf9 \strokec9 (\cf5 \strokec5 SUM\cf9 \strokec9 (\cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 gt.flow_type\cf4 \strokec4  = \cf7 \strokec7 'inflow'\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf6 \strokec6 gt.txn_date\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf8 \strokec8 10\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf6 \strokec6 gt.amount\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 trend_income_ratio\cf4 \cb1 \strokec4 \
\
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 event_with_target\cf4 \strokec4  \cf6 \strokec6 evt\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 general_txn\cf4 \strokec4  \cf6 \strokec6 gt\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 gt.userIdentifier\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 gt.txn_date\cf4 \strokec4  \cf9 \strokec9 >=\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 12\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 gt.txn_date\cf4 \strokec4  \cf9 \strokec9 <\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 GROUP\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 11: FLAGS DE CAMBIO DE R\'c9GIMEN\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 event_regime_changes\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNT\cf9 \strokec9 (\cf5 \strokec5 DISTINCT\cf4 \strokec4  \cf6 \strokec6 nc.amount_cents\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 distinct_plans_30d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 COUNT\cf9 \strokec9 (\cf5 \strokec5 DISTINCT\cf4 \strokec4  \cf6 \strokec6 nc.xCard_last_four_digits\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 distinct_cards_30d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 COUNT\cf9 \strokec9 (\cf5 \strokec5 DISTINCT\cf4 \strokec4  \cf6 \strokec6 nc.amount_cents\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 >\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 plan_change_flag_30d\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 CASE\cf4 \strokec4  \cf5 \strokec5 WHEN\cf4 \strokec4  \cf5 \strokec5 COUNT\cf9 \strokec9 (\cf5 \strokec5 DISTINCT\cf4 \strokec4  \cf6 \strokec6 nc.xCard_last_four_digits\cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 >\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \strokec4  \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 card_change_flag_30d\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 event_with_target\cf4 \strokec4  \cf6 \strokec6 evt\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 target_cof\cf4 \strokec4  \cf6 \strokec6 nc\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 nc.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 evt.userIdentifier\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 nc.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf5 \strokec5 DATE_SUB\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 29\cf4 \strokec4  \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 GROUP\cf4 \strokec4  \cf5 \strokec5 BY\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 , \cf6 \strokec6 evt.d_txn\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \strokec4 ,\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- PASO 12: USER PROFILE\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 user_profile\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\cb3     \cf6 \strokec6 a.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 a.userTypeIdentifier\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 g.genderType\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gender\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 a.stateName\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 state_name\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 a.createdAccountDate\cf4 \strokec4 , \cf7 \strokec7 "America/Mexico_City"\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 signup_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 DATE\cf9 \strokec9 (\cf6 \strokec6 a.birthDate\cf4 \strokec4 , \cf7 \strokec7 "America/Mexico_City"\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 birth_date\cf4 \strokec4 ,\cb1 \
\cb3     \cf5 \strokec5 IF\cf9 \strokec9 (\cf6 \strokec6 pm.accountid\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \strokec4 , \cf8 \strokec8 1\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 has_premia\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 `spin-dp-trusted-prod.spin_account.tbl_dim_user`\cf4 \strokec4  \cf6 \strokec6 a\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 `spin-dp-trusted-prod.spin_catalogs.tbl_dim_gender`\cf4 \strokec4  \cf6 \strokec6 g\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 a.genderIdentifier\cf4 \strokec4  = \cf6 \strokec6 g.genderIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 `daf-dp-trusted-prod.coa_mastertables.tbl_users`\cf4 \strokec4  \cf6 \strokec6 pm\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 a.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 pm.userid\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 )\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- OUTPUT FINAL\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 -- =============================================================================\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 SELECT\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_date\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.ts_txn\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 event_ts\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.attempt_seq\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.status_type\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.decline_code\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.xCard_last_four_digits\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.amount_cents\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.amount_mxn\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.tipo_tarjeta\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.day_of_month\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.attempts_in_day\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.approvals_in_day\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.rejects_in_day\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.day_has_approval\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 evt.days_to_next_attempt\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.next_attempt_date\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.next_attempt_status\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 ae.next_approval_date_clean\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 next_approval_date\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf6 \strokec6 ae.next_approval_date_clean\cf4 \strokec4 , \cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_to_next_approval\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 evt.time_to_event_days\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.event_observed\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.is_censored\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.y_3d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.y_7d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.y_14d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.y_30d\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 evt.prev_attempt_date\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 evt.days_since_prev_attempt\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 etf.attempts_7d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.approvals_7d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.rejects_7d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.attempts_14d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.approvals_14d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.rejects_14d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.attempts_30d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.approvals_30d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.rejects_30d\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf5 \strokec5 SAFE_DIVIDE\cf9 \strokec9 (\cf6 \strokec6 etf.rejects_30d\cf4 \strokec4 , \cf6 \strokec6 etf.attempts_30d\cf9 \strokec9 )\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 decline_rate_30d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.rejects_7d\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 retry_intensity_7d\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 etf.last_attempt_date\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.last_approval_date\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 etf.last_reject_date\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 etf.last_attempt_date\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_since_last_attempt\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 etf.last_approval_date\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_since_last_approval\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 etf.last_reject_date\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_since_last_reject\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf6 \strokec6 ers.max_reject_streak_30d\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 max_reject_streak_30d\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 eth.last_payment_date\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eth.days_since_last_payment\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eth.plan_amount\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eth.billing_day_of_month\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 CASE\cf4 \strokec4  \cb1 \
\cb3     \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 eth.last_payment_date\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 DATE_ADD\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf5 \strokec5 DATE_ADD\cf9 \strokec9 (\cf6 \strokec6 eth.last_payment_date\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3         \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf5 \strokec5 LEAST\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3           \cf5 \strokec5 EXTRACT\cf9 \strokec9 (\cf6 \strokec6 DAY\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 eth.last_payment_date\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3           \cf5 \strokec5 EXTRACT\cf9 \strokec9 (\cf6 \strokec6 DAY\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf5 \strokec5 LAST_DAY\cf9 \strokec9 (\cf5 \strokec5 DATE_ADD\cf9 \strokec9 (\cf6 \strokec6 eth.last_payment_date\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )))\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 -\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf4 \cb1 \strokec4 \
\cb3       \cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 predicted_next_due_date\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 CASE\cf4 \strokec4  \cb1 \
\cb3     \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 eth.last_payment_date\cf4 \strokec4  \cf5 \strokec5 IS\cf4 \strokec4  \cf5 \strokec5 NOT\cf4 \strokec4  \cf5 \strokec5 NULL\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \cb1 \strokec4 \
\cb3       \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 DATE_ADD\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3           \cf5 \strokec5 DATE_TRUNC\cf9 \strokec9 (\cf5 \strokec5 DATE_ADD\cf9 \strokec9 (\cf6 \strokec6 eth.last_payment_date\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 , \cf6 \strokec6 MONTH\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3           \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf5 \strokec5 LEAST\cf9 \strokec9 (\cf4 \cb1 \strokec4 \
\cb3             \cf5 \strokec5 EXTRACT\cf9 \strokec9 (\cf6 \strokec6 DAY\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 eth.last_payment_date\cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3             \cf5 \strokec5 EXTRACT\cf9 \strokec9 (\cf6 \strokec6 DAY\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf5 \strokec5 LAST_DAY\cf9 \strokec9 (\cf5 \strokec5 DATE_ADD\cf9 \strokec9 (\cf6 \strokec6 eth.last_payment_date\cf4 \strokec4 , \cf5 \strokec5 INTERVAL\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 MONTH\cf9 \strokec9 )))\cf4 \cb1 \strokec4 \
\cb3           \cf9 \strokec9 )\cf4 \strokec4  \cf9 \strokec9 -\cf4 \strokec4  \cf8 \strokec8 1\cf4 \strokec4  \cf6 \strokec6 DAY\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 )\cf4 \strokec4 ,\cb1 \
\cb3         \cf6 \strokec6 evt.d_txn\cf4 \strokec4 ,\cb1 \
\cb3         \cf6 \strokec6 DAY\cf4 \cb1 \strokec4 \
\cb3       \cf9 \strokec9 )\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_to_predicted_due\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_m1\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m1\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_m2\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m2\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_m3\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m3\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_m4\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m4\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_m5\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m5\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_m6\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_m6\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_cof_m1\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m1\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_cof_m2\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m2\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_cof_m3\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m3\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_cof_m4\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m4\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_cof_m5\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m5\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_cof_m6\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_cof_m6\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_total_12m\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_total_12m\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_total_6m\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_total_6m\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_txn_total_3m\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_txn_total_3m\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eth.target_months_active\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 target_months_active\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 er.n_intervals\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 er.payment_interval_stddev\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 er.payment_interval_avg\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 er.last_payment_gap\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf6 \strokec6 eff.inflow_7d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.outflow_7d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.inflow_7d\cf4 \strokec4  \cf9 \strokec9 -\cf4 \strokec4  \cf6 \strokec6 eff.outflow_7d\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 net_flow_7d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.inflow_14d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.outflow_14d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.inflow_14d\cf4 \strokec4  \cf9 \strokec9 -\cf4 \strokec4  \cf6 \strokec6 eff.outflow_14d\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 net_flow_14d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.inflow_30d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.outflow_30d\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.inflow_30d\cf4 \strokec4  \cf9 \strokec9 -\cf4 \strokec4  \cf6 \strokec6 eff.outflow_30d\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 net_flow_30d\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_inflow_m1\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m1\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_inflow_m2\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m2\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_inflow_m3\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m3\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_inflow_m4\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m4\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_inflow_m5\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m5\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_inflow_m6\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_inflow_m6\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_outflow_m1\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m1\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_outflow_m2\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m2\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_outflow_m3\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m3\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_outflow_m4\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m4\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_outflow_m5\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m5\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.gen_amt_outflow_m6\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gen_amt_outflow_m6\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.inflow_total_6m\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 inflow_total_6m\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.inflow_total_12m\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 inflow_total_12m\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.outflow_total_6m\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 outflow_total_6m\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.outflow_total_12m\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 outflow_total_12m\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 eff.net_flow_12m\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 net_flow_12m\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 eff.trend_income_ratio\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf6 \strokec6 erc.distinct_plans_30d\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 distinct_plans_30d\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf6 \strokec6 erc.distinct_cards_30d\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 distinct_cards_30d\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf6 \strokec6 erc.plan_change_flag_30d\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 plan_change_flag_30d\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 COALESCE\cf9 \strokec9 (\cf6 \strokec6 erc.card_change_flag_30d\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 card_change_flag_30d\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 up.gender\cf4 \strokec4 , \cf7 \strokec7 'Unknown'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 gender\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 up.state_name\cf4 \strokec4 , \cf7 \strokec7 'Unknown'\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 state_name\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 up.birth_date\cf4 \strokec4 , \cf6 \strokec6 YEAR\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 user_age_years\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 DATE_DIFF\cf9 \strokec9 (\cf6 \strokec6 evt.d_txn\cf4 \strokec4 , \cf6 \strokec6 up.signup_date\cf4 \strokec4 , \cf6 \strokec6 DAY\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 days_on_book\cf4 \strokec4 ,\cb1 \
\cb3   \cf5 \strokec5 IFNULL\cf9 \strokec9 (\cf6 \strokec6 up.has_premia\cf4 \strokec4 , \cf8 \strokec8 0\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 has_premia\cf4 \strokec4 ,\cb1 \
\cb3   \cf6 \strokec6 up.userTypeIdentifier\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf5 \strokec5 CASE\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 WHEN\cf4 \strokec4  \cf6 \strokec6 eth.days_since_last_payment\cf4 \strokec4  \cf9 \strokec9 <=\cf4 \strokec4  \cf6 \strokec6 cohort_max_days_since_last\cf4 \strokec4  \cf5 \strokec5 THEN\cf4 \strokec4  \cf8 \strokec8 1\cf4 \cb1 \strokec4 \
\cb3     \cf5 \strokec5 ELSE\cf4 \strokec4  \cf8 \strokec8 0\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 END\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 in_cohort_operable\cf4 \strokec4 ,\cb1 \
\
\cb3   \cf9 \strokec9 (\cf5 \strokec5 SELECT\cf4 \strokec4  \cf6 \strokec6 today\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 params\cf9 \strokec9 )\cf4 \strokec4  \cf5 \strokec5 AS\cf4 \strokec4  \cf6 \strokec6 run_date\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 event_with_target\cf4 \strokec4  \cf6 \strokec6 evt\cf4 \cb1 \strokec4 \
\
\cf5 \cb3 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 approved_events\cf4 \strokec4  \cf6 \strokec6 ae\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 ae.userIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  = \cf6 \strokec6 ae.d_txn\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 event_target_features\cf4 \strokec4  \cf6 \strokec6 etf\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 etf.userIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  = \cf6 \strokec6 etf.event_date\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 event_reject_streaks\cf4 \strokec4  \cf6 \strokec6 ers\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 ers.userIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  = \cf6 \strokec6 ers.event_date\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 event_regularity\cf4 \strokec4  \cf6 \strokec6 er\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 er.userIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  = \cf6 \strokec6 er.event_date\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 event_target_history\cf4 \strokec4  \cf6 \strokec6 eth\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 eth.userIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  = \cf6 \strokec6 eth.event_date\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 event_flow_features\cf4 \strokec4  \cf6 \strokec6 eff\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 eff.userIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  = \cf6 \strokec6 eff.event_date\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 event_regime_changes\cf4 \strokec4  \cf6 \strokec6 erc\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 erc.userIdentifier\cf4 \cb1 \strokec4 \
\cb3   \cf5 \strokec5 AND\cf4 \strokec4  \cf6 \strokec6 evt.d_txn\cf4 \strokec4  = \cf6 \strokec6 erc.event_date\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 LEFT\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 user_profile\cf4 \strokec4  \cf6 \strokec6 up\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf5 \strokec5 ON\cf4 \strokec4  \cf6 \strokec6 evt.userIdentifier\cf4 \strokec4  = \cf6 \strokec6 up.userIdentifier\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 CROSS\cf4 \strokec4  \cf5 \strokec5 JOIN\cf4 \strokec4  \cf6 \strokec6 params\cf4 \strokec4  \cf6 \strokec6 p\cf4 \cb1 \strokec4 \
\cf5 \cb3 \strokec5 WHERE\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3   \cf6 \strokec6 evt.d_txn\cf4 \strokec4  \cf5 \strokec5 BETWEEN\cf4 \strokec4  \cf6 \strokec6 p.start_date\cf4 \strokec4  \cf5 \strokec5 AND\cf4 \strokec4  \cf9 \strokec9 (\cf5 \strokec5 SELECT\cf4 \strokec4  \cf6 \strokec6 today\cf4 \strokec4  \cf5 \strokec5 FROM\cf4 \strokec4  \cf6 \strokec6 params\cf9 \strokec9 )\cf4 \cb1 \strokec4 \
}