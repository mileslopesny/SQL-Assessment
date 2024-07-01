/* Query #1:
Write a query that returns all of the records that contain visible CarrierTrackingNumbers, an OrderQty of 15 or more, and also has a Modified date of July 1st 2013 or greater

Tables Used:
[Sales].[SalesOrderDetail]

The report should contain the following columns:
SalesOrderID
SalesOrderDetailID
CarrierTrackingNumber
OrderQty
ProductID
LineTotal
ModifiedDate
*/

/* Answer #1 = 313 Rows
Assumed "visible CarrierTrackingNumbers" means that these were not NULL, already checked to see if there were any "blank" ie non nulls and there were none ...TRIM(CarrierTrackingNumber) <> '' 
*/

SELECT [SalesOrderID]
      ,[SalesOrderDetailID]
      ,[CarrierTrackingNumber]
      ,[OrderQty]
      ,[ProductID]
      ,[LineTotal]
      ,[ModifiedDate]
  FROM [AdventureWorks2022].[Sales].[SalesOrderDetail]
  WHERE CarrierTrackingNumber is not null
  AND OrderQty >= 15
  AND ModifiedDate > = '2013-07-01'

/* Query #2:
Find the territory that has the best SalesYTD value and create a report that returns all of the people from that territory

Tables Used:
[Sales].[SalesPerson]
[Person].[Person]
[Sales].[SalesTerritory]

The report should contain the following columns:
TerritoryID
TerritoryName
FirstName
LastName
SalesYTD
*/

/* Answer #2 = 2 Rows , TerritoryID 4 (Southwest) Linda Mitchell and Shu Ito
- Opted to "ignore" 3 Records in [Sales].[SalesPerson] that have a TerritoryID = NULL
- Assumed the SalesYTD was per Salesperson for the Territory that had the highest total SalesYTD for all salespersons in that territory
*/

 SELECT 
  S.TerritoryID 
 ,T.[Name] as TerritotyName
 ,P.[FirstName]
 ,P.[LastName]
 ,S.[SalesYTD]
  FROM
  [AdventureWorks2022].[Sales].[SalesPerson] as S
  ,[AdventureWorks2022].[Person].[Person] as P
  ,[AdventureWorks2022].[Sales].[SalesTerritory] as T
  WHERE
  S.BusinessEntityID = P.BusinessEntityID 
  AND S.TerritoryID is not null 
  AND S.TerritoryID = T.TerritoryID
  AND S.TerritoryID in
   (SELECT top 1
  T1.[TerritoryID]
 --,T1.[SalesYTD] -- this is the SalesYTD for all salespersons in that territory
  FROM
  [AdventureWorks2022].[Sales].[SalesTerritory] as T1
  ORDER by T1.[SalesYTD] DESC)

/* Query #3:
For online orders only that shipped in 2014, write a query that returns the total number of sales orders, the line total dollars, and the total due dollars for each customer. Group the results for each customer by the ship date year and month as well as the product name. Order the results to show the latest ship dates first and secondly by customerID in ascending order

Tables Used:
[Sales].[SalesOrderDetail]
[Sales].[SalesOrderHeader]
[Production].[Product]
[Purchasing].[ShipMethod]

The report should contain the following columns:
CustomerID
ShipYear
ShipMonth
ShipMethodName
ProductName
TotalSalesOrders
LineTotal
TotalDue
*/

/* Answer #3 = 28,600 Rows
Used "PARTITION" vs "GROUP BY"
Assumed that all the orders (in descending order  Shipdate ie latest first) per CustomerID (in ascending order) 
eg CustomerID 11019 has 18 orders from 6/2014 to 1/2014
*/

