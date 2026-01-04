-- ============================================================================
-- AMAZON SALES DATA - ADVANCED SQL ANALYTICS QUERIES
-- ============================================================================
-- Author: Data Analyst Portfolio Project
-- Description: Advanced SQL queries demonstrating analytical capabilities
-- Skills: CTEs, Window Functions, Aggregations, Subqueries, Date Functions
-- ============================================================================
-- ============================================================================
-- 1. REVENUE ANALYTICS - Monthly Trends with Moving Averages
-- ============================================================================
WITH monthly_revenue AS (
    SELECT DATE_TRUNC('month', order_date) AS month,
        SUM(revenue_usd) AS total_revenue,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(profit) AS total_profit
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
),
revenue_with_metrics AS (
    SELECT month,
        total_revenue,
        order_count,
        total_profit,
        -- 3-Month Moving Average
        AVG(total_revenue) OVER (
            ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS revenue_3m_avg,
        -- Month-over-Month Growth Rate
        ROUND(
            (
                total_revenue - LAG(total_revenue) OVER (
                    ORDER BY month
                )
            ) * 100.0 / NULLIF(
                LAG(total_revenue) OVER (
                    ORDER BY month
                ),
                0
            ),
            2
        ) AS mom_growth_pct,
        -- Year-over-Year Growth (if applicable)
        LAG(total_revenue, 12) OVER (
            ORDER BY month
        ) AS revenue_last_year,
        -- Running Total
        SUM(total_revenue) OVER (
            ORDER BY month
        ) AS cumulative_revenue,
        -- Rank by Revenue
        RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS revenue_rank
    FROM monthly_revenue
)
SELECT *
FROM revenue_with_metrics
ORDER BY month;
-- ============================================================================
-- 2. CATEGORY PERFORMANCE ANALYSIS - Pareto Analysis (80/20 Rule)
-- ============================================================================
WITH category_revenue AS (
    SELECT p.category,
        SUM(o.revenue_usd) AS total_revenue,
        SUM(o.profit) AS total_profit,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.units_sold) AS units_sold
    FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.category
),
pareto_analysis AS (
    SELECT category,
        total_revenue,
        total_profit,
        order_count,
        units_sold,
        -- Percentage of total
        ROUND(
            total_revenue * 100.0 / SUM(total_revenue) OVER (),
            2
        ) AS revenue_pct,
        -- Cumulative percentage
        ROUND(
            SUM(total_revenue) OVER (
                ORDER BY total_revenue DESC
            ) * 100.0 / SUM(total_revenue) OVER (),
            2
        ) AS cumulative_revenue_pct,
        -- Profit margin
        ROUND(
            total_profit * 100.0 / NULLIF(total_revenue, 0),
            2
        ) AS profit_margin_pct,
        -- Category ranking
        DENSE_RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS category_rank
    FROM category_revenue
)
SELECT *,
    CASE
        WHEN cumulative_revenue_pct <= 80 THEN 'Top Performer (80%)'
        ELSE 'Supporting Category (20%)'
    END AS pareto_classification
