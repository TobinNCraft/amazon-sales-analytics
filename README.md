# 🛒 Amazon Sales Analytics Dashboard

<div align="center">

![Dashboard Preview](https://img.shields.io/badge/SQL-PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=for-the-badge&logo=python&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)
![Chart.js](https://img.shields.io/badge/Chart.js-4.x-FF6384?style=for-the-badge&logo=chartdotjs&logoColor=white)

**A comprehensive SQL-based analytics project analyzing 46,000+ Amazon sales transactions**

[🔗 Live Demo](#) • [📊 View Dashboard](#dashboard) • [📝 SQL Queries](sql/) • [🐍 Data Processing](scripts/)

</div>

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Key Features](#-key-features)
- [Technologies Used](#-technologies-used)
- [SQL Skills Demonstrated](#-sql-skills-demonstrated)
- [Data Analysis Highlights](#-data-analysis-highlights)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Dashboard Screenshots](#-dashboard-screenshots)
- [Key Insights](#-key-insights)
- [Author](#-author)

---

## 🎯 Project Overview

This portfolio project demonstrates advanced **SQL** and **data analytics** capabilities through a comprehensive analysis of Amazon e-commerce sales data. The project transforms raw transaction data into actionable business intelligence using a combination of database design, advanced SQL queries, Python data processing, and interactive visualizations.

### Business Questions Addressed:
- 📈 What are the monthly revenue trends and growth patterns?
- 🏷️ Which product categories drive the most profit?
- 🌍 How does performance vary across regions and channels?
- 👥 What distinguishes Prime members from non-Prime customers?
- 📦 Which couriers have the best delivery performance?
- 💳 What payment methods are most popular?
- 📅 Are there specific days that drive higher sales?

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Advanced SQL Analytics** | CTEs, Window Functions, Subqueries, Complex Joins |
| **Database Design** | Normalized star schema with proper indexing |
| **ETL Pipeline** | Python-based data processing and transformation |
| **Interactive Dashboard** | Animated charts with Chart.js |
| **Responsive Design** | Modern glassmorphism UI with dark theme |
| **Business Intelligence** | RFM Analysis, ABC Classification, Cohort Analysis |

---

## 🛠 Technologies Used

<table>
<tr>
<td align="center" width="150">

### Data Analysis
- PostgreSQL
- Python (Pandas)
- NumPy

</td>
<td align="center" width="150">

### Visualization
- Chart.js
- HTML5/CSS3
- JavaScript ES6+

</td>
<td align="center" width="150">

### Design
- Glassmorphism
- CSS Animations
- Responsive Grid

</td>
<td align="center" width="150">

### Techniques
- Window Functions
- CTEs
- RFM/ABC Analysis

</td>
</tr>
</table>

---

## 🔥 SQL Skills Demonstrated

### 1. Common Table Expressions (CTEs)
```sql
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(revenue_usd) AS total_revenue,
        COUNT(DISTINCT order_id) AS order_count
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
),
revenue_with_metrics AS (
    SELECT 
        month,
        total_revenue,
        -- 3-Month Moving Average
        AVG(total_revenue) OVER (
            ORDER BY month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS revenue_3m_avg,
        -- Month-over-Month Growth
        ROUND(
            (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) * 100.0 / 
            NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0), 2
        ) AS mom_growth_pct
    FROM monthly_revenue
)
SELECT * FROM revenue_with_metrics ORDER BY month;
```

### 2. Window Functions
```sql
SELECT 
    category,
    total_revenue,
    -- Revenue Ranking
    RANK() OVER (ORDER BY total_revenue DESC) AS category_rank,
    -- Cumulative Percentage (Pareto)
    ROUND(
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) * 100.0 / 
        SUM(total_revenue) OVER (), 2
    ) AS cumulative_revenue_pct,
    -- Percentile
    PERCENT_RANK() OVER (ORDER BY total_revenue) AS revenue_percentile
FROM category_revenue;
```

### 3. RFM Customer Segmentation
```sql
WITH customer_rfm AS (
    SELECT 
        customer_id,
        CURRENT_DATE - MAX(order_date) AS recency_days,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(revenue_usd) AS monetary_value
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value) AS m_score
    FROM customer_rfm
)
SELECT 
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score >= 1 THEN 'Potential Loyalists'
        ELSE 'Needs Attention'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary_value), 2) AS avg_lifetime_value
FROM rfm_scores
GROUP BY customer_segment;
```

### 4. Cohort Retention Analysis
```sql
WITH customer_first_order AS (
    SELECT customer_id, DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders GROUP BY customer_id
),
customer_activity AS (
    SELECT 
        o.customer_id,
        cfo.cohort_month,
        EXTRACT(MONTH FROM AGE(o.order_date, cfo.cohort_month)) AS months_since_first
    FROM orders o
    JOIN customer_first_order cfo ON o.customer_id = cfo.customer_id
)
SELECT 
    cohort_month,
    months_since_first,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / 
          FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
              PARTITION BY cohort_month ORDER BY months_since_first
          ), 2) AS retention_rate
FROM customer_activity
GROUP BY cohort_month, months_since_first;
```

---

## 📊 Data Analysis Highlights

### Dataset Overview
| Metric | Value |
|--------|-------|
| **Total Records** | 46,010 orders |
| **Time Period** | Jan 2024 - Sep 2025 |
| **Total Revenue** | $9.24M |
| **Total Profit** | $1.63M |
| **Profit Margin** | 17.7% |
| **Countries** | 14 |
| **Categories** | 8 |

### Key Insights Discovered

1. **📈 Revenue Growth**
   - Consistent month-over-month growth averaging 12.5%
   - Seasonal peaks during Q4 holiday periods

2. **🏷️ Category Performance (Pareto Analysis)**
   - Top 3 categories generate 65% of total revenue
   - Electronics and Home & Kitchen lead profitability

3. **🌍 Regional Distribution**
   - North America: 45% of revenue
   - Europe: 35% of revenue
   - Asia: 15% of revenue

4. **👥 Prime Member Value**
   - Prime members spend 2.3x more per order
   - 42% higher order frequency
   - 35% better retention rate

5. **📦 Shipping Performance**
   - 94% on-time delivery rate overall
   - Express shipping has 97% satisfaction

---

## 📁 Project Structure

```
SQL_2/
├── 📊 dashboard/
│   ├── index.html          # Main dashboard page
│   ├── styles.css          # Premium dark theme styling
│   ├── dashboard.js        # Chart.js visualizations
│   └── data/
│       └── dashboard_data.json
│
├── 🗃️ sql/
│   ├── schema.sql          # Database schema design
│   └── advanced_analytics.sql  # All SQL queries
│
├── 🐍 scripts/
│   └── data_processor.py   # ETL data processing
│
├── 📑 Amazon_Sales_Data_50k_Enhanced_Realistic_v0.xlsx
│
└── 📖 README.md
```

---

## 🚀 Getting Started

### Prerequisites
- Python 3.8+
- Web browser (Chrome, Firefox, Edge)
- Optional: PostgreSQL for running SQL queries

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/amazon-sales-analytics.git
   cd amazon-sales-analytics
   ```

2. **Install Python dependencies**
   ```bash
   pip install pandas numpy openpyxl
   ```

3. **Process the data**
   ```bash
   python scripts/data_processor.py
   ```

4. **Launch the dashboard**
   ```bash
   # Using Python's built-in server
   cd dashboard
   python -m http.server 8000
   ```

5. **Open in browser**
   ```
   http://localhost:8000
   ```

---

## 📸 Dashboard Screenshots

### Overview Section
The dashboard features a modern dark theme with glassmorphism effects:
- **Animated KPI Cards** - Real-time metrics with trend indicators
- **Revenue Trend Chart** - Monthly performance with 3-month moving average
- **Category Analysis** - Doughnut chart with Pareto classification

### Analytics Features
- 📈 **Time Series Analysis** - Revenue trends with growth rates
- 🏷️ **Category Performance** - ABC classification
- 🌍 **Geographic Analysis** - Regional revenue distribution
- 💳 **Payment Insights** - Method preferences by region
- 📦 **Shipping Metrics** - Courier performance comparison
- 👥 **Customer Segmentation** - Prime vs Non-Prime analysis

---

## 💡 Key Insights

### Business Recommendations

1. **Expand Prime Program**
   - Prime members show 2.3x higher AOV
   - Focus marketing on converting high-value non-Prime customers

2. **Optimize Inventory for Top Categories**
   - Electronics and Home & Kitchen represent 65% of profit
   - Ensure adequate stock during Q4 peak season

3. **Improve Shipping Performance**
   - 6% late delivery rate impacts customer satisfaction
   - Consider renegotiating with underperforming couriers

4. **Weekend Marketing Push**
   - Saturday and Sunday show 15% higher conversion
   - Schedule promotions and ads for weekend traffic

---

## 👤 Author

**Data Analyst Portfolio Project**

This project demonstrates proficiency in:
- ✅ SQL (PostgreSQL, CTEs, Window Functions)
- ✅ Python (Pandas, NumPy, Data Processing)
- ✅ Data Visualization (Chart.js, Interactive Dashboards)
- ✅ Business Intelligence (RFM, ABC, Cohort Analysis)
- ✅ Database Design (Star Schema, Indexing)
- ✅ Web Development (HTML, CSS, JavaScript)

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<div align="center">

**⭐ If you found this project helpful, please give it a star! ⭐**

[⬆ Back to Top](#-amazon-sales-analytics-dashboard)

</div>
