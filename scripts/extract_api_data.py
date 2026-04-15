"""
LastMile Analytics — API Data Extractor (Simulated)
=====================================================
This script simulates extracting data from a REST API.

In real-world analytics engineering, you often need to pull data from:
- Internal APIs (order management, warehouse systems)
- Third-party APIs (weather data, traffic data, shipping carriers)

WHAT YOU'LL LEARN:
- How to interact with REST APIs using Python's requests library
- Pagination handling (APIs return data in pages)
- Error handling and retries
- Saving API responses as structured data

NOTE: This uses a simulated API (json data) since we don't have a real API.
The patterns shown here are the SAME ones you'd use with real APIs.
"""

import json
import pandas as pd
from datetime import datetime, timedelta
import random
import time

# Simulated API responses (in practice, you'd use the `requests` library)
# Example of what a real API call looks like:
#
#   import requests
#   response = requests.get(
#       "https://api.gobolt.com/v1/deliveries",
#       headers={"Authorization": "Bearer YOUR_API_KEY"},
#       params={"page": 1, "per_page": 100}
#   )
#   data = response.json()


def simulate_api_response(endpoint: str, page: int, per_page: int = 50) -> dict:
    """
    Simulate an API response with pagination.

    Real APIs return data like this:
    {
        "data": [...],
        "meta": {"page": 1, "per_page": 50, "total_pages": 10, "total_records": 500}
    }
    """
    random.seed(42 + page)
    total_records = 200
    total_pages = (total_records + per_page - 1) // per_page

    if page > total_pages:
        return {"data": [], "meta": {"page": page, "total_pages": total_pages, "total_records": total_records}}

    start_idx = (page - 1) * per_page
    end_idx = min(start_idx + per_page, total_records)
    records_on_page = end_idx - start_idx

    data = []
    for i in range(records_on_page):
        record_id = start_idx + i + 1
        data.append({
            "zone_id": f"ZONE-{(record_id % 20) + 1:03d}",
            "date": (datetime.now() - timedelta(days=random.randint(1, 365))).strftime("%Y-%m-%d"),
            "avg_delivery_time_minutes": round(random.uniform(25, 180), 1),
            "total_deliveries": random.randint(5, 100),
            "on_time_percentage": round(random.uniform(60, 99), 1),
            "avg_distance_km": round(random.uniform(3, 50), 1),
            "weather_condition": random.choice(["clear", "rain", "snow", "cloudy"]),
        })

    return {
        "data": data,
        "meta": {
            "page": page,
            "per_page": per_page,
            "total_pages": total_pages,
            "total_records": total_records,
        }
    }


def extract_with_pagination(endpoint: str, per_page: int = 50) -> list:
    """
    Extract all records from a paginated API.

    This is a COMMON PATTERN in data engineering:
    1. Call page 1
    2. Check how many total pages exist
    3. Loop through remaining pages
    4. Combine all results

    In production, you'd add:
    - Rate limiting (time.sleep between calls)
    - Retry logic for failed requests
    - Error handling for timeouts
    """
    all_records = []
    page = 1

    print(f"  Extracting from {endpoint}...")

    while True:
        # Simulate network delay (real APIs have latency)
        time.sleep(0.1)

        response = simulate_api_response(endpoint, page, per_page)
        meta = response["meta"]
        records = response["data"]

        if not records:
            break

        all_records.extend(records)
        print(f"    Page {page}/{meta['total_pages']} — got {len(records)} records")

        if page >= meta["total_pages"]:
            break

        page += 1

    print(f"  Total extracted: {len(all_records)} records\n")
    return all_records


def main():
    """Extract data from simulated APIs and save as CSV."""
    print("🔌 LastMile Analytics — API Data Extractor")
    print("=" * 45)

    # Extract delivery zone performance data
    zone_data = extract_with_pagination("/api/v1/zone-performance")

    # Convert to DataFrame and save
    df = pd.DataFrame(zone_data)
    output_path = "seeds/raw_zone_performance.csv"
    df.to_csv(output_path, index=False)

    print(f"✅ Saved to {output_path}")
    print(f"   Columns: {list(df.columns)}")
    print(f"   Rows: {len(df)}")
    print(f"\n📋 Sample data:")
    print(df.head().to_string(index=False))


if __name__ == "__main__":
    main()
