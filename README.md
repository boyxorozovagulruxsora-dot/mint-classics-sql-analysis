# Mint Classics – Warehouse Optimization Analysis (MySQL)

Coursera project: *Analyze Data in a Model Car Database with MySQL Workbench*

## Problem
Mint Classics, a retailer of classic model cars, wants to close one of its four warehouses. The goal is to recommend which one, and how to reorganize or reduce inventory while still serving customers on time.

Data: `mintclassics` database (tables `warehouses`, `products`, `productlines`, `orders`, `orderdetails`). Orders cover Jan 2003 – May 2005 (about 29 months).

Assumption: `warehousePctCap` is the % of capacity in use, so estimated capacity = units in stock ÷ (pctCap ÷ 100).

## Key findings

### Warehouses (`01_warehouse_overview.sql`)
| Warehouse | Product lines | Products | Units in stock | % used | Est. free space |
|---|---|---|---|---|---|
| a – North | Motorcycles, Planes | 25 | 131,688 | 72% | 51,212 |
| b – East | Classic Cars | 38 | 219,183 | 67% | 107,956 |
| c – West | Vintage Cars | 24 | 124,880 | 50% | 124,880 |
| d – South | Ships, Trains, Trucks and Buses | 23 | 79,380 | 75% | 26,460 |

### Sales (`02_sales_by_warehouse.sql`)
| Warehouse | Units sold | Revenue | Gross profit |
|---|---|---|---|
| a – North | 24,650 | $2,076,064 | $835,216 |
| b – East | 35,582 | $3,853,922 | $1,526,212 |
| c – West | 22,933 | $1,797,560 | $737,268 |
| d – South | 22,351 | $1,876,645 | $727,184 |

- Only 5 of 326 orders were filled entirely from the South warehouse.
- Average time from order to shipment: 3.76 days.

### Products (`03_product_performance.sql`)
- Total stock (555,131 units) is more than 5× all units sold in 29 months (105,516).
- 59 of 110 products hold more than 5× their total sales.
- The 1985 Toyota Supra has 7,733 units in stock and has never been ordered.
- Some best-sellers are low on stock (e.g. 1960 BSA Gold Star: 15 in stock vs 1,015 sold).
- Price has little effect on sales: average units sold per product are similar across price bands.

### What-if scenarios (`04_what_if_scenarios.sql`)
- 5% stock cut: frees 27,757 units; products with under 12 months of demand rise only from 4 to 5.
- Keeping 12 months of demand per product would need about 42,400 units; over 90% of stock is excess.
- South's full inventory (79,380 units) fits into West's free space (124,880).

## Recommendations
1. Close the South warehouse and move its stock to West.
2. Gradually reduce overstock, starting with the 59 most overstocked products.
3. Discontinue or clear the never-sold 1985 Toyota Supra.
4. Restock fast-selling, low-stock items.
5. Monitor shipping time after the move (keep it near 3.76 days).

## Conclusion
The real issue is excess inventory, not lack of space. Closing the South warehouse is the least disruptive option, and combining it with overstock reduction cuts storage costs while keeping customer service at today's level.

## SQL scripts
- `01_warehouse_overview.sql` – stock, capacity, free space, product lines
- `02_sales_by_warehouse.sql` – sales, revenue, profit, order dependency, shipping time
- `03_product_performance.sql` – best/worst sellers, unsold items, stock-to-sales ratio, price bands
- `04_what_if_scenarios.sql` – 5% cut, 12-month cap, relocation of South's stock
