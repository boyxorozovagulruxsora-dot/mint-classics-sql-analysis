-- =====================================================================
-- 03_product_performance.sql
-- Mint Classics: best/worst sellers, unsold items, stock-to-sales ratio,
--                and the effect of price on sales
-- =====================================================================
USE mintclassics;

-- 3.1 Top 10 best-selling products
SELECT
    p.productCode, p.productName, p.productLine, p.warehouseCode,
    SUM(od.quantityOrdered) AS units_sold,
    p.quantityInStock
FROM products p
JOIN orderdetails od ON od.productCode = p.productCode
GROUP BY p.productCode, p.productName, p.productLine, p.warehouseCode, p.quantityInStock
ORDER BY units_sold DESC
LIMIT 10;

-- 3.2 Bottom 10 sellers (among products that sold at least once)
SELECT
    p.productCode, p.productName, p.productLine, p.warehouseCode,
    SUM(od.quantityOrdered) AS units_sold,
    p.quantityInStock
FROM products p
JOIN orderdetails od ON od.productCode = p.productCode
GROUP BY p.productCode, p.productName, p.productLine, p.warehouseCode, p.quantityInStock
ORDER BY units_sold ASC
LIMIT 10;

-- 3.3 Products that have never been ordered
SELECT p.productCode, p.productName, p.warehouseCode, p.quantityInStock
FROM products p
LEFT JOIN orderdetails od ON od.productCode = p.productCode
WHERE od.productCode IS NULL;

-- 3.4 Stock-to-sales ratio for every product
--     ratio > 5  -> heavily overstocked
--     ratio < 1  -> less stock on hand than was sold in the whole period
WITH product_sales AS (
    SELECT
        p.productCode, p.productName, p.warehouseCode, p.quantityInStock,
        COALESCE(SUM(od.quantityOrdered), 0) AS units_sold
    FROM products p
    LEFT JOIN orderdetails od ON od.productCode = p.productCode
    GROUP BY p.productCode, p.productName, p.warehouseCode, p.quantityInStock
)
SELECT
    productCode, productName, warehouseCode, quantityInStock, units_sold,
    ROUND(quantityInStock / NULLIF(units_sold, 0), 2) AS stock_to_sales_ratio,
    CASE
        WHEN units_sold = 0                     THEN 'Never sold'
        WHEN quantityInStock > 5 * units_sold   THEN 'Overstocked'
        WHEN quantityInStock < units_sold       THEN 'Low stock - reorder'
        ELSE 'Balanced'
    END AS stock_status
FROM product_sales
ORDER BY stock_to_sales_ratio DESC;

-- 3.5 Count of overstocked products per warehouse
WITH product_sales AS (
    SELECT
        p.productCode, p.warehouseCode, p.quantityInStock,
        COALESCE(SUM(od.quantityOrdered), 0) AS units_sold
    FROM products p
    LEFT JOIN orderdetails od ON od.productCode = p.productCode
    GROUP BY p.productCode, p.warehouseCode, p.quantityInStock
)
SELECT
    warehouseCode,
    COUNT(*)                                  AS products,
    SUM(quantityInStock > 5 * units_sold)     AS overstocked_5x,
    SUM(quantityInStock < units_sold)         AS low_stock
FROM product_sales
GROUP BY warehouseCode
ORDER BY warehouseCode;

-- 3.6 Does price affect sales? Average units sold by MSRP band
WITH product_sales AS (
    SELECT
        p.productCode, p.MSRP,
        COALESCE(SUM(od.quantityOrdered), 0) AS units_sold
    FROM products p
    LEFT JOIN orderdetails od ON od.productCode = p.productCode
    GROUP BY p.productCode, p.MSRP
)
SELECT
    CASE
        WHEN MSRP < 50  THEN '1) under $50'
        WHEN MSRP < 100 THEN '2) $50-99'
        WHEN MSRP < 150 THEN '3) $100-149'
        ELSE                 '4) $150+'
    END                     AS price_band,
    COUNT(*)                AS products,
    SUM(units_sold)         AS units_sold,
    ROUND(AVG(units_sold))  AS avg_units_per_product
FROM product_sales
GROUP BY price_band
ORDER BY price_band;
