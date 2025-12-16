-- CREATING TABLE 
CREATE TABLE trips (
    ride_id VARCHAR(50),
    rideable_type VARCHAR(50),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_name VARCHAR(255),
    start_station_id VARCHAR(100),
    end_station_name VARCHAR(255),
    end_station_id VARCHAR(100),
    start_lat DECIMAL(10, 8),
    start_lng DECIMAL(11, 8),
    end_lat DECIMAL(10, 8),
    end_lng DECIMAL(11, 8),
    member_casual VARCHAR(20)
);

--- *BASIC EDA*

-- Executive Summary (Trips Overview)
SELECT 
    COUNT(*) as total_trips,
    COUNT(DISTINCT start_station_id) as unique_stations,
    MIN(started_at::DATE) as period_start,
    MAX(started_at::DATE) as period_end,
    COUNT(DISTINCT started_at::DATE) as days_analyzed,
    COUNT(CASE WHEN EXTRACT(DOW FROM started_at) BETWEEN 1 AND 5 THEN 1 END) as weekday_trips,
    COUNT(CASE WHEN EXTRACT(DOW FROM started_at) IN (0,6) THEN 1 END) as weekend_trips,
    ROUND(AVG(EXTRACT(EPOCH FROM (ended_at - started_at))/60), 1) as avg_trip_minutes
FROM trips
WHERE started_at >= '2024-07-01' AND started_at < '2024-08-01';

-- 1. Total Rider Count by Type
SELECT 
    member_casual,
    COUNT(*) AS trip_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 
        1
    ) AS percentage
FROM trips
GROUP BY member_casual
ORDER BY percentage DESC;

-- 2. Trip Distribution: Weekday vs Weekend
SELECT 
   CASE WHEN EXTRACT(DOW FROM started_at) IN (0,6) THEN 'Weekend'
        ELSE 'Weekday'
   END,
   COUNT(*)
FROM trips
GROUP BY 1;

-- 3. Morning Net Loss by Station (with avg per day)
WITH morning_flows AS (
    SELECT start_station_id AS station_id,
	       start_station_name AS station_name, 
		   COUNT(*) AS checkouts,
		   0 AS returns,
		   DATE(started_at) AS trip_date
	FROM trips
	WHERE EXTRACT(DOW FROM started_at) BETWEEN 1 AND 5
	      AND EXTRACT(HOUR FROM started_at) BETWEEN 6 AND 10
		  AND started_at >= '2024-07-01'
		  AND started_at < '2024-08-01'
		  AND start_station_id IS NOT NULL
	GROUP BY 1, 2, 5

	UNION ALL

	SELECT end_station_id AS station_id,
	       end_station_name AS station_id, 
		   0 AS checkouts,
		   COUNT(*) AS returns, 
		   DATE(ended_at) AS trip_date
	FROM trips
	WHERE EXTRACT(DOW FROM ended_at) BETWEEN 1 AND 5
	      AND EXTRACT(HOUR FROM ended_at) BETWEEN 6 AND 10
		  AND ended_at >= '2024-07-01'
		  AND ended_at < '2024-08-01'
		  AND end_station_id IS NOT NULL
	GROUP BY 1, 2, 5
), 
station_totals AS (
    SELECT station_name, 
	       SUM(checkouts) AS total_checkouts,
		   SUM(returns) AS total_returns,
		   SUM(checkouts - returns) AS net_loss,
		   COUNT(DISTINCT trip_date) AS num_days
	FROM morning_flows
	GROUP BY station_name
		  
)
SELECT station_name, 
       total_checkouts,
	   total_returns,
	   net_loss,
	   ROUND(net_loss * 1.0 / num_days, 2) AS avg_net_loss_per_day
FROM station_totals
WHERE total_checkouts > 100
ORDER BY avg_net_loss_per_day DESC
LIMIT 10;


-- 4. Evening Net Gain by Station (with avg per day)
WITH evening_flows AS (
    SELECT start_station_id AS station_id,
           start_station_name AS station_name, 
           COUNT(*) AS checkouts,
           0 AS returns,
           DATE(started_at) AS trip_date
    FROM trips
    WHERE EXTRACT(DOW FROM started_at) BETWEEN 1 AND 5
          AND EXTRACT(HOUR FROM started_at) BETWEEN 17 AND 20   
          AND started_at >= '2024-07-01'
          AND started_at < '2024-08-01'
          AND start_station_id IS NOT NULL
    GROUP BY 1, 2, 5

    UNION ALL

    SELECT end_station_id AS station_id,
           end_station_name AS station_name, 
           0 AS checkouts,
           COUNT(*) AS returns,
           DATE(ended_at) AS trip_date
    FROM trips
    WHERE EXTRACT(DOW FROM ended_at) BETWEEN 1 AND 5
          AND EXTRACT(HOUR FROM ended_at) BETWEEN 17 AND 20   
          AND end_station_id IS NOT NULL
    GROUP BY 1, 2, 5
),
station_totals AS (
    SELECT station_name,
           SUM(checkouts) AS total_checkouts,
           SUM(returns) AS total_returns,
           SUM(returns - checkouts) AS net_gain,   
           COUNT(DISTINCT trip_date) AS num_days
    FROM evening_flows
    GROUP BY station_name
)
SELECT station_name,
       total_checkouts,
       total_returns,
       net_gain,
       ROUND(net_gain * 1.0 / num_days, 2) AS avg_net_gain_per_day
