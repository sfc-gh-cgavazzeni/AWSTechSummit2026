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
-- END OF MODULE 0
-- ==================================================================================
