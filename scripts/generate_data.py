"""
LastMile Analytics — Fake Data Generator
=========================================
This script generates realistic logistics data for a last-mile delivery company.

WHAT YOU'LL LEARN:
- Using Faker library to generate realistic fake data
- Using Pandas DataFrames to structure and export data
- Data modeling concepts: how tables relate to each other via foreign keys
- Python best practices: functions, type hints, reproducible random seeds
"""

import pandas as pd
from faker import Faker
import random
from datetime import datetime, timedelta

# Set seed for reproducibility — same data every time you run this
fake = Faker("en_CA")  # Canadian locale (GoBolt is Toronto-based)
Faker.seed(42)
random.seed(42)

# --- Configuration ---
NUM_CUSTOMERS = 500
NUM_DRIVERS = 50
NUM_WAREHOUSES = 8
NUM_ORDERS = 5000
NUM_DELIVERIES = 4500  # Not all orders get delivered

# Canadian cities where GoBolt operates
CITIES = [
    ("Toronto", "ON"),
    ("Mississauga", "ON"),
    ("Brampton", "ON"),
    ("Hamilton", "ON"),
    ("Ottawa", "ON"),
    ("Montreal", "QC"),
    ("Vancouver", "BC"),
    ("Calgary", "AB"),
]

ORDER_STATUSES = ["pending", "processing", "shipped", "delivered", "cancelled", "returned"]
DELIVERY_STATUSES = ["in_transit", "delivered", "failed", "returned_to_warehouse"]
VEHICLE_TYPES = ["electric_van", "electric_truck", "gas_van", "gas_truck", "cargo_bike"]
DRIVER_STATUSES = ["active", "inactive", "on_leave"]


def generate_warehouses() -> pd.DataFrame:
    """Generate warehouse data — these are the fulfillment centers."""
    warehouses = []
    for i in range(1, NUM_WAREHOUSES + 1):
        city, province = CITIES[i % len(CITIES)]
        warehouses.append({
            "warehouse_id": f"WH-{i:03d}",
            "warehouse_name": f"{city} Fulfillment Center {i}",
            "city": city,
            "province": province,
            "capacity": random.choice([500, 1000, 2000, 5000]),
            "opened_date": fake.date_between(start_date="-5y", end_date="-1y"),
        })
    return pd.DataFrame(warehouses)


def generate_customers() -> pd.DataFrame:
    """Generate customer data — the ecommerce brands using our logistics."""
    customers = []
    for i in range(1, NUM_CUSTOMERS + 1):
        city, province = random.choice(CITIES)
        customers.append({
            "customer_id": f"CUST-{i:04d}",
            "customer_name": fake.company(),
            "email": fake.company_email(),
            "city": city,
            "province": province,
            "signup_date": fake.date_between(start_date="-3y", end_date="-30d"),
        })
    return pd.DataFrame(customers)


def generate_drivers() -> pd.DataFrame:
    """Generate driver data — includes EV vs gas vehicles (GoBolt's EV fleet focus)."""
    drivers = []
    for i in range(1, NUM_DRIVERS + 1):
        # 60% chance of EV — reflects GoBolt's push toward electric fleet
        vehicle = random.choices(
            VEHICLE_TYPES,
            weights=[30, 15, 10, 5, 10],  # Heavy weight toward EVs
            k=1
        )[0]
        drivers.append({
            "driver_id": f"DRV-{i:03d}",
            "driver_name": fake.name(),
            "vehicle_type": vehicle,
            "hire_date": fake.date_between(start_date="-4y", end_date="-30d"),
            "driver_status": random.choices(
                DRIVER_STATUSES,
                weights=[80, 10, 10],
                k=1
            )[0],
        })
    return pd.DataFrame(drivers)


