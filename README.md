# LastMile Analytics

A data warehouse I built to model last-mile delivery operations using **dbt**, **DuckDB**, and **Kimball dimensional modeling**. The project covers the full analytics engineering lifecycle: synthetic data generation, staging/transformation layers, a star schema, automated testing, and CI/CD.

## Architecture

```
                         +------------------+
                         |    dim_date      |
                         | (date, fiscal    |
                         |  year, weekend)  |
                         +--------+---------+
                                  |
+------------------+    +---------+----------+    +------------------+
|  dim_customers   |----| fact_deliveries    |----|   dim_drivers    |
| (segment, city,  |    | (duration, dist,   |    | (EV flag, type,  |
|  tenure)         |    |  amount, on_time)  |    |  tenure)         |
+------------------+    +---------+----------+    +------------------+
                                  |
                         +--------+---------+
                         | dim_warehouses   |
                         | (city, capacity  |
                         |  tier)           |
                         +------------------+
```

## Why I Built This

I wanted a project that demonstrates the kind of work I do as an analytics engineer -- not just SQL, but the full stack: data generation, transformation layers, testing, and CI. I modeled it around last-mile logistics because the domain has interesting data relationships (orders, deliveries, drivers, warehouses) and real operational KPIs like on-time rate and EV fleet adoption.

## Tech Stack

| Tool | Why I chose it |
|------|---------------|
| **dbt** | Industry-standard transformation framework; I wanted to show staging/intermediate/mart layering |
| **DuckDB** | Runs locally with zero infrastructure -- great for a portfolio project that anyone can clone and run |
| **Python** | Data generation (Faker), API extraction simulation, CLI dashboard |
| **GitHub Actions** | Automated CI that runs `dbt build` on every PR |

## Project Structure

```
lastmile-analytics/
├── models/
│   ├── staging/          # 1:1 with raw tables, clean & type-cast
│   ├── intermediate/     # Join orders + deliveries (ephemeral)
│   └── marts/            # Star schema (dims + facts)
├── seeds/                # Raw CSV data (generated)
├── scripts/              # Data gen, API extraction, dashboard
├── analyses/             # Ad-hoc analytical queries
├── macros/               # Reusable SQL (date spine, currency)
├── tests/                # Custom data quality tests
└── .github/workflows/    # CI pipeline
```

## Key Design Decisions

- **Incremental fact table**: `fact_deliveries` is incremental because in production, delivery tables grow fast and full rebuilds are wasteful.
- **Ephemeral intermediate layer**: `int_orders_deliveries_joined` is ephemeral so it doesn't materialize a redundant table -- it just inlines as a CTE in the fact model.
- **Surrogate keys via dbt_utils**: Hash-based surrogate keys decouple the warehouse from source system IDs.
- **EV flag in staging**: I derive `is_ev_driver` at the staging layer so every downstream model can slice by it without re-implementing the logic.
- **Canadian fiscal year**: The date dimension uses an April-start fiscal year to match Canadian government FY conventions.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt
dbt deps --profiles-dir .

# Generate data and build the warehouse
python scripts/generate_data.py
python scripts/extract_api_data.py
dbt seed --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .

# Explore
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .

# Run the CLI dashboard
python scripts/dashboard.py
```

## Analytical Queries

The `analyses/` folder contains queries I wrote to explore the data:

- **delivery_performance.sql** -- Performance by warehouse, vehicle type, and day of week
- **customer_cohort_analysis.sql** -- Retention and revenue trends by signup cohort
- **driver_efficiency.sql** -- Driver rankings with quartile bucketing
- **warehouse_utilization.sql** -- Capacity tracking with MoM growth and utilization alerts
