-- =====================================================
-- 📊 Instagram Performance Analysis using SQL
-- Author: Alfiya Inamdar
-- Description: SQL queries to analyze Instagram content performance
-- =====================================================


-- =====================================================
-- Q1. Unique post types in fact_content
-- =====================================================
SELECT DISTINCT post_type
FROM fact_content;


-- =====================================================
-- Q2. Highest and lowest impressions by post type
-- =====================================================
SELECT 
    post_type,
    MAX(impressions) AS highest_impressions,
    MIN(impressions) AS lowest_impressions
FROM fact_content
GROUP BY post_type;


-- =====================================================
-- Q3. Weekend posts in March & April
-- =====================================================
SELECT 
    a.*,
    b.month_name
FROM fact_content a
JOIN dim_dates b
    ON a.date = b.date
WHERE b.month_name IN ('March', 'April')
  AND b.weekday_or_weekend = 'Weekend';


-- =====================================================
-- Q4. Monthly account statistics
-- Fields: month_name, total_profile_visits, total_new_followers
-- =====================================================
SELECT 
    b.month_name,
    SUM(a.profile_visits) AS total_profile_visits,
    SUM(a.new_followers) AS total_new_followers
FROM fact_account a
JOIN dim_dates b
    ON a.date = b.date
GROUP BY b.month_name
ORDER BY total_profile_visits DESC;


-- =====================================================
-- Q5. Total likes by post category in July (CTE)
-- =====================================================
WITH category_likes AS (
    SELECT 
        a.post_category,
        SUM(a.likes) AS total_likes
    FROM fact_content a
    JOIN dim_dates b
        ON a.date = b.date
    WHERE b.month_name = 'July'
    GROUP BY a.post_category
)

SELECT *
FROM category_likes
ORDER BY total_likes DESC;


-- =====================================================
-- Q6. Monthly unique post categories and count
-- =====================================================
SELECT 
    b.month_name,
    GROUP_CONCAT(DISTINCT a.post_category ORDER BY a.post_category SEPARATOR ', ') AS post_category_names,
    COUNT(DISTINCT a.post_category) AS post_category_count
FROM fact_content a
JOIN dim_dates b
    ON a.date = b.date
GROUP BY b.month_name;


-- =====================================================
-- Q7. Percentage breakdown of total reach by post type
-- =====================================================
SELECT 
    post_type,
    SUM(reach) AS total_reach,
    ROUND(
        SUM(reach) * 100.0 / (SELECT SUM(reach) FROM fact_content),
        2
    ) AS reach_percentage
FROM fact_content
GROUP BY post_type;


-- =====================================================
-- Q8. Quarterly comments and saves by post category
-- =====================================================
SELECT 
    a.post_category,
    CASE
        WHEN b.month_name IN ('January','February','March') THEN 'Q1'
        WHEN b.month_name IN ('April','May','June') THEN 'Q2'
        WHEN b.month_name IN ('July','August','September') THEN 'Q3'
    END AS quarter,
    SUM(a.comments) AS total_comments,
    SUM(a.saves) AS total_saves
FROM fact_content a
JOIN dim_dates b
    ON a.date = b.date
GROUP BY a.post_category, quarter
ORDER BY a.post_category, quarter;


-- =====================================================
-- Q9. Top 3 dates per month by new followers
-- =====================================================
WITH follower_rank AS (
    SELECT 
        b.month_name,
        a.date,
        SUM(a.new_followers) AS total_new_followers,
        DENSE_RANK() OVER (
            PARTITION BY b.month_name 
            ORDER BY SUM(a.new_followers) DESC
        ) AS rank_no
    FROM fact_account a
    JOIN dim_dates b
        ON a.date = b.date
    GROUP BY b.month_name, a.date
)

SELECT 
    month_name,
    date,
    total_new_followers
FROM follower_rank
WHERE rank_no <= 3;


-- =====================================================
-- Q10. Stored Procedure: Total shares by post type (week-wise)
-- =====================================================
DELIMITER //

CREATE PROCEDURE get_total_shares_by_week(IN input_week VARCHAR(5))
BEGIN
    SELECT 
        a.post_type,
        SUM(a.shares) AS total_shares
    FROM fact_content a
    JOIN dim_dates b
        ON a.date = b.date
    WHERE b.week_no = input_week
    GROUP BY a.post_type;
END //

DELIMITER ;

-- Example call:
CALL get_total_shares_by_week('W15');