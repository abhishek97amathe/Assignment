create database airport_db;
use airport_db;
select * from airports 
limit 5 ;

-- Problem Statement 1 = The objective is to calculate the total number of passengers for each pair of origin and destination airports.
SELECT 
	origin_airport,
    destination_airport,
    SUM(passengers) Total_passengers
FROM 
	airports
GROUP BY
	origin_airport,
    destination_airport;
    
-- Problem Statement 2  = calculate the average seat utilization for each passengers by the total number of seats available. 
SELECT
	origin_airport,
    destination_airport,
    ROUND(AVG(CAST(Passengers AS FLOAT)/nullif(seats,0))*100,2) avg_seat_utilization
FROM 
	airports
GROUP BY 
	origin_airport,
    destination_airport
ORDER BY
	avg_seat_utilization DESC;
    
-- Problem Statement 3 =  determine the top 5 origin and destination airport pairs that have the highest total passenger volume. 
SELECT 
	Origin_airport,
	Destination_airport,
	SUM(Passengers) Total_passengers
FROM
	airports
GROUP BY 
	Origin_airport,
	Destination_airport
ORDER BY
	Total_passengers DESC;

-- Problem Statement 4 = calculate the total number of flights and passengers departing from each origin city. 
SELECT
	Origin_city,
    COUNT(Flights) Total_flights,
    SUM(Passengers) Total_passengers
FROM
	airports
GROUP BY 
	Origin_city
ORDER BY 
	Total_flights DESC,
	Total_passengers DESC;

-- Problem Statement 5 = Total distance flown by flights originating from each airport. 
SELECT
	Origin_airport,
    SUM(Distance) Total_distance_flown
FROM 
	airports
GROUP BY
	Origin_airport
ORDER BY
	Total_distance_flown DESC;
    
-- Problem Statement 6 = The objective is to group flights by month and year using the Fly_date column to calculate the number of flights, 
-- total passengers, and average distance traveled per month.
SELECT 
	YEAR(fly_date) Year,
    MONTH(Fly_date) Month,
    COUNT(Flights) no_of_flights,
    SUM(passengers) Total_passengers,
    AVG(Distance) Avg_distances_flown
FROM
	airports
GROUP BY 
	YEAR(fly_date),
    MONTH(Fly_date)
ORDER BY 
	Year,
    Month;

-- Problem Statement 7 = calculate the passenger-to-seats ratio for each  origin and destination route and filter the results to display only 
-- those routes where this ratio is less than 0.5. 
SELECT
	Origin_airport,
    Destination_airport,
    SUM(Passengers) Total_passengers,
    SUM(seats) Total_seats,
    (CAST(SUM(Passengers) AS FLOAT))/ NULLIF(SUM(seats),0) Ratio
FROM
	airports
GROUP BY 
	Origin_airport,
    Destination_airport
HAVING
	Ratio <0.5
ORDER BY
	Ratio;

-- Problem Statement 8 = determine the top 3 origin airports with the highest frequency of flights. 
SELECT
	Origin_airport,
	COUNT(Flights) No_Of_flights
FROM 
	airports
GROUP BY
	Origin_airport
ORDER BY 
	No_Of_flights DESC
LIMIT 3 ;
	
-- Problem Statement 9 = identify the city (excluding Bend, OR) that sends the most flights and passengers to Bend, OR. 
SELECT
	Origin_city,
    Destination_city,
    SUM(Passengers) total_passengers,
    COUNT(flights) No_of_flights
FROM
	airports
WHERE 
	Origin_city <> 'Bend, OR' AND
    Destination_city = 'Bend, OR'
GROUP BY 
	Origin_city
ORDER BY
	 total_passengers DESC,
     No_of_flights DESC;
     
-- Problem Statement 10 = identify the longest flight route in terms of distance traveled, including both the origin and destination airports.
SELECT
	Origin_airport,
	Destination_airport,
	Max(Distance) Longest_flight
FROM 
	airports
GROUP BY
	Origin_airport,
	Destination_airport
ORDER BY
	Longest_flight DESC
LIMIT 1;

-- Problem Statement 11 = The objective is to determine the most and least busy months by flight count across multiple years
WITH monthly_flights AS
(
SELECT 
	YEAR(fly_date) year,
    MONTH(fly_date) month,
    COUNT(flights) Flight_count
FROM
	airports
GROUP BY 
	YEAR(fly_date),
    MONTH(fly_date)
)
SELECT
	month,
	Flight_count,
    CASE
		WHEN  Flight_count = (SELECT MAX(Flight_count) FROM monthly_flights) THEN 'MOST BUSY'
        WHEN  Flight_count = (SELECT MIN(Flight_count) FROM monthly_flights) THEN 'LEAST BUSY'
        ELSE NULL
	END AS Month_status
FROM 
	monthly_flights
WHERE
	Flight_count = (SELECT MAX(Flight_count) FROM  monthly_flights) OR
    Flight_count = (SELECT MIN(Flight_count) FROM  monthly_flights);
    
