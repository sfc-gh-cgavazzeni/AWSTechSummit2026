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
-- Grant to the current user (needed for the Analyst UI to allow switching to this role)
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
-- PART 2: Create MCP PAT Token (run as ACCOUNTADMIN after completing all modules)
-- ==================================================================================
-- After you have created the MCP Server (Module 05), run the following to generate
-- a Programmatic Access Token for external connectivity (e.g., AWS Bedrock AgentCore).

USE ROLE ACCOUNTADMIN;

ALTER USER RETAILIQ_USER
    ADD PROGRAMMATIC ACCESS TOKEN RETAILIQ_MCP_TOKEN
    DAYS_TO_EXPIRY = 7
    ROLE_RESTRICTION = 'RETAILIQ_ROLE';

-- Retrieve the MCP Server endpoint URL:
DESCRIBE MCP SERVER RETAILIQ_DB.ANALYTICS.RETAILIQ_MCP_SERVER;

-- ==================================================================================
-- PART 3: Network Policy (OPTIONAL — for production use)
-- ==================================================================================
-- Uncomment and customize the following for production deployments to restrict
-- access to known IP ranges (e.g., AWS VPC NAT Gateway IPs).

-- CREATE NETWORK POLICY IF NOT EXISTS RETAILIQ_NETWORK_POLICY
--     ALLOWED_IP_LIST = ('0.0.0.0/0')  -- Replace with your CIDR ranges
--     BLOCKED_IP_LIST = ()
--     COMMENT = 'Network policy for RetailIQ MCP access';

-- ALTER USER RETAILIQ_USER SET NETWORK_POLICY = RETAILIQ_NETWORK_POLICY;

-- ==================================================================================
-- END OF MODULE 0
-- ==================================================================================
