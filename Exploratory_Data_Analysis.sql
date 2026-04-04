-- Exploratory Data Analysis
-- total_laid_off → Absolute number of employees laid off.
-- percentage_laid_off → Share of the total workforce that was laid off (e.g. 0.08 = 8%).
-- funds_raised_millions → Total funding raised by the company, in millions of dollars.

-- Before to start the analysis, let's improve de db

-- Improve the percentage column

UPDATE layoffs_stagging2
SET percentage_laid_off = CAST(percentage_laid_off AS DECIMAL(5,4))
WHERE percentage_laid_off IS NOT NULL AND percentage_laid_off != 'NULL';



-- Look at all the data
SELECT *
FROM layoffs_stagging2;

-- Find the highest number of layoffs and the highest layoff percentage
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_stagging2;

-- Find companies that laid off 100% of their workers, ordered by most funded
-- Well here we don't have more columns to could find 100% this percentage
SELECT *
FROM layoffs_stagging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Total layoffs per company, biggest first
SELECT company, SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY company
ORDER BY 2 DESC;

-- Find the date range of the dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_stagging2;

-- Total layoffs per country, biggest first
SELECT country, SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY country
ORDER BY 2 DESC;

-- Total layoffs per industry, biggest first
SELECT industry, SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY industry
ORDER BY 2 DESC;

-- Total layoffs per year, most recent first
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY YEAR(`date`)	
ORDER BY 1 DESC;

-- Total layoffs by company stage, biggest first
SELECT stage, SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY stage
ORDER BY 2 DESC;

-- Monthly layoffs with a running total over time
WITH Rolling_Total AS 
(
-- Get total layoffs per month
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_stagging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)

-- Add an acumulative sum that grows month by month
SELECT `MONTH`, total_off,
SUM(total_off) OVER (ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- Top 5 companies with most layoffs, ranked per year
WITH Company_Laid_Off_Year (company, years, total_laid_off) AS
(
-- Total layoffs per company per year
SELECT company, YEAR(`date`),  SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
-- Rank companies within each year
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS
Ranking_Laid_Offs
FROM Company_Laid_Off_Year
WHERE years IS NOT NULL)

-- Show only the top 5 per year
SELECT *
FROM Company_Year_Rank
WHERE Ranking_Laid_Offs <= 5;

-- Efficieny ratio between total layoffs vs funds raised millions

-- See which are the companies with the best ratio

SELECT company, funds_raised_millions, total_laid_off,
ROUND(total_laid_off / funds_raised_millions, 2) AS layoffs_per_million
FROM layoffs_stagging2
WHERE  funds_raised_millions > 0 AND total_laid_off IS NOT NULL
ORDER BY layoffs_per_million DESC;

-- See which are the companies with the worst ratio

SELECT company, funds_raised_millions, total_laid_off,
ROUND(total_laid_off / funds_raised_millions, 2) AS layoffs_per_million
FROM layoffs_stagging2
WHERE  funds_raised_millions > 0 AND total_laid_off IS NOT NULL
ORDER BY layoffs_per_million ASC;

-- How many times laid off each company

SELECT company, COUNT(*) AS layoff_events, SUM(total_laid_off) AS total
FROM layoffs_stagging2
GROUP BY company
HAVING COUNT(*) > 2
ORDER BY layoff_events DESC;

-- Total layoffs per company per quarter

SELECT YEAR(`date`) AS year, QUARTER(`date`) AS quarter, SUM(total_laid_off)
FROM layoffs_stagging2
WHERE total_laid_off IS NOT NULL
GROUP BY year, quarter
ORDER BY year, quarter ASC;

-- Which stage layoff more in proportion, comparing the avg percentage laid off 
-- from each stage	

SELECT stage, ROUND(AVG(percentage_laid_off), 2) AS avg_pct,
SUM(total_laid_off) AS total
FROM layoffs_stagging2
WHERE percentage_laid_off IS NOT NULL AND stage IS NOT NULL
GROUP BY stage 
ORDER BY avg_pct DESC;

-- For each million funding, how many people was laid off in each country

SELECT country, SUM(total_laid_off) AS total_laid_off,
SUM(funds_raised_millions) AS total_funding,
ROUND(SUM(total_laid_off) / SUM(funds_raised_millions), 2) AS ratio
FROM layoffs_stagging2
WHERE total_laid_off IS NOT NULL AND funds_raised_millions > 0
GROUP BY country
ORDER BY ratio DESC;

-- How many companies closed definetly from each industry

SELECT industry, COUNT(*) AS companies_shutdown
FROM layoffs_stagging2
WHERE percentage_laid_off = 1
GROUP BY industry
ORDER BY companies_shutdown DESC;

-- Now let's create a view, with KPI (Key Performance Indicator) which are the alies
-- In this case we could used it for few of ours queries, but we'll do it for
-- If another partner take this code and has no idea off the queries we made before
-- Be allow to continue or tu query using this view prepared for him and also
-- When will expand to make a graphic with this db, with Power or Tableau, we'll be
-- Much easier to connect it and make it without doing anything more in SQL!
-- In addittion, if we refresh our db, instead of change 10 queries, the view will be updated itself

CREATE VIEW v_layoffs_summary AS 
SELECT company, location, industry, country, stage, `date`,
YEAR(`date`) AS year, QUARTER(`date`) AS quarter, total_laid_off,
percentage_laid_off AS pct_laid_off, funds_raised_millions AS funds_per_million,
-- The most notable thing here is if a company is closed definetly, i will be a column that says yes, 
-- And if it not, it will say no
CASE WHEN percentage_laid_off = 1
	THEN 'YES' 
    ELSE 'NO' 
END AS full_shutdown,
-- -- Here we calculate the efficiency ratio, returning NULL if data is missing
CASE WHEN funds_raised_millions > 0 AND total_laid_off IS NOT NULL
	THEN ROUND(total_laid_off / funds_raised_millions, 4)
    ELSE NULL
END AS layoffs_per_million_raised
FROM layoffs_stagging2;

-- And we check it

SELECT * 
FROM v_layoffs_summary;

-- To conclude, let's do the indexes, because now it's a small db
-- But in case we would have a inmense db, with the indexes, the query 
-- Will be more faster and easier for MySQL to find each data
-- And nomrally we do it with the most used data

ALTER TABLE layoffs_stagging2
ADD INDEX idx_date (`date`),
ADD INDEX idx_country (country(50)),
ADD INDEX idx_industry (industry(50)),
ADD INDEX idx_stage (stage(50));