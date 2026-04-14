# -> Layoffs Data Analysis — Cleaning & Exploratory Aanalysis in SQL

Project made as a practice from data analytics by a 18 years old student in process of being a **Data Analyst**.
Starting with a real dataset of massive layoffs in tecnology nitch, we'll do a complete **data cleaning**, followed by an **exploratory analysis** in **MySQL**, aplying habituals techniques in professional enviroments of analysis

---

## -> Dataset

The original file (`layoffs.csv`) contains lots of registers of layoffs of technology companies around the world, with the next columns:

| Column | Description |
|--------|-------------|
| `company` | Company name |
| `location` | city area |
| `industry` | Company sector |
| `total_laid_off` | Absolute number of employees laid off |
| `percentage_laid_off` | percentage of employees laid off |
| `date` | Date of the layoff event |
| `stage` | Company funding stage (Seed, Series A… Post-IPO) |
| `country` | Company's country |
| `funds_raised_millions` | Total funding raised, in millions of dollars |

The dataset covers **60 countries** and **32 different industries**, with company stages ranging from `Seed` to `Post-IPO`.

---

## -> Phase 1 — Data Cleaning (`DataCleaning.sql`)

Before doing any analysis, it's essential to make sure the data is clean and reliable. The cleaning process follows these four standard steps:

### 1. Removing Duplicates
All the work is done on a staging table (`layoffs_stagging`) to keep the original data safe. We use `ROW_NUMBER()` with `PARTITION BY` across all relevant columns to detect duplicate rows: 
  - any record with `row_num > 1` is an exact duplicate.
Since MySQL doesn't allow deleting directly from a CTE, a second table (`layoffs_stagging2`) is created with the `row_num` column already stored, so we can delete the duplicates from there.

### 2. Standardizing Data
- `TRIM()` is applied to the `company` column to remove leading and trailing spaces from company names.
- Different versions of the `Crypto` industry (`Crypto Currency`, `CryptoCurrency`…) are unified under a single standard value.
- `TRIM(TRAILING '.' FROM country)` is used to remove the trailing dot that appeared in some country names.
- The `date` column is converted from `TEXT` to a proper `DATE` type using `STR_TO_DATE()` and `ALTER TABLE MODIFY COLUMN`.
- 
- *(In production this would be handled during the import, but here it's practiced manually as a learning exercise.)*

### 3. Handling Null and Blank Values
- Blank values in the `industry` column are first converted to `NULL` so they can be handled consistently.
- A self-join is used to fill in missing industries: if the same company appears in another record with an industry value, that value is used to fill the null.
- Rows where both `total_laid_off` and `percentage_laid_off` are `NULL` are deleted, since they don't provide any useful information for the analysis.

### 4. Removing Irrelevant Columns
Once the cleaning is done, the helper column `row_num` that was added to detect duplicates is dropped, leaving the table ready for analysis.

---

## -> Phase 2 — Exploratory Data Analysis (`Exploratory_Data_Analysis.sql`)

With the clean data, queries of different complexity levels are run to extract valuable insights from the dataset.

### Basic Context Queries
- Maximum absolute layoffs and maximum layoff percentage recorded.
- Companies that laid off **100% of their workforce** (`percentage_laid_off = 1`), ordered by funding to see how big they were.
- Time range of the dataset: earliest and latest dates recorded.

### Aggregations by Dimension
Total layoffs are grouped by different dimensions to understand the sectoral and geographical impact:

- **By company** — ranking of companies with the most total layoffs.
- **By country** — most affected countries.
- **By industry** — sectors with the highest impact.
- **By year** — year-over-year evolution.
- **By company stage** — which type of company (Seed, Series B, Post-IPO…) laid off the most.
- **By quarter** — quarterly distribution to detect seasonality patterns.

### Advanced Analysis with CTEs and Window Functions

**Monthly Rolling Total:** A CTE is used to calculate total layoffs per month, then `SUM() OVER (ORDER BY month)` is applied on top of it to get a growing cumulative total. 
This makes it easy to see the evolution of the layoff crisis over time.

**Top 5 Companies per Year:** A CTE aggregates layoffs by company and year, and a second one applies `DENSE_RANK() OVER (PARTITION BY year ORDER BY total DESC)` to rank companies within each year. 
The final query filters only the top 5 per year.

### Efficiency Ratio: Layoffs per Million Raised
An original metric that connects the money raised with the layoffs produced, calculated as `total_laid_off / funds_raised_millions`. 
It helps identify which companies had the most layoffs relative to the capital they raised — a potential indicator of poor use of funding.

### Layoff Frequency per Company
Identifies which companies went through **more than two rounds of layoffs**, combining the number of events with the cumulative total.

### Full Shutdowns by Industry
Groups companies with `percentage_laid_off = 1` (complete closure) by industry, to see which sectors had the most definitive closures.

### Ratio by Country
Calculates, for each country, how many layoffs happened per million dollars raised in funding, as a measure of relative impact by region.

---

## -> View and Final Optimization

### View `v_layoffs_summary`
A view is created that brings together the most useful columns from the dataset along with two calculated fields:

- `full_shutdown` — returns `YES` if the company shut down completely, `NO` otherwise.
- `layoffs_per_million_raised` — layoffs per million raised ratio, with proper null handling.

The view works as an abstraction layer: another analyst can query it directly without knowing the underlying logic. 
It's also the natural connection point for visualization tools like **Power BI** or **Tableau**. 
If the source data is updated, the view refreshes itself automatically.

### -> Indexes
Indexes are added on the most queried columns (`date`, `country`, `industry`, `stage`) to improve query performance on larger databases.

---

## -> Techniques Used

- Staging tables to protect the original data
- `ROW_NUMBER()` with `PARTITION BY` for duplicate detection
- Self-joins to fill null values using existing context
- `STR_TO_DATE()` and `ALTER TABLE MODIFY COLUMN` for data type conversion
- CTEs (`WITH`) to break complex queries into readable steps
- Window functions: `SUM() OVER`, `DENSE_RANK() OVER (PARTITION BY)`
- Custom calculated ratios as business metrics
- Views (`CREATE VIEW`) as a semantic layer for BI tools
- Indexes for query optimization

---

## -> Technologies Used

- **MySQL 8+**
- **MySQL Workbench**
- Dataset in **CSV** format (imported from Excel/CSV)

--- 
