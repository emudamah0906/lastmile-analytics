# LastMile Analytics — dbt + DuckDB Data Warehouse

A production-grade analytics engineering project that models a **last-mile delivery company's** data warehouse using **dbt**, **DuckDB**, **Python**, and **Kimball dimensional modeling**.

## Architecture

```
                         ┌─────────────────┐
                         │   dim_date      │
                         │ (date, fiscal   │
                         │  year, weekend) │
                         └────────┬────────┘
                                  │
┌─────────────────┐    ┌──────────┴──────────┐    ┌─────────────────┐
│  dim_customers  │────│   fact_deliveries   │────│   dim_drivers   │
│ (segment, city, │    │ (duration, distance,│    │ (EV flag, type, │
│  tenure)        │    │  amount, on_time)   │    │  tenure)        │
└─────────────────┘    └──────────┬──────────┘    └─────────────────┘
                                  │
                         ┌────────┴────────┐
                         │ dim_warehouses  │
                         │ (city, capacity │
                         │  tier)          │
                         └─────────────────┘
```

## Tech Stack

| Tool | Purpose |
|------|---------|
| **dbt** | Data transformation (ELT), testing, documentation |
| **DuckDB** | Local analytical database (warehouse) |
| **Python** | Data generation, API extraction, analytics |
| **Pandas** | Data manipulation and export |
| **Faker** | Realistic fake data generation |
| **GitHub Actions** | CI/CD pipeline for data quality |

## Project Structure

```
lastmile-analytics/
├── models/
│   ├── staging/          # 1:1 with raw tables, clean & rename
│   ├── intermediate/     # Join & enrich (ephemeral)
│   └── marts/            # Star schema (dims + facts)
├── seeds/                # Raw CSV data
├── scripts/              # Python: data gen, API extract, dashboard
├── analyses/             # Advanced SQL analytics
├── macros/               # Reusable SQL functions
├── tests/                # Custom data quality tests
└── .github/workflows/    # CI/CD pipeline
```

## Key Features

- **Kimball Star Schema**: Fact table with 4 dimension tables
- **Incremental Models**: fact_deliveries uses incremental loading
- **43 Automated Tests**: uniqueness, not-null, relationships, custom data quality
- **Custom Macros**: Reusable SQL (date spine, currency conversion)
- **CI/CD Pipeline**: GitHub Actions runs `dbt build` on every PR
- **Python Data Engineering**: Faker-based generation + API extraction patterns
- **Sustainability Tracking**: EV vs gas vehicle performance metrics

## Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Install dbt packages
dbt deps --profiles-dir .

# 3. Generate fake logistics data
python scripts/generate_data.py
python scripts/extract_api_data.py

# 4. Build the data warehouse
dbt seed --profiles-dir .     # Load CSVs
dbt run --profiles-dir .      # Build models
dbt test --profiles-dir .     # Run 43 tests

# 5. Explore
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .   # Opens interactive docs

# 6. Run analytics dashboard
python scripts/dashboard.py
```

## dbt Layers

| Layer | Materialization | Purpose |
|-------|----------------|---------|
| **Staging** | View | Clean raw data: rename, cast, filter nulls |
| **Intermediate** | Ephemeral | Join orders + deliveries, apply business logic |
| **Marts (Dims)** | Table | Customer, driver, warehouse, date dimensions |
| **Marts (Facts)** | Incremental | Delivery fact table — core of the star schema |

## Analytics Queries

The `analyses/` folder contains advanced SQL demonstrating:

- **Window Functions**: Running averages, LAG/LEAD, RANK, NTILE
- **CTEs**: Multi-step analytical queries
- **Cohort Analysis**: Customer retention by signup month
- **Performance Rankings**: Driver efficiency with DENSE_RANK

## Skills Demonstrated

This project covers the following analytics engineering competencies:

- dbt (models, tests, macros, packages, incremental, docs)
- Kimball Dimensional Modeling (star schema, fact/dim tables)
- Advanced SQL (CTEs, window functions, partitioning)
- Python (Pandas, Faker, REST API patterns)
- CI/CD for data pipelines (GitHub Actions)
- Data quality testing and monitoring
- Git version control
- Logistics domain (last-mile delivery, EV fleet, warehouse operations)
