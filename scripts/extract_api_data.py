"""
LastMile Analytics — API Data Extractor (Simulated)
=====================================================
I built this to demonstrate how I'd pull zone-performance data from a
paginated REST API in a real pipeline. The API is simulated here, but
the pagination loop, response parsing, and output format are identical
to what I'd use against a live endpoint.
"""

import json
import pandas as pd
from datetime import datetime, timedelta
import random
import time

# In production I'd swap simulate_api_response() for requests.get() calls
# against the real endpoint. Everything else stays the same.


def simulate_api_response(endpoint: str, page: int, per_page: int = 50) -> dict:
    """Return a fake paginated API response with zone-performance records."""
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
    """Walk through every page of a paginated endpoint and return all records."""
    all_records = []
    page = 1

    print(f"  Extracting from {endpoint}...")

    while True:
        # Simulated latency
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
