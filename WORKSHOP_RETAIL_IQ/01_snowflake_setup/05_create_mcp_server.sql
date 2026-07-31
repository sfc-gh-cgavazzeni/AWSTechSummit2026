-- ==================================================================================
-- MODULE 4: CREATE MCP SERVER & CORTEX AGENT — RetailIQ Workshop
-- ==================================================================================
-- Creates:
--   1. MCP Server with 3 tools (Cortex Analyst + 2 Cortex Search Services)
--   2. Cortex Agent with the same 3 tools for in-Snowflake usage
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- MCP SERVER: RETAILIQ_MCP_SERVER
-- ==================================================================================
CREATE OR REPLACE MCP SERVER RETAILIQ_MCP_SERVER
FROM SPECIFICATION $$
{
    "capabilities": {
        "tools": [
            {
                "name": "retailiq_analyst",
                "type": "CORTEX_ANALYST_MESSAGE",
                "identifier": "RETAILIQ_DB.ANALYTICS.RETAILIQ_SV",
                "description": "Structured analytics tool for RetailIQ sales, orders, customers and stores data. Use for quantitative questions about revenue, conversion rates, order volumes, customer segments, regional performance, product categories, and time-series trends.",
                "title": "RetailIQ Analytics"
            },
            {
                "name": "retailiq_reviews_search",
                "type": "CORTEX_SEARCH_SERVICE_QUERY",
                "identifier": "RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH",
                "description": "Semantic search over RetailIQ customer reviews. Use for qualitative insights, sentiment analysis, product feedback, and understanding what customers say about their experiences.",
                "title": "Customer Reviews Search"
            },
            {
                "name": "retailiq_tickets_search",
                "type": "CORTEX_SEARCH_SERVICE_QUERY",
                "identifier": "RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH",
                "description": "Semantic search over support tickets. Use for understanding common issues, complaints, return reasons, and service quality feedback.",
                "title": "Support Tickets Search"
            }
        ]
    }
}
$$;

-- ==================================================================================
-- VERIFICATION: Describe MCP Server
-- ==================================================================================
DESCRIBE MCP SERVER RETAILIQ_MCP_SERVER;

-- ==================================================================================
-- USAGE INSTRUCTIONS
-- ==================================================================================
-- 1. Get the MCP Server endpoint URL from the DESCRIBE output above.
--    The endpoint will look like:
--    https://<account>.snowflakecomputing.com/api/v2/cortex/mcp/<db>/<schema>/<server_name>/sse
--
-- 2. Generate a PAT token (run as ACCOUNTADMIN — see 01_setup_environment.sql PART 2):
--    ALTER USER RETAILIQ_USER
--        ADD PROGRAMMATIC ACCESS TOKEN RETAILIQ_MCP_TOKEN
--        DAYS_TO_EXPIRY = 7
--        ROLE_RESTRICTION = 'RETAILIQ_ROLE';
--
-- 3. Use the endpoint and PAT token in your MCP client configuration:
--    {
--        "mcpServers": {
--            "retailiq": {
--                "url": "<endpoint_url_from_describe>",
--                "headers": {
--                    "Authorization": "Bearer <pat_token_value>"
--                }
--            }
--        }
--    }
--
-- 4. For AWS Bedrock AgentCore integration, configure the MCP endpoint
--    as a tool server in your AgentCore agent definition.

-- ==================================================================================
-- CORTEX AGENT: RETAILIQ_CORTEX_AGENT (for in-Snowflake usage)
-- ==================================================================================
CREATE OR REPLACE CORTEX AGENT RETAILIQ_CORTEX_AGENT
    QUERY_WAREHOUSE = RETAILIQ_WH
    AGENT_ROLE = RETAILIQ_ROLE
    TOOLS = (
        CORTEX_ANALYST_TOOL (
            SEMANTIC_VIEW => 'RETAILIQ_DB.ANALYTICS.RETAILIQ_SV',
            TOOL_DESCRIPTION => 'Structured analytics tool for RetailIQ sales, orders, customers and stores data. Use for quantitative questions about revenue, conversion rates, order volumes, customer segments, regional performance, product categories, and time-series trends.'
        ),
        CORTEX_SEARCH_TOOL (
            CORTEX_SEARCH_SERVICE => 'RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH',
            TOOL_DESCRIPTION => 'Semantic search over RetailIQ customer reviews. Use for qualitative insights, sentiment analysis, product feedback, and understanding what customers say about their experiences.'
        ),
        CORTEX_SEARCH_TOOL (
            CORTEX_SEARCH_SERVICE => 'RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH',
            TOOL_DESCRIPTION => 'Semantic search over support tickets. Use for understanding common issues, complaints, return reasons, and service quality feedback.'
        )
    )
    COMMENT = 'RetailIQ Cortex Agent — combines structured analytics with unstructured search';

-- ==================================================================================
-- VERIFICATION: Describe Cortex Agent
-- ==================================================================================
DESCRIBE CORTEX AGENT RETAILIQ_CORTEX_AGENT;

-- ==================================================================================
-- END OF MODULE 4
-- ==================================================================================