-- Problem Statement 12 =  calculate the year-over-year percentage growth in the total number of passengers for each origin 
-- and destination airport pair
WITH passengers_summary AS
(
    SELECT 
		Origin_airport,
		Destination_airport,
        YEAR(fly_date) Year,
		SUM(Passengers) Total_passengers
    FROM
		airports
    GROUP BY 
		Origin_airport,
        Destination_airport,
        YEAR(fly_date)
),
passenger_growth AS
(
    SELECT
		Origin_airport,
		Destination_airport,
		Year,
		Total_passengers,
		LAG(Total_passengers) OVER(PARTITION BY Origin_airport,Destination_airport ORDER BY Year) Pervious_year
    FROM 
		passengers_summary
)
SELECT 
	origin_airport,
	Destination_airport,
	Year,
	Total_passengers,
CASE
	WHEN Pervious_year IS NOT NULL THEN
     ((Total_passengers-Pervious_year)*100.0)/NULLIF(Pervious_year,0)
	ELSE NULL
END AS Growth_Percentage
FROM 
	passenger_growth
ORDER BY 
	origin_airport,
	Destination_airport,
	Year;

-- Problem Statement 13 =  identify routes (from origin to destination) that have demonstrated consistent 
-- year-over-year growth in the number of flights.
WITH flight_stats AS
(
    SELECT 
		Origin_airport,
		Destination_airport,
        YEAR(fly_date) Year,
		COUNT(Flights) No_flights
	FROM
		airports
	GROUP BY 
		Origin_airport,
		Destination_airport,
        YEAR(fly_date)
),
flight_rate AS
(
SELECT
	Origin_airport,
	Destination_airport,
	Year,
	No_flights,
    LAG(No_flights)OVER(PARTITION BY Origin_airport,Destination_airport ORDER BY YEAR) AS pervious_flights
FROM
	flight_stats
),
growth_rates AS
(
SELECT
	Origin_airport,
	Destination_airport,
	Year,
	No_flights,
	CASE
		WHEN
        pervious_flights  IS NOT NULL  AND pervious_flights > 0 THEN
        ((No_flights-pervious_flights)*100.0/pervious_flights )
        ELSE NULL 
	END AS Growth_rate,
    CASE
		WHEN
        pervious_flights  IS NOT NULL  AND No_flights > pervious_flights  THEN 1
        ELSE 0 
	END AS Growth_indicator
FROM 
	flight_rate
)
SELECT 
	Origin_airport,
	Destination_airport,
    MAX(Growth_rate) Maximun_growth,
    MIN(Growth_rate) Minimum_growth
FROM 
	growth_rates
WHERE
	Growth_indicator = 1
GROUP BY 
	Origin_airport,
	Destination_airport
HAVING
	MIN(Growth_indicator) = 1
ORDER BY
	Origin_airport,
	Destination_airport;
    
-- Problem Statement 14 = The aim is to determine the top 3 origin airports with the highest weighted passenger-to-seats utilization ratio, 
-- considering the total number of flights for weighting
WITH ratio AS
(
SELECT 
	Origin_airport,
    SUM(Passengers) Total_passengers,
    SUM(seats) Total_seats,
    COUNT(flights) Total_flights,
    CAST(SUM(Passengers) AS FLOAT)/SUM(seats)  passenger_to_seats
FROM
	airports
GROUP BY 
	Origin_airport
),
wieghted AS
(
	SELECT
		Origin_airport,
		Total_passengers,
		Total_seats,
		Total_flights,
		passenger_to_seats,
		(passenger_to_seats*Total_flights)/SUM(Total_flights) OVER() AS wieghted_utilization
	FROM 
		ratio
)
SELECT
	Origin_airport,
	Total_passengers,
	Total_seats,
	Total_flights,
	passenger_to_seats,
	wieghted_utilization
FROM 
	wieghted
ORDER BY 
	wieghted_utilization DESC
LIMIT 3;

-- Problem Statement 15 = identify the peak traffic month for each origin city based on the highest number of passengers, 
-- including any ties where multiple months have the same passenger count.
WITH TOTAL AS
(
SELECT 
	Origin_city,
	YEAR(fly_date) Year,
	MONTH(fly_date) Month,
	SUM(Passengers) Total_passenger
FROM
	airports 
GROUP BY 
	Origin_city,
	YEAR(fly_date),
	MONTH(fly_date)
),
MAX AS
(
SELECT
	Origin_city,
	MAX(Total_passenger) Highest_passenger
FROM
	TOTAL
GROUP BY 
	Origin_city
)
SELECT 
	t.Origin_city,
	t.Year,
	t.Month,
	t.Total_passenger
FROM
	MAX m
	JOIN TOTAL t
	ON t.origin_city = m.origin_city
	AND t.Total_passenger = m.Highest_passenger
ORDER BY
	t.Origin_city,
	t.Year,
	t.Month;
    
