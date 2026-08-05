# ==================================================================================
# MODULE 3: TEST CORTEX SEARCH SERVICES (REST API - Python) — RetailIQ Workshop
# ==================================================================================
# This script tests Cortex Search using the REST API with the requests library.
# Unlike the Snowpark version, this uses pure HTTP calls — the same interface
# that external clients (AWS Bedrock AgentCore, Strands agents) use.
#
# Prerequisites:
#   pip install requests
#   A Programmatic Access Token (PAT) from Snowsight:
#     User menu → My Profile → Programmatic Access Tokens → Generate
# ==================================================================================

import json
import requests

# --- CONFIGURATION (replace with your values) ---
ACCOUNT_URL = "https://<your-account>.snowflakecomputing.com"
PAT = "<your-pat-token>"

DATABASE = "RETAILIQ_DB"
SCHEMA = "ANALYTICS"

HEADERS = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": f"Bearer {PAT}",
}


def query_search_service(service_name: str, query: str, columns: list, limit: int = 5, filter_obj: dict = None):
    """Query a Cortex Search Service via REST API."""
    url = f"{ACCOUNT_URL}/api/v2/databases/{DATABASE}/schemas/{SCHEMA}/cortex-search-services/{service_name}:query"

    payload = {
        "query": query,
        "columns": columns,
        "limit": limit,
    }
    if filter_obj:
        payload["filter"] = filter_obj

    response = requests.post(url, headers=HEADERS, json=payload)
    response.raise_for_status()
    return response.json()


# ==================================================================================
# TEST 1: Semantic search on Customer Reviews
# ==================================================================================
print("=" * 70)
print("TEST 1: Delivery problems in southern Italy (Reviews)")
print("=" * 70)

results = query_search_service(
    "RETAILIQ_REVIEWS_SEARCH",
    query="delivery problems in southern Italy",
    columns=["REVIEW_TEXT", "PRODUCT_NAME", "RATING"],
)

for i, row in enumerate(results.get("results", []), 1):
    print(f"\n--- Result {i} ---")
    print(f"  Product: {row['PRODUCT_NAME']}")
    print(f"  Rating:  {row['RATING']}/5")
    print(f"  Review:  {row['REVIEW_TEXT'][:150]}...")


# ==================================================================================
# TEST 2: Semantic search on Support Tickets
# ==================================================================================
print("\n\n" + "=" * 70)
print("TEST 2: Refund not processed (Support Tickets)")
print("=" * 70)

results = query_search_service(
    "RETAILIQ_TICKETS_SEARCH",
    query="refund not processed",
    columns=["TICKET_TEXT", "CATEGORY", "STATUS"],
)

for i, row in enumerate(results.get("results", []), 1):
    print(f"\n--- Result {i} ---")
    print(f"  Category: {row['CATEGORY']}")
    print(f"  Status:   {row['STATUS']}")
    print(f"  Ticket:   {row['TICKET_TEXT'][:150]}...")


# ==================================================================================
# TEST 3: Search with filter (low ratings only)
# ==================================================================================
print("\n\n" + "=" * 70)
print("TEST 3: Poor quality + filter on rating <= 2 (Reviews)")
print("=" * 70)

results = query_search_service(
    "RETAILIQ_REVIEWS_SEARCH",
    query="poor product quality and defects",
    columns=["REVIEW_TEXT", "PRODUCT_NAME", "CATEGORY", "RATING"],
    filter_obj={"@lte": {"RATING": 2}},
)

for i, row in enumerate(results.get("results", []), 1):
    print(f"\n--- Result {i} ---")
    print(f"  Product:  {row['PRODUCT_NAME']} ({row['CATEGORY']})")
    print(f"  Rating:   {row['RATING']}/5")
    print(f"  Review:   {row['REVIEW_TEXT'][:150]}...")


# ==================================================================================
# TEST 4: Urgent unresolved tickets
# ==================================================================================
print("\n\n" + "=" * 70)
print("TEST 4: Waiting too long + filter on Open status (Tickets)")
print("=" * 70)

results = query_search_service(
    "RETAILIQ_TICKETS_SEARCH",
    query="customer waiting too long for resolution",
    columns=["TICKET_TEXT", "CATEGORY", "PRIORITY", "STATUS"],
    filter_obj={"@eq": {"STATUS": "Open"}},
)

for i, row in enumerate(results.get("results", []), 1):
    print(f"\n--- Result {i} ---")
    print(f"  Category: {row['CATEGORY']}")
    print(f"  Priority: {row['PRIORITY']}")
    print(f"  Status:   {row['STATUS']}")
    print(f"  Ticket:   {row['TICKET_TEXT'][:150]}...")

print("\n\n" + "=" * 70)
print("ALL REST API TESTS COMPLETE")
print("=" * 70)
