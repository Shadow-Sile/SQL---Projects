-- DATA CLEANING

SELECT * 
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standarize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Irrelevant Columns and Rows

CREATE TABLE layoffs_stagging
LIKE layoffs;

SELECT * 
FROM layoffs_stagging;

-- Add all the data from layoffs, to layoffs_stagging too

INSERT layoffs_stagging
SELECT * 
FROM layoffs;	

-- We create a CTE to save our subquery where we'll find those duplicates tables

WITH duplicate_cte AS
(
SELECT * ,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging 
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1; -- So here, as each row has a unique value, every unique row should be 1, and if the row_num
-- Is 2 or higher, that means there are more than rows which are the same

-- Here just a proof where we see an example of duplicates rows in Casper's company

SELECT * 
FROM layoffs_stagging
WHERE company = 'Casper';

-- WE can't delete directly those duplicate rows so, we'll try to do another table where includes
-- The row-num uniques and in the other part the row_num where are 2 or higher and delete the last column

CREATE TABLE `layoffs_stagging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_stagging2
WHERE row_num > 1;

-- Let's insert the same data from layoffs_stagging to the version 2

INSERT INTO layoffs_stagging2
SELECT * ,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging;

-- To sum up, the function row number that whe did before, it isn't saved in a column so was not able to delete any duplicate column
-- To resolve that, this function we saved it in a new column of a new table so now we can delete them

DELETE 
FROM layoffs_stagging2
WHERE row_num > 1;

-- Standardizing data

-- Here wee see in few companie's names, are a space before the name, so let's fix this with a trim, 
-- First testing how would it be if we ad a trim
SELECT company, TRIM(company)
FROM layoffs_stagging2;

-- And now are clean

UPDATE layoffs_stagging2
SET company = TRIM(company);

-- The same with industry, where there are duplicate indutries and a few rows in blank

SELECT *
FROM layoffs_stagging2
WHERE industry LIKE 'Crypto%'
ORDER BY 1;

UPDATE layoffs_stagging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_stagging2
SET country = TRIM(TRAILING '.' FROM COUNTRY); -- Trailing '.' delete the char specified 
-- in order to a space, in these case, a dot

SELECT DISTINCT country
FROM layoffs_stagging2;

-- We'll change the type of data 'date' from text to date and change the format

SELECT `date`
FROM layoffs_stagging2;

UPDATE layoffs_stagging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_stagging2
MODIFY COLUMN `date` DATE; -- Finally, we passed from text to date format 100%
-- Was just to practice but always better when we import the sql
-- to try to change the type of each column in these import, not like now


-- No wit's tame to delete or manipulate those null or blank values
-- Firstly analyazing which columns it has it

SELECT * 
FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Before change the nulls, we put into null the blank values

UPDATE layoffs_stagging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_stagging2
WHERE industry IS null
OR industry = '';

SELECT *
FROM layoffs_stagging2
WHERE company = 'Airbnb';

-- This is just to see the difference between the values null and not null

SELECT t1.industry, t2.industry
FROM layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- And we update it

UPDATE layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Now we just delete the columns where there isn't any relevant info and still
-- practicing de data cleaning, in others projects i'll work with the laidoffs more deeper

DELETE
FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Finally, we drop this table that we don't need anymore

ALTER TABLE layoffs_stagging2
DROP COLUMN row_num;
