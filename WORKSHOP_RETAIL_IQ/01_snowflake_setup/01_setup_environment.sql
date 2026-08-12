-- ==================================================================================
-- MODULE 0: ENVIRONMENT SETUP — RetailIQ Workshop
-- ==================================================================================
-- Run this script ONCE as ACCOUNTADMIN to set up the workshop environment.
-- This creates the role, user, warehouse, database, schema, and stage.
-- ==================================================================================

USE ROLE ACCOUNTADMIN;

-- ==================================================================================
-- PART 1: Create Role, User, Warehouse, Database, Schema, and Stage
-- ==================================================================================

-- == Create Role ==
CREATE ROLE IF NOT EXISTS RETAILIQ_ROLE
    COMMENT = 'Role for RetailIQ workshop — AWS Tech Summit 2026';

-- == Create User ==
CREATE USER IF NOT EXISTS RETAILIQ_USER
    DEFAULT_ROLE = RETAILIQ_ROLE
    MUST_CHANGE_PASSWORD = TRUE
    COMMENT = 'Service user for RetailIQ workshop';

-- == Grant Role ==
GRANT ROLE RETAILIQ_ROLE TO USER RETAILIQ_USER;
GRANT ROLE RETAILIQ_ROLE TO ROLE ACCOUNTADMIN;

-- == Network Policy for MCP access (required for PAT-based external connections) ==
CREATE OR REPLACE NETWORK POLICY RETAILIQ_USER_POLICY
  ALLOWED_IP_LIST = ('0.0.0.0/0')
  COMMENT = 'Allow retailiq_user PAT access from any IP (required for MCP from AWS)';
ALTER USER RETAILIQ_USER SET NETWORK_POLICY = RETAILIQ_USER_POLICY;

-- !! IMPORTANT: Grant RETAILIQ_ROLE to YOUR user (required for Analyst UI role switching).
-- Select this entire block (all 4 lines) and run it together:
BEGIN
  LET usr := CURRENT_USER();
  EXECUTE IMMEDIATE 'GRANT ROLE RETAILIQ_ROLE TO USER ' || :usr;
END;

-- == Create Warehouse ==
CREATE WAREHOUSE IF NOT EXISTS RETAILIQ_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for RetailIQ workshop';

-- == Create Database and Schema ==
CREATE DATABASE IF NOT EXISTS RETAILIQ_DB
    COMMENT = 'Database for RetailIQ workshop — Cortex + AWS Bedrock AgentCore';

CREATE SCHEMA IF NOT EXISTS RETAILIQ_DB.ANALYTICS
    COMMENT = 'Analytics schema for RetailIQ workshop data and services';

-- == Grant Ownership ==
GRANT OWNERSHIP ON DATABASE RETAILIQ_DB TO ROLE RETAILIQ_ROLE COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA RETAILIQ_DB.ANALYTICS TO ROLE RETAILIQ_ROLE COPY CURRENT GRANTS;
GRANT OWNERSHIP ON WAREHOUSE RETAILIQ_WH TO ROLE RETAILIQ_ROLE COPY CURRENT GRANTS;

-- == Switch to RETAILIQ_ROLE ==
USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- == Create Stage ==
CREATE STAGE IF NOT EXISTS RETAILIQ_STG
    FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"')
    COMMENT = 'Stage for loading RetailIQ CSV data files';

-- ==================================================================================
-- GRANTS FOR MCP ACCESS (needed when Cortex Agent is owned by ACCOUNTADMIN)
-- Run these AFTER creating the agent (Module 4) — they enable retailiq_user
-- to invoke the agent and access all underlying objects via MCP.
-- ==================================================================================
-- USE ROLE ACCOUNTADMIN;
-- GRANT USAGE ON AGENT RETAILIQ_DB.ANALYTICS.RETAILIQ_CORTEX_AGENT TO ROLE RETAILIQ_ROLE;
-- GRANT SELECT ON SEMANTIC VIEW RETAILIQ_DB.ANALYTICS.RETAILIQ_SV TO ROLE RETAILIQ_ROLE;
-- GRANT SELECT ON ALL TABLES IN SCHEMA RETAILIQ_DB.ANALYTICS TO ROLE RETAILIQ_ROLE;
-- GRANT USAGE ON ALL CORTEX SEARCH SERVICES IN SCHEMA RETAILIQ_DB.ANALYTICS TO ROLE RETAILIQ_ROLE;

-- ==================================================================================
-- END OF MODULE 0
-- ==================================================================================
