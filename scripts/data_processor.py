"""
Amazon Sales Data Processor
============================
This script processes the raw Excel data and generates JSON files
for the interactive dashboard visualization.

Author: Data Analyst Portfolio Project
Skills Demonstrated: Python, Pandas, Data Engineering, ETL
"""

import pandas as pd
import numpy as np
import json
from datetime import datetime
import os

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)
INPUT_FILE = os.path.join(BASE_DIR, 'Amazon_Sales_Data_50k_Enhanced_Realistic_v0.xlsx')
OUTPUT_DIR = os.path.join(BASE_DIR, 'dashboard', 'data')

def load_and_clean_data():
    """Load and clean the raw Amazon sales data."""
    print("Loading data from Excel...")
    df = pd.read_excel(INPUT_FILE)
    
    # Data cleaning
    print("Cleaning data...")
    
    # Handle missing values
    df['Category'] = df['Category'].fillna('Unknown')
    df['Brand'] = df['Brand'].fillna('Unknown Brand')
    df['Region'] = df['Region'].fillna('Unknown')
    df['Country'] = df['Country'].fillna('Unknown')
    df['Payment_Method'] = df['Payment_Method'].fillna('Unknown')
    df['Courier'] = df['Courier'].fillna('Unknown')
    
    # Convert dates
    df['OrderDate'] = pd.to_datetime(df['OrderDate'])
    df['Shipping_Date'] = pd.to_datetime(df['Shipping_Date'], errors='coerce')
    df['Expected_Delivery_Date'] = pd.to_datetime(df['Expected_Delivery_Date'], errors='coerce')
    
    # Clean numeric columns
    numeric_cols = ['Revenue_USD', 'Profit', 'UnitsSold', 'UnitPrice', 'Shipping_Cost', 
                   'TaxAmount', 'DiscountAmount', 'Refund_Amount']
    for col in numeric_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
    
    # Clean boolean columns
    df['Prime_Member'] = df['Prime_Member'].fillna(0).astype(bool)
    df['Late Deliveries?'] = df['Late Deliveries?'].fillna('No')
    df['IsLate'] = df['Late Deliveries?'].apply(lambda x: True if str(x).lower() == 'yes' else False)
    
    # Extract date components
    df['Year'] = df['OrderDate'].dt.year
    df['Month'] = df['OrderDate'].dt.month
    df['MonthName'] = df['OrderDate'].dt.strftime('%b')
    df['DayOfWeek'] = df['OrderDate'].dt.dayofweek
    df['DayName'] = df['OrderDate'].dt.strftime('%A')
    df['YearMonth'] = df['OrderDate'].dt.to_period('M').astype(str)
    
    print(f"Data loaded: {len(df)} rows, {len(df.columns)} columns")
    return df

def calculate_kpis(df):
    """Calculate key performance indicators."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    kpis = {
        'total_revenue': round(completed_df['Revenue_USD'].sum(), 2),
        'total_profit': round(completed_df['Profit'].sum(), 2),
        'total_orders': int(completed_df['Order Id'].nunique()),
        'total_units_sold': int(completed_df['UnitsSold'].sum()),
        'avg_order_value': round(completed_df['Revenue_USD'].mean(), 2),
        'profit_margin': round(completed_df['Profit'].sum() / completed_df['Revenue_USD'].sum() * 100, 2),
        'unique_customers': int(completed_df['Buyer_Email'].nunique()),
        'prime_member_pct': round(completed_df['Prime_Member'].mean() * 100, 2),
        'late_delivery_pct': round(completed_df['IsLate'].mean() * 100, 2),
        'unique_products': int(completed_df['ProductName'].nunique()),
        'unique_countries': int(completed_df['Country'].nunique()),
        'avg_discount_rate': round(completed_df['DiscountRate'].mean() * 100, 2),
        'data_period': f"{df['OrderDate'].min().strftime('%b %Y')} - {df['OrderDate'].max().strftime('%b %Y')}"
    }
    
    return kpis

def calculate_monthly_trends(df):
    """Calculate monthly revenue and order trends."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    monthly = completed_df.groupby('YearMonth').agg({
        'Revenue_USD': 'sum',
        'Profit': 'sum',
        'Order Id': 'nunique',
        'UnitsSold': 'sum'
    }).reset_index()
    
    monthly.columns = ['month', 'revenue', 'profit', 'orders', 'units']
    monthly['revenue'] = monthly['revenue'].round(2)
    monthly['profit'] = monthly['profit'].round(2)
    
    # Calculate growth rates
    monthly['revenue_growth'] = monthly['revenue'].pct_change() * 100
    monthly['revenue_growth'] = monthly['revenue_growth'].round(2).fillna(0)
    
    # Calculate 3-month moving average
    monthly['revenue_ma3'] = monthly['revenue'].rolling(window=3).mean().round(2)
    monthly['revenue_ma3'] = monthly['revenue_ma3'].fillna(monthly['revenue'])
    
    return monthly.to_dict(orient='records')

