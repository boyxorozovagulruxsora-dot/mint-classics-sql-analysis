-- =====================================================================
-- 01_warehouse_overview.sql
-- Mint Classics: inventory, capacity and free space per warehouse
-- =====================================================================
USE mintclassics;

-- 1.1 Products, units in stock and inventory value per warehouse
SELECT
    w.warehouseCode,
    w.warehouseName,
    CAST(w.warehousePctCap AS UNSIGNED)       AS pct_capacity_used,
    COUNT(p.productCode)                      AS product_count,
    SUM(p.quantityInStock)                    AS units_in_stock,
    ROUND(SUM(p.quantityInStock * p.buyPrice), 2) AS inventory_value_at_cost
FROM warehouses w
JOIN products p ON p.warehouseCode = w.warehouseCode
GROUP BY w.warehouseCode, w.warehouseName, w.warehousePctCap
ORDER BY units_in_stock DESC;

-- 1.2 Estimated total capacity and free space
--     Assumption: warehousePctCap = % of the warehouse's capacity in use,
--     so capacity = units_in_stock / (pct / 100).
WITH stock AS (
    SELECT
        w.warehouseCode,
        w.warehouseName,
        CAST(w.warehousePctCap AS UNSIGNED) AS pct_used,
        SUM(p.quantityInStock)              AS units_in_stock
    FROM warehouses w
    JOIN products p ON p.warehouseCode = w.warehouseCode
    GROUP BY w.warehouseCode, w.warehouseName, w.warehousePctCap
)
SELECT
    warehouseCode,
    warehouseName,
    pct_used,
    units_in_stock,
    ROUND(units_in_stock / (pct_used / 100))                  AS est_capacity,
    ROUND(units_in_stock / (pct_used / 100)) - units_in_stock AS est_free_space
FROM stock
ORDER BY warehouseCode;

-- 1.3 Product lines stored in each warehouse
SELECT
    p.warehouseCode,
    p.productLine,
    COUNT(*)               AS product_count,
    SUM(p.quantityInStock) AS units_in_stock
FROM products p
GROUP BY p.warehouseCode, p.productLine
ORDER BY p.warehouseCode, p.productLine;
