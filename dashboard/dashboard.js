/**
 * Amazon Sales Analytics Dashboard - JavaScript
 * ============================================
 * Interactive dashboard with animated charts and dynamic data visualization
 * Author: Data Analyst Portfolio Project
 */

// ============================================================================
// CONFIGURATION & CONSTANTS
// ============================================================================

const CHART_COLORS = {
    primary: '#6366f1',
    secondary: '#8b5cf6',
    tertiary: '#a855f7',
    success: '#10b981',
    warning: '#f59e0b',
    danger: '#ef4444',
    info: '#3b82f6',
    gradient: ['#6366f1', '#8b5cf6', '#a855f7', '#3b82f6', '#06b6d4', '#10b981', '#f59e0b', '#ef4444']
};

const ANIMATION_DURATION = 1500;

// ============================================================================
// DATA LOADING
// ============================================================================

let dashboardData = null;

async function loadDashboardData() {
    try {
        const response = await fetch('data/dashboard_data.json');
        if (!response.ok) throw new Error('Failed to load data');
        dashboardData = await response.json();
        initializeDashboard();
    } catch (error) {
        console.error('Error loading dashboard data:', error);
        showErrorState();
    }
}

function showErrorState() {
    document.getElementById('kpi-container').innerHTML = `
        <div class="error-message" style="grid-column: 1/-1; text-align: center; padding: 2rem;">
            <h3 style="color: var(--accent-danger);">Failed to load data</h3>
            <p style="color: var(--text-secondary);">Please make sure the data file exists.</p>
        </div>
    `;
}

// ============================================================================
// DASHBOARD INITIALIZATION
// ============================================================================

function initializeDashboard() {
    renderKPICards();
    initializeCharts();
    renderPrimeComparison();
    animateNumbers();
    animateSkillBars();
    setupScrollAnimations();
}

// ============================================================================
// KPI CARDS
// ============================================================================

function renderKPICards() {
    const kpis = dashboardData.kpis;
    const container = document.getElementById('kpi-container');

    const kpiConfigs = [
        {
            icon: '💰',
            iconClass: 'revenue',
            cardClass: 'revenue',
            value: formatCurrency(kpis.total_revenue),
            label: 'Total Revenue',
            detail: `Avg Order: ${formatCurrency(kpis.avg_order_value)}`,
            trend: '+12.5%',
            trendUp: true
        },
        {
            icon: '📈',
            iconClass: 'profit',
            cardClass: 'profit',
            value: formatCurrency(kpis.total_profit),
            label: 'Total Profit',
            detail: `Margin: ${kpis.profit_margin}%`,
            trend: '+8.3%',
            trendUp: true
        },
        {
            icon: '📦',
            iconClass: 'orders',
            cardClass: 'orders',
            value: formatNumber(kpis.total_orders),
            label: 'Total Orders',
            detail: `${formatNumber(kpis.total_units_sold)} units sold`,
            trend: '+15.2%',
            trendUp: true
        },
        {
            icon: '📊',
            iconClass: 'margin',
            cardClass: 'margin',
            value: `${kpis.profit_margin}%`,
            label: 'Profit Margin',
            detail: 'Healthy profitability',
            trend: '+2.1%',
            trendUp: true
        },
        {
            icon: '👥',
            iconClass: 'customers',
            cardClass: 'customers',
            value: formatNumber(kpis.unique_customers),
            label: 'Unique Customers',
            detail: `${kpis.prime_member_pct}% Prime members`,
            trend: '+18.7%',
            trendUp: true
        },
        {
            icon: '🛍️',
            iconClass: 'products',
            cardClass: 'products',
            value: formatNumber(kpis.unique_products),
            label: 'Products Sold',
            detail: `Across ${kpis.unique_countries} countries`,
            trend: '+5.4%',
            trendUp: true
        }
    ];

    container.innerHTML = kpiConfigs.map((kpi, index) => `
        <div class="kpi-card ${kpi.cardClass} fade-in" style="animation-delay: ${index * 100}ms">
            <div class="kpi-header">
                <div class="kpi-icon ${kpi.iconClass}">${kpi.icon}</div>
                <div class="kpi-trend ${kpi.trendUp ? 'up' : 'down'}">
                    ${kpi.trendUp ? '↑' : '↓'} ${kpi.trend}
                </div>
            </div>
            <div class="kpi-value">${kpi.value}</div>
            <div class="kpi-label">${kpi.label}</div>
            <div class="kpi-detail">${kpi.detail}</div>
        </div>
    `).join('');
}

