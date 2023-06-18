SELECT COUNT(transaction_id), YEAR(transaction_time), MONTH(transaction_time)
FROM fact_transaction_2019
GROUP BY YEAR(transaction_time), MONTH(transaction_time)


-- 1. Top 5 types with the highest percentage of total

WITH joined_table AS ( 
SELECT fact_19.*, transaction_type
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena 
    ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS stat 
    ON fact_19.status_id = stat.status_id
WHERE status_description = 'success' 
)
, total_table AS (
SELECT transaction_type 
    , COUNT(transaction_id) AS number_trans
    , (SELECT COUNT(transaction_id) FROM joined_table) AS total_trans 
FROM joined_table
GROUP BY transaction_type
)
SELECT TOP 5 
    *
    , FORMAT ( number_trans*1.0/total_trans, 'p') AS pct  
FROM total_table
ORDER BY number_trans DESC 


-- 2. The number of payment categories 

WITH summary_table AS (
SELECT customer_id
    , COUNT(DISTINCT scena.category) AS number_categories
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena 
        ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS sta 
        ON fact_19.status_id = sta.status_id 
WHERE status_description = 'success'
    AND transaction_type = 'payment'
GROUP BY customer_id -- 
)
SELECT number_categories
    , COUNT(customer_id) AS number_customers
    , (SELECT COUNT(customer_id) FROM summary_table) AS total_customer 
    , FORMAT ( COUNT(customer_id)*1.0/(SELECT COUNT(customer_id) FROM summary_table), 'p') AS pct
FROM summary_table
GROUP BY number_categories 
ORDER BY number_categories


/* Bin the total charged amount and number of transactions then calculate the frequency of the total charged amount */ 

WITH summary_table AS (
SELECT customer_id
    , SUM(charged_amount) AS total_amount
    , CASE
        WHEN SUM(charged_amount) < 1000000 THEN '0-01M'
        WHEN SUM(charged_amount) >= 1000000 AND SUM(charged_amount) < 2000000 THEN '01M-02M'
        WHEN SUM(charged_amount) >= 2000000 AND SUM(charged_amount) < 3000000 THEN '02M-03M'
        WHEN SUM(charged_amount) >= 3000000 AND SUM(charged_amount) < 4000000 THEN '03M-04M'
        WHEN SUM(charged_amount) >= 4000000 AND SUM(charged_amount) < 5000000 THEN '04M-05M'
        WHEN SUM(charged_amount) >= 5000000 AND SUM(charged_amount) < 6000000 THEN '05M-06M'
        WHEN SUM(charged_amount) >= 6000000 AND SUM(charged_amount) < 7000000 THEN '06M-07M'
        WHEN SUM(charged_amount) >= 7000000 AND SUM(charged_amount) < 8000000 THEN '07M-08M'
        WHEN SUM(charged_amount) >= 8000000 AND SUM(charged_amount) < 9000000 THEN '08M-09M'
        WHEN SUM(charged_amount) >= 9000000 AND SUM(charged_amount) < 10000000 THEN '09M-10M'
        WHEN SUM(charged_amount) >= 10000000 THEN 'more > 10M'
        END AS charged_amount_range
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena
        ON fact_19.scenario_id = scena.scenario_id
WHERE status_id = '1'
    AND transaction_type = 'payment'
GROUP BY customer_id
)
SELECT charged_amount_range
    , COUNT(customer_id) AS number_customers
FROM summary_table
GROUP BY charged_amount_range 
ORDER BY charged_amount_range





-- Cohort Analysis
SELECT *
FROM fact_transaction_2019 -- 396,817 rows


WITH success as (
    SELECT fact19.*, sce.category, sce.sub_category
    FROM fact_transaction_2019 fact19
    LEFT JOIN dim_scenario sce 
        ON fact19.scenario_id = sce.scenario_id
    WHERE status_id = '1' -- 337,334 rows
)
, dup_check as (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY transaction_id, scenario_id, platform_id ORDER BY transaction_time) dup_flag
    FROM success
)

SELECT *
INTO #retail_main
FROM dup_check
WHERE dup_flag = 1 -- 337,335 rows

--Clean Data
-- Begin Cohort Analysis

SELECT *
FROM #retail_main

/* Unique Identifier (customer_id)
 Initial Start Date (First transaction_time)
 Revenue Data */

SELECT customer_id
    , MIN(transaction_time) first_purchase_date
    , DATEFROMPARTS(YEAR(MIN(transaction_time)), MONTH(MIN(transaction_time)), 1) cohort_date
INTO #cohort
FROM #retail_main
GROUP BY customer_id

SELECT *
FROM #cohort

-- Creat Cohort Index
SELECT mmm.*
    , cohort_index = year_diff *12 + month_diff +1
INTO #cohort_retention
FROM 
    (
        SELECT mm.*
            , year_diff = trans_year - cohort_year
            , month_diff = trans_month - cohort_month
        FROM 
            (
                SELECT m.*, c.cohort_date
                    , YEAR(m.transaction_time) trans_year
                    , MONTH(m.transaction_time) trans_month 
                    , YEAR(c.cohort_date) cohort_year
                    , MONTH(c.cohort_date) cohort_month
                FROM #retail_main m 
                LEFT JOIN #cohort c 
                    ON m.customer_id = c.customer_id
            ) mm 
      )  mmm

SELECT *
FROM #cohort_retention

---Pivot Data to see the cohort table
SELECT 	*
INTO #cohort_pivot
FROM(
	SELECT DISTINCT  
		customer_id,
		cohort_date,
		cohort_index
	FROM #cohort_retention
)tbl
PIVOT(
	COUNT(customer_id)
	FOR cohort_index in 
		(
		[1], 
        [2], 
        [3], 
        [4], 
        [5], 
        [6], 
        [7],
		[8], 
        [9], 
        [10], 
        [11], 
        [12])

) as pivot_table

SELECT *
FROM #cohort_pivot
ORDER BY cohort_date

SELECT cohort_date ,
	1.0 * [1]/[1] * 100 as [1], 
    1.0 * [2]/[1] * 100 as [2], 
    1.0 * [3]/[1] * 100 as [3],  
    1.0 * [4]/[1] * 100 as [4],  
    1.0 * [5]/[1] * 100 as [5], 
    1.0 * [6]/[1] * 100 as [6], 
    1.0 * [7]/[1] * 100 as [7], 
	1.0 * [8]/[1] * 100 as [8], 
    1.0 * [9]/[1] * 100 as [9], 
    1.0 * [10]/[1] * 100 as [10],   
    1.0 * [11]/[1] * 100 as [11],  
    1.0 * [12]/[1] * 100 as [12] 
FROM #cohort_pivot
ORDER BY cohort_date


SELECT distinct category
from dim_scenario


--Time series
SELECT 
    Year(transaction_time) AS year, Month(transaction_time) AS month
    , CONVERT (varchar(6), transaction_time, 112) AS timecalendar
    , DATEFROMPARTS(YEAR(MIN(transaction_time)), MONTH(MIN(transaction_time)),1) cohort_date
    , sub_category
    , COUNT(transaction_id) AS number_trans
FROM fact_transaction_2019 fact 
JOIN dim_scenario AS sce 
    ON fact.scenario_id = sce.scenario_id 
WHERE status_id = 1 
GROUP BY Year(transaction_time), Month(transaction_time), CONVERT (varchar(6), transaction_time, 112), sub_category
ORDER BY year, month 