def calculate_category_performance(df):
    """Calculate category-wise performance metrics."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    category = completed_df.groupby('Category').agg({
        'Revenue_USD': 'sum',
        'Profit': 'sum',
        'Order Id': 'nunique',
        'UnitsSold': 'sum'
    }).reset_index()
    
    category.columns = ['category', 'revenue', 'profit', 'orders', 'units']
    category['revenue'] = category['revenue'].round(2)
    category['profit'] = category['profit'].round(2)
    category['profit_margin'] = (category['profit'] / category['revenue'] * 100).round(2)
    category['revenue_share'] = (category['revenue'] / category['revenue'].sum() * 100).round(2)
    
    # Pareto classification
    category = category.sort_values('revenue', ascending=False)
    category['cumulative_share'] = category['revenue_share'].cumsum()
    category['pareto_class'] = category['cumulative_share'].apply(
        lambda x: 'Top Performer' if x <= 80 else 'Supporting'
    )
    
    return category.to_dict(orient='records')

def calculate_regional_performance(df):
    """Calculate regional performance metrics."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    regional = completed_df.groupby(['Region', 'Country']).agg({
        'Revenue_USD': 'sum',
        'Profit': 'sum',
        'Order Id': 'nunique',
        'Buyer_Email': 'nunique'
    }).reset_index()
    
    regional.columns = ['region', 'country', 'revenue', 'profit', 'orders', 'customers']
    regional['revenue'] = regional['revenue'].round(2)
    regional['profit'] = regional['profit'].round(2)
    regional['avg_order_value'] = (regional['revenue'] / regional['orders']).round(2)
    regional['revenue_per_customer'] = (regional['revenue'] / regional['customers']).round(2)
    
    return regional.to_dict(orient='records')

def calculate_channel_performance(df):
    """Calculate channel-wise performance."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    channel = completed_df.groupby('Channel').agg({
        'Revenue_USD': 'sum',
        'Profit': 'sum',
        'Order Id': 'nunique',
        'UnitsSold': 'sum'
    }).reset_index()
    
    channel.columns = ['channel', 'revenue', 'profit', 'orders', 'units']
    channel['revenue'] = channel['revenue'].round(2)
    channel['profit'] = channel['profit'].round(2)
    channel['market_share'] = (channel['revenue'] / channel['revenue'].sum() * 100).round(2)
    
    return channel.sort_values('revenue', ascending=False).to_dict(orient='records')

def calculate_payment_analysis(df):
    """Calculate payment method analysis."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    payment = completed_df.groupby('Payment_Method').agg({
        'Revenue_USD': ['sum', 'mean'],
        'Order Id': 'nunique',
        'Payment_Fees': 'sum'
    }).reset_index()
    
    payment.columns = ['payment_method', 'revenue', 'avg_order_value', 'orders', 'fees']
    payment['revenue'] = payment['revenue'].round(2)
    payment['avg_order_value'] = payment['avg_order_value'].round(2)
    payment['fees'] = payment['fees'].round(2)
    payment['share'] = (payment['revenue'] / payment['revenue'].sum() * 100).round(2)
    
    return payment.sort_values('revenue', ascending=False).to_dict(orient='records')

def calculate_day_of_week_analysis(df):
    """Calculate day of week performance patterns."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    daily = completed_df.groupby(['DayOfWeek', 'DayName']).agg({
        'Revenue_USD': 'sum',
        'Order Id': 'nunique'
    }).reset_index()
    
    daily.columns = ['day_num', 'day_name', 'revenue', 'orders']
    daily['revenue'] = daily['revenue'].round(2)
    daily['avg_revenue'] = (daily['revenue'] / daily['orders']).round(2)
    
    # Calculate index vs average
    avg_revenue = daily['revenue'].mean()
    daily['index'] = (daily['revenue'] / avg_revenue * 100).round(2)
    
    return daily.sort_values('day_num').to_dict(orient='records')

def calculate_prime_analysis(df):
    """Compare Prime vs Non-Prime members."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    prime = completed_df.groupby('Prime_Member').agg({
        'Revenue_USD': ['sum', 'mean'],
        'Profit': 'sum',
        'Order Id': 'nunique',
        'Buyer_Email': 'nunique',
        'UnitsSold': 'sum'
    }).reset_index()
    
    prime.columns = ['is_prime', 'revenue', 'avg_order_value', 'profit', 'orders', 'customers', 'units']
    prime['is_prime'] = prime['is_prime'].apply(lambda x: 'Prime' if x else 'Non-Prime')
    prime['revenue'] = prime['revenue'].round(2)
    prime['avg_order_value'] = prime['avg_order_value'].round(2)
    prime['profit'] = prime['profit'].round(2)
    prime['orders_per_customer'] = (prime['orders'] / prime['customers']).round(2)
    prime['revenue_per_customer'] = (prime['revenue'] / prime['customers']).round(2)
    
    return prime.to_dict(orient='records')

