# ==================================================================================
# MODULE 3: TEST CORTEX SEARCH SERVICES (Python) — RetailIQ Workshop
# ==================================================================================
# Run this in a Snowflake Python Worksheet to test semantic search.
# Open: Projects → Worksheets → "+" → Python Worksheet
# Set Database: RETAILIQ_DB, Schema: ANALYTICS, Warehouse: RETAILIQ_WH
# ==================================================================================

from snowflake.snowpark.context import get_active_session

session = get_active_session()

# ==================================================================================
# TEST 1: Semantic search on Customer Reviews
# ==================================================================================
# This query finds reviews about delivery issues in southern Italy,
# even if the exact phrase "delivery problems" doesn't appear in the text.

print("=" * 70)
print("TEST 1: Delivery problems in southern Italy (Reviews)")
print("=" * 70)

results = session.sql("""
    SELECT *
    FROM TABLE(
      SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH',
        '{
          "query": "delivery problems in southern Italy",
          "columns": ["review_text", "product_name", "rating"],
          "limit": 5
        }'
      )
    )
""").collect()

for i, row in enumerate(results, 1):
    print(f"\n--- Result {i} ---")
    print(f"  Product: {row['PRODUCT_NAME']}")
    print(f"  Rating:  {row['RATING']}/5")
    print(f"  Review:  {row['REVIEW_TEXT'][:150]}...")

# ==================================================================================
# TEST 2: Semantic search on Support Tickets
# ==================================================================================
# Finds tickets about refund/billing issues using semantic matching.

print("\n\n" + "=" * 70)
print("TEST 2: Refund not processed (Support Tickets)")
print("=" * 70)

tickets = session.sql("""
    SELECT *
    FROM TABLE(
      SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH',
        '{
          "query": "refund not processed",
          "columns": ["ticket_text", "category", "status"],
          "limit": 5
        }'
      )
    )
""").collect()

for i, row in enumerate(tickets, 1):
    print(f"\n--- Result {i} ---")
    print(f"  Category: {row['CATEGORY']}")
    print(f"  Status:   {row['STATUS']}")
    print(f"  Ticket:   {row['TICKET_TEXT'][:150]}...")

# ==================================================================================
# TEST 3: Product quality feedback
# ==================================================================================
# Demonstrates semantic understanding of "quality" — finds reviews mentioning
# defective, broken, poor craftsmanship, doesn't work, etc.

print("\n\n" + "=" * 70)
print("TEST 3: Poor product quality and defects (Reviews)")
print("=" * 70)

quality = session.sql("""
    SELECT *
    FROM TABLE(
      SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RETAILIQ_DB.ANALYTICS.RETAILIQ_REVIEWS_SEARCH',
        '{
          "query": "poor product quality and defects",
          "columns": ["review_text", "product_name", "category", "rating"],
          "limit": 5
        }'
      )
    )
""").collect()

for i, row in enumerate(quality, 1):
    print(f"\n--- Result {i} ---")
    print(f"  Product:  {row['PRODUCT_NAME']} ({row['CATEGORY']})")
    print(f"  Rating:   {row['RATING']}/5")
    print(f"  Review:   {row['REVIEW_TEXT'][:150]}...")

# ==================================================================================
# TEST 4: Urgent unresolved issues
# ==================================================================================

print("\n\n" + "=" * 70)
print("TEST 4: Customer waiting too long for resolution (Tickets)")
print("=" * 70)

urgent = session.sql("""
    SELECT *
    FROM TABLE(
      SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'RETAILIQ_DB.ANALYTICS.RETAILIQ_TICKETS_SEARCH',
        '{
          "query": "customer waiting too long for resolution",
          "columns": ["ticket_text", "category", "priority", "status"],
          "limit": 5
        }'
      )
    )
""").collect()

for i, row in enumerate(urgent, 1):
    print(f"\n--- Result {i} ---")
    print(f"  Category: {row['CATEGORY']}")
    print(f"  Priority: {row['PRIORITY']}")
    print(f"  Status:   {row['STATUS']}")
    print(f"  Ticket:   {row['TICKET_TEXT'][:150]}...")

print("\n\n" + "=" * 70)
print("ALL TESTS COMPLETE")
print("=" * 70)
