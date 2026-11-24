-- =====================================================================
-- 02_sales_by_warehouse.sql
-- Mint Classics: sales volume, revenue, profit and customer reach per warehouse
-- =====================================================================
USE mintclassics;

-- 2.1 Units sold, revenue, gross profit and number of orders per warehouse
SELECT
    p.warehouseCode,
    w.warehouseName,
    SUM(od.quantityOrdered)                                   AS units_sold,
    ROUND(SUM(od.quantityOrdered * od.priceEach), 2)           AS revenue,
    ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS gross_profit,
    COUNT(DISTINCT od.orderNumber)                             AS orders_involved,
    ROUND(100 * SUM(od.quantityOrdered * od.priceEach)
          / (SELECT SUM(quantityOrdered * priceEach) FROM orderdetails), 1) AS revenue_share_pct
FROM products p
JOIN orderdetails od ON od.productCode = p.productCode
JOIN warehouses  w  ON w.warehouseCode = p.warehouseCode
GROUP BY p.warehouseCode, w.warehouseName
ORDER BY units_sold DESC;

-- 2.2 How many orders depend ONLY on the South warehouse (d)?
--     If very few orders are served solely from one warehouse,
--     its products can be moved without breaking order fulfilment.
WITH order_wh AS (
    SELECT
        od.orderNumber,
        MAX(p.warehouseCode = 'd')       AS has_south_item,
        COUNT(DISTINCT p.warehouseCode)  AS warehouses_used
    FROM orderdetails od
    JOIN products p ON p.productCode = od.productCode
    GROUP BY od.orderNumber
)
SELECT
    COUNT(*)                                          AS total_orders,
    SUM(has_south_item)                               AS orders_with_south_items,
    SUM(has_south_item = 1 AND warehouses_used = 1)   AS orders_only_from_south
FROM order_wh;

-- 2.3 Average days from order to shipment (service level baseline)
SELECT
    ROUND(AVG(DATEDIFF(shippedDate, orderDate)), 2) AS avg_days_to_ship,
    MAX(DATEDIFF(shippedDate, orderDate))           AS max_days_to_ship
FROM orders
WHERE status = 'Shipped';

-- 2.4 Units sold per year
SELECT
    YEAR(o.orderDate)       AS order_year,
    SUM(od.quantityOrdered) AS units_sold
FROM orders o
JOIN orderdetails od ON od.orderNumber = o.orderNumber
GROUP BY YEAR(o.orderDate)
ORDER BY order_year;
