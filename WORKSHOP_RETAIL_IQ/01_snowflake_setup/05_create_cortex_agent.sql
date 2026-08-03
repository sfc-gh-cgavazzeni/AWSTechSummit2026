-- ==================================================================================
-- MODULE 4: CREATE CORTEX AGENT — RetailIQ Workshop
-- ==================================================================================
-- Creates a native Snowflake Cortex Agent that orchestrates:
--   - Cortex Analyst (structured analytics via Semantic View)
--   - Cortex Search ×2 (customer reviews + support tickets)
--
-- After creation, test it in CoWork (Snowsight → AI & ML → CoWork).
-- ==================================================================================

USE ROLE RETAILIQ_ROLE;
USE DATABASE RETAILIQ_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RETAILIQ_WH;

-- ==================================================================================
-- CREATE CORTEX AGENT: RETAILIQ_CORTEX_AGENT
-- ==================================================================================
-- This agent combines structured analytics (Cortex Analyst over the Semantic View)
-- with unstructured search (Cortex Search over reviews and tickets).
-- When a user asks a question, the agent decides which tool(s) to call:
--   - Quantitative questions → Cortex Analyst (generates SQL)
--   - Qualitative questions → Cortex Search (semantic search)
--   - Complex questions → Both tools, then synthesizes the answer
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
-- VERIFICATION
-- ==================================================================================
DESCRIBE CORTEX AGENT RETAILIQ_CORTEX_AGENT;

-- ==================================================================================
-- HOW TO TEST IN COWORK
-- ==================================================================================
-- 1. In Snowsight, click the AI & ML icon (brain icon) in the left sidebar
-- 2. Select "CoWork" from the menu
-- 3. Click "New Session" or "+" to start a new conversation
-- 4. Select RETAILIQ_CORTEX_AGENT from the agent dropdown
-- 5. Start asking questions!
--
-- Recommended demo sequence:
--
-- Q1 (Analyst only):
--   "What are our top 5 categories by revenue this quarter?"
--
-- Q2 (Search only):
--   "What do customers say about our electronics products?"
--
-- Q3 (Both tools - the key demo):
--   "Which product categories have the highest return rates,
--    and what are customers saying about those returns?"
--
-- Q4 (Cross-tool reasoning):
--   "Compare revenue performance by region — are there regions
--    with more delivery complaints?"
--
-- OBSERVE: The reasoning trace shows which tool was selected, why,
-- and how the agent synthesizes answers from multiple sources.
-- ==================================================================================
-- END OF MODULE 4
-- ==================================================================================