def generate_orders(customers: pd.DataFrame, warehouses: pd.DataFrame) -> pd.DataFrame:
    """
    Generate order data — these represent ecommerce orders flowing through our system.

    Notice how orders reference customer_id and warehouse_id — these are FOREIGN KEYS,
    which create relationships between tables. This is fundamental to data modeling.
    """
    orders = []
    customer_ids = customers["customer_id"].tolist()
    warehouse_ids = warehouses["warehouse_id"].tolist()

    for i in range(1, NUM_ORDERS + 1):
        order_date = fake.date_time_between(start_date="-1y", end_date="now")
        orders.append({
            "order_id": f"ORD-{i:05d}",
            "customer_id": random.choice(customer_ids),
            "warehouse_id": random.choice(warehouse_ids),
            "order_date": order_date.strftime("%Y-%m-%d %H:%M:%S"),
            "order_status": random.choices(
                ORDER_STATUSES,
                weights=[5, 5, 10, 60, 15, 5],  # Most orders are delivered
                k=1
            )[0],
            "total_amount": round(random.uniform(15.0, 500.0), 2),
            "item_count": random.randint(1, 12),
        })
    return pd.DataFrame(orders)


def generate_deliveries(orders: pd.DataFrame, drivers: pd.DataFrame) -> pd.DataFrame:
    """
    Generate delivery data — the actual last-mile delivery events.

    Key concept: Not all orders become deliveries (some are cancelled).
    We only create deliveries for orders that were shipped/delivered.
    """
    deliveries = []
    driver_ids = drivers["driver_id"].tolist()

    # Only create deliveries for non-cancelled, non-pending orders
    eligible_orders = orders[
        orders["order_status"].isin(["shipped", "delivered", "returned"])
    ].head(NUM_DELIVERIES)

    for idx, (_, order) in enumerate(eligible_orders.iterrows(), 1):
        order_dt = datetime.strptime(order["order_date"], "%Y-%m-%d %H:%M:%S")
        # Pickup happens 1-3 days after order
        pickup_time = order_dt + timedelta(hours=random.randint(12, 72))
        # Delivery takes 30 min to 4 hours after pickup
        delivery_minutes = random.randint(30, 240)
        delivery_time = pickup_time + timedelta(minutes=delivery_minutes)

        distance = round(random.uniform(2.0, 80.0), 1)
        status = random.choices(
            DELIVERY_STATUSES,
            weights=[5, 80, 10, 5],
            k=1
        )[0]

        deliveries.append({
            "delivery_id": f"DEL-{idx:05d}",
            "order_id": order["order_id"],
            "driver_id": random.choice(driver_ids),
            "pickup_time": pickup_time.strftime("%Y-%m-%d %H:%M:%S"),
            "delivery_time": delivery_time.strftime("%Y-%m-%d %H:%M:%S"),
            "delivery_status": status,
            "distance_km": distance,
            "delivery_duration_minutes": delivery_minutes,
        })
    return pd.DataFrame(deliveries)


def main():
    """Generate all data and save as CSVs in the seeds/ directory."""
    print("🚚 LastMile Analytics — Data Generator")
    print("=" * 45)

    # Generate data in dependency order
    print("Generating warehouses...")
    warehouses = generate_warehouses()

    print("Generating customers...")
    customers = generate_customers()

    print("Generating drivers...")
    drivers = generate_drivers()

    print("Generating orders...")
    orders = generate_orders(customers, warehouses)

    print("Generating deliveries...")
    deliveries = generate_deliveries(orders, drivers)

    # Save to seeds/ directory (dbt will load these)
    output_dir = "seeds"
    datasets = {
        "raw_warehouses": warehouses,
        "raw_customers": customers,
        "raw_drivers": drivers,
        "raw_orders": orders,
        "raw_deliveries": deliveries,
    }

    for name, df in datasets.items():
        filepath = f"{output_dir}/{name}.csv"
        df.to_csv(filepath, index=False)
        print(f"  ✅ {filepath} — {len(df)} rows, {len(df.columns)} columns")

    print("\n📊 Data Summary:")
    print(f"  Warehouses:  {len(warehouses)}")
    print(f"  Customers:   {len(customers)}")
    print(f"  Drivers:     {len(drivers)}")
    print(f"  Orders:      {len(orders)}")
    print(f"  Deliveries:  {len(deliveries)}")
    print("\nDone! Run 'dbt seed' to load this data into DuckDB.")


if __name__ == "__main__":
    main()
