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
-- IMPORTANT: Verified queries use __tablename and logical column names (entity names),
-- NOT physical table/column names. See Snowflake docs:
-- https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/verified-query-repository
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
    ORDERS.ORDER_TOTAL_AMOUNT AS total_amount
      WITH SYNONYMS = ('total amount', 'order value', 'order total')
      COMMENT = 'Total monetary value of the order after discounts.',

    ORDERS.ORDER_QUANTITY AS quantity
      WITH SYNONYMS = ('quantity', 'qty', 'items')
      COMMENT = 'Number of units purchased in this order.',

    ORDERS.ORDER_UNIT_PRICE AS unit_price
      COMMENT = 'Unit price at which the product was sold in this order.',

    ORDERS.ORDER_DISCOUNT_PCT AS discount_pct
      WITH SYNONYMS = ('discount rate', 'sconto', 'discount percentage')
      COMMENT = 'Discount percentage applied to this order (0 if none).',

    ORDERS.ORDER_SHIPPING_DAYS AS shipping_days
      WITH SYNONYMS = ('shipping days', 'delivery days', 'shipping time')
      COMMENT = 'Number of days between order placement and delivery (0 for In-Store).',

    PRODUCTS.PRODUCT_UNIT_COST AS unit_cost
      COMMENT = 'Unit cost paid by RetailIQ for this product.',

    PRODUCTS.PRODUCT_LIST_PRICE AS list_price
      COMMENT = 'Standard list price of the product before discounts.',

    STORES.STORE_EMPLOYEE_COUNT AS employee_count
      WITH SYNONYMS = ('employees', 'headcount', 'dipendenti')
      COMMENT = 'Number of employees working at the store.'
  )

  -- ════════════════════════════════════════════════════════════════════════════════
  -- DIMENSIONS (categorical attributes for analysis)
  -- ════════════════════════════════════════════════════════════════════════════════
  DIMENSIONS (
    -- Order dimensions
    ORDERS.ORDER_CHANNEL AS channel
      WITH SYNONYMS = ('channel', 'sales channel', 'purchase channel', 'how purchased', 'canale')
      COMMENT = 'Sales channel through which the order was placed: In-Store, Online, or Mobile App.'
      SAMPLE_VALUES ('In-Store', 'Online', 'Mobile App') IS_ENUM,

    ORDERS.ORDER_STATUS AS status
      WITH SYNONYMS = ('status', 'order state', 'stato ordine')
      COMMENT = 'Current status of the order: Completed, Returned, Pending, or Cancelled.'
      SAMPLE_VALUES ('Completed', 'Returned', 'Cancelled', 'Pending') IS_ENUM,

    ORDERS.IS_RETURN AS return_flag
      WITH SYNONYMS = ('return', 'returned', 'reso', 'has return')
      COMMENT = 'Indicates whether the order was flagged as a return.',

    -- Time dimensions (order)
    ORDERS.ORDER_DATE AS order_date
      WITH SYNONYMS = ('date', 'when', 'order day', 'purchase date', 'data ordine')
      COMMENT = 'Date on which the order was placed.',

    ORDERS.ORDER_MONTH AS DATE_TRUNC('month', order_date)
      WITH SYNONYMS = ('month', 'monthly', 'mese')
      COMMENT = 'Calendar month in which the order was placed.',

    ORDERS.ORDER_QUARTER AS DATE_TRUNC('quarter', order_date)
      WITH SYNONYMS = ('quarter', 'quarterly', 'trimestre')
      COMMENT = 'Calendar quarter in which the order was placed.',

    ORDERS.ORDER_YEAR AS YEAR(order_date)
      WITH SYNONYMS = ('year', 'annual', 'anno')
      COMMENT = 'Calendar year in which the order was placed.',

    -- Product dimensions
    PRODUCTS.PRODUCT_NAME AS product_name
      WITH SYNONYMS = ('product', 'item', 'article', 'prodotto')
      COMMENT = 'Commercial name of the product.',

    PRODUCTS.PRODUCT_CATEGORY AS category
      WITH SYNONYMS = ('category', 'product type', 'department', 'categoria')
      COMMENT = 'Top-level product category.'
      SAMPLE_VALUES ('Electronics', 'Clothing & Apparel', 'Food & Beverage', 'Home & Garden', 'Sports & Outdoors') IS_ENUM,

    PRODUCTS.PRODUCT_SUBCATEGORY AS subcategory
      WITH SYNONYMS = ('subcategory', 'sub-category', 'sottocategoria')
      COMMENT = 'Second-level product category within the main category.',

    PRODUCTS.BRAND AS brand
      WITH SYNONYMS = ('brand name', 'marca')
      COMMENT = 'Brand or manufacturer of the product.',

    PRODUCTS.IS_PREMIUM_PRODUCT AS is_premium
      WITH SYNONYMS = ('premium', 'luxury', 'high-end')
      COMMENT = 'Indicates whether the product is classified as premium.',

    -- Customer dimensions
    CUSTOMERS.CUSTOMER_REGION AS region
      WITH SYNONYMS = ('region', 'area', 'geographic area', 'zona', 'regione')
      COMMENT = 'Italian region where the customer is located (e.g. Lombardia, Lazio, Sicilia).',

    CUSTOMERS.CUSTOMER_CITY AS city
      WITH SYNONYMS = ('city', 'citta')
      COMMENT = 'City where the customer is located.',

    CUSTOMERS.LOYALTY_TIER AS loyalty_tier
      WITH SYNONYMS = ('loyalty', 'tier', 'membership level', 'card type')
      COMMENT = 'Customer loyalty program tier.'
      SAMPLE_VALUES ('Bronze', 'Silver', 'Gold', 'Platinum') IS_ENUM,

    CUSTOMERS.CUSTOMER_AGE_GROUP AS age_group
      WITH SYNONYMS = ('age', 'demographic', 'age group')
      COMMENT = 'Age group bucket of the customer.'
      SAMPLE_VALUES ('18-25', '26-35', '36-50', '50+') IS_ENUM,

    CUSTOMERS.CUSTOMER_SIGNUP_DATE AS signup_date
      WITH SYNONYMS = ('signup date', 'registration date', 'data iscrizione')
      COMMENT = 'Date when the customer signed up.',

    -- Store dimensions
    STORES.STORE_NAME AS store_name
      WITH SYNONYMS = ('store', 'location', 'negozio')
      COMMENT = 'Name of the store.',

    STORES.STORE_REGION AS region
      WITH SYNONYMS = ('store area', 'store region', 'regione negozio')
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
    -- Derived metric (cross-table)
    REVENUE_PER_CUSTOMER AS orders.total_revenue / NULLIF(orders.customer_count, 0)
      WITH SYNONYMS = ('ARPU', 'average revenue per customer', 'ricavo per cliente')
      COMMENT = 'Average revenue per distinct customer.',

    -- Table-level metrics (orders)
    ORDERS.TOTAL_REVENUE AS SUM(CASE WHEN order_status = 'Completed' THEN order_total_amount ELSE 0 END)
      WITH SYNONYMS = ('revenue', 'sales', 'fatturato', 'total sales', 'gross revenue', 'ricavi')
      COMMENT = 'Total revenue from completed orders.',

    ORDERS.ORDER_COUNT AS COUNT(DISTINCT CASE WHEN order_status IN ('Completed', 'Returned') THEN order_id END)
      WITH SYNONYMS = ('number of orders', 'orders', 'ordini')
      COMMENT = 'Total number of completed or returned orders.',

    ORDERS.COMPLETED_ORDER_COUNT AS COUNT(DISTINCT CASE WHEN order_status = 'Completed' THEN order_id END)
      WITH SYNONYMS = ('completed orders', 'successful orders')
      COMMENT = 'Number of orders with status Completed.',

    ORDERS.AVERAGE_ORDER_VALUE AS SUM(CASE WHEN order_status = 'Completed' THEN order_total_amount ELSE 0 END) / NULLIF(COUNT(DISTINCT CASE WHEN order_status = 'Completed' THEN order_id END), 0)
      WITH SYNONYMS = ('AOV', 'average basket', 'scontrino medio', 'average ticket')
      COMMENT = 'Average revenue per completed order.',

    ORDERS.RETURN_RATE AS COUNT(DISTINCT CASE WHEN is_return = TRUE THEN order_id END) * 100.0 / NULLIF(COUNT(DISTINCT order_id), 0)
      WITH SYNONYMS = ('return ratio', '% returns', 'tasso resi')
      COMMENT = 'Percentage of orders that were returned.',

    ORDERS.TOTAL_UNITS_SOLD AS SUM(CASE WHEN order_status = 'Completed' THEN order_quantity ELSE 0 END)
      WITH SYNONYMS = ('units sold', 'items sold', 'pezzi venduti')
      COMMENT = 'Total number of units sold in completed orders.',

    ORDERS.CUSTOMER_COUNT AS COUNT(DISTINCT customer_id)
      WITH SYNONYMS = ('customers', 'unique customers', 'clienti')
      COMMENT = 'Number of distinct customers who placed orders.',

    ORDERS.AVERAGE_DISCOUNT AS AVG(CASE WHEN order_discount_pct > 0 THEN order_discount_pct END)
      WITH SYNONYMS = ('discount', 'sconto medio', 'avg discount')
      COMMENT = 'Average discount percentage applied to discounted orders.',

    ORDERS.AVG_SHIPPING_DAYS AS AVG(CASE WHEN order_channel != 'In-Store' THEN order_shipping_days END)
      WITH SYNONYMS = ('delivery time', 'avg delivery', 'tempo consegna')
      COMMENT = 'Average number of shipping days for non-store orders.'
  )

  -- ════════════════════════════════════════════════════════════════════════════════
  -- CUSTOM INSTRUCTIONS FOR CORTEX ANALYST
  -- ════════════════════════════════════════════════════════════════════════════════
  AI_SQL_GENERATION 'When computing revenue, always filter for order_status = ''Completed'' unless explicitly asked about all orders. Format currency values in EUR. Round percentages to 2 decimal places. When grouping by time, default to monthly granularity unless the user specifies otherwise. The term "region" refers to customer_region (from customers table) unless the user explicitly says "store region".'

  AI_QUESTION_CATEGORIZATION 'If the user asks about "customer satisfaction", "reviews", "feedback", or "complaints", classify the question as OUT_OF_SCOPE and suggest using the Cortex Search service instead, as this semantic view only covers structured transactional data.'

  -- ════════════════════════════════════════════════════════════════════════════════
  -- VERIFIED QUERIES
  -- VQ SQL uses __tablename (logical table) and entity names (logical columns).
  -- Physical table/column names are NOT allowed here.
  -- ════════════════════════════════════════════════════════════════════════════════
  AI_VERIFIED_QUERIES (
    TOP_5_CATEGORIES_BY_REVENUE AS (
      QUESTION 'What are the top 5 product categories by revenue in the last 3 months?'
      ONBOARDING_QUESTION true
      SQL 'SELECT p.product_category, SUM(o.order_total_amount) AS revenue FROM __orders AS o JOIN __products AS p ON o.product_id = p.product_id WHERE o.order_status = ''Completed'' AND o.order_date >= DATEADD(MONTH, -3, CURRENT_DATE) GROUP BY 1 ORDER BY 2 DESC LIMIT 5'
    ),

    REVENUE_BY_REGION_YTD AS (
      QUESTION 'What is the total revenue by customer region year-to-date?'
      ONBOARDING_QUESTION true
      SQL 'SELECT c.customer_region, SUM(o.order_total_amount) AS revenue FROM __orders AS o JOIN __customers AS c ON o.customer_id = c.customer_id WHERE o.order_status = ''Completed'' AND YEAR(o.order_date) = YEAR(CURRENT_DATE) GROUP BY 1 ORDER BY 2 DESC'
    ),

    MONTHLY_REVENUE_TREND_LAST_12M AS (
      QUESTION 'Show me the monthly revenue trend for the last 12 months'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE_TRUNC(''MONTH'', o.order_date) AS month, SUM(o.order_total_amount) AS revenue FROM __orders AS o WHERE o.order_status = ''Completed'' AND o.order_date >= DATEADD(MONTH, -12, CURRENT_DATE) GROUP BY 1 ORDER BY 1'
    ),

    TOP_10_PRODUCTS_BY_UNITS AS (
      QUESTION 'Which are the top 10 best-selling products by units sold this year?'
      SQL 'SELECT p.product_name, p.product_category, SUM(o.order_quantity) AS units_sold FROM __orders AS o JOIN __products AS p ON o.product_id = p.product_id WHERE o.order_status = ''Completed'' AND YEAR(o.order_date) = YEAR(CURRENT_DATE) GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 10'
    ),

    RETURN_RATE_BY_CATEGORY AS (
      QUESTION 'What is the return rate by product category?'
      SQL 'SELECT p.product_category, ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.is_return = TRUE THEN o.order_id END) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS return_rate_pct FROM __orders AS o JOIN __products AS p ON o.product_id = p.product_id GROUP BY 1 ORDER BY 2 DESC'
    ),

    REVENUE_BY_CHANNEL_AND_LOYALTY AS (
      QUESTION 'How does revenue break down by sales channel and customer loyalty tier?'
      SQL 'SELECT o.order_channel, c.loyalty_tier, SUM(o.order_total_amount) AS revenue FROM __orders AS o JOIN __customers AS c ON o.customer_id = c.customer_id WHERE o.order_status = ''Completed'' GROUP BY 1, 2 ORDER BY 1, 3 DESC'
    ),

    AVG_ORDER_VALUE_BY_STORE_TYPE AS (
      QUESTION 'What is the average order value by store type?'
      SQL 'SELECT s.store_type, ROUND(AVG(o.order_total_amount), 2) AS avg_order_value FROM __orders AS o JOIN __stores AS s ON o.store_id = s.store_id WHERE o.order_status = ''Completed'' GROUP BY 1 ORDER BY 2 DESC'
    ),

    PREMIUM_VS_STANDARD_PRODUCT_MARGIN AS (
      QUESTION 'What is the gross margin for premium vs standard products?'
      SQL 'SELECT CASE WHEN p.is_premium_product = TRUE THEN ''Premium'' ELSE ''Standard'' END AS product_tier, SUM(o.order_total_amount) AS revenue, SUM(o.order_total_amount - o.order_quantity * p.product_unit_cost) AS gross_margin, ROUND(100.0 * SUM(o.order_total_amount - o.order_quantity * p.product_unit_cost) / NULLIF(SUM(o.order_total_amount), 0), 2) AS margin_pct FROM __orders AS o JOIN __products AS p ON o.product_id = p.product_id WHERE o.order_status = ''Completed'' GROUP BY 1'
    ),

    TOP_STORES_BY_REVENUE AS (
      QUESTION 'What are the top 10 stores by revenue this year?'
      SQL 'SELECT s.store_name, s.store_region, s.store_type, SUM(o.order_total_amount) AS revenue FROM __orders AS o JOIN __stores AS s ON o.store_id = s.store_id WHERE o.order_status = ''Completed'' AND YEAR(o.order_date) = YEAR(CURRENT_DATE) GROUP BY 1, 2, 3 ORDER BY 4 DESC LIMIT 10'
    ),

    REVENUE_BY_CHANNEL_YTD AS (
      QUESTION 'What is the total revenue by channel year to date?'
      ONBOARDING_QUESTION true
      SQL 'SELECT o.order_channel, SUM(o.order_total_amount) AS revenue, COUNT(DISTINCT o.order_id) AS order_count FROM __orders AS o WHERE o.order_status = ''Completed'' AND YEAR(o.order_date) = YEAR(CURRENT_DATE) GROUP BY 1 ORDER BY 2 DESC'
    )
  );

-- ==================================================================================
-- VERIFY
-- ==================================================================================
SHOW SEMANTIC VIEWS LIKE 'RETAILIQ_SV' IN SCHEMA RETAILIQ_DB.ANALYTICS;

-- ==================================================================================
-- END OF MODULE 2b
-- ==================================================================================
