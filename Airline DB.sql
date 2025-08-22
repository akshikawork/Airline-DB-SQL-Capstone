-- Q1: Find the top 5 most expensive flights by price with airline name and source-destination airports.
SELECT TOP 5 F.FlightID, A.AirlineName, S.AirportName AS SourceAirport, D.AirportName AS DestinationAirport, F.Price
FROM Flights F
JOIN Airlines A ON F.AirlineID = A.AirlineID
JOIN Airports S ON F.SourceAirportID = S.AirportID
JOIN Airports D ON F.DestAirportID = D.AirportID
ORDER BY F.Price DESC;

-- Q2: Count how many flights each airline operates and rank them.
SELECT A.AirlineName, COUNT(F.FlightID) AS TotalFlights,
       RANK() OVER (ORDER BY COUNT(F.FlightID) DESC) AS AirlineRank
FROM Airlines A
JOIN Flights F ON A.AirlineID = F.AirlineID
GROUP BY A.AirlineName;

-- Q3: Find passengers who booked more than 5 flights in the past year.
SELECT P.PassengerID, P.FirstName, P.LastName, COUNT(B.BookingID) AS TotalBookings
FROM Passengers P
JOIN Bookings B ON P.PassengerID = B.PassengerID
WHERE YEAR(B.BookingDate) = YEAR(GETDATE())
GROUP BY P.PassengerID, P.FirstName, P.LastName
HAVING COUNT(B.BookingID) > 5;

-- Q4: Find the average ticket price for each flight class across all airlines.
SELECT Class, AVG(Price) AS AvgPrice
FROM Bookings
GROUP BY Class;

-- Q5: List the top 3 youngest passengers who booked a Business class ticket.
SELECT TOP 3 P.PassengerID, P.FirstName, P.LastName, P.Age
FROM Passengers P
JOIN Bookings B ON P.PassengerID = B.PassengerID
WHERE B.Class = 'Business'
ORDER BY P.Age ASC;

-- Q6: Find the busiest route (most bookings between a source and destination).
SELECT S.City AS SourceCity, D.City AS DestCity, COUNT(B.BookingID) AS TotalBookings
FROM Bookings B
JOIN Flights F ON B.FlightID = F.FlightID
JOIN Airports S ON F.SourceAirportID = S.AirportID
JOIN Airports D ON F.DestAirportID = D.AirportID
GROUP BY S.City, D.City
ORDER BY TotalBookings DESC;

-- Q7: Find the average flight duration by airline.
SELECT A.AirlineName, AVG(F.Duration) AS AvgDuration
FROM Flights F
JOIN Airlines A ON F.AirlineID = A.AirlineID
GROUP BY A.AirlineName;

-- Q8: Find the passenger who spent the most money overall.
SELECT TOP 1 P.PassengerID, P.FirstName, P.LastName, SUM(B.Price) AS TotalSpent
FROM Passengers P
JOIN Bookings B ON P.PassengerID = B.PassengerID
GROUP BY P.PassengerID, P.FirstName, P.LastName
ORDER BY TotalSpent DESC;

-- Q9: Find passengers who booked both Economy and Business class tickets.
SELECT PassengerID
FROM Bookings
GROUP BY PassengerID
HAVING SUM(CASE WHEN Class = 'Economy' THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN Class = 'Business' THEN 1 ELSE 0 END) > 0;

-- Q10: Find all flights delayed more than 2 hours.
SELECT FlightID, AirlineID, Status, DepartureTime, ArrivalTime, DATEDIFF(HOUR, DepartureTime, ArrivalTime) AS DelayHours
FROM Flights
WHERE Status = 'Delayed' AND DATEDIFF(HOUR, DepartureTime, ArrivalTime) > 2;

-- Q11: Find the percentage of delayed flights for each airline.
SELECT A.AirlineName,
       100.0 * SUM(CASE WHEN F.Status = 'Delayed' THEN 1 ELSE 0 END) / COUNT(*) AS DelayPercentage
FROM Airlines A
JOIN Flights F ON A.AirlineID = F.AirlineID
GROUP BY A.AirlineName;

-- Q12: Find passengers with consecutive bookings on the same day (self-join).
SELECT DISTINCT B1.PassengerID, P.FirstName, P.LastName, B1.BookingDate
FROM Bookings B1
JOIN Bookings B2 ON B1.PassengerID = B2.PassengerID AND B1.BookingID <> B2.BookingID
JOIN Passengers P ON B1.PassengerID = P.PassengerID
WHERE CAST(B1.BookingDate AS DATE) = CAST(B2.BookingDate AS DATE);

-- Q13: Find the airline with the longest average distance per flight.
SELECT TOP 1 A.AirlineName, AVG(F.Distance) AS AvgDistance
FROM Airlines A
JOIN Flights F ON A.AirlineID = F.AirlineID
GROUP BY A.AirlineName
ORDER BY AvgDistance DESC;

-- Q14: Find passengers who never booked an Economy ticket.
SELECT P.PassengerID, P.FirstName, P.LastName
FROM Passengers P
WHERE P.PassengerID NOT IN (
    SELECT PassengerID FROM Bookings WHERE Class = 'Economy'
);