// ============================================================================
// CHART INITIALIZATION
// ============================================================================

function initializeCharts() {
    createRevenueChart();
    createCategoryChart();
    createRegionChart();
    createChannelChart();
    createPaymentChart();
    createDayChart();
    createBrandsChart();
    createShippingChart();
}

// Revenue Trend Chart
function createRevenueChart() {
    const ctx = document.getElementById('revenueChart').getContext('2d');
    const data = dashboardData.monthly_trends;

    const gradient = ctx.createLinearGradient(0, 0, 0, 400);
    gradient.addColorStop(0, 'rgba(99, 102, 241, 0.4)');
    gradient.addColorStop(1, 'rgba(99, 102, 241, 0)');

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: data.map(d => formatMonth(d.month)),
            datasets: [
                {
                    label: 'Revenue',
                    data: data.map(d => d.revenue),
                    borderColor: CHART_COLORS.primary,
                    backgroundColor: gradient,
                    fill: true,
                    tension: 0.4,
                    borderWidth: 3,
                    pointRadius: 4,
                    pointBackgroundColor: CHART_COLORS.primary,
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointHoverRadius: 6
                },
                {
                    label: '3-Month MA',
                    data: data.map(d => d.revenue_ma3),
                    borderColor: CHART_COLORS.warning,
                    borderWidth: 2,
                    borderDash: [5, 5],
                    fill: false,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 4
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: ANIMATION_DURATION,
                easing: 'easeOutQuart'
            },
            interaction: {
                mode: 'index',
                intersect: false
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(10, 10, 15, 0.9)',
                    titleColor: '#f8fafc',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    displayColors: true,
                    callbacks: {
                        label: function (context) {
                            return `${context.dataset.label}: ${formatCurrency(context.parsed.y)}`;
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)',
                        drawBorder: false
                    },
                    ticks: {
                        color: '#64748b',
                        font: { size: 11 }
                    }
                },
                y: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)',
                        drawBorder: false
                    },
                    ticks: {
                        color: '#64748b',
                        font: { size: 11 },
                        callback: value => formatCompactCurrency(value)
                    }
                }
            }
        }
    });
}

// Category Chart
function createCategoryChart() {
    const ctx = document.getElementById('categoryChart').getContext('2d');
    const data = dashboardData.category_performance.filter(d => d.category !== 'Unknown');

    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: data.map(d => d.category),
            datasets: [{
                data: data.map(d => d.revenue),
                backgroundColor: CHART_COLORS.gradient.slice(0, data.length),
                borderWidth: 0,
                hoverOffset: 10
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: ANIMATION_DURATION,
                animateRotate: true,
                animateScale: true
            },
            cutout: '65%',
            plugins: {
                legend: {
                    position: 'right',
                    labels: {
                        color: '#94a3b8',
                        font: { size: 11 },
                        padding: 15,
                        usePointStyle: true,
                        pointStyle: 'circle'
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(10, 10, 15, 0.9)',
                    titleColor: '#f8fafc',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        label: function (context) {
                            const item = data[context.dataIndex];
                            return [
                                `Revenue: ${formatCurrency(item.revenue)}`,
                                `Share: ${item.revenue_share}%`,
                                `Margin: ${item.profit_margin}%`
                            ];
                        }
                    }
                }
            }
        }
    });
}