FROM pareto_analysis
ORDER BY total_revenue DESC;
-- ============================================================================
-- 3. REGIONAL PERFORMANCE WITH MARKET PENETRATION
-- ============================================================================
WITH regional_metrics AS (
    SELECT r.region_name,
        r.country,
        r.channel,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.revenue_usd) AS total_revenue,
        SUM(o.profit) AS total_profit,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        AVG(o.revenue_usd) AS avg_order_value
    FROM orders o
        JOIN regions r ON o.region_id = r.region_id
    WHERE o.order_status = 'Completed'
    GROUP BY r.region_name,
        r.country,
        r.channel
),
regional_ranking AS (
    SELECT *,
        -- Revenue per customer
        ROUND(total_revenue / NULLIF(unique_customers, 0), 2) AS revenue_per_customer,
        -- Regional share
        ROUND(
            total_revenue * 100.0 / SUM(total_revenue) OVER (PARTITION BY region_name),
            2
        ) AS country_share_in_region,
        -- Global share
        ROUND(
            total_revenue * 100.0 / SUM(total_revenue) OVER (),
            2
        ) AS global_share,
        -- Rank within region
        RANK() OVER (
            PARTITION BY region_name
            ORDER BY total_revenue DESC
        ) AS rank_in_region,
        -- Global rank
        RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS global_rank
    FROM regional_metrics
)
SELECT *
FROM regional_ranking
ORDER BY total_revenue DESC;
-- ============================================================================
-- 4. CUSTOMER SEGMENTATION - RFM ANALYSIS
-- ============================================================================
WITH customer_rfm AS (
    SELECT c.customer_id,
        c.buyer_name,
        c.is_prime_member,
        -- Recency: Days since last order
        CURRENT_DATE - MAX(o.order_date) AS recency_days,
        -- Frequency: Number of orders
        COUNT(DISTINCT o.order_id) AS frequency,
        -- Monetary: Total spending
        SUM(o.revenue_usd) AS monetary_value
    FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id,
        c.buyer_name,
        c.is_prime_member
),
rfm_scores AS (
    SELECT *,
        -- RFM Scoring (1-5 scale using NTILE)
        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS r_score,
        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,
        NTILE(5) OVER (
            ORDER BY monetary_value
        ) AS m_score
    FROM customer_rfm
),
customer_segments AS (
    SELECT *,
        -- Combined RFM Score
        r_score * 100 + f_score * 10 + m_score AS rfm_score,
        -- Customer Segment Classification
        CASE
            WHEN r_score >= 4
            AND f_score >= 4
            AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 4
            AND f_score >= 3
            AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 3
            AND f_score >= 1
            AND m_score >= 1 THEN 'Potential Loyalists'
            WHEN r_score >= 4
            AND f_score <= 2
            AND m_score <= 2 THEN 'New Customers'
            WHEN r_score >= 3
            AND f_score >= 3
            AND m_score >= 3 THEN 'Promising'
            WHEN r_score >= 2
            AND f_score >= 2
            AND m_score >= 2 THEN 'Need Attention'
            WHEN r_score >= 2
            AND f_score <= 2
            AND m_score <= 2 THEN 'About to Sleep'
            WHEN r_score <= 2
            AND f_score >= 3
            AND m_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2
            AND f_score >= 4
            AND m_score >= 4 THEN 'Cannot Lose Them'
            WHEN r_score <= 2
            AND f_score <= 2
            AND m_score <= 2 THEN 'Hibernating'
            ELSE 'Lost'
        END AS customer_segment
    FROM rfm_scores
)
SELECT customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_value,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(recency_days), 0) AS avg_recency_days,
    SUM(
        CASE
            WHEN is_prime_member THEN 1
            ELSE 0
        END
    ) AS prime_members
FROM customer_segments
GROUP BY customer_segment
ORDER BY avg_monetary_value DESC;
-- ============================================================================
-- 5. PRODUCT PERFORMANCE - ABC ANALYSIS
-- ============================================================================
WITH product_metrics AS (
    SELECT p.product_id,
        p.product_name,
        p.category,
        p.brand,
        SUM(oi.units_sold) AS total_units_sold,
        SUM(oi.line_subtotal) AS total_sales,
        COUNT(DISTINCT oi.order_id) AS order_count,
        AVG(oi.discount_rate) AS avg_discount_rate
    FROM products p
        JOIN order_items oi ON p.product_id = oi.product_id
        JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_id,
        p.product_name,
        p.category,
        p.brand
),
abc_classification AS (
    SELECT *,
        -- Cumulative sales percentage
        ROUND(
            SUM(total_sales) OVER (
                ORDER BY total_sales DESC
            ) * 100.0 / SUM(total_sales) OVER (),
            2
        ) AS cumulative_sales_pct,
        -- Product ranking
        ROW_NUMBER() OVER (
            ORDER BY total_sales DESC
        ) AS product_rank,
        -- Percentile
        PERCENT_RANK() OVER (
            ORDER BY total_sales
        ) AS sales_percentile
    FROM product_metrics
)
SELECT *,
    -- ABC Classification
    CASE
        WHEN cumulative_sales_pct <= 70 THEN 'A - High Value'
        WHEN cumulative_sales_pct <= 90 THEN 'B - Medium Value'
        ELSE 'C - Low Value'
    END AS abc_class,
    -- Sales velocity indicator
    CASE
        WHEN total_units_sold > (
            SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (
                    ORDER BY total_units_sold
                )
            FROM product_metrics
        ) THEN 'Fast Moving'
        WHEN total_units_sold > (
            SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (
                    ORDER BY total_units_sold
                )
            FROM product_metrics
        ) THEN 'Medium Moving'
        ELSE 'Slow Moving'
    END AS velocity_class
