CREATE DATABASE superstore_db;
USE superstore_db;
-- DROP DATABASE superstore_db;
-- Drop TABLE sales;

DESCRIBE sales;
SELECT COUNT(*) FROM sales;
select * from sales LIMIT 10;


-- Date conversion
SELECT `Order Date`, `Ship Date`
FROM sales
LIMIT 5;

UPDATE sales
SET `Order Date` = STR_TO_DATE(`Order Date`, '%m/%d/%Y %H:%i'),
    `Ship Date`  = STR_TO_DATE(`Ship Date`,  '%m/%d/%Y %H:%i');


ALTER TABLE sales
MODIFY `Order Date` DATETIME,
MODIFY `Ship Date` DATETIME;


-- CLEANING
-- Check for NULL customers

SELECT COUNT(*) 
FROM sales
WHERE `Customer ID` IS NULL;

-- Remove invalid sales
DELETE FROM sales
WHERE Sales <= 0;

-- Create a clean sales amount column

ALTER TABLE sales
ADD TotalAmount DECIMAL(10,2);

UPDATE sales
SET TotalAmount = Sales;

-- DROP VIEW IF EXISTS single_customer_view;

-- -- VIEW
CREATE VIEW single_customer_view AS
SELECT
`Customer ID` AS CustomerID,
MAX(`Order Date`) AS LastPurchaseDate,
COUNT(DISTINCT `Order ID`) AS Frequency,
SUM(Sales) AS MonetaryValue
FROM sales
GROUP BY `Customer ID` ;


SELECT * FROM single_customer_view LIMIT 10;

SELECT * FROM single_customer_view 
ORDER BY LastPurchaseDate DESC;



-- creating fact table and Dim tables and then creating single customer view

CREATE TABLE DimCustomer (
    CustomerID VARCHAR(50) PRIMARY KEY,
    CustomerName VARCHAR(100)
);

INSERT INTO DimCustomer (CustomerID, CustomerName)
SELECT DISTINCT
    `Customer ID`,
    `Customer Name`
FROM sales;


CREATE TABLE DimProduct (
    ProductID VARCHAR(50) PRIMARY KEY,
    ProductName VARCHAR(150),
    Category VARCHAR(50)
);
INSERT INTO DimProduct (ProductID,  Category)
SELECT DISTINCT
    `Product ID`,
    'Category'
FROM sales;

CREATE TABLE DimRegion (
    RegionID INT AUTO_INCREMENT PRIMARY KEY,
    Region VARCHAR(50),
    State VARCHAR(50)
);

INSERT INTO DimRegion (Region, State)
SELECT DISTINCT
    Region,
    State
FROM sales;


CREATE TABLE DimDate (
    DateID DATE PRIMARY KEY,
    Year INT,
    Month INT,
    Day INT
);

INSERT INTO DimDate (DateID, Year, Month, Day)
SELECT DISTINCT
    `Order Date`,
    YEAR(`Order Date`),
    MONTH(`Order Date`),
    DAY(`Order Date`)
FROM sales;


CREATE TABLE FactSales (
    OrderID VARCHAR(50),
    OrderDate DATE,
    CustomerID VARCHAR(50),
    ProductID VARCHAR(50),
    RegionID INT,
    Sales DECIMAL(10,2),

    FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID),
    FOREIGN KEY (RegionID) REFERENCES DimRegion(RegionID),
    FOREIGN KEY (OrderDate) REFERENCES DimDate(DateID)
);


INSERT INTO FactSales
SELECT
    s.`Order ID`,
    s.`Order Date`,
    s.`Customer ID`,
    s.`Product ID`,
    r.RegionID,
    s.Quantity,
    s.Sales
FROM sales s
JOIN DimRegion r
  ON s.Region = r.Region
 AND s.State = r.State;

INSERT INTO FactSales (
    OrderID,
    OrderDate,
    CustomerID,
    ProductID,
    RegionID,
    Sales
)
SELECT
    s.`Order ID`,
    s.`Order Date`,
    s.`Customer ID`,
    s.`Product ID`,
    r.RegionID,
    s.Sales
FROM sales s
JOIN DimRegion r
  ON s.Region = r.Region
 AND s.State = r.State;


CREATE VIEW single_customer_view_1 AS
SELECT
    CustomerID,
    MAX(OrderDate) AS LastPurchaseDate,
    COUNT(DISTINCT OrderID) AS Frequency,
    SUM(Sales) AS MonetaryValue
FROM FactSales
GROUP BY CustomerID;

SELECT * FROM single_customer_view_1 LIMIT 10;
-- SELECT COUNT(*) FROM single_customer_view_1;

-- SELECT COUNT(*) 
-- FROM single_customer_view_1
-- WHERE CustomerID IS NULL;