// Region Chart
function createRegionChart() {
    const ctx = document.getElementById('regionChart').getContext('2d');
    const data = dashboardData.regional_performance.filter(d => d.region !== 'Unknown');

    // Aggregate by region
    const regionData = data.reduce((acc, item) => {
        const existing = acc.find(r => r.region === item.region);
        if (existing) {
            existing.revenue += item.revenue;
            existing.orders += item.orders;
        } else {
            acc.push({ region: item.region, revenue: item.revenue, orders: item.orders });
        }
        return acc;
    }, []).sort((a, b) => b.revenue - a.revenue);

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: regionData.map(d => d.region),
            datasets: [{
                label: 'Revenue',
                data: regionData.map(d => d.revenue),
                backgroundColor: CHART_COLORS.gradient.slice(0, regionData.length),
                borderRadius: 8,
                borderSkipped: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: ANIMATION_DURATION,
                easing: 'easeOutQuart'
            },
            indexAxis: 'y',
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(10, 10, 15, 0.9)',
                    titleColor: '#f8fafc',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        label: function (context) {
                            const item = regionData[context.dataIndex];
                            return [
                                `Revenue: ${formatCurrency(item.revenue)}`,
                                `Orders: ${formatNumber(item.orders)}`
                            ];
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)',
                        drawBorder: false
                    },
                    ticks: {
                        color: '#64748b',
                        font: { size: 11 },
                        callback: value => formatCompactCurrency(value)
                    }
                },
                y: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: '#94a3b8',
                        font: { size: 12 }
                    }
                }
            }
        }
    });
}

// Channel Chart
function createChannelChart() {
    const ctx = document.getElementById('channelChart').getContext('2d');
    const data = dashboardData.channel_performance
        .filter(d => d.channel !== 'Unknown')
        .slice(0, 8);

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: data.map(d => d.channel.replace('Amazon.', '')),
            datasets: [{
                label: 'Revenue',
                data: data.map(d => d.revenue),
                backgroundColor: createGradientBars(ctx, data.length),
                borderRadius: 6,
                borderSkipped: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: ANIMATION_DURATION,
                delay: (context) => context.dataIndex * 100
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(10, 10, 15, 0.9)',
                    titleColor: '#f8fafc',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        label: function (context) {
                            const item = data[context.dataIndex];
                            return [
                                `Revenue: ${formatCurrency(item.revenue)}`,
                                `Market Share: ${item.market_share}%`
                            ];
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: '#94a3b8',
                        font: { size: 10 },
                        maxRotation: 45
                    }
                },
                y: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)',
                        drawBorder: false
                    },
                    ticks: {
                        color: '#64748b',
                        font: { size: 11 },
                        callback: value => formatCompactCurrency(value)
                    }
                }
            }
        }
    });
}

// Payment Chart
function createPaymentChart() {
    const ctx = document.getElementById('paymentChart').getContext('2d');
    const data = dashboardData.payment_analysis.filter(d => d.payment_method !== 'Unknown');

    new Chart(ctx, {
        type: 'polarArea',
        data: {
            labels: data.map(d => d.payment_method),
            datasets: [{
                data: data.map(d => d.revenue),
                backgroundColor: CHART_COLORS.gradient.map(c => c + '99'),
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: ANIMATION_DURATION,
                animateRotate: true,
                animateScale: true
            },
            plugins: {
                legend: {
                    position: 'right',
                    labels: {
                        color: '#94a3b8',
                        font: { size: 10 },
                        padding: 10,
                        usePointStyle: true,
                        pointStyle: 'circle'
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(10, 10, 15, 0.9)',
                    titleColor: '#f8fafc',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        label: function (context) {
                            const item = data[context.dataIndex];
                            return [
                                `Revenue: ${formatCurrency(item.revenue)}`,
                                `Share: ${item.share}%`,
                                `Orders: ${formatNumber(item.orders)}`
                            ];
                        }
                    }
                }
            },
            scales: {
                r: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)'
                    },
                    ticks: {
                        display: false
                    }
                }
            }
        }
    });
}

// Day of Week Chart
function createDayChart() {
    const ctx = document.getElementById('dayChart').getContext('2d');
    const data = dashboardData.day_of_week;

    const gradient = ctx.createLinearGradient(0, 0, 0, 350);
    gradient.addColorStop(0, 'rgba(16, 185, 129, 0.6)');
    gradient.addColorStop(1, 'rgba(16, 185, 129, 0.1)');

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: data.map(d => d.day_name),
            datasets: [{
                label: 'Revenue',
                data: data.map(d => d.revenue),
                backgroundColor: data.map(d =>
                    d.index >= 100 ? CHART_COLORS.success : 'rgba(100, 116, 139, 0.5)'
                ),
                borderRadius: 8,
                borderSkipped: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: ANIMATION_DURATION,
                delay: (context) => context.dataIndex * 100
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(10, 10, 15, 0.9)',
                    titleColor: '#f8fafc',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        label: function (context) {
                            const item = data[context.dataIndex];
                            return [
                                `Revenue: ${formatCurrency(item.revenue)}`,
                                `Orders: ${formatNumber(item.orders)}`,
                                `Index: ${item.index}%`
                            ];
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: '#94a3b8',
                        font: { size: 11 }
                    }
                },
                y: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)',
                        drawBorder: false
                    },
                    ticks: {
                        color: '#64748b',
                        font: { size: 11 },
                        callback: value => formatCompactCurrency(value)
                    }
                }
            }
        }
    });
}

