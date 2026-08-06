# ==================================================================================
# MODULE 3: TEST CORTEX SEARCH SERVICES (Python) — RetailIQ Workshop
# ==================================================================================
# Run this in a Snowflake Python Worksheet to test semantic search.
# Set Database: RETAILIQ_DB, Schema: ANALYTICS, Warehouse: RETAILIQ_WH
# ==================================================================================

from snowflake.snowpark.context import get_active_session
import json

session = get_active_session()

# ==================================================================================
# TEST 1: Semantic search on Customer Reviews
# ==================================================================================
print("=" * 70)
print("TEST 1: Delivery problems in southern Italy (Reviews)")
print("=" * 70)

result = session.sql("""
    SELECT PARSE_JSON(
      SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RETAILIQ_REVIEWS_SEARCH',
        '{
          "query": "delivery problems in southern Italy",
          "columns": ["review_text", "product_name", "rating"],
          "limit": 5
        }'
      )
    )['results'] AS results
""").collect()

results = json.loads(result[0]['RESULTS'])
for i, row in enumerate(results, 1):
    print(f"\n--- Result {i} ---")
    print(f"  Product: {row['product_name']}")
    print(f"  Rating:  {row['rating']}/5")
    print(f"  Review:  {row['review_text'][:150]}...")

# ==================================================================================
# TEST 2: Semantic search on Support Tickets
# ==================================================================================
print("\n\n" + "=" * 70)
print("TEST 2: Refund not processed (Support Tickets)")
print("=" * 70)

result = session.sql("""
    SELECT PARSE_JSON(
      SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RETAILIQ_TICKETS_SEARCH',
        '{
          "query": "refund not processed",
          "columns": ["ticket_text", "category", "status"],
          "limit": 5
        }'
      )
    )['results'] AS results
""").collect()

results = json.loads(result[0]['RESULTS'])
for i, row in enumerate(results, 1):
    print(f"\n--- Result {i} ---")
    print(f"  Category: {row['category']}")
    print(f"  Status:   {row['status']}")
    print(f"  Ticket:   {row['ticket_text'][:150]}...")

# ==================================================================================
# TEST 3: Product quality feedback
# ==================================================================================
print("\n\n" + "=" * 70)
print("TEST 3: Poor product quality and defects (Reviews)")
print("=" * 70)

result = session.sql("""
    SELECT PARSE_JSON(
      SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RETAILIQ_REVIEWS_SEARCH',
        '{
          "query": "poor product quality and defects",
          "columns": ["review_text", "product_name", "category", "rating"],
          "limit": 5
        }'
      )
    )['results'] AS results
""").collect()

results = json.loads(result[0]['RESULTS'])
for i, row in enumerate(results, 1):
    print(f"\n--- Result {i} ---")
    print(f"  Product:  {row['product_name']} ({row['category']})")
    print(f"  Rating:   {row['rating']}/5")
    print(f"  Review:   {row['review_text'][:150]}...")

# ==================================================================================
# TEST 4: Urgent unresolved issues
# ==================================================================================
print("\n\n" + "=" * 70)
print("TEST 4: Customer waiting too long for resolution (Tickets)")
print("=" * 70)

result = session.sql("""
    SELECT PARSE_JSON(
      SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RETAILIQ_TICKETS_SEARCH',
        '{
          "query": "customer waiting too long for resolution",
          "columns": ["ticket_text", "category", "priority", "status"],
          "limit": 5
        }'
      )
    )['results'] AS results
""").collect()

results = json.loads(result[0]['RESULTS'])
for i, row in enumerate(results, 1):
    print(f"\n--- Result {i} ---")
    print(f"  Category: {row['category']}")
    print(f"  Priority: {row['priority']}")
    print(f"  Status:   {row['status']}")
    print(f"  Ticket:   {row['ticket_text'][:150]}...")

print("\n\n" + "=" * 70)
print("ALL TESTS COMPLETE")
print("=" * 70)
