-- ==================================================================================
-- !!  WARNING: DESTRUCTIVE OPERATIONS  !!
-- ==================================================================================
-- This script PERMANENTLY DELETES all RetailIQ workshop objects.
-- Only run this AFTER the workshop is complete and you no longer need the data.
-- There is NO undo. All data, services, and configurations will be destroyed.
-- ==================================================================================

-- ==================================================================================
-- STEP 1: Remove agent from Snowflake CoWork and drop it
-- ==================================================================================
USE ROLE ACCOUNTADMIN;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- Remove agent from CoWork (ignore error if not added)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT RETAILIQ_DB.ANALYTICS.RETAILIQ_CORTEX_AGENT;

DROP AGENT IF EXISTS RETAILIQ_CORTEX_AGENT;

-- ==================================================================================
-- STEP 2: Switch to RETAILIQ_ROLE for remaining objects
-- ==================================================================================
USE ROLE RETAILIQ_ROLE;

-- ==================================================================================
-- STEP 3: Drop Cortex Search Services
-- ==================================================================================
DROP CORTEX SEARCH SERVICE IF EXISTS RETAILIQ_REVIEWS_SEARCH;
DROP CORTEX SEARCH SERVICE IF EXISTS RETAILIQ_TICKETS_SEARCH;

-- ==================================================================================
-- STEP 4: Drop MCP Servers
-- ==================================================================================
DROP MCP SERVER IF EXISTS RETAILIQ_MCP_SERVER;
DROP MCP SERVER IF EXISTS RETAILIQ_MCP_SERVER_AGENT;

-- ==================================================================================
-- STEP 5: Drop Semantic Views
-- ==================================================================================
DROP SEMANTIC VIEW IF EXISTS RETAILIQ_SV;
DROP SEMANTIC VIEW IF EXISTS RETAILIQ_SV_BASIC;

-- ==================================================================================
-- STEP 6: Drop Tables
-- ==================================================================================
DROP TABLE IF EXISTS ORDERS;
DROP TABLE IF EXISTS PRODUCTS;
DROP TABLE IF EXISTS CUSTOMERS;
DROP TABLE IF EXISTS STORES;
DROP TABLE IF EXISTS CUSTOMER_REVIEWS;
DROP TABLE IF EXISTS SUPPORT_TICKETS;

-- ==================================================================================
-- STEP 7: Drop Stage
-- ==================================================================================
DROP STAGE IF EXISTS RETAILIQ_STG;

-- ==================================================================================
-- STEP 8: Drop Schema and Database
-- ==================================================================================
DROP SCHEMA IF EXISTS RETAILIQ_DB.ANALYTICS;
DROP DATABASE IF EXISTS RETAILIQ_DB;

-- ==================================================================================
-- STEP 9: Drop Warehouse, Role, Network Policy, and User (requires ACCOUNTADMIN)
-- ==================================================================================
USE ROLE ACCOUNTADMIN;

DROP WAREHOUSE IF EXISTS RETAILIQ_WH;
DROP ROLE IF EXISTS RETAILIQ_ROLE;

-- Must drop network policy before user (policy is attached to user)
ALTER USER RETAILIQ_USER UNSET NETWORK_POLICY;
DROP NETWORK POLICY IF EXISTS RETAILIQ_USER_POLICY;
DROP USER IF EXISTS RETAILIQ_USER;

-- ==================================================================================
-- CLEANUP COMPLETE — All RetailIQ workshop objects have been removed.
-- ==================================================================================
