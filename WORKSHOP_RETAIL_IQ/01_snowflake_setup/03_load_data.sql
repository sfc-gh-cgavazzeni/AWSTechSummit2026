-- ==================================================================================
-- MODULE 2: LOAD DATA — RetailIQ Workshop
-- ==================================================================================
-- Loads CSV data from the RETAILIQ_STG stage into all 6 tables.
-- Ensure CSV files have been uploaded to the stage before running this script.
--
-- Expected row counts:
--   orders           ~ 50,000
--   products         ~    200
--   customers        ~  5,000
--   stores           ~     50
--   customer_reviews ~ 15,000
--   support_tickets  ~  8,000
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- VERIFY STAGE FILES
-- ==================================================================================
LS @RETAILIQ_STG;

-- ==================================================================================
-- LOAD: ORDERS (~50,000 rows)
-- ==================================================================================
COPY INTO ORDERS
    FROM @RETAILIQ_STG/orders.csv
    FILE_FORMAT = (
        TYPE = 'CSV'
        FIELD_DELIMITER = ','
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    )
    ON_ERROR = CONTINUE;

-- ==================================================================================
-- LOAD: PRODUCTS (~200 rows)
-- ==================================================================================
COPY INTO PRODUCTS
    FROM @RETAILIQ_STG/products.csv
    FILE_FORMAT = (
        TYPE = 'CSV'
        FIELD_DELIMITER = ','
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    )
    ON_ERROR = CONTINUE;

-- ==================================================================================
-- LOAD: CUSTOMERS (~5,000 rows)
-- ==================================================================================
COPY INTO CUSTOMERS
    FROM @RETAILIQ_STG/customers.csv
    FILE_FORMAT = (
        TYPE = 'CSV'
        FIELD_DELIMITER = ','
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    )
    ON_ERROR = CONTINUE;

-- ==================================================================================
-- LOAD: STORES (~50 rows)
-- ==================================================================================
COPY INTO STORES
    FROM @RETAILIQ_STG/stores.csv
    FILE_FORMAT = (
        TYPE = 'CSV'
        FIELD_DELIMITER = ','
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    )
    ON_ERROR = CONTINUE;

-- ==================================================================================
-- LOAD: CUSTOMER_REVIEWS (~15,000 rows)
-- ==================================================================================
COPY INTO CUSTOMER_REVIEWS
    FROM @RETAILIQ_STG/customer_reviews.csv
    FILE_FORMAT = (
        TYPE = 'CSV'
        FIELD_DELIMITER = ','
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    )
    ON_ERROR = CONTINUE;

-- ==================================================================================
-- LOAD: SUPPORT_TICKETS (~8,000 rows)
-- ==================================================================================
COPY INTO SUPPORT_TICKETS
    FROM @RETAILIQ_STG/support_tickets.csv
    FILE_FORMAT = (
        TYPE = 'CSV'
        FIELD_DELIMITER = ','
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    )
    ON_ERROR = CONTINUE;

-- ==================================================================================
-- VERIFICATION: Row Counts
-- ==================================================================================
SELECT 'ORDERS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM ORDERS              -- Expected: ~50,000
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS                                      -- Expected: ~200
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS                                    -- Expected: ~5,000
UNION ALL
SELECT 'STORES', COUNT(*) FROM STORES                                          -- Expected: ~50
UNION ALL
SELECT 'CUSTOMER_REVIEWS', COUNT(*) FROM CUSTOMER_REVIEWS                      -- Expected: ~15,000
UNION ALL
SELECT 'SUPPORT_TICKETS', COUNT(*) FROM SUPPORT_TICKETS;                       -- Expected: ~8,000

-- ==================================================================================
-- VERIFICATION: Sample Data (5 rows per table)
-- ==================================================================================
SELECT * FROM ORDERS LIMIT 5;
SELECT * FROM PRODUCTS LIMIT 5;
SELECT * FROM CUSTOMERS LIMIT 5;
SELECT * FROM STORES LIMIT 5;
SELECT * FROM CUSTOMER_REVIEWS LIMIT 5;
SELECT * FROM SUPPORT_TICKETS LIMIT 5;

-- ==================================================================================
-- END OF MODULE 2
-- ==================================================================================
