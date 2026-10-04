# Salesperson Performance Analysis - Step by Step Guide (Hinglish)

Total time: lagbhag 4-6 ghante. Order follow karo: **SQL -> Excel -> Power BI -> PDF -> GitHub -> LinkedIn**.

## Pehle ye samajh lo (important)
- Superstore CSV me **salesperson ka column hi nahi hai**. Isliye standard Superstore "People" table use kiya: har Region ka Regional Manager = salesperson.
  West = Anna Andreadi, East = Chuck Magee, Central = Kelly Williams, South = Cassandra Brandow.
- Report me ye assumption likha hai. Agar mentor ne alag mapping di ho to batao / badal do.
- Maine tumhare liye ready kiya hua hai: `data/superstore_sql.csv` (salesperson + order_year column ke saath), SQL script, Excel workbook, DAX file, PDF report, README, LinkedIn post.
- Tumhe khud karna hai: SQL run karna, Power BI dashboard banana, screenshots lena, GitHub/LinkedIn pe post karna (kyunki ye tumhare accounts me hoga).

---
## PART 1: Folder setup
1. Desktop pe folder banao: `salesperson-performance-analysis`.
2. Zip extract karke saari files isi folder me rakho (data, sql, excel, powerbi, report, images).

---
## PART 2: SQL (MySQL Workbench)
**Install:** MySQL Server + MySQL Workbench (dev.mysql.com/downloads/installer).

1. MySQL Workbench kholo -> apne connection (Local instance) pe double-click -> password daalo.
2. Menu **File > Open SQL Script** -> `sql/salesperson_performance.sql` select karo.
3. Sirf **STEP 0** wala hissa select karo (CREATE DATABASE se CREATE TABLE tak) -> upar **bijli wala icon (Execute)** dabao.
4. Left side **Navigator > SCHEMAS** ke paas refresh icon dabao -> `veda_sales` dikhega.
5. `veda_sales` > **Tables** > `superstore` pe **right-click > Table Data Import Wizard**.
6. **Browse** -> `data/superstore_sql.csv` -> Next -> **Use existing table: veda_sales.superstore** -> Next.
7. Column mapping check karo (sab columns ek ek se map hone chahiye) -> Next -> Next -> Finish. (9994 rows import honi chahiye; 1-2 minute lag sakta hai.)
8. Ab script ke baaki steps ek ek karke chalao: query select karo -> **Ctrl+Enter** (ek query) ya poori select karke Execute.
   - STEP 1 check: expect **9994 rows, 5009 orders, 2014-01-03 se 2017-12-30**, null = 0.
   - STEP 2: core KPIs. STEP 3: YoY. STEP 4: CAGR. STEP 5: territory. STEP 6: discount. STEP 7: category. STEP 8: **final ranking**.