FROM abc_classification
ORDER BY total_sales DESC
LIMIT 50;
-- ============================================================================
-- 6. TIME-SERIES ANALYSIS - Daily Patterns and Seasonality
-- ============================================================================
WITH daily_metrics AS (
    SELECT order_date,
        EXTRACT(
            DOW
            FROM order_date
        ) AS day_of_week,
        EXTRACT(
            MONTH
            FROM order_date
        ) AS month,
        EXTRACT(
            YEAR
            FROM order_date
        ) AS year,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(revenue_usd) AS daily_revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY order_date
),
day_analysis AS (
    SELECT day_of_week,
        CASE
            day_of_week
            WHEN 0 THEN 'Sunday'
            WHEN 1 THEN 'Monday'
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
        END AS day_name,
        AVG(order_count) AS avg_orders,
        AVG(daily_revenue) AS avg_revenue,
        STDDEV(daily_revenue) AS revenue_stddev
    FROM daily_metrics
    GROUP BY day_of_week
),
monthly_seasonality AS (
    SELECT month,
        TO_CHAR(TO_DATE(month::text, 'MM'), 'Month') AS month_name,
        AVG(daily_revenue) AS avg_daily_revenue,
        SUM(daily_revenue) AS total_monthly_revenue
    FROM daily_metrics
    GROUP BY month
)
SELECT 'Daily Pattern' AS analysis_type,
    day_name AS period,
    ROUND(avg_revenue, 2) AS avg_revenue,
    ROUND(avg_orders, 2) AS avg_orders,
    -- Index compared to average
    ROUND(
        avg_revenue * 100.0 / (
            SELECT AVG(avg_revenue)
            FROM day_analysis
        ),
        2
    ) AS index_vs_avg
FROM day_analysis
ORDER BY day_of_week;
-- ============================================================================
-- 7. PAYMENT METHOD ANALYSIS WITH COHORT COMPARISON
-- ============================================================================
WITH payment_analysis AS (
    SELECT payment_method,
        order_status,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(revenue_usd) AS total_revenue,
        AVG(revenue_usd) AS avg_order_value,
        SUM(payment_fees) AS total_fees,
        AVG(payment_fee_rate) AS avg_fee_rate
    FROM orders
    GROUP BY payment_method,
        order_status
),
payment_summary AS (
    SELECT payment_method,
        SUM(order_count) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(
            CASE
                WHEN order_status = 'Completed' THEN order_count
            END
        ) AS completed_orders,
        SUM(
            CASE
                WHEN order_status = 'Refunded' THEN order_count
            END
        ) AS refunded_orders,
        AVG(avg_fee_rate) AS avg_fee_rate
    FROM payment_analysis
    GROUP BY payment_method
)
SELECT *,
    -- Completion rate
    ROUND(
        completed_orders * 100.0 / NULLIF(total_orders, 0),
        2
    ) AS completion_rate,
    -- Refund rate
    ROUND(
        COALESCE(refunded_orders, 0) * 100.0 / NULLIF(total_orders, 0),
        2
    ) AS refund_rate,
    -- Revenue share
    ROUND(
        total_revenue * 100.0 / SUM(total_revenue) OVER (),
        2
    ) AS revenue_share,
    -- Ranking
    RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS payment_rank