-- Problem Statement 16 = o identify the routes (origin-destination pairs) that have 
-- experienced the largest decline in passenger numbers year-over-year. 
WITH YEARLY_PASSENGER AS
(
SELECT
	Origin_airport,
	Destination_airport,
	YEAR(Fly_date) year,
	SUM(Passengers) Total_Passengers
FROM
	airports
GROUP BY
	Origin_airport,
	Destination_airport,
	YEAR(Fly_date)
),
yearly_decline AS
(
SELECT
	Y1.Origin_airport,
	Y1.Destination_airport,
	Y1.year AS year1,
	Y1.Total_Passengers AS passengers_year1,
    Y2.year AS year2,
    Y2.Total_Passengers AS passengers_year2,
    ((Y2.Total_Passengers - Y1.Total_Passengers)/NULLIF(Y1.Total_Passengers,0))*100 AS percentage_change
FROM 	
	YEARLY_PASSENGER Y1
JOIN
	YEARLY_PASSENGER Y2
ON Y1.origin_airport = Y2.origin_airport
AND Y1.destination_airport = Y2.destination_airport 
AND Y1.year = Y2.year+1
)
SELECT
	Origin_airport,
	Destination_airport,
	year1,
	passengers_year1,
    year2,
    passengers_year2
FROM
	yearly_decline
WHERE 
	percentage_change < 0
ORDER BY 
	percentage_change
LIMIT 5;

-- Problem Statement 17 = list all origin and destination airports that had at least 10 flights but maintained 
-- an average seat utilization (passengers/seats) of less than 50%. 
WITH flight_details AS
(
SELECT
	Origin_airport,
	Destination_airport,
	COUNT(Flights) as total_flights,
	SUM(Seats) as total_seats,
	SUM(Passengers) as total_passengers
FROM 
	airports
GROUP BY 
	Origin_airport,
	Destination_airport
),
avg_seat_utilization AS
(
SELECT
	Origin_airport,
	Destination_airport,
    total_seats,
    total_passengers,
    total_flights,
	ROUND(total_passengers/NULLIF(total_seats,0),2) AS avg_seat_uitilizations
FROM
	flight_details
)
SELECT
	Origin_airport,
	Destination_airport,
    total_seats,
    total_passengers,
    total_flights,
	avg_seat_uitilizations
FROM
	avg_seat_utilization
WHERE 
	total_flights >= 10
AND	avg_seat_uitilizations < 0.5
ORDER BY 
	avg_seat_uitilizations;


-- Problem Statement 18 =  calculate the average flight distance for each unique city-to-city pair (origin and destination) and 
-- identify the routes with the longest average distance.
WITH distance_stats AS
(
SELECT 
	Origin_city,
	Destination_city,
	AVG(Distance) avg_distance
FROM
	airports
GROUP BY 
	Origin_city,
	Destination_city
)

SELECT 
	Origin_city,
	Destination_city,
	ROUND(avg_distance,2) average_distance
FROM
	distance_stats
ORDER BY
	avg_distance DESC;

-- Problem Statement 19 = calculate the total number of flights and passengers for each year, along with the percentage 
-- growth in both flights and passengers compared to the previous year.
WITH fly_summary AS
(
SELECT 
	YEAR(fly_date) Year,
    SUM(passengers) Total_passengers,
    COUNT(flights) Total_flights
FROM 
	airports
GROUP BY 
	YEAR(fly_date)
),
growth AS
(
SELECT
	 Year,
     Total_passengers,
     Total_flights,
     LAG(Total_passengers) OVER(ORDER BY Year) AS perivous_Passengers,
     LAG(Total_flights) OVER(ORDER BY Year) AS perivous_flights
FROM 
	fly_summary
)
SELECT
	Year,
	Total_passengers,
	Total_flights,
	ROUND(((Total_passengers-perivous_Passengers)/NULLIF(perivous_Passengers,0)*100),2) passenger_growth_percentage,
    ROUND(((Total_flights - perivous_flights)/NULLIF(perivous_flights,0)*100),2) flight_growth_percentage
FROM
	growth
ORDER BY 
	Year;

-- Problem Statement 19 = identify the top 3 busiest routes (origin destination pairs) based on the 
-- total distance flown, weighted by the number of flights.
WITH routes AS
(
SELECT
	Origin_airport,
    Destination_airport,
    COUNT(Flights) total_flights ,
    SUM(Distance) total_distance
FROM
	airports
GROUP BY 
	Origin_airport,
    Destination_airport
),
wieghted AS
(
SELECT 
	Origin_airport,
    Destination_airport,
    total_flights ,
	total_distance,
    total_distance* total_flights AS wieghted_distance
FROM
	routes
)
SELECT
	Origin_airport,
    Destination_airport,
    total_flights ,
	total_distance,
    wieghted_distance
FROM 
	wieghted
ORDER BY 
	wieghted_distance DESC
LIMIT 3 ;