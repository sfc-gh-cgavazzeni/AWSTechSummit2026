-- Create Cortex Search Services for semantic search over reviews and tickets
-- Co-authored with CoCo
-- ==================================================================================
-- MODULE 3: CREATE CORTEX SEARCH SERVICES — RetailIQ Workshop
-- ==================================================================================
-- Creates two Cortex Search Services for semantic search over unstructured text:
--   1. RETAILIQ_REVIEWS_SEARCH  — customer reviews
--   2. RETAILIQ_TICKETS_SEARCH  — support tickets
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- CORTEX SEARCH SERVICE: RETAILIQ_REVIEWS_SEARCH
-- ==================================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE RETAILIQ_REVIEWS_SEARCH
    ON REVIEW_TEXT
    ATTRIBUTES REVIEW_ID, ORDER_ID, CUSTOMER_ID, PRODUCT_NAME, CATEGORY, RATING, SENTIMENT_LABEL, REVIEW_DATE, STORE_REGION, VERIFIED_PURCHASE
    WAREHOUSE = RETAILIQ_WH
    TARGET_LAG = '5 MIN'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
AS (
    SELECT
        REVIEW_ID,
        ORDER_ID,
        CUSTOMER_ID,
        PRODUCT_NAME,
        CATEGORY,
        REVIEW_TEXT,
        RATING,
        SENTIMENT_LABEL,
        REVIEW_DATE,
        STORE_REGION,
        VERIFIED_PURCHASE
    FROM CUSTOMER_REVIEWS
);

-- ==================================================================================
-- CORTEX SEARCH SERVICE: RETAILIQ_TICKETS_SEARCH
-- ==================================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE RETAILIQ_TICKETS_SEARCH
    ON TICKET_TEXT
    ATTRIBUTES TICKET_ID, CUSTOMER_ID, ORDER_ID, CATEGORY, PRIORITY, STATUS, CREATED_AT
    WAREHOUSE = RETAILIQ_WH
    TARGET_LAG = '5 MIN'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
AS (
    SELECT
        TICKET_ID,
        CUSTOMER_ID,
        ORDER_ID,
        TICKET_TEXT,
        CATEGORY,
        PRIORITY,
        STATUS,
        CREATED_AT
    FROM SUPPORT_TICKETS
);

-- ==================================================================================
-- VERIFICATION: Describe Services
-- ==================================================================================
DESCRIBE CORTEX SEARCH SERVICE RETAILIQ_REVIEWS_SEARCH;
DESCRIBE CORTEX SEARCH SERVICE RETAILIQ_TICKETS_SEARCH;

-- ==================================================================================
-- VERIFICATION: Row Counts via CORTEX_SEARCH_DATA_SCAN
-- ==================================================================================
SELECT COUNT(*) AS REVIEWS_INDEXED
FROM TABLE(CORTEX_SEARCH_DATA_SCAN(SERVICE_NAME => 'RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH'));

SELECT COUNT(*) AS TICKETS_INDEXED
FROM TABLE(CORTEX_SEARCH_DATA_SCAN(SERVICE_NAME => 'RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH'));

-- ==================================================================================
-- EXAMPLE TEST QUERIES (run these to validate the search services)
-- ==================================================================================
-- Example 1: Find reviews about product quality issues
-- SELECT * FROM TABLE(RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH!SEARCH(
--     QUERY => 'product broke after one week poor quality',
--     COLUMNS => ['REVIEW_TEXT', 'PRODUCT_NAME', 'CATEGORY', 'RATING', 'SENTIMENT_LABEL'],
--     LIMIT => 5
-- ));

-- Example 2: Find positive reviews about customer service
-- SELECT * FROM TABLE(RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH!SEARCH(
--     QUERY => 'excellent customer service helpful staff',
--     COLUMNS => ['REVIEW_TEXT', 'PRODUCT_NAME', 'RATING', 'STORE_REGION'],
--     FILTER => {'@eq': {'VERIFIED_PURCHASE': TRUE}},
--     LIMIT => 5
-- ));

-- Example 3: Find tickets about shipping delays
-- SELECT * FROM TABLE(RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH!SEARCH(
--     QUERY => 'shipping delay package not arrived late delivery',
--     COLUMNS => ['TICKET_TEXT', 'CATEGORY', 'PRIORITY', 'STATUS'],
--     LIMIT => 5
-- ));

-- Example 4: Find high-priority refund requests
-- SELECT * FROM TABLE(RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH!SEARCH(
--     QUERY => 'refund request money back charged incorrectly',
--     COLUMNS => ['TICKET_TEXT', 'CATEGORY', 'PRIORITY', 'STATUS'],
--     FILTER => {'@eq': {'PRIORITY': 'High'}},
--     LIMIT => 5
-- ));

-- Example 5: Find reviews mentioning specific product defects
-- SELECT * FROM TABLE(RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH!SEARCH(
--     QUERY => 'defective damaged broken missing parts',
--     COLUMNS => ['REVIEW_TEXT', 'PRODUCT_NAME', 'CATEGORY', 'RATING'],
--     FILTER => {'@lte': {'RATING': 2}},
--     LIMIT => 5
-- ));

-- ==================================================================================
-- END OF MODULE 3
-- ==================================================================================
