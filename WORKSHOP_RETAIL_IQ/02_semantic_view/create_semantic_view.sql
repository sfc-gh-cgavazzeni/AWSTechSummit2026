-- ==================================================================================
-- MODULE 2b: CREATE SEMANTIC VIEW — RetailIQ Workshop
-- ==================================================================================
-- Creates the tuned RETAILIQ_SV semantic view using DDL syntax.
-- This semantic view defines business metrics, dimensions, and verified queries
-- that power Cortex Analyst for natural language analytics.
--
-- Prerequisites:
--   - Tables must exist (run 02_create_tables.sql + 03_load_data.sql first)
--   - Use RETAILIQ_ROLE with CREATE SEMANTIC VIEW privilege on the schema
--
-- IMPORTANT NOTES on DDL syntax:
--   - Entity aliases (AS ...) MUST match the physical column name (case-insensitive)
--   - Metrics reference entity aliases (= physical column names) in expressions
--   - Verified queries use __tablename prefix with physical column names
--   - Two tables CAN share the same alias for the same-named column (e.g. REGION)
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- CREATE THE SEMANTIC VIEW
-- ==================================================================================

CREATE OR REPLACE SEMANTIC VIEW RETAILIQ_SV

  -- ════════════════════════════════════════════════════════════════════════════════
  -- TABLES
  -- ════════════════════════════════════════════════════════════════════════════════
  TABLES (
    RETAILIQ_DB.ANALYTICS.ORDERS
      PRIMARY KEY (ORDER_ID)
      COMMENT = 'Transactional order records including channel, pricing, quantity, discount, shipping, and return details.',

    RETAILIQ_DB.ANALYTICS.PRODUCTS
      PRIMARY KEY (PRODUCT_ID)
      COMMENT = 'Product catalog with category hierarchy, brand, cost, list price, and premium flag.',

    RETAILIQ_DB.ANALYTICS.CUSTOMERS
      PRIMARY KEY (CUSTOMER_ID)
      COMMENT = 'Customer master data including location (city/region), loyalty tier, age group, and signup date.',

    RETAILIQ_DB.ANALYTICS.STORES
      PRIMARY KEY (STORE_ID)
      COMMENT = 'Physical and digital store locations with type, region, opening year, and employee headcount.'
  )

  -- ════════════════════════════════════════════════════════════════════════════════
  -- RELATIONSHIPS
  -- ════════════════════════════════════════════════════════════════════════════════
  RELATIONSHIPS (
    ORDERS_TO_CUSTOMERS AS ORDERS(CUSTOMER_ID) REFERENCES CUSTOMERS(CUSTOMER_ID),
    ORDERS_TO_PRODUCTS  AS ORDERS(PRODUCT_ID)  REFERENCES PRODUCTS(PRODUCT_ID),
    ORDERS_TO_STORES    AS ORDERS(STORE_ID)    REFERENCES STORES(STORE_ID)
  )

  -- ════════════════════════════════════════════════════════════════════════════════
  -- FACTS (row-level quantitative attributes)
  -- ════════════════════════════════════════════════════════════════════════════════
  FACTS (
    ORDERS.TOTAL_AMOUNT AS total_amount
      WITH SYNONYMS = ('total amount', 'order value', 'order total')
      COMMENT = 'Total monetary value of the order after discounts.',

    ORDERS.QUANTITY AS quantity
      WITH SYNONYMS = ('quantity', 'qty', 'items')
      COMMENT = 'Number of units purchased in this order.',

    ORDERS.UNIT_PRICE AS unit_price
      COMMENT = 'Unit price at which the product was sold in this order.',

    ORDERS.DISCOUNT_PCT AS discount_pct
      WITH SYNONYMS = ('discount rate', 'sconto', 'discount percentage')
      COMMENT = 'Discount percentage applied to this order (0 if none).',

    ORDERS.SHIPPING_DAYS AS shipping_days
      WITH SYNONYMS = ('shipping days', 'delivery days', 'shipping time')
      COMMENT = 'Number of days between order placement and delivery (0 for In-Store).',

    PRODUCTS.UNIT_COST AS unit_cost
      COMMENT = 'Unit cost paid by RetailIQ for this product.',

    PRODUCTS.LIST_PRICE AS list_price
      COMMENT = 'Standard list price of the product before discounts.',

    STORES.EMPLOYEE_COUNT AS employee_count
      WITH SYNONYMS = ('employees', 'headcount', 'dipendenti')
      COMMENT = 'Number of employees working at the store.'
  )

  -- ════════════════════════════════════════════════════════════════════════════════
  -- DIMENSIONS (categorical attributes for analysis)
  -- ════════════════════════════════════════════════════════════════════════════════
  DIMENSIONS (
    -- Order dimensions
    ORDERS.CHANNEL AS channel
      WITH SYNONYMS = ('channel', 'sales channel', 'purchase channel', 'how purchased', 'canale')
      COMMENT = 'Sales channel through which the order was placed: In-Store, Online, or Mobile App.'
      SAMPLE_VALUES ('In-Store', 'Online', 'Mobile App') IS_ENUM,

    ORDERS.STATUS AS status
      WITH SYNONYMS = ('status', 'order status', 'order state', 'stato ordine')
      COMMENT = 'Current status of the order: Completed, Returned, Pending, or Cancelled.'
      SAMPLE_VALUES ('Completed', 'Returned', 'Cancelled', 'Pending') IS_ENUM,

    ORDERS.RETURN_FLAG AS return_flag
      WITH SYNONYMS = ('return', 'returned', 'reso', 'has return')
      COMMENT = 'Indicates whether the order was flagged as a return.',

    ORDERS.ORDER_DATE AS order_date
      WITH SYNONYMS = ('date', 'when', 'order day', 'purchase date', 'data ordine')
      COMMENT = 'Date on which the order was placed.',

    -- Product dimensions
    PRODUCTS.PRODUCT_NAME AS product_name
      WITH SYNONYMS = ('product', 'item', 'article', 'prodotto')
      COMMENT = 'Commercial name of the product.',

    PRODUCTS.CATEGORY AS category
      WITH SYNONYMS = ('category', 'product type', 'department', 'categoria')
      COMMENT = 'Product category (28 categories including Smartphones, Laptops, Gaming, Wine & Spirits, Women''s, Kitchen, Cycling, etc.).'
      SAMPLE_VALUES ('Smartphones', 'Laptops', 'Gaming', 'Wine & Spirits', 'Women''s', 'Kitchen'),

    PRODUCTS.SUBCATEGORY AS subcategory
      WITH SYNONYMS = ('subcategory', 'sub-category', 'sottocategoria')
      COMMENT = 'Second-level product category within the main category.',

    PRODUCTS.BRAND AS brand
      WITH SYNONYMS = ('brand name', 'marca')
      COMMENT = 'Brand or manufacturer of the product.',

    PRODUCTS.IS_PREMIUM AS is_premium
      WITH SYNONYMS = ('premium', 'luxury', 'high-end')
      COMMENT = 'Indicates whether the product is classified as premium.',

    -- Customer dimensions
    CUSTOMERS.REGION AS region
      WITH SYNONYMS = ('region', 'customer region', 'area', 'geographic area', 'zona', 'regione')
      COMMENT = 'Italian region where the customer is located (e.g. Lombardia, Lazio, Sicilia).',

    CUSTOMERS.CITY AS city
      WITH SYNONYMS = ('city', 'customer city', 'citta')
      COMMENT = 'City where the customer is located.',

    CUSTOMERS.LOYALTY_TIER AS loyalty_tier
      WITH SYNONYMS = ('loyalty', 'tier', 'membership level', 'card type')
      COMMENT = 'Customer loyalty program tier.'
      SAMPLE_VALUES ('Bronze', 'Silver', 'Gold', 'Platinum') IS_ENUM,

    CUSTOMERS.AGE_GROUP AS age_group
      WITH SYNONYMS = ('age', 'demographic', 'age group')
      COMMENT = 'Age group bucket of the customer.'
      SAMPLE_VALUES ('18-25', '26-35', '36-50', '50+') IS_ENUM,

    CUSTOMERS.SIGNUP_DATE AS signup_date
      WITH SYNONYMS = ('signup date', 'registration date', 'data iscrizione')
      COMMENT = 'Date when the customer signed up.',

    -- Store dimensions
    STORES.STORE_NAME AS store_name
      WITH SYNONYMS = ('store', 'location', 'negozio')
      COMMENT = 'Name of the store.',

    STORES.REGION AS region
      WITH SYNONYMS = ('store region', 'store area', 'regione negozio')
      COMMENT = 'Italian region where the store is located.',

    STORES.STORE_TYPE AS store_type
      WITH SYNONYMS = ('store format', 'tipo negozio')
      COMMENT = 'Format/type of the store.'
      SAMPLE_VALUES ('Flagship', 'Standard', 'Express', 'Pop-Up') IS_ENUM
  )

  -- ════════════════════════════════════════════════════════════════════════════════
  -- METRICS (aggregate measures)
  -- ════════════════════════════════════════════════════════════════════════════════
  METRICS (
    ORDERS.TOTAL_REVENUE AS SUM(CASE WHEN status = 'Completed' THEN total_amount ELSE 0 END)
      WITH SYNONYMS = ('revenue', 'sales', 'fatturato', 'total sales', 'gross revenue', 'ricavi')
      COMMENT = 'Total revenue from completed orders.',

    ORDERS.ORDER_COUNT AS COUNT(DISTINCT CASE WHEN status IN ('Completed', 'Returned') THEN ORDER_ID END)
      WITH SYNONYMS = ('number of orders', 'orders', 'ordini')
      COMMENT = 'Total number of completed or returned orders.',

    ORDERS.COMPLETED_ORDER_COUNT AS COUNT(DISTINCT CASE WHEN status = 'Completed' THEN ORDER_ID END)
      WITH SYNONYMS = ('completed orders', 'successful orders')
      COMMENT = 'Number of orders with status Completed.',

    ORDERS.AVERAGE_ORDER_VALUE AS SUM(CASE WHEN status = 'Completed' THEN total_amount ELSE 0 END) / NULLIF(COUNT(DISTINCT CASE WHEN status = 'Completed' THEN ORDER_ID END), 0)
      WITH SYNONYMS = ('AOV', 'average basket', 'scontrino medio', 'average ticket')
      COMMENT = 'Average revenue per completed order.',

    ORDERS.RETURN_RATE AS COUNT(DISTINCT CASE WHEN return_flag = TRUE THEN ORDER_ID END) * 100.0 / NULLIF(COUNT(DISTINCT ORDER_ID), 0)
      WITH SYNONYMS = ('return ratio', '% returns', 'tasso resi')
      COMMENT = 'Percentage of orders that were returned.',

    ORDERS.TOTAL_UNITS_SOLD AS SUM(CASE WHEN status = 'Completed' THEN quantity ELSE 0 END)
      WITH SYNONYMS = ('units sold', 'items sold', 'pezzi venduti')
      COMMENT = 'Total number of units sold in completed orders.',

    ORDERS.CUSTOMER_COUNT AS COUNT(DISTINCT CUSTOMER_ID)
      WITH SYNONYMS = ('customers', 'unique customers', 'clienti')
      COMMENT = 'Number of distinct customers who placed orders.',

    ORDERS.AVERAGE_DISCOUNT AS AVG(CASE WHEN discount_pct > 0 THEN discount_pct END)
      WITH SYNONYMS = ('discount', 'sconto medio', 'avg discount')
      COMMENT = 'Average discount percentage applied to discounted orders.',

    ORDERS.AVG_SHIPPING_DAYS AS AVG(CASE WHEN channel != 'In-Store' THEN shipping_days END)
      WITH SYNONYMS = ('delivery time', 'avg delivery', 'tempo consegna')
      COMMENT = 'Average number of shipping days for non-store orders.'
  )

  -- ════════════════════════════════════════════════════════════════════════════════
  -- CUSTOM INSTRUCTIONS FOR CORTEX ANALYST
  -- ════════════════════════════════════════════════════════════════════════════════
  AI_SQL_GENERATION 'When computing revenue, always filter for STATUS = ''Completed'' unless explicitly asked about all orders. Format currency values in EUR. Round percentages to 2 decimal places. When grouping by time, default to monthly granularity unless the user specifies otherwise. The term "region" refers to CUSTOMERS.REGION unless the user explicitly says "store region".'

  AI_QUESTION_CATEGORIZATION 'If the user asks about "customer satisfaction", "reviews", "feedback", or "complaints", classify the question as OUT_OF_SCOPE and suggest using the Cortex Search service instead, as this semantic view only covers structured transactional data.'

  -- ════════════════════════════════════════════════════════════════════════════════
  -- VERIFIED QUERIES
  -- Uses __tablename prefix with physical column names.
  -- ════════════════════════════════════════════════════════════════════════════════
  AI_VERIFIED_QUERIES (
    TOP_5_CATEGORIES_BY_REVENUE AS (
      QUESTION 'What are the top 5 product categories by revenue in the last 3 months?'
      ONBOARDING_QUESTION true
      SQL 'SELECT p.CATEGORY, SUM(o.TOTAL_AMOUNT) AS revenue FROM __orders AS o JOIN __products AS p ON o.PRODUCT_ID = p.PRODUCT_ID WHERE o.STATUS = ''Completed'' AND o.ORDER_DATE >= ''2024-10-01'' GROUP BY 1 ORDER BY 2 DESC LIMIT 5'
    ),

    REVENUE_BY_REGION_YTD AS (
      QUESTION 'What is the total revenue by customer region year-to-date?'
      ONBOARDING_QUESTION true
      SQL 'SELECT c.REGION, SUM(o.TOTAL_AMOUNT) AS revenue FROM __orders AS o JOIN __customers AS c ON o.CUSTOMER_ID = c.CUSTOMER_ID WHERE o.STATUS = ''Completed'' AND YEAR(o.ORDER_DATE) = 2024 GROUP BY 1 ORDER BY 2 DESC'
    ),

    MONTHLY_REVENUE_TREND_LAST_12M AS (
      QUESTION 'Show me the monthly revenue trend for the last 12 months'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE_TRUNC(''MONTH'', o.ORDER_DATE) AS month, SUM(o.TOTAL_AMOUNT) AS revenue FROM __orders AS o WHERE o.STATUS = ''Completed'' AND o.ORDER_DATE >= ''2024-01-01'' GROUP BY 1 ORDER BY 1'
    ),

    TOP_10_PRODUCTS_BY_UNITS AS (
      QUESTION 'Which are the top 10 best-selling products by units sold this year?'
      SQL 'SELECT p.PRODUCT_NAME, p.CATEGORY, SUM(o.QUANTITY) AS units_sold FROM __orders AS o JOIN __products AS p ON o.PRODUCT_ID = p.PRODUCT_ID WHERE o.STATUS = ''Completed'' AND YEAR(o.ORDER_DATE) = 2024 GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 10'
    ),

    RETURN_RATE_BY_CATEGORY AS (
      QUESTION 'What is the return rate by product category?'
      SQL 'SELECT p.CATEGORY, ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.RETURN_FLAG = TRUE THEN o.ORDER_ID END) / NULLIF(COUNT(DISTINCT o.ORDER_ID), 0), 2) AS return_rate_pct FROM __orders AS o JOIN __products AS p ON o.PRODUCT_ID = p.PRODUCT_ID GROUP BY 1 ORDER BY 2 DESC'
    ),

    REVENUE_BY_CHANNEL_AND_LOYALTY AS (
      QUESTION 'How does revenue break down by sales channel and customer loyalty tier?'
      SQL 'SELECT o.CHANNEL, c.LOYALTY_TIER, SUM(o.TOTAL_AMOUNT) AS revenue FROM __orders AS o JOIN __customers AS c ON o.CUSTOMER_ID = c.CUSTOMER_ID WHERE o.STATUS = ''Completed'' GROUP BY 1, 2 ORDER BY 1, 3 DESC'
    ),

    AVG_ORDER_VALUE_BY_STORE_TYPE AS (
      QUESTION 'What is the average order value by store type?'
      SQL 'SELECT s.STORE_TYPE, ROUND(AVG(o.TOTAL_AMOUNT), 2) AS avg_order_value FROM __orders AS o JOIN __stores AS s ON o.STORE_ID = s.STORE_ID WHERE o.STATUS = ''Completed'' GROUP BY 1 ORDER BY 2 DESC'
    ),

    PREMIUM_VS_STANDARD_PRODUCT_MARGIN AS (
      QUESTION 'What is the gross margin for premium vs standard products?'
      SQL 'SELECT CASE WHEN p.IS_PREMIUM = TRUE THEN ''Premium'' ELSE ''Standard'' END AS product_tier, SUM(o.TOTAL_AMOUNT) AS revenue, SUM(o.TOTAL_AMOUNT - o.QUANTITY * p.UNIT_COST) AS gross_margin, ROUND(100.0 * SUM(o.TOTAL_AMOUNT - o.QUANTITY * p.UNIT_COST) / NULLIF(SUM(o.TOTAL_AMOUNT), 0), 2) AS margin_pct FROM __orders AS o JOIN __products AS p ON o.PRODUCT_ID = p.PRODUCT_ID WHERE o.STATUS = ''Completed'' GROUP BY 1'
    ),

    TOP_STORES_BY_REVENUE AS (
      QUESTION 'What are the top 10 stores by revenue this year?'
      SQL 'SELECT s.STORE_NAME, s.REGION, s.STORE_TYPE, SUM(o.TOTAL_AMOUNT) AS revenue FROM __orders AS o JOIN __stores AS s ON o.STORE_ID = s.STORE_ID WHERE o.STATUS = ''Completed'' AND YEAR(o.ORDER_DATE) = 2024 GROUP BY 1, 2, 3 ORDER BY 4 DESC LIMIT 10'
    ),

    REVENUE_BY_CHANNEL_YTD AS (
      QUESTION 'What is the total revenue by channel year to date?'
      ONBOARDING_QUESTION true
      SQL 'SELECT o.CHANNEL, SUM(o.TOTAL_AMOUNT) AS revenue, COUNT(DISTINCT o.ORDER_ID) AS order_count FROM __orders AS o WHERE o.STATUS = ''Completed'' AND YEAR(o.ORDER_DATE) = 2024 GROUP BY 1 ORDER BY 2 DESC'
    )
  );

-- ==================================================================================
-- Grant ACCOUNTADMIN ownership so it can open the SV in read-write from the Analyst UI
-- ==================================================================================
USE ROLE RETAILIQ_ROLE;
GRANT OWNERSHIP ON SEMANTIC VIEW RETAILIQ_SV TO ROLE ACCOUNTADMIN COPY CURRENT GRANTS;

-- ==================================================================================
-- VERIFY
-- ==================================================================================
SHOW SEMANTIC VIEWS LIKE 'RETAILIQ_SV' IN SCHEMA RETAILIQ_DB.ANALYTICS;

-- ==================================================================================
-- END OF MODULE 2b
-- ==================================================================================
