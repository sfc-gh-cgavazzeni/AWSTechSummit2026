-- ==================================================================================
-- MODULE 3: TEST CORTEX SEARCH SERVICES — RetailIQ Workshop
-- ==================================================================================
-- Run these queries to verify semantic search is working and demonstrate
-- hybrid retrieval (BM25 + vector embeddings).
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

SELECT *
FROM TABLE(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH',
    '{
      "query": "delivery problems in southern Italy",
      "columns": ["review_text", "product_name", "rating"],
      "limit": 5
    }'
  )
);

-- ==================================================================================
-- TEST 2: Semantic search on Support Tickets
-- ==================================================================================
-- This query finds tickets about refund/billing issues using semantic matching.
-- It will return results mentioning payment problems, credit not received,
-- money back requests, etc. — not just exact "refund" keyword matches.

SELECT *
FROM TABLE(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH',
    '{
      "query": "refund not processed",
      "columns": ["ticket_text", "category", "status"],
      "limit": 5
    }'
  )
);

-- ==================================================================================
-- TEST 3: Product quality feedback
-- ==================================================================================
-- Demonstrates semantic understanding of "quality" across different phrasings:
-- defective, broken, poor craftsmanship, doesn't work, etc.

SELECT *
FROM TABLE(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH',
    '{
      "query": "poor product quality and defects",
      "columns": ["review_text", "product_name", "category", "rating"],
      "limit": 5
    }'
  )
);

-- ==================================================================================
-- TEST 4: Urgent unresolved issues
-- ==================================================================================
-- Find tickets where customers are frustrated and waiting for resolution.

SELECT *
FROM TABLE(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH',
    '{
      "query": "customer waiting too long for resolution",
      "columns": ["ticket_text", "category", "priority", "status"],
      "limit": 5
    }'
  )
);

-- ==================================================================================
-- END OF CORTEX SEARCH TESTING
-- ==================================================================================
