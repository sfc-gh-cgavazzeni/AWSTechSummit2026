-- ==================================================================================
-- !!  WARNING: DESTRUCTIVE OPERATIONS  !!
-- ==================================================================================
-- This script PERMANENTLY DELETES all RetailIQ workshop objects.
-- Only run this AFTER the workshop is complete and you no longer need the data.
-- There is NO undo. All data, services, and configurations will be destroyed.
-- ==================================================================================

-- ==================================================================================
-- STEP 1: Drop Cortex Agent
-- ==================================================================================
USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

DROP CORTEX AGENT IF EXISTS RETAILIQ_CORTEX_AGENT;

-- ==================================================================================
-- STEP 2: Drop Cortex Search Services
-- ==================================================================================
DROP CORTEX SEARCH SERVICE IF EXISTS RETAILIQ_REVIEWS_SEARCH;
DROP CORTEX SEARCH SERVICE IF EXISTS RETAILIQ_TICKETS_SEARCH;

-- ==================================================================================
-- STEP 3: Drop MCP Server
-- ==================================================================================
DROP MCP SERVER IF EXISTS RETAILIQ_MCP_SERVER;

-- ==================================================================================
-- STEP 4: Drop Tables
-- ==================================================================================
DROP TABLE IF EXISTS ORDERS;
DROP TABLE IF EXISTS PRODUCTS;
DROP TABLE IF EXISTS CUSTOMERS;
DROP TABLE IF EXISTS STORES;
DROP TABLE IF EXISTS CUSTOMER_REVIEWS;
DROP TABLE IF EXISTS SUPPORT_TICKETS;

-- ==================================================================================
-- STEP 5: Drop Stage
-- ==================================================================================
DROP STAGE IF EXISTS RETAILIQ_STG;

-- ==================================================================================
-- STEP 6: Drop Schema and Database
-- ==================================================================================
DROP SCHEMA IF EXISTS RETAILIQ_DB.ANALYTICS;
DROP DATABASE IF EXISTS RETAILIQ_DB;

-- ==================================================================================
-- STEP 7: Drop Warehouse, Role, and User (requires ACCOUNTADMIN)
-- ==================================================================================
USE ROLE ACCOUNTADMIN;

DROP WAREHOUSE IF EXISTS RETAILIQ_WH;
DROP ROLE IF EXISTS RETAILIQ_ROLE;
DROP USER IF EXISTS RETAILIQ_USER;

-- ==================================================================================
-- CLEANUP COMPLETE — All RetailIQ workshop objects have been removed.
-- ==================================================================================