-- Q15: Find the most popular destination city per airline using window functions.
WITH DestRank AS (
    SELECT A.AirlineName, D.City, COUNT(*) AS TotalFlights,
           RANK() OVER (PARTITION BY A.AirlineName ORDER BY COUNT(*) DESC) AS rnk
    FROM Flights F
    JOIN Airlines A ON F.AirlineID = A.AirlineID
    JOIN Airports D ON F.DestAirportID = D.AirportID
    GROUP BY A.AirlineName, D.City
)
SELECT AirlineName, City AS TopDestination, TotalFlights
FROM DestRank
WHERE rnk = 1;

-- Q16: Find the second most expensive ticket booked by each passenger.
WITH RankedBookings AS (
    SELECT PassengerID, Price,
           ROW_NUMBER() OVER (PARTITION BY PassengerID ORDER BY Price DESC) AS RowNum
    FROM Bookings
)
SELECT PassengerID, Price
FROM RankedBookings
WHERE RowNum = 2;

-- Q17: Calculate the total revenue per year for the airline industry.
SELECT YEAR(BookingDate) AS Year, SUM(Price) AS TotalRevenue
FROM Bookings
GROUP BY YEAR(BookingDate)
ORDER BY Year;

-- Q18: Find flights with more than 70% occupancy (based on bookings).
WITH FlightBookingCount AS (
    SELECT F.FlightID, COUNT(B.BookingID) AS SeatsBooked
    FROM Flights F
    LEFT JOIN Bookings B ON F.FlightID = B.FlightID
    GROUP BY F.FlightID
)
SELECT F.FlightID, (1.0 * FB.SeatsBooked / 180) * 100 AS OccupancyPercentage -- assuming 180 seats per flight
FROM Flights F
JOIN FlightBookingCount FB ON F.FlightID = FB.FlightID
WHERE (1.0 * FB.SeatsBooked / 180) * 100 > 70;

-- Q19: Find passengers who booked the same flight more than once.
SELECT PassengerID, FlightID, COUNT(*) AS BookingCount
FROM Bookings
GROUP BY PassengerID, FlightID
HAVING COUNT(*) > 1;

-- Q20: Find the airline with the highest revenue from Business class bookings.
SELECT TOP 1 A.AirlineName, SUM(B.Price) AS BusinessRevenue
FROM Bookings B
JOIN Flights F ON B.FlightID = F.FlightID
JOIN Airlines A ON F.AirlineID = A.AirlineID
WHERE B.Class = 'Business'
GROUP BY A.AirlineName
ORDER BY BusinessRevenue DESC;

-- Q21: Find the top 3 oldest passengers flying to 'New York'.
SELECT TOP 3 P.PassengerID, P.FirstName, P.LastName, P.Age
FROM Passengers P
JOIN Bookings B ON P.PassengerID = B.PassengerID
JOIN Flights F ON B.FlightID = F.FlightID
JOIN Airports D ON F.DestAirportID = D.AirportID
WHERE D.City = 'New York'
ORDER BY P.Age DESC;

-- Q22: Find the top 2 most frequent flyers for each airline.
WITH PassengerFlights AS (
    SELECT A.AirlineName, P.PassengerID, COUNT(B.BookingID) AS TotalFlights,
           ROW_NUMBER() OVER (PARTITION BY A.AirlineName ORDER BY COUNT(B.BookingID) DESC) AS rnk
    FROM Airlines A
    JOIN Flights F ON A.AirlineID = F.AirlineID
    JOIN Bookings B ON F.FlightID = B.FlightID
    JOIN Passengers P ON B.PassengerID = P.PassengerID
    GROUP BY A.AirlineName, P.PassengerID
)
SELECT AirlineName, PassengerID, TotalFlights
FROM PassengerFlights
WHERE rnk <= 2;

-- Q23: Find passengers who booked flights with at least 3 different airlines.
SELECT P.PassengerID, P.FirstName, P.LastName, COUNT(DISTINCT A.AirlineID) AS AirlinesUsed
FROM Passengers P
JOIN Bookings B ON P.PassengerID = B.PassengerID
JOIN Flights F ON B.FlightID = F.FlightID
JOIN Airlines A ON F.AirlineID = A.AirlineID
GROUP BY P.PassengerID, P.FirstName, P.LastName
HAVING COUNT(DISTINCT A.AirlineID) >= 3;

-- Q24: Find the most profitable route (based on booking revenue).
SELECT TOP 1 S.City AS SourceCity, D.City AS DestCity, SUM(B.Price) AS TotalRevenue
FROM Bookings B
JOIN Flights F ON B.FlightID = F.FlightID
JOIN Airports S ON F.SourceAirportID = S.AirportID
JOIN Airports D ON F.DestAirportID = D.AirportID
GROUP BY S.City, D.City
ORDER BY TotalRevenue DESC;

-- Q25: Find the average age of passengers for each class of travel.
SELECT B.Class, AVG(P.Age) AS AvgPassengerAge
FROM Bookings B
JOIN Passengers P ON B.PassengerID = P.PassengerID
GROUP BY B.Class;
