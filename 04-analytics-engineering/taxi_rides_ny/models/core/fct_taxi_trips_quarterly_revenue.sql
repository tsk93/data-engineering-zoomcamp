-- Compute the Quarterly Revenues for each year for based on total_amount
-- Compute the Quarterly YoY (Year-over-Year) revenue growth
-- Ans: green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q1, worst: 2020/Q2}

{{ config(materialized='table') }}

with trips_data as (
    select * from {{ ref('fact_trips') }}
),
cte as ( 
    select 
    service_type,
    extract(year from pickup_datetime) as year,
    {{pickup_date_quarter("pickup_datetime")}} as quarter,
    sum(total_amount) as quarterly_revenue,
    from trips_data
    where extract(year from pickup_datetime) in (2019,2020)
    group by 1,2,3),
cte2 as (select service_type,year,quarter, quarterly_revenue,
lag(quarterly_revenue) over (partition by service_type,quarter order by year) as previous_year_revenue from cte
order by service_type,quarter,year),
cte3 as (select service_type, concat(year,"/",quarter) as year_quarter,
(quarterly_revenue-previous_year_revenue)/previous_year_revenue*100 as yoy_growth from cte2)
select*from cte3 where yoy_growth is not null order by service_type,yoy_growth desc
