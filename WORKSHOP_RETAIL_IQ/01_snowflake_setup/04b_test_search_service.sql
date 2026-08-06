-- ==================================================================================
-- MODULE 3: TEST CORTEX SEARCH SERVICES — RetailIQ Workshop
-- ==================================================================================
-- Run these queries to verify semantic search is working and demonstrate
-- hybrid retrieval (BM25 + vector embeddings).
--
-- NOTE: SEARCH_PREVIEW is a scalar function returning JSON — use PARSE_JSON
-- and FLATTEN to get tabular results.
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- TEST 1: Semantic search on Customer Reviews
-- ==================================================================================
-- This query finds reviews about delivery issues in southern Italy,
-- even if the exact phrase "delivery problems" doesn't appear in the text.
-- The search engine understands semantically related terms like
-- "slow shipping", "lost packages", "courier issues", etc.

SELECT value['product_name']::TEXT AS product_name,
       value['rating']::NUMBER AS rating,
       value['review_text']::TEXT AS review_text
FROM TABLE(FLATTEN(PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'RETAILIQ_REVIEWS_SEARCH',
    '{
      "query": "delivery problems in southern Italy",
      "columns": ["review_text", "product_name", "rating"],
      "limit": 5
    }'
  )
)['results']));

-- ==================================================================================
-- TEST 2: Semantic search on Support Tickets
-- ==================================================================================
-- This query finds tickets about refund/billing issues using semantic matching.
-- It will return results mentioning payment problems, credit not received,
-- money back requests, etc. — not just exact "refund" keyword matches.

SELECT value['ticket_text']::TEXT AS ticket_text,
       value['category']::TEXT AS category,
       value['status']::TEXT AS status
FROM TABLE(FLATTEN(PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'RETAILIQ_TICKETS_SEARCH',
    '{
      "query": "refund not processed",
      "columns": ["ticket_text", "category", "status"],
      "limit": 5
    }'
  )
)['results']));

-- ==================================================================================
-- TEST 3: Product quality feedback
-- ==================================================================================
-- Demonstrates semantic understanding of "quality" across different phrasings:
-- defective, broken, poor craftsmanship, doesn't work, etc.

SELECT value['product_name']::TEXT AS product_name,
       value['category']::TEXT AS category,
       value['rating']::NUMBER AS rating,
       value['review_text']::TEXT AS review_text
FROM TABLE(FLATTEN(PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'RETAILIQ_REVIEWS_SEARCH',
    '{
      "query": "poor product quality and defects",
      "columns": ["review_text", "product_name", "category", "rating"],
      "limit": 5
    }'
  )
)['results']));

-- ==================================================================================
-- TEST 4: Urgent unresolved issues
-- ==================================================================================
-- Find tickets where customers are frustrated and waiting for resolution.

SELECT value['ticket_text']::TEXT AS ticket_text,
       value['category']::TEXT AS category,
       value['priority']::TEXT AS priority,
       value['status']::TEXT AS status
FROM TABLE(FLATTEN(PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'RETAILIQ_TICKETS_SEARCH',
    '{
      "query": "customer waiting too long for resolution",
      "columns": ["ticket_text", "category", "priority", "status"],
      "limit": 5
    }'
  )
)['results']));

-- ==================================================================================
-- END OF CORTEX SEARCH TESTING
-- ==================================================================================
