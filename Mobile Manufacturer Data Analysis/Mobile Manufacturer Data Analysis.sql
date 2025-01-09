--SQL Advance Case Study
USE db_SQLCaseStudies

--Q1--BEGIN 
SELECT LC.State
FROM FACT_TRANSACTIONS TR
LEFT JOIN DIM_DATE  DT ON TR.Date= DT.DATE
LEFT JOIN DIM_LOCATION  LC ON TR.IDLocation= LC.IDLocation
WHERE DT.YEAR >2005
GROUP BY LC.State

--Q1--END

--Q2--BEGIN
SELECT TOP 1 T1.State, SUM(T2.IDModel) AS TOTAL_SALE FROM 
(SELECT TR.IDModel, lc.State
FROM FACT_TRANSACTIONS TR
LEFT JOIN DIM_LOCATION  LC ON TR.IDLocation= LC.IDLocation
WHERE lc.Country = 'US'
) T1
JOIN (
SELECT ML.IDModel, MF.Manufacturer_Name FROM DIM_MODEL ML
LEFT JOIN DIM_MANUFACTURER MF ON ML.IDManufacturer = MF.IDManufacturer
WHERE MF.Manufacturer_Name = 'Samsung'
) T2 ON
T1.IDModel = T2.IDModel
GROUP BY T1.State
ORDER BY TOTAL_SALE DESC


--Q2--END

--Q3--BEGIN      
	
SELECT LC.State, LC.ZipCode, ML.Model_Name, COUNT(FT.IDCustomer) AS TOTAL_TRANS
FROM FACT_TRANSACTIONS FT
LEFT JOIN DIM_LOCATION LC ON FT.IDLocation = LC.IDLocation
LEFT JOIN DIM_MODEL ML ON FT.IDModel = ML.IDModel
GROUP BY LC.State, LC.ZipCode, ML.Model_Name


--Q3--END

--Q4--BEGIN

SELECT TOP 1 DM.Model_Name, FT.TotalPrice
FROM FACT_TRANSACTIONS FT
JOIN DIM_MODEL DM ON FT.IDModel = DM.IDModel
ORDER BY FT.TotalPrice;


--Q4--END

--Q5--BEGIN

WITH Top5Manufacturers AS (
  SELECT TOP 5 DMF.IDManufacturer, SUM(FT.Quantity) as Sales
  FROM Fact_Transactions FT
  JOIN Dim_Model DM ON FT.IDModel = DM.IDModel
  JOIN Dim_Manufacturer DMF ON DM.IDManufacturer = DMF.IDManufacturer
  GROUP BY DMF.IDManufacturer
  ORDER BY Sales DESC
)

SELECT Dim_Model.Model_Name, AVG(Fact_Transactions.TotalPrice) as Average_Price
FROM Fact_Transactions 
JOIN Dim_Model ON FACT_TRANSACTIONS.IDModel = Dim_Model.IDModel
WHERE Dim_Model.IDManufacturer IN (SELECT IDManufacturer FROM Top5Manufacturers)
GROUP BY Dim_Model.Model_Name
ORDER BY Average_Price ASC;

--Q5--END

--Q6--BEGIN

SELECT T2.Customer_Name, AVG(T1.TotalPrice) AS AVERAGE_PRICE
FROM FACT_TRANSACTIONS T1
LEFT JOIN DIM_CUSTOMER T2 ON T1.IDCustomer= T2.IDCustomer
LEFT JOIN DIM_DATE T3 ON T1.Date = T3.DATE
WHERE T3.YEAR = 2009 
GROUP BY T2.Customer_Name
HAVING AVG(T1.TotalPrice) >500


--Q6--END
	
--Q7--BEGIN  
	
WITH Top5Models2008 AS (
  SELECT TOP 5 Dim_Model.Model_Name, SUM(Fact_Transactions.Quantity) as Sales
  FROM Fact_Transactions
  JOIN Dim_Model ON Fact_Transactions.IDModel = Dim_Model.IDModel
  WHERE Fact_Transactions.Date >= '2008-01-01' AND Fact_Transactions.Date < '2009-01-01'
  GROUP BY Dim_Model.Model_Name
  ORDER BY Sales DESC
),
Top5Models2009 AS (
  SELECT TOP 5 Dim_Model.Model_Name, SUM(Fact_Transactions.Quantity) as Sales
  FROM Fact_Transactions
  JOIN Dim_Model ON Fact_Transactions.IDModel = Dim_Model.IDModel
  WHERE Fact_Transactions.Date >= '2009-01-01' AND Fact_Transactions.Date < '2010-01-01'
  GROUP BY Dim_Model.Model_Name
  ORDER BY Sales DESC
),
Top5Models2010 AS (
  SELECT TOP 5 Dim_Model.Model_Name, SUM(Fact_Transactions.Quantity) as Sales
  FROM Fact_Transactions
  JOIN Dim_Model ON Fact_Transactions.IDModel = Dim_Model.IDModel
  WHERE Fact_Transactions.Date >= '2010-01-01' AND Fact_Transactions.Date < '2011-01-01'
  GROUP BY Dim_Model.Model_Name
  ORDER BY Sales DESC
)
SELECT Model_Name FROM Top5Models2008
INTERSECT
SELECT  Model_Name FROM Top5Models2009
INTERSECT
SELECT Model_Name FROM Top5Models2010;
--Q7--END	


