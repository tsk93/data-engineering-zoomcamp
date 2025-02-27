-- For each record in dim_fhv_trips.sql, compute the timestamp_diff in seconds between dropoff_datetime and pickup_datetime - 
-- we'll call it trip_duration for this exercise
-- Compute the continous p90 of trip_duration partitioning by year, month, pickup_location_id, and dropoff_location_id
-- For the Trips that respectively started from Newark Airport, SoHo, and Yorkville East, in November 2019, 
-- what are dropoff_zones with the 2nd longest p90 trip_duration ?
-- Ans: LaGuardia Airport, Chinatown, Garment District

{{ config(materialized='table') }}

with trips_data as (
    select * from {{ ref('fhv_trips') }}
),
cte as ( 
    select 
    year, month, pickup_zone, dropoff_zone, pickup_locationid, dropoff_locationid,
    DATETIME_DIFF(dropoff_datetime,pickup_datetime,second) as trip_duration
    from trips_data
    where pickup_zone in ('Newark Airport', 'SoHo', 'Yorkville East') and year=2019 and month=11),
cte2 as (select pickup_zone,dropoff_zone,
percentile_cont(trip_duration,0.90) over (partition by year, month, pickup_locationid, dropoff_locationid) as p90
from cte),
cte3 as (select distinct*from cte2 order by dropoff_zone, p90 desc),
cte4 as (select *, rank() over (partition by pickup_zone order by p90 desc) as ranking from cte3)
select pickup_zone, dropoff_zone, p90 from cte4 where ranking=2 order by pickup_zone