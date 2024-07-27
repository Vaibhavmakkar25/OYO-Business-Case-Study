-- Use the database named CS
USE CS;

-- Initial Data Retrieval
SELECT * FROM OYO.Hotel_Sales;
SELECT * FROM OYO.City;

-- Add new columns and update them
ALTER TABLE OYO.Hotel_Sales ADD COLUMN Price FLOAT NULL;
UPDATE OYO.Hotel_Sales SET Price = amount + discount;

ALTER TABLE OYO.Hotel_Sales ADD COLUMN no_of_nights INT NULL;
UPDATE OYO.Hotel_Sales SET no_of_nights = DATEDIFF(check_out, check_in);

ALTER TABLE OYO.Hotel_Sales ADD COLUMN rate FLOAT NULL;
UPDATE OYO.Hotel_Sales 
SET rate = ROUND(
    CASE 
        WHEN no_of_rooms = 1 THEN Price / no_of_nights 
        ELSE Price / no_of_nights / no_of_rooms 
    END, 2);

-- Summary Statistics
SELECT COUNT(1) AS total_records FROM OYO.Hotel_Sales;
SELECT COUNT(1) AS no_of_hotels FROM OYO.City;
SELECT COUNT(DISTINCT city) AS total_cities FROM OYO.City;

-- No of hotels in different cities
SELECT city, COUNT(*) AS no_of_hotels
FROM OYO.City
GROUP BY city
ORDER BY no_of_hotels DESC;

-- Average room rates of different cities
SELECT b.city, ROUND(AVG(a.rate), 2) AS average_room_rates
FROM OYO.Hotel_Sales AS a
INNER JOIN OYO.City AS b ON a.hotel_id = b.hotel_id
GROUP BY b.city
ORDER BY average_room_rates DESC;

-- Cancellation rates of different cities
SELECT b.city AS City, 
       FORMAT(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(date_of_booking), 1) AS cancellation_rate
FROM OYO.Hotel_Sales AS a
INNER JOIN OYO.City AS b ON a.hotel_id = b.hotel_id
GROUP BY b.city
ORDER BY cancellation_rate DESC;

-- No of bookings of different cities in Jan Feb Mar Months
SELECT b.city AS City, MONTHNAME(date_of_booking) AS Months, COUNT(*) AS no_of_bookings
FROM OYO.Hotel_Sales AS a
INNER JOIN OYO.City AS b ON a.hotel_id = b.hotel_id
GROUP BY b.city, MONTH(date_of_booking)
ORDER BY City, MONTH(date_of_booking);

-- Frequency of early bookings prior to check-in the hotel
SELECT DATEDIFF(check_in, date_of_booking) AS days_before_check_in, COUNT(*) AS frequency_early_bookings_days
FROM OYO.Hotel_Sales
GROUP BY days_before_check_in;

-- Frequency of bookings of no of rooms in Hotel
SELECT no_of_rooms, COUNT(*) AS frequency_of_bookings
FROM OYO.Hotel_Sales
GROUP BY no_of_rooms
ORDER BY no_of_rooms;

-- Net revenue to company (due to some bookings cancelled) & Gross revenue to company
SELECT b.city, SUM(a.amount) AS gross_revenue, 
       SUM(CASE WHEN a.status IN ('No Show', 'Stayed') THEN a.amount END) AS net_revenue
FROM OYO.Hotel_Sales AS a
INNER JOIN OYO.City AS b ON a.hotel_id = b.hotel_id
GROUP BY b.city
ORDER BY b.city;

-- Discount offered by different cities
SELECT b.city, FORMAT(AVG(100.0 * a.discount / a.Price), 1) AS discount_offered
FROM OYO.Hotel_Sales AS a
INNER JOIN OYO.City AS b ON a.hotel_id = b.hotel_id
GROUP BY b.city
ORDER BY discount_offered;

-- New and repeat customers analysis
WITH Cust_jan AS (
    SELECT DISTINCT customer_id
    FROM OYO.Hotel_Sales
    WHERE MONTH(date_of_booking) = 1
),
repeat_cust_feb AS (
    SELECT DISTINCT s.customer_id
    FROM OYO.Hotel_Sales AS s
    INNER JOIN Cust_jan AS b ON b.customer_id = s.customer_id
    WHERE MONTH(s.date_of_booking) = 2
),
total_Cust_feb AS (
    SELECT DISTINCT customer_id
    FROM OYO.Hotel_Sales
    WHERE MONTH(date_of_booking) = 2
),
new_cust_feb AS (
    SELECT customer_id AS new_customer_in_feb
    FROM total_Cust_feb AS a
    WHERE a.customer_id NOT IN (SELECT customer_id FROM repeat_cust_feb)
)
SELECT COUNT(c.new_customer_in_feb) AS new_customers_in_feb
FROM new_cust_feb AS c;

-- Insights:
-- 1. Bangalore, Gurgaon & Delhi were popular in the bookings, whereas Kolkata is less popular in bookings.
-- 2. Nature of Bookings:
--    • Nearly 50% of the bookings were made on the day of check-in only.
--    • Nearly 85% of the bookings were made with less than 4 days prior to the date of check-in.
--    • Very few bookings were made in advance (i.e., over a month or 2 months).
--    • Most of the bookings involved only a single room.
--    • Nearly 80% of the bookings involved a stay of 1 night only.
-- 3. OYO should acquire more hotels in the cities of Pune, Kolkata & Mumbai. Because their average room rates are comparatively higher, so more revenue will come.
-- 4. The % cancellation rate is high in all 9 cities except Pune, so OYO should focus on finding reasons for cancellations.

