-- ============================================================================
-- AMAZON SALES DATA ANALYTICS - DATABASE SCHEMA
-- ============================================================================
-- Author: Data Analyst Portfolio Project
-- Description: PostgreSQL schema design for Amazon Sales Data Analysis
-- Demonstrates: Normalization, Indexing Strategy, Data Types, Constraints
-- ============================================================================
-- Drop existing tables if they exist (for clean slate)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS regions CASCADE;
DROP TABLE IF EXISTS shipping_info CASCADE;
-- ============================================================================
-- DIMENSION TABLES
-- ============================================================================
-- Regions Dimension Table
CREATE TABLE regions (
    region_id SERIAL PRIMARY KEY,
    region_name VARCHAR(50) NOT NULL,
    country VARCHAR(100) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    fx_to_usd DECIMAL(10, 6) NOT NULL DEFAULT 1.0,
    dial_code VARCHAR(10),
    channel VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(country, channel)
);
-- Create index for faster lookups
CREATE INDEX idx_regions_country ON regions(country);
CREATE INDEX idx_regions_channel ON regions(channel);
-- Products Dimension Table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    variant VARCHAR(100),
    sku VARCHAR(50) UNIQUE NOT NULL,
    asin VARCHAR(20),
    unit_price DECIMAL(12, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Indexes for product analytics
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_sku ON products(sku);
-- Customers Dimension Table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    buyer_name VARCHAR(255) NOT NULL,
    buyer_email VARCHAR(255) UNIQUE,
    phone_display VARCHAR(50),
    address TEXT,
    is_prime_member BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Indexes for customer analytics
CREATE INDEX idx_customers_prime ON customers(is_prime_member);
CREATE INDEX idx_customers_email ON customers(buyer_email);
-- ============================================================================
-- FACT TABLE - ORDERS
-- ============================================================================
CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    region_id INTEGER REFERENCES regions(region_id),
    order_date DATE NOT NULL,
    day_of_week INTEGER CHECK (
        day_of_week BETWEEN 1 AND 7
    ),
    payment_method VARCHAR(50) NOT NULL,
    payment_fee_rate DECIMAL(5, 4),
    payment_fees DECIMAL(12, 2),
    order_status VARCHAR(50) NOT NULL,
    revenue_local DECIMAL(15, 2) NOT NULL,
    revenue_usd DECIMAL(15, 2) NOT NULL,
    tax_rate DECIMAL(5, 4),
    tax_amount DECIMAL(12, 2),
    order_total_local DECIMAL(15, 2),
    order_total_usd DECIMAL(15, 2),
    profit DECIMAL(15, 2),
    refund_amount DECIMAL(12, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Comprehensive indexes for order analytics
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_payment ON orders(payment_method);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_region ON orders(region_id);
CREATE INDEX idx_orders_revenue ON orders(revenue_usd DESC);
-- Composite index for time-series analysis
CREATE INDEX idx_orders_date_status ON orders(order_date, order_status);
-- ============================================================================
-- ORDER ITEMS TABLE
-- ============================================================================
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id VARCHAR(20) REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    units_sold INTEGER NOT NULL CHECK (units_sold > 0),
    unit_price DECIMAL(12, 2) NOT NULL,
    discount_rate DECIMAL(5, 4) DEFAULT 0,
    discount_amount DECIMAL(12, 2) DEFAULT 0,
    line_subtotal DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Indexes for order items
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
-- ============================================================================
-- SHIPPING INFO TABLE
-- ============================================================================
CREATE TABLE shipping_info (
    shipping_id SERIAL PRIMARY KEY,
    order_id VARCHAR(20) REFERENCES orders(order_id),
    courier VARCHAR(100),
    shipping_method VARCHAR(50),
    fulfillment VARCHAR(50),
    shipping_cost DECIMAL(10, 2),
    shipping_date DATE,
    expected_delivery_date DATE,
    delivery_status VARCHAR(50),
    is_delivered BOOLEAN DEFAULT FALSE,
    is_late BOOLEAN DEFAULT FALSE,
    days_to_deliver INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Indexes for shipping analytics
CREATE INDEX idx_shipping_order ON shipping_info(order_id);
CREATE INDEX idx_shipping_status ON shipping_info(delivery_status);
CREATE INDEX idx_shipping_courier ON shipping_info(courier);
CREATE INDEX idx_shipping_late ON shipping_info(is_late);
-- ============================================================================
-- VIEWS FOR ANALYTICS
-- ============================================================================
-- Sales Summary View
CREATE OR REPLACE VIEW vw_sales_summary AS
SELECT o.order_date,
    r.region_name,
    r.country,
    r.channel,
    p.category,
    p.brand,
    oi.units_sold,
    o.revenue_usd,
    o.profit,
    o.payment_method,
    c.is_prime_member,
    s.is_late,
    s.courier
FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN regions r ON o.region_id = r.region_id
    JOIN customers c ON o.customer_id = c.customer_id
    LEFT JOIN shipping_info s ON o.order_id = s.order_id;
-- Monthly Performance View
CREATE OR REPLACE VIEW vw_monthly_performance AS
SELECT DATE_TRUNC('month', order_date) AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(revenue_usd) AS total_revenue,
    SUM(profit) AS total_profit,
    AVG(revenue_usd) AS avg_order_value,
    SUM(revenue_usd) / NULLIF(
        LAG(SUM(revenue_usd)) OVER (
            ORDER BY DATE_TRUNC('month', order_date)
        ),
        0
    ) - 1 AS mom_growth
FROM orders
WHERE order_status = 'Completed'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON TABLE orders IS 'Main fact table containing all order transactions';
COMMENT ON TABLE products IS 'Product dimension table with catalog information';
COMMENT ON TABLE customers IS 'Customer dimension table with buyer information';
COMMENT ON TABLE regions IS 'Geographic dimension with regional and channel data';
COMMENT ON TABLE shipping_info IS 'Shipping and delivery tracking information';
COMMENT ON TABLE order_items IS 'Line items linking orders to products';
-- ============================================================================
-- END OF SCHEMA
-- ============================================================================