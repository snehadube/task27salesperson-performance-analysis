# Salesperson Performance Analysis

Fair evaluation of salespeople using **sales, profit, growth and average order value** on the Superstore dataset (2014-2017).
Built during my Data Analytics internship at **Veda Technology** using **SQL (MySQL), Excel and Power BI**.

![Dashboard](images/dashboard.png)

## Business question
Revenue alone does not show who is really performing well. How can we rank salespeople **fairly** when their territories are different?

## Key findings
| Rank | Salesperson (Region) | Sales | Profit | Margin | Score (territory-fair) |
|---|---|---|---|---|---|
| 1 | Anna Andreadi (West) | $725K | $108K | 14.9% | 94.1 |
| 2 | Chuck Magee (East) | $679K | $92K | 13.5% | 75.6 |
| 3 | Cassandra Brandow (South) | $392K | $47K | 11.9% | 33.1 |
| 4 | Kelly Williams (Central) | $501K | $40K | 7.9% | 11.7 |

- **Revenue is misleading:** Central sells $110K more than South but earns $7K *less* profit.
- **Discounts above 20% lost $135K** across the company (total profit: $286K).
- **Territory matters:** sales per state ranges from $35.6K (South) to $66.0K (West); 10 of 49 states are loss-making (Texas, Ohio, Pennsylvania, Illinois lead the losses).
- The ranking order stayed the same in both the absolute model and the territory-fair model.

## Method
1. Data checks (9,994 rows, no nulls/duplicates) and salesperson mapping
2. KPIs in SQL: sales, profit, margin, orders, AOV, customers, discount, YoY, CAGR, sales per state, profit per customer
3. Composite score (min-max scaled 0-100): Model A (absolute) and **Model B (territory-fair, recommended)**: sales/state 20%, profit/customer 20%, margin 20%, CAGR 20%, AOV 10%, discount discipline 10%
4. Excel workbook with live formulas (change weights and see the rank change)
5. Power BI dashboard with DAX measures
6. Recommendations (discount approval above 20%, state-level targets, loss-making state review)

> **Assumption:** the Superstore file has no salesperson column. Salesperson = Regional Manager of the region (standard Superstore "People" table). Because one person owns one region, skill and territory cannot be fully separated.

## Repository structure
```
data/      superstore.csv (original), superstore_sql.csv (with salesperson + year columns)
sql/       salesperson_performance.sql
excel/     Salesperson_Performance_Analysis.xlsx
powerbi/   DAX_measures.txt  (+ .pbix file)
report/    Salesperson_Performance_Report.pdf
images/    dashboard and chart screenshots
```

## How to run
- **SQL:** run `sql/salesperson_performance.sql` in MySQL Workbench, import `data/superstore_sql.csv` into the `superstore` table.
- **Excel:** open `excel/Salesperson_Performance_Analysis.xlsx` (sheets: KPI_Summary, Scorecard, Territory, Discount, Charts).
- **Power BI:** load `data/superstore_sql.csv`, paste measures from `powerbi/DAX_measures.txt`.

## Tools
SQL (MySQL 8) | Excel (SUMIFS, SUMPRODUCT, RANK, charts) | Power BI (DAX) | Python (data prep, charts)

## Author
Sneha - Data Analytics Intern, Veda Technology
