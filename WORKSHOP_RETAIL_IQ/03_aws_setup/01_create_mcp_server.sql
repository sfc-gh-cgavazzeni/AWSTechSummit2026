-- ==================================================================================
-- MODULE 5: CREATE MCP SERVER — RetailIQ Workshop
-- ==================================================================================
-- Creates a Snowflake Managed MCP Server that exposes the same 3 tools
-- (Cortex Analyst + 2 Cortex Search Services) over the MCP protocol.
-- External MCP clients (AWS Bedrock AgentCore, Claude Desktop, etc.) connect
-- to this endpoint using a PAT token for authentication.
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- CREATE MCP SERVER: RETAILIQ_MCP_SERVER
-- ==================================================================================
CREATE OR REPLACE MCP SERVER RETAILIQ_MCP_SERVER
FROM SPECIFICATION $$
tools:
  - name: "retailiq_analyst"
    type: "CORTEX_ANALYST_MESSAGE"
    identifier: "RETAILIQ_DB.ANALYTICS.RETAILIQ_SV"
    description: "Structured analytics tool for RetailIQ sales, orders, customers and stores data. Use for quantitative questions about revenue, conversion rates, order volumes, customer segments, regional performance, product categories, and time-series trends."
    title: "RetailIQ Analytics"

  - name: "retailiq_reviews_search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH"
    description: "Semantic search over RetailIQ customer reviews. Use for qualitative insights, sentiment analysis, product feedback, and understanding what customers say about their experiences."
    title: "Customer Reviews Search"

  - name: "retailiq_tickets_search"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    identifier: "RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH"
    description: "Semantic search over support tickets. Use for understanding common issues, complaints, return reasons, and service quality feedback."
    title: "Support Tickets Search"
$$;

-- ==================================================================================
-- VERIFICATION
-- ==================================================================================
DESCRIBE MCP SERVER RETAILIQ_MCP_SERVER;

-- ==================================================================================
-- PAT TOKEN CREATION (run as ACCOUNTADMIN)
-- ==================================================================================
-- IMPORTANT: The token value is displayed ONLY ONCE — save it immediately!

USE ROLE ACCOUNTADMIN;

ALTER USER RETAILIQ_USER
    ADD PROGRAMMATIC ACCESS TOKEN RETAILIQ_MCP_TOKEN
    DAYS_TO_EXPIRY = 7
    ROLE_RESTRICTION = 'RETAILIQ_ROLE';

-- Retrieve the MCP Server endpoint URL:
DESCRIBE MCP SERVER RETAILIQ_DB.ANALYTICS.RETAILIQ_MCP_SERVER;

-- ==================================================================================
-- NETWORK POLICY (OPTIONAL — for production use)
-- ==================================================================================
-- Uncomment and customize the following for production deployments to restrict
-- access to known IP ranges (e.g., AWS VPC NAT Gateway IPs).

-- CREATE NETWORK POLICY IF NOT EXISTS RETAILIQ_NETWORK_POLICY
--     ALLOWED_IP_LIST = ('0.0.0.0/0')  -- Replace with your CIDR ranges
--     BLOCKED_IP_LIST = ()
--     COMMENT = 'Network policy for RetailIQ MCP access';

-- ALTER USER RETAILIQ_USER SET NETWORK_POLICY = RETAILIQ_NETWORK_POLICY;

-- ==================================================================================
-- WHAT TO SAVE BEFORE MOVING TO AWS
-- ==================================================================================
-- After running the above, collect these 3 values:
--
-- 1. MCP Endpoint URL (from DESCRIBE output):
--    https://<account>.snowflakecomputing.com/api/v2/cortex/mcp/<db>/<schema>/<server_name>/sse
--
-- 2. PAT Token (from ALTER USER output — shown once only)
--
-- 3. Account Locator (Snowsight → bottom-left → Account Details → Account Locator)

-- ==================================================================================
-- MCP CLIENT CONFIGURATION EXAMPLE
-- ==================================================================================
-- Use the endpoint and PAT token in your MCP client (Claude Desktop, VS Code, etc.):
--
-- {
--     "mcpServers": {
--         "retailiq": {
--             "url": "<endpoint_url_from_describe>",
--             "headers": {
--                 "Authorization": "Bearer <pat_token_value>"
--             }
--         }
--     }
-- }

-- ==================================================================================
-- USER-LEVEL NETWORK POLICY (required for external MCP access)
-- ==================================================================================
-- Most Snowflake accounts have an account-level network policy that only allows
-- corporate VPN IPs. The EC2 instance's IP won't be in that list.
-- A user-level policy on retailiq_user overrides the account policy for that user only.

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE NETWORK POLICY RETAILIQ_USER_POLICY
  ALLOWED_IP_LIST = ('0.0.0.0/0')
  COMMENT = 'Allow retailiq_user MCP access from any IP (workshop)';

ALTER USER RETAILIQ_USER SET NETWORK_POLICY = RETAILIQ_USER_POLICY;

-- ==================================================================================
-- END OF MODULE 5
-- ==================================================================================
