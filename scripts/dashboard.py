"""
LastMile Analytics — Dashboard Script
=======================================
Quick CLI dashboard that queries the star schema in DuckDB and prints
KPIs, trends, and breakdowns. I use this for sanity-checking the
warehouse after a dbt run; in production I'd point Metabase or Looker
at the same tables.
"""

import duckdb
import pandas as pd


def run_query(conn, name: str, query: str) -> pd.DataFrame:
    """Run a SQL query and return results as a DataFrame."""
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"{'='*60}")
    df = conn.execute(query).fetchdf()
    print(df.to_string(index=False))
    return df


def main():
    # Connect to the DuckDB database (same file dbt writes to)
    conn = duckdb.connect("lastmile.duckdb", read_only=True)

    print("\n" + "#" * 60)
    print("#  LASTMILE ANALYTICS — EXECUTIVE DASHBOARD")
    print("#  Generated from Star Schema (dbt + DuckDB)")
    print("#" * 60)

    # --- KPI Summary ---
    run_query(conn, "KEY PERFORMANCE INDICATORS", """
        select
            count(*)                                        as total_deliveries,
            count(distinct order_id)                        as unique_orders,
            round(avg(delivery_duration_minutes), 1)        as avg_delivery_min,
            round(sum(order_amount), 2)                     as total_revenue,
            round(100.0 * sum(case when is_on_time then 1 else 0 end)
                  / count(*), 1)                            as on_time_pct,
            round(100.0 * sum(case when is_ev_delivery then 1 else 0 end)
                  / count(*), 1)                            as ev_delivery_pct
        from main.fact_deliveries
    """)

    # --- EV vs Gas Performance ---
    run_query(conn, "EV vs GAS VEHICLE PERFORMANCE", """
        select
            case when is_ev_delivery then 'Electric' else 'Gas/Other' end as vehicle_type,
            count(*)                                        as deliveries,
            round(avg(delivery_duration_minutes), 1)        as avg_duration_min,
            round(avg(distance_km), 1)                      as avg_distance_km,
            round(100.0 * sum(case when is_on_time then 1 else 0 end)
                  / count(*), 1)                            as on_time_pct
        from main.fact_deliveries
        group by is_ev_delivery
        order by vehicle_type
    """)

    # --- Top 5 Warehouses by Volume ---
    run_query(conn, "TOP WAREHOUSES BY DELIVERY VOLUME", """
        select
            dw.warehouse_name,
            dw.city,
            dw.capacity_tier,
            count(*)                                        as total_deliveries,
            round(avg(f.delivery_duration_minutes), 1)      as avg_duration_min,
            round(sum(f.order_amount), 2)                   as total_revenue
        from main.fact_deliveries f
        join main.dim_warehouses dw on f.warehouse_key = dw.warehouse_key
        group by dw.warehouse_name, dw.city, dw.capacity_tier
        order by total_deliveries desc
        limit 5
    """)

    # --- Top 10 Drivers by On-Time % ---
    run_query(conn, "TOP 10 DRIVERS BY ON-TIME PERFORMANCE", """
        select
            dd.driver_name,
            dd.vehicle_type,
            count(*)                                        as deliveries,
            round(100.0 * sum(case when f.is_on_time then 1 else 0 end)
                  / count(*), 1)                            as on_time_pct,
            round(avg(f.delivery_duration_minutes), 1)      as avg_duration_min
        from main.fact_deliveries f
        join main.dim_drivers dd on f.driver_key = dd.driver_key
        group by dd.driver_name, dd.vehicle_type
        having count(*) >= 20
        order by on_time_pct desc
        limit 10
    """)

    # --- Monthly Trend ---
    run_query(conn, "MONTHLY DELIVERY TREND", """
        select
            strftime(dt.date_day, '%Y-%m')                  as month,
            count(*)                                        as deliveries,
            round(sum(f.order_amount), 2)                   as revenue,
            round(avg(f.delivery_duration_minutes), 1)      as avg_duration_min,
            round(100.0 * sum(case when f.is_on_time then 1 else 0 end)
                  / count(*), 1)                            as on_time_pct
        from main.fact_deliveries f
        join main.dim_date dt on f.date_key = dt.date_key
        group by strftime(dt.date_day, '%Y-%m')
        order by month
    """)

    # --- Customer Segments ---
    run_query(conn, "PERFORMANCE BY CUSTOMER SEGMENT", """
        select
            dc.customer_segment,
            count(distinct dc.customer_id)                  as customers,
            count(*)                                        as total_deliveries,
            round(sum(f.order_amount), 2)                   as total_revenue,
            round(avg(f.order_amount), 2)                   as avg_order_value
        from main.fact_deliveries f
        join main.dim_customers dc on f.customer_key = dc.customer_key
        group by dc.customer_segment
        order by total_revenue desc
    """)

    print(f"\n{'='*60}")
    print("  Dashboard complete! Star schema is working perfectly.")
    print(f"{'='*60}\n")

    conn.close()


if __name__ == "__main__":
    main()