Select
SOH.[CustomerID]
,YEAR(SOH.[ShipDate]) as ShipYear
,MONTH(SOH.[ShipDate]) as ShipMonth
,SM.[Name] as ShipMethodName
,P.[Name] as ProductName
,COUNT(SOH.SalesOrderID) over (PARTITION by SOH.CustomerID,YEAR(SOH.ShipDate),MONTH(SOH.ShipDate),P.Name) as TotalSalesOrders 
,SUM(SOD.LineTotal) over (PARTITION by SOH.CustomerID,YEAR(SOH.ShipDate),MONTH(SOH.ShipDate),P.Name) as LineTotal 
,SUM(SOH.TotalDue) over (PARTITION by SOH.CustomerID,YEAR(SOH.ShipDate),MONTH(SOH.ShipDate),P.Name) as TotalDue
FROM 
[AdventureWorks2022].[Sales].[SalesOrderHeader]  as SOH 
,[AdventureWorks2022].[Sales].[SalesOrderDetail] as SOD 
,[AdventureWorks2022].[Purchasing].[ShipMethod] as SM 
,[AdventureWorks2022].[Production].[Product] as P 
WHERE 
SOH.ShipMethodID = SM.ShipMethodID 
AND 
SOH.SalesOrderID = SOD.SalesOrderID
AND
P.ProductID = SOD.ProductID
AND
YEAR(SOH.[ShipDate])= 2014
AND 
SOH.OnlineOrderFlag = 1
ORDER BY SOH.[CustomerID] ASC, SOH.[ShipDate] DESC 

/* ALternate Answer #3 = 28,529 Rows so does not match the "partition solution" above
Used "GROUP BY CUBE" (to remove the "summary rows" had to filter out "null values"
Tested CustomerID 11019 has 18 orders from 6/2014 to 1/2014 so matches "partition solution" above
*/

select
A.CustomerID
,A.ShipYear
,A.ShipMonth
,A.ProductName
,A.ShipMethodName
,A.TotalSalesOrders
,A.LineTotal
,A.TotalDue
from
(Select
SOH.[CustomerID]
,YEAR(SOH.[ShipDate]) as ShipYear
,MONTH(SOH.[ShipDate]) as ShipMonth
,SM.[Name] as ShipMethodName
,P.[Name] as ProductName
,COUNT(SOH.SalesOrderID) as TotalSalesOrders 
,SUM(SOD.LineTotal) as LineTotal 
,SUM(SOH.TotalDue) as TotalDue
FROM 
[AdventureWorks2022].[Sales].[SalesOrderHeader]  as SOH 
,[AdventureWorks2022].[Sales].[SalesOrderDetail] as SOD 
,[AdventureWorks2022].[Purchasing].[ShipMethod] as SM 
,[AdventureWorks2022].[Production].[Product] as P 
WHERE 
SOH.ShipMethodID = SM.ShipMethodID 
AND 
SOH.SalesOrderID = SOD.SalesOrderID
AND
P.ProductID = SOD.ProductID
AND
YEAR(SOH.[ShipDate])= 2014
AND 
SOH.OnlineOrderFlag = 1
--AND SOH.[CustomerID] = 11019 -- test 18 orders
GROUP BY cube(SOH.[CustomerID],YEAR(SOH.[ShipDate]),MONTH(SOH.[ShipDate]),SM.[Name],P.[Name])) as A
where
-- checking for nulls ie bad method to remove "summary rows"---
A.CustomerID is not null AND
A.ShipYear is not null AND
A.ShipMonth is not null AND
A.ProductName is not null AND
A.ShipMethodName is not null AND
A.TotalSalesOrders is not null AND
A.LineTotal is not null AND
A.TotalDue is not null 
---ordered by Month descending as year is 2014 anyway
ORDER BY A.CustomerID ASC, A.ShipMonth DESC 

/* Query #4:
Write a query that returns the order quantity and line totals for orders with an order date during years of 2012 and 2013. Group the totals by the order date year and month. Filter results for ship method of "CARGO TRANSPORT 5" and only sum the values for non-online orders only. Order the results in descending order for OrderYear and OrderMonth

Tables Used:
[Sales].[SalesOrderDetail]
[Sales].[SalesOrderHeader]
[Purchasing].[ShipMethod]

The report should contain the following columns:
OrderYear
OrderMonth
NonOnlineOrderQty
NonOnlineLineTotal
*/

/* Answer #4 = 24 Rows
To avoid any "edge cases" where OnlineOrderFlag has a number other than 1 or is NULL opted for OnlineOrderFlag <> 1 instead of OnlineOrderFlag = 0
*/

