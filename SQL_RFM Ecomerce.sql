
WITH trans_table as (
SELECT  OrderCreatedDate
      ,[OrderShippingDate]
      ,[OrderID]
      ,[OrderChannel]
      ,[OrderMethod]
      ,[RestaurantName]
      ,[OrderCreatedDay]
      ,[OrderCreatedTime]
      ,[OrderShippingTime]
      ,[OrderStatusDate]
      ,[OrderStatus]
      ,[CustomerName]
      ,[CustomerPhone]
      ,[OrderTotal]
  FROM [MIS].[dbo].[Transactions]
  WHERE  OrderStatus = N'Hoàn tất' AND 
    --OrderChannel = 'Online' AND
    OrderShippingDate BETWEEN '2023-01-01' AND '2024-06-30'
)
, rfm_table as (
    SELECT CustomerPhone
        , DATEDIFF(DAY, MAX(OrderCreatedDate), '2024-06-30')+1 recency
        , COUNT( DISTINCT OrderID)/((DATEDIFF(DAY,IIF( YEAR(MIN(OrderCreatedDate)) < 2023, '2023-01-01', MIN(OrderCreatedDate)), '2024-06-30' )+1)*1.0/365)  frequency_per_year
        , SUM(OrderTotal*1.0) monetary
    FROM trans_table
    GROUP BY CustomerPhone
)
, rank_table AS (
   SELECT *
       , NTILE(5) OVER (ORDER BY recency DESC) r_rank
       , NTILE(5) OVER (ORDER BY frequency_per_year ) f_rank
       , NTILE(5) OVER (ORDER BY monetary ) m_rank
   FROM rfm_table
)
, date_table as (
  SELECT  [CustomerPhone]
    , MIN(OrderCreatedDate) start_date
    , '2024-06-30' end_date
    , MAX(OrderCreatedDate) last_date
    , DATEDIFF(DAY,MIN(OrderCreatedDate), '2024-06-30' )+1 ops_day
    , (DATEDIFF(DAY,MIN(OrderCreatedDate), '2024-06-30' )+1)*1.0/365  year_w_me
    , DATEDIFF(DAY, IIF(YEAR(MIN(OrderCreatedDate)) < 2023, '2023-01-01', MIN(OrderCreatedDate)),'2024-06-30')*1.0+1  year_normalize      
  FROM [MIS].[dbo].[Transactions]
  WHERE  OrderStatus = N'Hoàn tất' --AND OrderCreatedDate BETWEEN '2023-01-01' AND '2024-06-30' 
  GROUP BY CustomerPhone 
)
, TA_table as (
    SELECT CustomerPhone
        , COUNT( DISTINCT CONVERT (varchar(10),OrderCreatedDate)) TC
        , SUM(OrderTotal*1.0)/(COUNT( DISTINCT CONVERT (varchar(10),OrderCreatedDate))*1.0) TA
    FROM trans_table
    GROUP BY CustomerPhone
)
   SELECT ra.CustomerPhone
        , dat.start_date, dat.last_date, dat.end_date, dat.ops_day, dat.year_w_me, dat.year_normalize
        , recency, frequency_per_year, monetary
        , ta.TC, ta.TA
        , NTILE(5) OVER (ORDER BY ta.TA) ta_rank
        , r_rank, f_rank, m_rank
        , CONCAT ( r_rank, f_rank, m_rank) AS rfm_score
    INTO #save_table
   FROM rank_table ra
    LEFT JOIN date_table dat
        ON ra.CustomerPhone = dat.CustomerPhone
    LEFT JOIN TA_table ta
        ON ra.CustomerPhone = ta.CustomerPhone
--WHERE ra.CustomerPhone = '0978970681'
DROP TABLE #save_table

SELECT *
FROM #save_table
WHERE CustomerPhone