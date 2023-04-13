
-- Show sale date table and order by date

SELECT *
FROM AdventureWorks_Sales_2016
ORDER BY 1, 2

-- Union with sale 2017

SELECT *
FROM AdventureWorks_Sales_2016
UNION 
    (SELECT * 
    FROM AdventureWorks_Sales_2017)
ORDER BY 1

-- Looking at number of order by product key 

SELECT sale.ProductKey, sale.TerritoryKey
    , SUM (sale.OrderQuantity) order_number
FROM (SELECT * FROM AdventureWorks_Sales_2016
       UNION 
      SELECT * FROM AdventureWorks_Sales_2017) sale
GROUP BY sale.ProductKey, sale.TerritoryKey

-- Join return_table to get return quantity

SELECT sale.OrderDate, sale.StockDate, sale.OrderQuantity, sale.ProductKey
    , sale.Territorykey, re.ReturnQuantity, re.ReturnDate
FROM (SELECT * FROM AdventureWorks_Sales_2016
       UNION 
      SELECT * FROM AdventureWorks_Sales_2017) sale
LEFT JOIN Adventureworks_Returns re 
    ON sale.TerritoryKey = re.TerritoryKey 
    AND sale.ProductKey = re.ProductKey

-- Caculate return rate by productkey

With product_table (ProductKey, TerritoryKey, order_number, return_number, return_qty) AS
(
    SELECT order_groupby.*
        , return_groupby.return_number
        , CASE WHEN return_groupby.return_number > 0 THEN return_groupby.return_number ELSE 0 END return_qty -- Replace NULL value by 0
    FROM (
            SELECT sale.ProductKey, sale.TerritoryKey
                , SUM (sale.OrderQuantity) order_number -- Get number of order by productkey
            FROM (SELECT * FROM AdventureWorks_Sales_2016
                UNION 
                SELECT * FROM AdventureWorks_Sales_2017) sale
            GROUP BY sale.ProductKey, sale.TerritoryKey) order_groupby
    LEFT JOIN ( 
            SELECT re.ProductKey, re.TerritoryKey
                , SUM (re.ReturnQuantity) return_number -- Get number of return by productkey
            FROM Adventureworks_Returns re
            GROUP BY re.ProductKey, re.TerritoryKey ) return_groupby
        ON order_groupby.TerritoryKey = return_groupby.TerritoryKey 
        AND order_groupby.ProductKey = return_groupby.ProductKey
)
SELECT pt.ProductKey, pt.order_number, pt.return_qty
    , FORMAT(return_number*1.0/order_number, 'p') return_rate -- Caculate return rate
    , p.ProductSKU, p.ProductName, p.ModelName, p.ProductCost, p.ProductPrice
FROM product_table pt 
LEFT JOIN AdventureWorks_Products p 
    ON pt.ProductKey = p.ProductKey
ORDER BY 4 DESC


-- Creat temp table
DROP TABLE IF EXISTS #Total_order_return_of_product
CREATE TABLE #Total_order_return_of_product
(
    productkey numeric,
    terrikey numeric,
    order_qty numeric,
    return_number numeric,
    return_qty numeric
)
INSERT INTO #Total_order_return_of_product
SELECT order_groupby.*
        , return_groupby.return_number
        , CASE WHEN return_groupby.return_number > 0 THEN return_groupby.return_number ELSE 0 END return_qty -- Replace NULL value by 0
    FROM (
            SELECT sale.ProductKey, sale.TerritoryKey
                , SUM (sale.OrderQuantity) order_number -- Get number of order by productkey
            FROM (SELECT * FROM AdventureWorks_Sales_2016
                UNION 
                SELECT * FROM AdventureWorks_Sales_2017) sale
            GROUP BY sale.ProductKey, sale.TerritoryKey) order_groupby
    LEFT JOIN ( 
            SELECT re.ProductKey, re.TerritoryKey
                , SUM (re.ReturnQuantity) return_number -- Get number of return by productkey
            FROM Adventureworks_Returns re
            GROUP BY re.ProductKey, re.TerritoryKey ) return_groupby
        ON order_groupby.TerritoryKey = return_groupby.TerritoryKey 
        AND order_groupby.ProductKey = return_groupby.ProductKey
SELECT * FROM #Total_order_return_of_product


-- Creat View

CREATE VIEW product_table as
With product_table (ProductKey, TerritoryKey, order_number, return_number, return_qty) AS
(
    SELECT order_groupby.*
        , return_groupby.return_number
        , CASE WHEN return_groupby.return_number > 0 THEN return_groupby.return_number ELSE 0 END return_qty -- Replace NULL value by 0
    FROM (
            SELECT sale.ProductKey, sale.TerritoryKey
                , SUM (sale.OrderQuantity) order_number  -- Get number of order by productkey
            FROM (SELECT * FROM AdventureWorks_Sales_2016
                UNION 
                SELECT * FROM AdventureWorks_Sales_2017) sale
            GROUP BY sale.ProductKey, sale.TerritoryKey) order_groupby
    LEFT JOIN ( 
            SELECT re.ProductKey, re.TerritoryKey
                , SUM (re.ReturnQuantity) return_number -- Get number of return by productkey
            FROM Adventureworks_Returns re
            GROUP BY re.ProductKey, re.TerritoryKey ) return_groupby
        ON order_groupby.TerritoryKey = return_groupby.TerritoryKey 
        AND order_groupby.ProductKey = return_groupby.ProductKey
)
SELECT pt.ProductKey, pt.order_number, pt.return_qty
    , FORMAT(return_number*1.0/order_number, 'p') return_rate -- Caculate return rate
    , p.ProductSKU, p.ProductName, p.ModelName, p.ProductCost, p.ProductPrice
FROM product_table pt 
LEFT JOIN AdventureWorks_Products p 
    ON pt.ProductKey = p.ProductKey

SELECT * FROM product_table