9. Har result ka **screenshot** lo (Windows: Win+Shift+S) aur `images/` me save karo: `sql_kpis.png`, `sql_ranking.png`.
10. Final ranking expected: Anna 94.1 (#1), Chuck 75.6 (#2), Cassandra 33.1 (#3), Kelly 11.7 (#4). Agar ye aaye to sahi hai.

**MySQL install nahi karna?** Free option: Power BI me direct CSV load karo (Part 4), aur SQL script GitHub me documentation ke taur pe rakho. Lekin task me SQL tool hai, isliye MySQL me chalana better hai (SQL script me `POW`; SQL Server me `POWER` use hota hai).

---
## PART 3: Excel
Ready workbook: `excel/Salesperson_Performance_Analysis.xlsx`. Isme sab formulas live hain.

**Sheets:** README (assumptions) | Territory | KPI_Summary | Scorecard | Discount | Charts | Data

Samajhne ke liye khud ek PivotTable bhi banao (interview me kaam aayega):
1. **Data** sheet kholo -> koi bhi cell click -> **Insert > PivotTable > OK (New Worksheet)**.
2. Fields: **Salesperson** -> Rows; **Sales** aur **Profit** -> Values (Sum).
3. Distinct orders ke liye: PivotTable banate waqt **"Add this data to the Data Model"** tick karo -> Values me `Order ID` daalo -> **Value Field Settings > Distinct Count**.
4. Pivot select -> **PivotTable Analyze > PivotChart** -> Clustered Column.
5. **Scorecard** sheet kholo: peeli (blue) cells weights hain. Weight badlo to rank/score badal jaata hai. Total hamesha 100% hona chahiye.
6. **Charts** sheet ka screenshot lo -> `images/excel_charts.png`.
7. Conditional formatting (optional): Scorecard ke Composite Score column select -> **Home > Conditional Formatting > Color Scales**.

---
## PART 4: Power BI Desktop (main dashboard)
**Install:** Microsoft Store se "Power BI Desktop".

### 4A. Data load
1. **Home > Get data > Text/CSV** -> `data/superstore_sql.csv` -> **Transform Data**.
2. Power Query me check karo: `order_date` = Date, `sales`, `profit`, `discount` = Decimal Number, `order_year` = Whole Number.
3. **Home > Close & Apply**.
4. Right side **Data pane** me `order_year` pe click -> **Column tools > Summarization: Don't summarize**.

### 4B. Measures
1. Data pane me `superstore` table pe **right-click > New measure**.
2. `powerbi/DAX_measures.txt` se ek ek measure paste karo (formula bar me), Enter dabao.
3. **Calculated column:** `superstore` pe click -> **Table tools > New column** -> `Discount Band` wala formula paste karo.
4. Numbers check karo (file ke end me list hai): Anna sales 725,458 / profit 108,418 / score 94.1.
5. DAX maine yahan Power BI me test nahi kiya (sandbox me Power BI nahi chalta). Isliye numbers match karna zaroori hai. Match na ho to formula ki copy-paste me kuch miss hua hoga ya table ka naam alag hoga (`superstore` hi rakhna).

### 4C. Dashboard layout (16:9, ek page)
**View > Page view > Fit to page.** Top se neeche:
1. **Title** (Insert > Text box): "Salesperson Performance Dashboard".
2. **Slicers** (Visualizations pane > Slicer icon): `order_year` (Format > Slicer settings > Style: Tile/Between), `category`.
3. **4 Cards**: Total Sales, Total Profit, Profit Margin %, AOV. (Card icon -> field/measure drag.)
4. **Leaderboard table**: Table/Matrix visual -> Columns: `salesperson`, Total Sales, Total Profit, Profit Margin %, AOV, CAGR 2014-17, Composite Score, Rank.
   - Rank pe click -> Sort descending/ascending (Rank ascending).
   - **Conditional formatting:** field ke dropdown > Conditional formatting > Data bars / Background color (Composite Score).
   - Is table ko Year slicer se alag rakho: table select -> **Format > Edit interactions** -> year slicer pe "None" (circle with line).
5. **Clustered column chart**: X = `salesperson`, Y = Total Sales + Total Profit.
6. **Line chart**: X = `order_year`, Y = Total Sales, Legend = `salesperson`.
7. **Bar chart (Territory)**: Y = `state`, X = Total Profit, Filter pane me **Top N** ya sirf bottom 10 (Filters > state > Filter type: Top N > Bottom 10 by Total Profit). Negative bars laal rakho (Format > Colors > fx).
8. **Column chart**: X = `Discount Band`, Y = Total Profit. (Dikhata hai discount badhne par profit girta hai.)
9. **Text box (Key insights)**: 3 line: "Anna (West) #1", "Discounts >20% lost $135K", "Central: highest sales rank-3 but lowest profit".
10. Colors: **View > Themes** se koi simple theme, ya navy + blue + orange + red. Har visual ka **title** likho (Format > Title).
11. Alignment: sab visuals select -> **Format > Align**.

### 4D. Save & export
1. **File > Save as** -> `powerbi/Salesperson_Performance.pbix`.
2. **File > Export > Export to PDF** -> `powerbi/Dashboard.pdf`.
3. Screenshot (Win+Shift+S) -> `images/dashboard.png` (ye naam README me use hua hai, isi naam se save karo).

---
## PART 5: PDF Report
1. Mera ready report: `report/Salesperson_Performance_Report.pdf` (5 pages: summary, KPIs, ranking, territory, discount, recommendations, limitations).
2. Isme apna Power BI dashboard jodo: **ilovepdf.com > Merge PDF** -> pehle `Salesperson_Performance_Report.pdf`, phir `Dashboard.pdf` upload -> Merge -> download -> naam: `Salesperson_Performance_Report_Final.pdf` -> `report/` me rakho.
3. Report me jo likha hai wo khud ek baar padho. Interview me poochenge: "Revenue alone kyun kam hai?" aur "Territory comparison ko kaise affect karti hai?" - Section 9 me short answers hain.

---
## PART 6: GitHub
1. github.com pe login -> top right **+ > New repository**.
2. Name: `salesperson-performance-analysis` | Description: "Fair salesperson evaluation using SQL, Excel and Power BI" | **Public** | README ka tick **mat** lagao -> **Create repository**.
3. Page pe **"uploading an existing file"** link -> poore folder ki saari files/folders drag & drop karo (README.md bhi). Folders drag karoge to structure bana rahega.
4. Neeche **Commit changes** (message: "Add salesperson performance analysis project").
5. `images/dashboard.png` upload ho gaya hai ya nahi check karo, tab README me dashboard dikhega.
6. Repo ke right side **About (gear icon)** -> topics: `power-bi`, `sql`, `excel`, `data-analytics`, `sales-analysis`.
7. Repo ka link copy karo - LinkedIn post me lagana hai.
(Git command line aati ho to: `git init`, `git add .`, `git commit -m "Initial commit"`, `git branch -M main`, `git remote add origin <repo-url>`, `git push -u origin main`.)

---
## PART 7: LinkedIn post
1. `linkedin_post.txt` kholo. `[GitHub link]` ki jagah apna repo link daalo (ya post ke baad pehle comment me link do).
2. LinkedIn -> **Start a post** -> text paste karo.
3. **Image icon** -> `images/dashboard.png` (+ ek-do chart) attach karo. Ya **+ > Add a document** -> final PDF report upload (carousel jaisa dikhta hai).
4. **@Veda Technology** tag karo (@ type karke company select karo).
5. Post karne se pehle numbers ek baar apni report se match kar lo.
6. Mentor aur team ko tag karna ho to karo; hashtags 4-6 kaafi hain.

---
## Final checklist
- [ ] SQL script MySQL me chali, ranking match hui
- [ ] Excel workbook dekh liya, Scorecard samajh aaya
- [ ] Power BI dashboard + .pbix + dashboard PDF
- [ ] Final PDF report (report + dashboard merged)
- [ ] GitHub repo public, README me dashboard dikh raha hai
- [ ] LinkedIn post live, link submission portal pe daal diya