def calculate_shipping_performance(df):
    """Calculate shipping and delivery performance."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    shipping = completed_df.groupby('Courier').agg({
        'Order Id': 'nunique',
        'IsLate': ['sum', 'mean'],
        'Shipping_Cost': 'mean',
        'Days ': 'mean'
    }).reset_index()
    
    shipping.columns = ['courier', 'shipments', 'late_count', 'late_rate', 'avg_cost', 'avg_days']
    shipping['late_rate'] = (shipping['late_rate'] * 100).round(2)
    shipping['on_time_rate'] = (100 - shipping['late_rate']).round(2)
    shipping['avg_cost'] = shipping['avg_cost'].round(2)
    shipping['avg_days'] = shipping['avg_days'].round(1)
    
    return shipping.sort_values('shipments', ascending=False).head(10).to_dict(orient='records')

def calculate_top_products(df):
    """Get top performing products."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    products = completed_df.groupby(['ProductName', 'Category', 'Brand']).agg({
        'Revenue_USD': 'sum',
        'Profit': 'sum',
        'UnitsSold': 'sum',
        'Order Id': 'nunique'
    }).reset_index()
    
    products.columns = ['product', 'category', 'brand', 'revenue', 'profit', 'units', 'orders']
    products['revenue'] = products['revenue'].round(2)
    products['profit'] = products['profit'].round(2)
    products['profit_margin'] = (products['profit'] / products['revenue'] * 100).round(2)
    
    return products.nlargest(20, 'revenue').to_dict(orient='records')

def calculate_top_brands(df):
    """Get top performing brands."""
    completed_df = df[df['Order_Status'] == 'Completed']
    
    brands = completed_df.groupby('Brand').agg({
        'Revenue_USD': 'sum',
        'Profit': 'sum',
        'UnitsSold': 'sum',
        'Order Id': 'nunique'
    }).reset_index()
    
    brands.columns = ['brand', 'revenue', 'profit', 'units', 'orders']
    brands['revenue'] = brands['revenue'].round(2)
    brands['profit'] = brands['profit'].round(2)
    brands['market_share'] = (brands['revenue'] / brands['revenue'].sum() * 100).round(2)
    
    return brands.nlargest(15, 'revenue').to_dict(orient='records')

def calculate_order_status_distribution(df):
    """Calculate order status distribution."""
    status = df.groupby('Order_Status').agg({
        'Order Id': 'nunique',
        'Revenue_USD': 'sum',
        'Refund_Amount': 'sum'
    }).reset_index()
    
    status.columns = ['status', 'orders', 'revenue', 'refunds']
    status['revenue'] = status['revenue'].round(2)
    status['refunds'] = status['refunds'].round(2)
    status['order_share'] = (status['orders'] / status['orders'].sum() * 100).round(2)
    
    return status.to_dict(orient='records')

def main():
    """Main execution function."""
    print("="*60)
    print("Amazon Sales Data Processor")
    print("="*60)
    
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Load and clean data
    df = load_and_clean_data()
    
    # Calculate all metrics
    print("\nCalculating KPIs...")
    kpis = calculate_kpis(df)
    
    print("Calculating monthly trends...")
    monthly_trends = calculate_monthly_trends(df)
    
    print("Calculating category performance...")
    category_performance = calculate_category_performance(df)
    
    print("Calculating regional performance...")
    regional_performance = calculate_regional_performance(df)
    
    print("Calculating channel performance...")
    channel_performance = calculate_channel_performance(df)
    
    print("Calculating payment analysis...")
    payment_analysis = calculate_payment_analysis(df)
    
    print("Calculating day of week patterns...")
    day_analysis = calculate_day_of_week_analysis(df)
    
    print("Calculating prime member analysis...")
    prime_analysis = calculate_prime_analysis(df)
    
    print("Calculating shipping performance...")
    shipping_performance = calculate_shipping_performance(df)
    
    print("Calculating top products...")
    top_products = calculate_top_products(df)
    
    print("Calculating top brands...")
    top_brands = calculate_top_brands(df)
    
    print("Calculating order status distribution...")
    order_status = calculate_order_status_distribution(df)
    
    # Compile all data
    dashboard_data = {
        'generated_at': datetime.now().isoformat(),
        'kpis': kpis,
        'monthly_trends': monthly_trends,
        'category_performance': category_performance,
        'regional_performance': regional_performance,
        'channel_performance': channel_performance,
        'payment_analysis': payment_analysis,
        'day_of_week': day_analysis,
        'prime_analysis': prime_analysis,
        'shipping_performance': shipping_performance,
        'top_products': top_products,
        'top_brands': top_brands,
        'order_status': order_status
    }
    
    # Save to JSON
    output_file = os.path.join(OUTPUT_DIR, 'dashboard_data.json')
    with open(output_file, 'w') as f:
        json.dump(dashboard_data, f, indent=2, default=str)
    
    print(f"\n✅ Dashboard data saved to: {output_file}")
    print("="*60)
    
    # Print summary
    print("\n📊 DATA SUMMARY:")
    print(f"   Total Revenue: ${kpis['total_revenue']:,.2f}")
    print(f"   Total Profit: ${kpis['total_profit']:,.2f}")
    print(f"   Total Orders: {kpis['total_orders']:,}")
    print(f"   Profit Margin: {kpis['profit_margin']}%")
    print(f"   Data Period: {kpis['data_period']}")
    print("="*60)

if __name__ == "__main__":
    main()