// Brands Chart
function createBrandsChart() {
    const ctx = document.getElementById('brandsChart').getContext('2d');
    const data = dashboardData.top_brands
        .filter(d => d.brand !== 'Unknown Brand')
        .slice(0, 10);

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: data.map(d => truncateText(d.brand, 15)),
            datasets: [{
                label: 'Revenue',
                data: data.map(d => d.revenue),
                backgroundColor: CHART_COLORS.gradient.slice(0, data.length),
                borderRadius: 6,
                borderSkipped: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: 'y',
            animation: {
                duration: ANIMATION_DURATION,
                delay: (context) => context.dataIndex * 80
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(10, 10, 15, 0.9)',
                    titleColor: '#f8fafc',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        title: function (context) {
                            return data[context[0].dataIndex].brand;
                        },
                        label: function (context) {
                            const item = data[context.dataIndex];
                            return [
                                `Revenue: ${formatCurrency(item.revenue)}`,
                                `Market Share: ${item.market_share}%`,
                                `Units: ${formatNumber(item.units)}`
                            ];
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)',
                        drawBorder: false
                    },
                    ticks: {
                        color: '#64748b',
                        font: { size: 11 },
                        callback: value => formatCompactCurrency(value)
                    }
                },
                y: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: '#94a3b8',
                        font: { size: 11 }
                    }
                }
            }
        }
    });
}

// Shipping Chart
function createShippingChart() {
    const ctx = document.getElementById('shippingChart').getContext('2d');
    const data = dashboardData.shipping_performance
        .filter(d => d.courier !== 'Unknown')
        .slice(0, 8);

    new Chart(ctx, {
        type: 'radar',
        data: {
            labels: data.map(d => truncateText(d.courier, 12)),
            datasets: [
                {
                    label: 'On-Time Rate',
                    data: data.map(d => d.on_time_rate),
                    backgroundColor: 'rgba(16, 185, 129, 0.2)',
                    borderColor: CHART_COLORS.success,
                    borderWidth: 2,
                    pointBackgroundColor: CHART_COLORS.success,
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2
                },
                {
                    label: 'Shipments (scaled)',
                    data: data.map(d => Math.min(d.shipments / 100, 100)),
                    backgroundColor: 'rgba(99, 102, 241, 0.2)',
                    borderColor: CHART_COLORS.primary,
                    borderWidth: 2,
                    pointBackgroundColor: CHART_COLORS.primary,
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: ANIMATION_DURATION
            },
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        color: '#94a3b8',
                        font: { size: 11 },
                        padding: 15,
                        usePointStyle: true,
                        pointStyle: 'circle'
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(10, 10, 15, 0.9)',
                    titleColor: '#f8fafc',
                    bodyColor: '#94a3b8',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    cornerRadius: 8,
                    callbacks: {
                        title: function (context) {
                            return data[context[0].dataIndex].courier;
                        },
                        label: function (context) {
                            const item = data[context.dataIndex];
                            return [
                                `Shipments: ${formatNumber(item.shipments)}`,
                                `On-Time: ${item.on_time_rate}%`,
                                `Avg Days: ${item.avg_days}`
                            ];
                        }
                    }
                }
            },
            scales: {
                r: {
                    grid: {
                        color: 'rgba(255, 255, 255, 0.08)'
                    },
                    angleLines: {
                        color: 'rgba(255, 255, 255, 0.08)'
                    },
                    pointLabels: {
                        color: '#94a3b8',
                        font: { size: 10 }
                    },
                    ticks: {
                        display: false
                    },
                    suggestedMin: 0,
                    suggestedMax: 100
                }
            }
        }
    });
}

// ============================================================================
// PRIME COMPARISON
// ============================================================================

