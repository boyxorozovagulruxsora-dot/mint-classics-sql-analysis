-- =====================================================================
-- 04_what_if_scenarios.sql
-- Mint Classics: what-if analysis for reducing inventory and closing
--                the South warehouse (d)
-- Sales period in the data: 2003-01-06 to 2005-05-31 (about 29 months)
-- =====================================================================
USE mintclassics;

-- 4.1 Scenario A: reduce every product's stock by 5%
--     How many units are freed, and how many products would then hold
--     less than 12 months of demand?
WITH product_sales AS (
    SELECT
        p.productCode, p.quantityInStock,
        COALESCE(SUM(od.quantityOrdered), 0) AS units_sold
    FROM products p
    LEFT JOIN orderdetails od ON od.productCode = p.productCode
    GROUP BY p.productCode, p.quantityInStock
)
SELECT
    SUM(quantityInStock)                                       AS current_units,
    ROUND(SUM(quantityInStock * 0.95))                          AS units_after_cut,
    ROUND(SUM(quantityInStock * 0.05))                          AS units_freed,
    SUM(quantityInStock        < units_sold / 29 * 12)          AS products_under_12m_now,
    SUM(quantityInStock * 0.95 < units_sold / 29 * 12)          AS products_under_12m_after
FROM product_sales;

-- 4.2 Scenario B: keep at most 12 months of demand per product
--     (average monthly sales x 12). Shows how much stock is excess.
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
    SUM(quantityInStock)                                              AS current_units,
    ROUND(SUM(LEAST(quantityInStock, units_sold / 29 * 12)))          AS units_needed_12m,
    ROUND(SUM(quantityInStock) - SUM(LEAST(quantityInStock, units_sold / 29 * 12))) AS excess_units
FROM product_sales
GROUP BY warehouseCode
ORDER BY warehouseCode;

-- 4.3 Scenario C: can South's (d) full inventory fit into another
--     warehouse's free space without any reduction?
WITH stock AS (
    SELECT
        w.warehouseCode,
        w.warehouseName,
        CAST(w.warehousePctCap AS UNSIGNED) AS pct_used,
        SUM(p.quantityInStock)              AS units_in_stock
    FROM warehouses w
    JOIN products p ON p.warehouseCode = w.warehouseCode
    GROUP BY w.warehouseCode, w.warehouseName, w.warehousePctCap
),
space AS (
    SELECT
        warehouseCode, warehouseName, units_in_stock,
        ROUND(units_in_stock / (pct_used / 100)) - units_in_stock AS free_space
    FROM stock
)
SELECT
    s.warehouseCode,
    s.warehouseName,
    s.free_space,
    (SELECT units_in_stock FROM stock WHERE warehouseCode = 'd') AS south_units_to_move,
    CASE
        WHEN s.free_space >= (SELECT units_in_stock FROM stock WHERE warehouseCode = 'd')
        THEN 'Fits'
        ELSE 'Does not fit'
    END AS can_absorb_south
FROM space s
WHERE s.warehouseCode <> 'd'
ORDER BY s.free_space DESC;