Select
OrderYear
,OrderMonth
,SUM(A.NonOnlineOrderQty) as NonOnlineOrderQty
,SUM(A.NonOnlineLineTotal) as NonOnlineLineTotal
FROM
(Select
YEAR(SOH.[OrderDate]) as OrderYear
,MONTH(SOH.[OrderDate]) as OrderMonth
,SM.[Name]
,CASE
WHEN SOH.OnlineOrderFlag <> 1 THEN SOD.[OrderQty] ELSE 0 
END AS NonOnlineOrderQty
,CASE
 WHEN SOH.OnlineOrderFlag <> 1 THEN SOD.[LineTotal]  ELSE 0 
END AS NonOnlineLineTotal
FROM 
[AdventureWorks2022].[Sales].[SalesOrderHeader]  as SOH 
,[AdventureWorks2022].[Sales].[SalesOrderDetail] as SOD 
,[AdventureWorks2022].[Purchasing].[ShipMethod] as SM 
WHERE 
SOH.ShipMethodID = SM.ShipMethodID 
AND 
SOH.SalesOrderID = SOD.SalesOrderID
AND
(YEAR(SOH.[OrderDate]) = 2012 OR YEAR(SOH.[OrderDate]) = 2013)
AND
SM.[Name] = 'CARGO TRANSPORT 5'
) as A
GROUP BY OrderYear,OrderMonth
Order by OrderYear DESC,OrderMonth DESC

/* Query #5:
Write a query that returns customer latest sales orders. For each customer's latest order, we need to know if they had a special offer discount type of either Seasonal Discount or Volume Discount (make this a binary flag shown as 1 or 0) and how many days has it been since the order due date relative to today's date.
We also want to know specific unit price bucket tiers (break the tiers up in to 3 buckets that show: 1) Unit price less than $1000 2) Unit prices between $1000.01 - $1999.99 3) greater or equal to $2000). These should be 3 separate columns. Default values should be NULL, and it's ok if some sales orders fall into more than one bucket.
Make sure there are no duplicates in the final result set. There should only be one row per CustomerID.

Tables Used:
[Sales].[SalesOrderDetail]
[Sales].[SalesOrderHeader]
[Sales].[SpecialOffer]

The report should contain the following columns:
CustomerID
LatestSalesOrderID
SpecialOfferDiscountFlag
UnitPriceBucket1
UnitPriceBucket2
UnitPriceBucket3
DaysSinceDueDate
*/

/* Answer #5 = 19,119 rows
Note on validation checked that there were 19,199 unique customerID's.
I opted to total the # of unitPriceBuckets for each Customer
CustomerID = 29566 was the test case I used to validate it had 6 "detail" records for OrderID 45787.
I also made the following assumption ...most  recent sales order was the "highest salesOrderID" ...the order date would be more accurate choice
*/

Select 
A.CustomerID, 
MAX(B.DaysSinceDueDate) as DaysSinceDueDate,
MAX(A.LatestSalesOrderID) as LatestSalesOrderID,
MAX(B.SpecialOfferDiscountFlag) as SpecialOfferDiscountFlag,
SUM(B.UnitPriceBucket1) as UnitPriceBucket1 ,
SUM(B.UnitPriceBucket2) as UnitPriceBucket2,
SUM(B.UnitPriceBucket3) as UnitPriceBucket3
FROM
(
Select
[CustomerID]
,MAX(SalesOrderID) as LatestSalesOrderID
FROM 
[AdventureWorks2022].[Sales].[SalesOrderHeader]
GROUP BY [CustomerID]
) as A,
(SELECT
SOH.[CustomerID]
,DATEDIFF(DAY,SOH.[DueDate],GETDATE()) as DaysSinceDueDate
,SOH.[SalesOrderID]
,CASE
WHEN SP.[Type] = 'Seasonal Discount' THEN 1 
WHEN SP.[Type] = 'Volume Discount' THEN 1
ELSE 0 
END AS SpecialOfferDiscountFlag
,CASE
WHEN SOD.[UnitPrice] < 1000 THEN 1 ELSE NULL
END AS UnitPriceBucket1
,CASE
WHEN SOD.[UnitPrice] >= 1000 AND SOD.[UnitPrice] < 2000 THEN 1 ELSE NULL
END AS UnitPriceBucket2
,CASE
WHEN SOD.[UnitPrice] >= 2000 THEN 1 ELSE NULL
END AS UnitPriceBucket3
FROM 
[AdventureWorks2022].[Sales].[SalesOrderHeader]  as SOH 
,[AdventureWorks2022].[Sales].[SalesOrderDetail] as SOD 
,[AdventureWorks2022].[Sales].[SpecialOffer] as SP
WHERE 
SOH.SalesOrderID = SOD.SalesOrderID
AND
SOD. [SpecialOfferID]  = SP. [SpecialOfferID]
) as B
WHERE A.LatestSalesOrderID = B.SalesOrderID
GROUP BY A.CustomerID
ORDER BY A.CustomerID