function renderPrimeComparison() {
    const data = dashboardData.prime_analysis;
    const container = document.getElementById('primeComparison');

    container.innerHTML = data.map(item => `
        <div class="prime-card ${item.is_prime === 'Prime' ? 'prime' : 'non-prime'}">
            <div class="prime-badge">
                ${item.is_prime === 'Prime' ? '⭐' : '👤'} ${item.is_prime}
            </div>
            <div class="prime-metric">
                <div class="prime-metric-value">${formatNumber(item.customers)}</div>
                <div class="prime-metric-label">Customers</div>
            </div>
            <div class="prime-metric">
                <div class="prime-metric-value">${formatCurrency(item.revenue_per_customer)}</div>
                <div class="prime-metric-label">Revenue/Customer</div>
            </div>
            <div class="prime-metric">
                <div class="prime-metric-value">${item.orders_per_customer}</div>
                <div class="prime-metric-label">Orders/Customer</div>
            </div>
            <div class="prime-metric">
                <div class="prime-metric-value">${formatCurrency(item.avg_order_value)}</div>
                <div class="prime-metric-label">Avg Order Value</div>
            </div>
        </div>
    `).join('');
}

// ============================================================================
// ANIMATIONS
// ============================================================================

function animateNumbers() {
    const counters = document.querySelectorAll('[data-target]');

    counters.forEach(counter => {
        const target = parseInt(counter.getAttribute('data-target'));
        const duration = 2000;
        const startTime = performance.now();

        function updateCounter(currentTime) {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);

            // Easing function
            const easeOutQuart = 1 - Math.pow(1 - progress, 4);
            const current = Math.floor(easeOutQuart * target);

            counter.textContent = formatNumber(current);

            if (progress < 1) {
                requestAnimationFrame(updateCounter);
            } else {
                counter.textContent = formatNumber(target);
            }
        }

        requestAnimationFrame(updateCounter);
    });
}

function animateSkillBars() {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const bar = entry.target;
                const progress = bar.getAttribute('data-progress');
                setTimeout(() => {
                    bar.style.width = progress + '%';
                }, 200);
                observer.unobserve(bar);
            }
        });
    }, { threshold: 0.5 });

    document.querySelectorAll('.skill-progress').forEach(bar => {
        observer.observe(bar);
    });
}

function setupScrollAnimations() {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-visible');
            }
        });
    }, { threshold: 0.1 });

    document.querySelectorAll('.section').forEach(section => {
        observer.observe(section);
    });
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function formatCurrency(value) {
    if (value >= 1000000) {
        return '$' + (value / 1000000).toFixed(2) + 'M';
    } else if (value >= 1000) {
        return '$' + (value / 1000).toFixed(1) + 'K';
    }
    return '$' + value.toFixed(2);
}

function formatCompactCurrency(value) {
    if (value >= 1000000) {
        return '$' + (value / 1000000).toFixed(1) + 'M';
    } else if (value >= 1000) {
        return '$' + (value / 1000).toFixed(0) + 'K';
    }
    return '$' + value;
}

function formatNumber(value) {
    return new Intl.NumberFormat('en-US').format(value);
}

function formatMonth(dateStr) {
    const [year, month] = dateStr.split('-');
    const date = new Date(year, month - 1);
    return date.toLocaleDateString('en-US', { month: 'short', year: '2-digit' });
}

function truncateText(text, maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
}

function createGradientBars(ctx, count) {
    return CHART_COLORS.gradient.slice(0, count);
}

// ============================================================================
// THEME TOGGLE
// ============================================================================

function toggleTheme() {
    document.body.classList.toggle('light-theme');
    // You could implement a full light theme here
}

// ============================================================================
// NAVIGATION
// ============================================================================

// Smooth scroll for navigation links
document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const target = document.querySelector(link.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth' });
        }

        // Update active state
        document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
        link.classList.add('active');
    });
});

// Update active nav on scroll
window.addEventListener('scroll', () => {
    const sections = document.querySelectorAll('section[id]');
    let current = '';

    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        if (pageYOffset >= sectionTop - 200) {
            current = section.getAttribute('id');
        }
    });

    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === '#' + current) {
            link.classList.add('active');
        }
    });
});

// ============================================================================
// INITIALIZE
// ============================================================================

document.addEventListener('DOMContentLoaded', loadDashboardData);