FROM payment_summary
ORDER BY total_revenue DESC;
-- ============================================================================
-- 8. SHIPPING PERFORMANCE & DELIVERY ANALYTICS
-- ============================================================================
WITH shipping_analysis AS (
    SELECT s.courier,
        s.shipping_method,
        r.region_name,
        COUNT(DISTINCT s.order_id) AS total_shipments,
        SUM(
            CASE
                WHEN s.is_delivered THEN 1
                ELSE 0
            END
        ) AS delivered_count,
        SUM(
            CASE
                WHEN s.is_late THEN 1
                ELSE 0
            END
        ) AS late_count,
        AVG(s.days_to_deliver) AS avg_delivery_days,
        AVG(s.shipping_cost) AS avg_shipping_cost
    FROM shipping_info s
        JOIN orders o ON s.order_id = o.order_id
        JOIN regions r ON o.region_id = r.region_id
    GROUP BY s.courier,
        s.shipping_method,
        r.region_name
)
SELECT *,
    -- Delivery success rate
    ROUND(
        delivered_count * 100.0 / NULLIF(total_shipments, 0),
        2
    ) AS delivery_rate,
    -- On-time delivery rate
    ROUND(
        (total_shipments - late_count) * 100.0 / NULLIF(total_shipments, 0),
        2
    ) AS on_time_rate,
    -- Performance score
    ROUND(
        (
            delivered_count * 100.0 / NULLIF(total_shipments, 0)
        ) * 0.4 + (
            (total_shipments - late_count) * 100.0 / NULLIF(total_shipments, 0)
        ) * 0.4 + (1 - (avg_delivery_days / 30)) * 20,
        2
    ) AS performance_score
FROM shipping_analysis
WHERE total_shipments >= 10
ORDER BY performance_score DESC;
-- ============================================================================
-- 9. PRIME VS NON-PRIME CUSTOMER COMPARISON
-- ============================================================================
WITH prime_analysis AS (
    SELECT c.is_prime_member,
        CASE
            WHEN c.is_prime_member THEN 'Prime Member'
            ELSE 'Non-Prime'
        END AS membership_status,
        COUNT(DISTINCT c.customer_id) AS customer_count,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.revenue_usd) AS total_revenue,
        AVG(o.revenue_usd) AS avg_order_value,
        SUM(o.profit) AS total_profit,
        SUM(oi.units_sold) AS total_units
    FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.is_prime_member
)
SELECT membership_status,
    customer_count,
    total_orders,
    ROUND(total_orders * 1.0 / customer_count, 2) AS orders_per_customer,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(total_revenue / customer_count, 2) AS revenue_per_customer,
    ROUND(total_profit, 2) AS total_profit,
    ROUND(total_profit * 100.0 / total_revenue, 2) AS profit_margin_pct,
    ROUND(total_units * 1.0 / total_orders, 2) AS units_per_order
FROM prime_analysis;
-- ============================================================================
-- 10. COHORT RETENTION ANALYSIS
-- ============================================================================
WITH customer_first_order AS (
    SELECT customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
customer_activity AS (
    SELECT o.customer_id,
        cfo.cohort_month,
        DATE_TRUNC('month', o.order_date) AS activity_month,
        EXTRACT(
            YEAR
            FROM AGE(
                    DATE_TRUNC('month', o.order_date),
                    cfo.cohort_month
                )
        ) * 12 + EXTRACT(
            MONTH
            FROM AGE(
                    DATE_TRUNC('month', o.order_date),
                    cfo.cohort_month
                )
        ) AS months_since_first
    FROM orders o
        JOIN customer_first_order cfo ON o.customer_id = cfo.customer_id
    WHERE o.order_status = 'Completed'
),
cohort_data AS (
    SELECT cohort_month,
        months_since_first,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM customer_activity
    GROUP BY cohort_month,
        months_since_first
),
cohort_sizes AS (
    SELECT cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_first_order
    GROUP BY cohort_month
)
SELECT cd.cohort_month,
    cd.months_since_first,
    cd.active_customers,
    cs.cohort_size,
    ROUND(cd.active_customers * 100.0 / cs.cohort_size, 2) AS retention_rate
FROM cohort_data cd
    JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.months_since_first <= 12
ORDER BY cd.cohort_month,
    cd.months_since_first;
-- ============================================================================
-- END OF ADVANCED ANALYTICS QUERIES
-- ============================================================================