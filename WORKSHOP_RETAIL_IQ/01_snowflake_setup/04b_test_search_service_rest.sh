#!/bin/bash
# ==================================================================================
# MODULE 3: TEST CORTEX SEARCH SERVICES (REST API) — RetailIQ Workshop
# ==================================================================================
# This script tests Cortex Search using the REST API with a PAT token.
# This is the same interface that external clients (AWS Bedrock, Strands agents)
# use to query Cortex Search programmatically.
#
# Prerequisites:
#   - A Programmatic Access Token (PAT) — generate one in Snowsight:
#     User menu → My Profile → Programmatic Access Tokens → Generate
#   - Set your account URL and PAT below
# ==================================================================================

# --- CONFIGURATION (replace with your values) ---
ACCOUNT_URL="https://<your-account>.snowflakecomputing.com"
PAT="<your-pat-token>"

DATABASE="RETAILIQ_DB"
SCHEMA="ANALYTICS"

# ==================================================================================
# TEST 1: Semantic search on Customer Reviews
# ==================================================================================
echo "============================================================"
echo "TEST 1: Delivery problems in southern Italy (Reviews)"
echo "============================================================"

curl -s --location "${ACCOUNT_URL}/api/v2/databases/${DATABASE}/schemas/${SCHEMA}/cortex-search-services/RETAILIQ_REVIEWS_SEARCH:query" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer ${PAT}" \
  --data '{
    "query": "delivery problems in southern Italy",
    "columns": ["REVIEW_TEXT", "PRODUCT_NAME", "RATING"],
    "limit": 5
  }' | python3 -m json.tool

echo ""

# ==================================================================================
# TEST 2: Semantic search on Support Tickets
# ==================================================================================
echo "============================================================"
echo "TEST 2: Refund not processed (Support Tickets)"
echo "============================================================"

curl -s --location "${ACCOUNT_URL}/api/v2/databases/${DATABASE}/schemas/${SCHEMA}/cortex-search-services/RETAILIQ_TICKETS_SEARCH:query" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer ${PAT}" \
  --data '{
    "query": "refund not processed",
    "columns": ["TICKET_TEXT", "CATEGORY", "STATUS"],
    "limit": 5
  }' | python3 -m json.tool

echo ""

# ==================================================================================
# TEST 3: Search with filter (Reviews with rating <= 2)
# ==================================================================================
echo "============================================================"
echo "TEST 3: Poor quality + filter on low ratings (Reviews)"
echo "============================================================"

curl -s --location "${ACCOUNT_URL}/api/v2/databases/${DATABASE}/schemas/${SCHEMA}/cortex-search-services/RETAILIQ_REVIEWS_SEARCH:query" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer ${PAT}" \
  --data '{
    "query": "poor product quality and defects",
    "columns": ["REVIEW_TEXT", "PRODUCT_NAME", "CATEGORY", "RATING"],
    "filter": {"@lte": {"RATING": 2}},
    "limit": 5
  }' | python3 -m json.tool

echo ""

# ==================================================================================
# TEST 4: Urgent unresolved tickets with filter
# ==================================================================================
echo "============================================================"
echo "TEST 4: Waiting too long + filter on Open status (Tickets)"
echo "============================================================"

curl -s --location "${ACCOUNT_URL}/api/v2/databases/${DATABASE}/schemas/${SCHEMA}/cortex-search-services/RETAILIQ_TICKETS_SEARCH:query" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer ${PAT}" \
  --data '{
    "query": "customer waiting too long for resolution",
    "columns": ["TICKET_TEXT", "CATEGORY", "PRIORITY", "STATUS"],
    "filter": {"@eq": {"STATUS": "Open"}},
    "limit": 5
  }' | python3 -m json.tool

echo ""
echo "============================================================"
echo "ALL REST API TESTS COMPLETE"
echo "============================================================"
