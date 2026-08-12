-- ==================================================================================
-- MODULE 5 (OPTION B): CREATE MCP SERVER WITH CORTEX AGENT — RetailIQ Workshop
-- ==================================================================================
-- This is the RECOMMENDED pattern for production: expose a single Cortex Agent
-- as the MCP tool. The agent handles tool selection and orchestration internally.
-- External MCP clients (AWS Bedrock AgentCore, Claude, Cursor, etc.) get ONE
-- governed endpoint — they send a question and receive a complete answer.
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- CREATE MCP SERVER: RETAILIQ_MCP_SERVER_AGENT
-- ==================================================================================
-- Single tool: the Cortex Agent orchestrates Analyst + Search internally.
-- The external client does NOT choose which tool to call — the agent decides.

CREATE OR REPLACE MCP SERVER RETAILIQ_MCP_SERVER_AGENT
FROM SPECIFICATION $$
tools:
  - name: "retailiq_agent"
    type: "CORTEX_AGENT_RUN"
    identifier: "RETAILIQ_DB.ANALYTICS.RETAILIQ_CORTEX_AGENT"
    description: "Governed business data agent for RetailIQ. Answers questions about sales, orders, revenue, customers (structured analytics via Cortex Analyst) and customer reviews, support tickets, delivery feedback (unstructured search via Cortex Search). Send any business question and receive a complete answer."
    title: "RetailIQ Business Agent"
$$;

-- ==================================================================================
-- GRANT ACCESS: Allow RETAILIQ_ROLE to invoke the agent and its underlying objects
-- (Required because the Cortex Agent is owned by ACCOUNTADMIN)
-- ==================================================================================
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON AGENT RETAILIQ_DB.ANALYTICS.RETAILIQ_CORTEX_AGENT TO ROLE RETAILIQ_ROLE;
GRANT SELECT ON SEMANTIC VIEW RETAILIQ_DB.ANALYTICS.RETAILIQ_SV TO ROLE RETAILIQ_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA RETAILIQ_DB.ANALYTICS TO ROLE RETAILIQ_ROLE;
GRANT USAGE ON ALL CORTEX SEARCH SERVICES IN SCHEMA RETAILIQ_DB.ANALYTICS TO ROLE RETAILIQ_ROLE;

-- ==================================================================================
-- VERIFICATION
-- ==================================================================================
USE ROLE RETAILIQ_ROLE;
SHOW MCP SERVERS IN SCHEMA RETAILIQ_DB.ANALYTICS;

-- ==================================================================================
-- END
-- ==================================================================================