--Q8--BEGIN

WITH Sales2009 AS (
  SELECT Dim_Manufacturer.Manufacturer_Name, SUM(Fact_Transactions.Quantity) as Total_Sales
  FROM Fact_Transactions
  JOIN Dim_Model ON Fact_Transactions.IDModel = Dim_Model.IDModel
  JOIN Dim_Manufacturer ON Dim_Model.IDManufacturer = Dim_Manufacturer.IDManufacturer
  WHERE Fact_Transactions.Date >= '2009-01-01' AND Fact_Transactions.Date < '2010-01-01'
  GROUP BY Dim_Manufacturer.Manufacturer_Name
),
Sales2010 AS (
  SELECT DIM_MANUFACTURER.Manufacturer_Name, SUM(Fact_Transactions.Quantity) as Total_Sales
  FROM Fact_Transactions
  JOIN Dim_Model ON Fact_Transactions.IDModel = Dim_Model.IDModel
  JOIN Dim_Manufacturer ON Dim_Model.IDManufacturer = Dim_Manufacturer.IDManufacturer
  WHERE Fact_Transactions.Date >= '2010-01-01' AND Fact_Transactions.Date < '2011-01-01'
  GROUP BY Dim_Manufacturer.Manufacturer_Name
)
SELECT Manufacturer_Name FROM (
  SELECT Manufacturer_Name, Total_Sales, 
    ROW_NUMBER() OVER (ORDER BY Total_Sales DESC) as RowNum
  FROM Sales2009) AS SubQuery
WHERE RowNum = 2
UNION ALL
SELECT Manufacturer_Name FROM (
  SELECT Manufacturer_Name, Total_Sales, 
    ROW_NUMBER() OVER (ORDER BY Total_Sales DESC) as RowNum
  FROM Sales2010) AS SubQuery
WHERE RowNum = 2;

--Q8--END


--Q9--BEGIN
	
SELECT Dim_Manufacturer.Manufacturer_Name
FROM Dim_Manufacturer
WHERE Dim_Manufacturer.IDManufacturer IN (
    SELECT Dim_Model.IDManufacturer
    FROM Fact_Transactions
    JOIN Dim_Model ON Fact_Transactions.IDModel = Dim_Model.IDModel
    WHERE Fact_Transactions.Date >= '2010-01-01' AND Fact_Transactions.Date < '2011-01-01'
  )
  AND Dim_Manufacturer.IDManufacturer NOT IN (
    SELECT Dim_Model.IDManufacturer
    FROM Fact_Transactions
    JOIN Dim_Model ON Fact_Transactions.IDModel = Dim_Model.IDModel
    WHERE Fact_Transactions.Date >= '2009-01-01' AND Fact_Transactions.Date < '2010-01-01'
  );

--Q9--END

--Q10--BEGIN
	
WITH Customer_Spend AS (
  SELECT Dim_Customer.IDCustomer, Dim_Customer.Customer_Name,
    YEAR(Fact_Transactions.Date) AS Years, 
	AVG(Fact_Transactions.TotalPrice) AS Avg_Spend,
    AVG(Fact_Transactions.Quantity) AS Avg_Quantity
  FROM Fact_Transactions
  JOIN Dim_Customer ON Fact_Transactions.IDCustomer = Dim_Customer.IDCustomer
  GROUP BY Dim_Customer.IDCustomer, Dim_Customer.Customer_Name, YEAR(Fact_Transactions.Date)
)
SELECT TOP 100 IDCustomer, Customer_Name, Years, Avg_Spend, Avg_Quantity,
  LAG(Avg_Spend, 1, 0) OVER (PARTITION BY IDCustomer ORDER BY Years) AS Prev_Year_Spend,
  CASE WHEN LAG(Avg_Spend, 1, 0) OVER (PARTITION BY IDCustomer ORDER BY Years) = 0 THEN 0
	   ELSE (Avg_Spend - LAG(Avg_Spend, 1, 0) OVER (PARTITION BY IDCustomer ORDER BY Years)) / 
  LAG(Avg_Spend, 1, 0) OVER (PARTITION BY IDCustomer ORDER BY Years) * 100
  END AS Spend_Change_Percentage
FROM Customer_Spend
ORDER BY Avg_Spend DESC

--Q10--END
	