FROM station_totals
WHERE total_returns > 100
ORDER BY avg_net_gain_per_day DESC
LIMIT 10;

-- 5. Morning Net Loss by Rider Type
WITH morning_flows AS (
    SELECT start_station_id AS station_id,
	       start_station_name AS station_name,
		   member_casual,
		   COUNT(*) AS checkouts,
		   0 AS returns
	FROM trips
	WHERE EXTRACT(DOW FROM started_at) BETWEEN 1 AND 5
	      AND EXTRACT(HOUR FROM started_at) BETWEEN 6 AND 10
		  AND start_station_id IS NOT NULL
	GROUP BY 1, 2, 3

	UNION ALL

	SELECT end_station_id AS station_id,
	       end_station_name AS station_name,
		   member_casual,
		   0 AS checkouts,
		   COUNT(*) AS returns
	FROM trips
	WHERE EXTRACT(DOW FROM ended_at) BETWEEN 1 AND 5
	      AND EXTRACT(HOUR FROM ended_at) BETWEEN 6 AND 10
		  AND end_station_id IS NOT NULL
	GROUP BY 1, 2, 3
)

SELECT station_id, 
       station_name, 
	   member_casual,
	   SUM(checkouts) AS total_checkouts,
	   SUM(returns) AS total_returns,
	   SUM(checkouts - returns) AS net_loss
FROM morning_flows
GROUP BY 1, 2, 3
HAVING SUM(checkouts) > 20
ORDER BY station_id, member_casual;

-- 6. Top Morning Commuter Corridors
SELECT
    start_station_id,
    start_station_name,
    end_station_id,
    end_station_name,
    member_casual,
    COUNT(*) AS trip_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (ended_at - started_at)) / 60), 1) AS avg_duration_minutes
FROM trips
WHERE
    EXTRACT(DOW FROM started_at) BETWEEN 1 AND 5  
    AND EXTRACT(HOUR FROM started_at) BETWEEN 6 AND 10
	AND started_at >= '2024-07-01'
	AND started_at < '2024-08-01'
    AND start_station_id IS NOT NULL
    AND end_station_id IS NOT NULL
    AND start_station_id != end_station_id  
GROUP BY 1, 2, 3, 4, 5
HAVING COUNT(*) >= 100  
ORDER BY trip_count DESC
LIMIT 5;

-- 7. Evening Net Gain by Rider Type
WITH evening_flows AS (
    SELECT
        end_station_id AS station_id,
        end_station_name AS station_name,
        member_casual,
        0 AS checkouts,
        COUNT(*) AS returns
    FROM trips
    WHERE
        EXTRACT(DOW FROM ended_at) BETWEEN 1 AND 5
        AND EXTRACT(HOUR FROM ended_at) BETWEEN 17 AND 20
        AND end_station_id IS NOT NULL
    GROUP BY 1, 2, 3

    UNION ALL

    SELECT
        start_station_id AS station_id,
        start_station_name AS station_name,
        member_casual,
        COUNT(*) AS checkouts,
        0 AS returns
    FROM trips
    WHERE
        EXTRACT(DOW FROM started_at) BETWEEN 1 AND 5
        AND EXTRACT(HOUR FROM started_at) BETWEEN 17 AND 20
        AND start_station_id IS NOT NULL
    GROUP BY 1, 2, 3
)
SELECT
    station_id,
    station_name,
    member_casual,
    SUM(checkouts) AS total_checkouts,
    SUM(returns) AS total_returns,
    SUM(returns - checkouts) AS net_gain
FROM evening_flows
GROUP BY 1, 2, 3
HAVING SUM(returns) > 20
ORDER BY station_id, member_casual;

-- 8. Top 5 Evening Trip Origin stations (5-8 PM)
SELECT
    start_station_id,
    start_station_name,
    member_casual,
    COUNT(*) AS evening_checkouts
FROM trips
WHERE
    EXTRACT(DOW FROM started_at) BETWEEN 1 AND 5
    AND EXTRACT(HOUR FROM started_at) BETWEEN 17 AND 20
    AND start_station_id IS NOT NULL
    AND start_station_id != end_station_id
GROUP BY 1, 2, 3
HAVING COUNT(*) >= 100
ORDER BY evening_checkouts DESC
LIMIT 5;


