-- =============================================================================
-- RetailIQ Semantic View — Upload & Registration Script
-- =============================================================================
-- Purpose : Upload retailiq_semantic_view.yaml to the Snowflake stage and
--           make it available to Cortex Analyst.
-- Prerequisites:
--   • RETAILIQ_ROLE granted to your user
--   • Stage RETAILIQ_DB.ANALYTICS.RETAILIQ_STG already exists
--   • SnowSQL or the Snowflake VSCode extension installed locally
-- =============================================================================

-- STEP 1 — Set session context
-- -----------------------------------------------------------------------------
USE ROLE    RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA  ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;


-- STEP 2 — Create the stage (idempotent; skip if it already exists)
-- -----------------------------------------------------------------------------
CREATE STAGE IF NOT EXISTS RETAILIQ_DB.ANALYTICS.RETAILIQ_STG
    DIRECTORY = ( ENABLE = TRUE )
    COMMENT   = 'Stage for Cortex Analyst semantic model YAML files';


-- STEP 3 — Upload the YAML file to the stage
-- -----------------------------------------------------------------------------
-- NOTE: The PUT command must be executed from SnowSQL (CLI) or via the
--       Snowflake Python connector / JDBC driver.  It cannot be run directly
--       inside Snowsight's SQL worksheet because the worksheet has no access
--       to your local filesystem.
--
-- Option A — SnowSQL CLI (recommended for workshops):
--
--   Open a terminal in the folder that contains this script and run:
--
--     snowsql -a <account> -u <user> -r RETAILIQ_ROLE \
--             -d RETAILIQ_DB -s ANALYTICS \
--             -q "PUT file://retailiq_semantic_view.yaml @RETAILIQ_DB.ANALYTICS.RETAILIQ_STG AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
--
-- Option B — snow CLI (Snowflake CLI):
--
--     snow stage copy retailiq_semantic_view.yaml @RETAILIQ_DB.ANALYTICS.RETAILIQ_STG \
--          --overwrite --connection <connection_name>
--
-- Option C — Snowsight UI upload:
--   1. Navigate to Data → Databases → RETAILIQ_DB → ANALYTICS → Stages → RETAILIQ_STG
--   2. Click "+ Files" and upload retailiq_semantic_view.yaml

-- Paste this PUT statement into SnowSQL or your driver session:
PUT file://retailiq_semantic_view.yaml @RETAILIQ_DB.ANALYTICS.RETAILIQ_STG
    AUTO_COMPRESS = FALSE
    OVERWRITE     = TRUE;


-- STEP 4 — Verify the file is on the stage
-- -----------------------------------------------------------------------------
LIST @RETAILIQ_DB.ANALYTICS.RETAILIQ_STG PATTERN='.*retailiq_semantic_view.*';


-- =============================================================================
-- STEP 5 — Using the Semantic Model with Cortex Analyst
-- =============================================================================
--
-- Cortex Analyst reads the YAML from the stage at query time.
-- There is NO "CREATE SEMANTIC VIEW FROM STAGE" DDL in Snowflake.
--
-- ── Option A: Snowsight Cortex Analyst UI ────────────────────────────────────
--   1. In Snowsight, open the left sidebar → "AI & ML" → "Cortex Analyst"
--      (or navigate to the Cortex Analyst Playground tab inside a worksheet).
--   2. Click "Select a semantic model".
--   3. Browse to @RETAILIQ_DB.ANALYTICS.RETAILIQ_STG and select
--      retailiq_semantic_view.yaml.
--   4. Start asking questions in natural language — the model will generate
--      SQL grounded in the RETAILIQ_SV semantic definition.
--
-- ── Option B: REST API (programmatic / app integration) ──────────────────────
--   POST https://<account>.snowflakecomputing.com/api/v2/cortex/analyst/message
--   Headers:
--     Authorization: Bearer <session_token>
--     Content-Type:  application/json
--   Body:
--     {
--       "messages": [
--         {"role": "user", "content": [{"type": "text", "text": "<your question>"}]}
--       ],
--       "semantic_model_file": "@RETAILIQ_DB.ANALYTICS.RETAILIQ_STG/retailiq_semantic_view.yaml"
--     }
--
-- ── Option C: Native Snowflake Semantic View DDL (alternative approach) ───────
--   Snowflake also supports CREATE SEMANTIC VIEW as a first-class DDL object.
--   This approach embeds the model definition as SQL DDL instead of a YAML file.
--   See: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-model-spec
--
--   Example skeleton (NOT equivalent to the YAML above — requires full rewrite):
--
--   CREATE OR REPLACE SEMANTIC VIEW RETAILIQ_DB.ANALYTICS.RETAILIQ_SV
--     TABLES (
--       orders  WITH BASE TABLE RETAILIQ_DB.ANALYTICS.ORDERS  AS o,
--       products WITH BASE TABLE RETAILIQ_DB.ANALYTICS.PRODUCTS AS p,
--       ...
--     )
--     RELATIONSHIPS ( ... )
--     DIMENSIONS    ( ... )
--     METRICS       ( ... );
--
--   For the workshop, the YAML-on-stage approach (Options A/B) is recommended
--   because it allows rapid iteration without DDL re-deployment.
--
-- =============================================================================


-- STEP 6 — Quick smoke-test via SQL (calls Cortex Analyst programmatically)
-- -----------------------------------------------------------------------------
-- Requires SNOWFLAKE.CORTEX_USER role or equivalent Cortex privilege.

SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'mistral-large2',
    'You are a Snowflake Cortex Analyst assistant. A user asked: '
    || '"What are the top 5 product categories by revenue this year?" '
    || 'Answer only with the SQL query that Cortex Analyst would generate '
    || 'against the RetailIQ semantic model.'
) AS sample_response;

-- =============================================================================
-- END OF SCRIPT
-- =============================================================================
