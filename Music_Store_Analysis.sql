-- 1. Who is the senior most employee based on job title?
SELECT TOP 1 first_name,
last_name,
title,
levels 
FROM employee
ORDER BY levels DESC

-- 2. Which countries have the most Invoices?
SELECT billing_country,
COUNT(*) AS Total_Invoices
FROM invoice
GROUP BY billing_country
ORDER BY Total_Invoices DESC

-- 3. What are top 3 values of total invoice?
SELECT TOP 3 billing_country,
SUM(total) AS Total_invoice
FROM invoice
GROUP BY billing_country
ORDER BY Total_invoice DESC

-- 4. Which city has the best customers? 
-- We would like to throw a promotional Music Festival in the city we made the most money.
-- Write a query that returns one city that has the highest sum of invoice totals.
-- Return both the city name & sum of all invoice totals
SELECT c.city,
ROUND(SUM(i.total),2) AS Total_Invoice
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.city
ORDER BY Total_Invoice DESC;

-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer.
-- Write a query that returns the person who has spent the most money
SELECT c.customer_id,
c.first_name,
c.last_name,
ROUND(SUM(i.total),2) AS Total_Spending
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY Total_Spending DESC;

-- 6. Write query to return the email, first name, last name, & Genre of all Rock Music listeners.
-- Return your list ordered alphabetically by email starting with A
SELECT DISTINCT c.first_name,
c.last_name,
c.email,
g.name
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
JOIN invoice_line il
ON i.invoice_id = il.invoice_id
JOIN track t
ON t.track_id = il.track_id
JOIN genre g 
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;

-- 7. Let's invite the artists who have written the most rock music in our dataset.
-- Write a query that returns the Artist name and total track count of the top 10 rock bands
SELECT TOP 10 
a.artist_id, 
a.name,
COUNT(*) AS Total_Tracks
FROM artist a
JOIN album ab
ON a.artist_id = ab.artist_id
JOIN track t
ON ab.album_id = t.album_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id, a.name
ORDER BY Total_Tracks DESC;


-- 8. Return all the track names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track.
-- Order by the song length with the longest songs listed first

SELECT name, milliseconds FROM track
WHERE milliseconds > 
	(SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC


-- 9. Find how much amount spent by each customer on artists?
-- Write a query to return customer name, artist name and total spent
WITH top_artist AS(
SELECT TOP 1
a.artist_id, 
a.name, 
ROUND(SUM(il.unit_price * il.quantity),2) AS Total
FROM artist a
JOIN album al
ON a.artist_id = al.artist_id
JOIN track t
ON t.album_id = al.album_id
JOIN invoice_line il
ON t.track_id = il.track_id
GROUP BY a.artist_id, a.name
ORDER BY Total DESC
)
SELECT c.customer_id, 
c.first_name + ' ' + c.last_name AS Customer_name,
ta.name AS Artist_name ,
SUM(il.quantity * il.unit_price) AS Total_spent
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
JOIN invoice_line il
ON i.invoice_id = il.invoice_id
JOIN track t
ON t.track_id = il.track_id
JOIN album al
ON al.album_id = t.album_id
JOIN artist a
ON al.artist_id = a.artist_id
JOIN top_artist ta
ON a.artist_id = ta.artist_id
GROUP BY c.customer_id, c.first_name + ' ' + c.last_name, ta.name
ORDER BY Total_spent DESC;

/* 
10. We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres
*/

WITH Country_Total AS (
SELECT i.billing_country,
g.genre_id, 
g.name,
SUM(il.quantity) AS Purchases
FROM invoice i
JOIN invoice_line il
ON i.invoice_id = il.invoice_id
JOIN track t
ON t.track_id = il.track_id
JOIN genre g
ON g.genre_id = t.genre_id
GROUP BY g.genre_id, g.name,i.billing_country),

Genre_Ranking AS(
SELECT *,
DENSE_RANK() OVER(PARTITION BY ct.billing_country ORDER BY ct.Purchases DESC ) AS rnk
FROM Country_Total ct)

SELECT billing_country,
genre_id,
name,
Purchases
FROM Genre_Ranking
WHERE rnk = 1
ORDER BY Purchases DESC

/*
11. Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount
*/

WITH cust_spent AS (
SELECT i.billing_country,
c.customer_id,
c.first_name + ' ' + c.last_name AS Customer_name,
ROUND(SUM(i.total),2) AS Total_Amt
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY i.billing_country, c.customer_id, c.first_name + ' ' + c.last_name),

top_cust AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY cs.billing_country ORDER BY cs.Total_Amt DESC) AS rnk
FROM cust_spent cs
)

SELECT billing_country,
customer_id,
Customer_name,
Total_Amt
FROM top_cust
WHERE rnk = 1;