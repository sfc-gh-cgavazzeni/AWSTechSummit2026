-- ==================================================================================
-- MODULE 1: CREATE TABLES — RetailIQ Workshop
-- ==================================================================================
-- Creates all 6 tables in RETAILIQ_DB.ANALYTICS for the workshop dataset.
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- TABLE: ORDERS
-- Primary Key: ORDER_ID
-- ==================================================================================
CREATE OR REPLACE TABLE ORDERS (
    ORDER_ID        VARCHAR     COMMENT 'Primary Key — Unique order identifier',
    CUSTOMER_ID     VARCHAR,
    PRODUCT_ID      VARCHAR,
    STORE_ID        VARCHAR,
    ORDER_DATE      DATE,
    QUANTITY        INT,
    UNIT_PRICE      FLOAT,
    TOTAL_AMOUNT    FLOAT,
    DISCOUNT_PCT    FLOAT,
    CHANNEL         VARCHAR,
    STATUS          VARCHAR,
    RETURN_FLAG     BOOLEAN,
    SHIPPING_DAYS   INT
)
COMMENT = 'Retail orders — ~50K rows covering multiple channels and regions';

-- ==================================================================================
-- TABLE: PRODUCTS
-- Primary Key: PRODUCT_ID
-- ==================================================================================
CREATE OR REPLACE TABLE PRODUCTS (
    PRODUCT_ID      VARCHAR     COMMENT 'Primary Key — Unique product identifier',
    PRODUCT_NAME    VARCHAR,
    CATEGORY        VARCHAR,
    SUBCATEGORY     VARCHAR,
    BRAND           VARCHAR,
    UNIT_COST       FLOAT,
    LIST_PRICE      FLOAT,
    IS_PREMIUM      BOOLEAN
)
COMMENT = 'Product catalog — ~200 products across categories';

-- ==================================================================================
-- TABLE: CUSTOMERS
-- Primary Key: CUSTOMER_ID
-- ==================================================================================
CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID     VARCHAR     COMMENT 'Primary Key — Unique customer identifier',
    FIRST_NAME      VARCHAR,
    LAST_NAME       VARCHAR,
    EMAIL           VARCHAR,
    CITY            VARCHAR,
    REGION          VARCHAR,
    COUNTRY         VARCHAR,
    SIGNUP_DATE     DATE,
    LOYALTY_TIER    VARCHAR,
    AGE_GROUP       VARCHAR
)
COMMENT = 'Customer profiles — ~5K customers with demographics and loyalty tiers';

-- ==================================================================================
-- TABLE: STORES
-- Primary Key: STORE_ID
-- ==================================================================================
CREATE OR REPLACE TABLE STORES (
    STORE_ID        VARCHAR     COMMENT 'Primary Key — Unique store identifier',
    STORE_NAME      VARCHAR,
    CITY            VARCHAR,
    REGION          VARCHAR,
    STORE_TYPE      VARCHAR,
    OPENING_YEAR    INT,
    EMPLOYEE_COUNT  INT
)
COMMENT = 'Store locations — ~50 stores across regions';

-- ==================================================================================
-- TABLE: CUSTOMER_REVIEWS
-- Primary Key: REVIEW_ID
-- ==================================================================================
CREATE OR REPLACE TABLE CUSTOMER_REVIEWS (
    REVIEW_ID           VARCHAR     COMMENT 'Primary Key — Unique review identifier',
    ORDER_ID            VARCHAR,
    CUSTOMER_ID         VARCHAR,
    PRODUCT_NAME        VARCHAR,
    CATEGORY            VARCHAR,
    REVIEW_TEXT         VARCHAR(2000),
    RATING              INT,
    SENTIMENT_LABEL     VARCHAR,
    REVIEW_DATE         DATE,
    STORE_REGION        VARCHAR,
    VERIFIED_PURCHASE   BOOLEAN
)
COMMENT = 'Customer reviews with sentiment — ~15K reviews for Cortex Search';

-- ==================================================================================
-- TABLE: SUPPORT_TICKETS
-- Primary Key: TICKET_ID
-- ==================================================================================
CREATE OR REPLACE TABLE SUPPORT_TICKETS (
    TICKET_ID       VARCHAR     COMMENT 'Primary Key — Unique ticket identifier',
    CUSTOMER_ID     VARCHAR,
    ORDER_ID        VARCHAR,
    TICKET_TEXT     VARCHAR(2000),
    CATEGORY        VARCHAR,
    PRIORITY        VARCHAR,
    STATUS          VARCHAR,
    CREATED_AT      TIMESTAMP_NTZ,
    RESOLVED_AT     TIMESTAMP_NTZ
)
COMMENT = 'Support tickets — ~8K tickets for Cortex Search';

-- ==================================================================================
-- VERIFICATION: Confirm tables were created (all counts should be 0)
-- ==================================================================================
SELECT 'ORDERS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM ORDERS
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS
UNION ALL
SELECT 'STORES', COUNT(*) FROM STORES
UNION ALL
SELECT 'CUSTOMER_REVIEWS', COUNT(*) FROM CUSTOMER_REVIEWS
UNION ALL
SELECT 'SUPPORT_TICKETS', COUNT(*) FROM SUPPORT_TICKETS;

-- ==================================================================================
-- END OF MODULE 1
-- ==================================================================================
