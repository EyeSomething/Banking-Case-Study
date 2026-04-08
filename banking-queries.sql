-- ============================================================================
-- BANKING CASE STUDY: SQL Query Collection
-- SQLite Database Schema & Analysis Queries
-- ============================================================================
-- Intermediate SQL Showcase: JOINs, Aggregations, Date Operations, Data Cleaning
-- ============================================================================

-- ============================================================================
-- PART 1: SCHEMA CREATION & SAMPLE DATA
-- ============================================================================

-- Drop existing tables to start fresh
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS branches;

-- ============================================================================
-- TABLE 1: BRANCHES
-- ============================================================================
CREATE TABLE branches (
    branch_id INTEGER PRIMARY KEY,
    branch_name TEXT NOT NULL,
    city TEXT NOT NULL,
    region TEXT NOT NULL,
    manager_name TEXT,
    annual_budget DECIMAL(12, 2)
);

INSERT INTO branches (branch_id, branch_name, city, region, manager_name, annual_budget) VALUES
(1, 'Downtown Metro', 'New York', 'Northeast', 'Sarah Johnson', 2500000.00),
(2, 'Midtown Plaza', 'New York', 'Northeast', 'David Chen', 2200000.00),
(3, 'Chicago Central', 'Chicago', 'Midwest', 'Jennifer Smith', 1800000.00),
(4, 'Texas Hub', 'Houston', 'South', 'Robert Martinez', 2000000.00),
(5, 'Silicon Valley', 'San Jose', 'West', 'Emily Rodriguez', 2800000.00),
(6, 'West Coast Tower', 'Los Angeles', 'West', 'Michael Brown', 2600000.00),
(7, 'Miami Beach', 'Miami', 'South', 'Lisa Anderson', 1600000.00),
(8, 'Boston Financial', 'Boston', 'Northeast', 'James O''Connor', 1900000.00);

-- ============================================================================
-- TABLE 2: CUSTOMERS
-- ============================================================================
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    branch_id INTEGER NOT NULL,
    account_created_date DATE NOT NULL,
    credit_score INTEGER,
    employment_status TEXT,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- Insert 1200 realistic customer records with varied credit scores and employment status
-- Note: Some employment_status values are NULL to simulate data quality issues
WITH RECURSIVE cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM cnt WHERE x < 1200
)
INSERT INTO customers (customer_id, name, email, phone, branch_id, account_created_date, credit_score, employment_status)
SELECT 
    x,
    'Customer_' || x,
    'customer' || x || '@email.com',
    '555-' || SUBSTR('0000' || x, -4),
    CASE WHEN x % 8 = 0 THEN 8 WHEN x % 8 = 1 THEN 1 WHEN x % 8 = 2 THEN 2 WHEN x % 8 = 3 THEN 3 WHEN x % 8 = 4 THEN 4 WHEN x % 8 = 5 THEN 5 WHEN x % 8 = 6 THEN 6 ELSE 7 END,
    DATE('2021-01-01', '+' || (x % 1095) || ' days'),
    600 + (x % 300),
    CASE 
        WHEN x % 10 = 0 THEN NULL  -- 10% have NULL employment status (data quality issue)
        WHEN x % 10 < 5 THEN 'Employed'
        WHEN x % 10 < 8 THEN 'Self-Employed'
        ELSE 'Retired'
    END
FROM cnt;

-- ============================================================================
-- TABLE 3: LOANS
-- ============================================================================
CREATE TABLE loans (
    loan_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    branch_id INTEGER NOT NULL,
    loan_amount DECIMAL(12, 2) NOT NULL,
    interest_rate DECIMAL(5, 2) NOT NULL,
    loan_type TEXT NOT NULL,
    approval_date DATE NOT NULL,
    loan_term_months INTEGER NOT NULL,
    status TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- Insert 1500 realistic loan records with varied statuses and amounts
WITH RECURSIVE cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM cnt WHERE x < 1500
)
INSERT INTO loans (loan_id, customer_id, branch_id, loan_amount, interest_rate, loan_type, approval_date, loan_term_months, status)
SELECT 
    x,
    CASE WHEN x % 15 = 0 THEN NULL ELSE (100 + (x % 1100)) END,  -- 7% have orphaned customer_id (NULL)
    CASE WHEN x % 8 = 0 THEN 8 WHEN x % 8 = 1 THEN 1 WHEN x % 8 = 2 THEN 2 WHEN x % 8 = 3 THEN 3 WHEN x % 8 = 4 THEN 4 WHEN x % 8 = 5 THEN 5 WHEN x % 8 = 6 THEN 6 ELSE 7 END,
    5000.00 + (x % 200000),
    3.5 + (x % 500) * 0.01,
    CASE WHEN x % 3 = 0 THEN 'Personal' WHEN x % 3 = 1 THEN 'Home' ELSE 'Auto' END,
    DATE('2022-01-01', '+' || (x % 730) || ' days'),
    CASE WHEN x % 3 = 0 THEN 36 WHEN x % 3 = 1 THEN 360 ELSE 60 END,
    CASE 
        WHEN x % 20 < 1 THEN 'Defaulted'  -- 5% defaulted
        WHEN x % 20 < 8 THEN 'Closed'      -- 35% closed
        ELSE 'Active'                      -- 60% active
    END
FROM cnt;

-- ============================================================================
-- TABLE 4: PAYMENTS
-- ============================================================================
CREATE TABLE payments (
    payment_id INTEGER PRIMARY KEY,
    loan_id INTEGER NOT NULL,
    payment_date DATE,
    due_date DATE NOT NULL,
    payment_amount DECIMAL(12, 2) NOT NULL,
    status TEXT NOT NULL,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
);

-- Insert ~8000 payment records (approx 5-6 payments per loan)
-- Multiple payments per loan to simulate realistic payment history
WITH RECURSIVE cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM cnt WHERE x < 9000
)
INSERT INTO payments (payment_id, loan_id, payment_date, due_date, payment_amount, status)
SELECT 
    x,
    (((x - 1) % 1500) + 1) AS loan_id,
    CASE 
        WHEN x % 10 = 0 THEN NULL  -- 10% have missing payment_date (data quality issue)
        ELSE DATE('2022-01-01', '+' || ((x / 1500) * 30) || ' days')
    END,
    DATE('2022-01-01', '+' || ((x / 1500 + 1) * 30) || ' days'),
    ROUND(5000.00 + ((x % 100) * 50), 2),
    CASE 
        WHEN x % 10 = 0 THEN 'Pending'  -- 10% pending
        WHEN x % 50 < 3 THEN 'Missed'   -- 6% missed
        WHEN x % 50 < 8 THEN 'Late'     -- 10% late
        ELSE 'On_Time'                  -- 74% on time
    END
FROM cnt;

-- ============================================================================
-- PART 2: ANALYSIS QUERIES
-- ============================================================================

-- ============================================================================
-- QUERY 1: DATA QUALITY AUDIT
-- ============================================================================
-- Purpose: Identify data quality issues in loans and payments tables
-- Showcases: DISTINCT, WHERE with NULL checks, COUNT and GROUP BY for aggregation
-- Business Context: Before analysis, we need to understand data issues
--
-- Key Findings:
-- - Orphaned loans (customer_id IS NULL)
-- - Loans missing payment records
-- - Payments with missing payment_date
-- - Duplicate payment records (if any)

SELECT 
    'Orphaned Loans' AS data_quality_issue,
    COUNT(*) AS issue_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM loans), 2) AS pct_of_total
FROM loans
WHERE customer_id IS NULL

UNION ALL

SELECT 
    'Loans with No Payment Records' AS data_quality_issue,
    (SELECT COUNT(DISTINCT loan_id) FROM loans WHERE loan_id NOT IN (SELECT DISTINCT loan_id FROM payments WHERE payment_id IS NOT NULL)) AS issue_count,
    ROUND(100.0 * (SELECT COUNT(DISTINCT loan_id) FROM loans WHERE loan_id NOT IN (SELECT DISTINCT loan_id FROM payments WHERE payment_id IS NOT NULL)) / (SELECT COUNT(*) FROM loans), 2) AS pct_of_total

UNION ALL

SELECT 
    'Payments Missing payment_date' AS data_quality_issue,
    COUNT(*) AS issue_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM payments), 2) AS pct_of_total
FROM payments
WHERE payment_date IS NULL

UNION ALL

SELECT 
    'Customers Missing Employment Status' AS data_quality_issue,
    COUNT(*) AS issue_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customers), 2) AS pct_of_total
FROM customers
WHERE employment_status IS NULL;

-- ============================================================================
-- QUERY 2: CUSTOMER PAYMENT PERFORMANCE BY BRANCH
-- ============================================================================
-- Purpose: Analyze payment behavior and branch performance
-- Showcases: INNER JOIN (customers → loans), LEFT JOIN (→ payments), 
--            GROUP BY, HAVING, CASE for status categorization
-- Business Context: Which branches have the best payment performance?
--
-- Key Metrics:
-- - Total customers per branch
-- - Total loans issued
-- - Payment on-time rate
-- - Late payment count and percentage
-- - Average days to pay (when pay_date - due_date)

SELECT 
    b.branch_id,
    b.branch_name,
    b.city,
    (SELECT COUNT(DISTINCT customer_id) FROM customers WHERE customer_id IS NOT NULL AND branch_id = b.branch_id) AS total_customers,
    (SELECT COUNT(*) FROM loans WHERE branch_id = b.branch_id) AS total_loans,
    (SELECT COUNT(*) FROM payments p JOIN loans l ON p.loan_id = l.loan_id WHERE l.branch_id = b.branch_id AND p.payment_date IS NOT NULL) AS total_payments,
    ROUND(100.0 * (SELECT COUNT(*) FROM payments p JOIN loans l ON p.loan_id = l.loan_id WHERE l.branch_id = b.branch_id AND p.payment_date IS NOT NULL AND p.status = 'On_Time') / NULLIF((SELECT COUNT(*) FROM payments p JOIN loans l ON p.loan_id = l.loan_id WHERE l.branch_id = b.branch_id AND p.payment_date IS NOT NULL), 0), 2) AS on_time_pct,
    (SELECT COUNT(*) FROM payments p JOIN loans l ON p.loan_id = l.loan_id WHERE l.branch_id = b.branch_id AND p.status = 'Late') AS late_payment_count,
    (SELECT COUNT(*) FROM payments p JOIN loans l ON p.loan_id = l.loan_id WHERE l.branch_id = b.branch_id AND p.status = 'Missed') AS missed_payment_count,
    ROUND(100.0 * (SELECT COUNT(*) FROM payments p JOIN loans l ON p.loan_id = l.loan_id WHERE l.branch_id = b.branch_id AND p.status IN ('Late', 'Missed')) / NULLIF((SELECT COUNT(*) FROM payments p JOIN loans l ON p.loan_id = l.loan_id WHERE l.branch_id = b.branch_id), 0), 2) AS delinquent_pct
FROM branches b
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY delinquent_pct DESC;

-- ============================================================================
-- QUERY 3: LOAN STATUS & PERFORMANCE ANALYSIS
-- ============================================================================
-- Purpose: Analyze loan lifecycle and aging
-- Showcases: Date operations (julianday for age calculation), CASE for date logic,
--            LEFT JOIN for optional payment data, GROUP BY with aggregation
-- Business Context: What's the breakdown of loan statuses and how old are active loans?
--
-- Key Metrics:
-- - Count by status (Active, Closed, Defaulted)
-- - Loan age in days
-- - Average loan amount by status
-- - Number of payments made per loan
-- - Overdue days for late loans

SELECT 
    l.status,
    COUNT(*) AS loan_count,
    ROUND(AVG(l.loan_amount), 2) AS avg_loan_amount,
    ROUND(AVG(JULIANDAY('now') - JULIANDAY(l.approval_date)), 1) AS avg_loan_age_days,
    ROUND(MIN(JULIANDAY('now') - JULIANDAY(l.approval_date)), 1) AS min_loan_age_days,
    ROUND(MAX(JULIANDAY('now') - JULIANDAY(l.approval_date)), 1) AS max_loan_age_days,
    COUNT(DISTINCT p.payment_id) AS total_payments_made
FROM loans l
LEFT JOIN payments p ON l.loan_id = p.loan_id
GROUP BY l.status
ORDER BY loan_count DESC;

-- ============================================================================
-- QUERY 4: CUSTOMER SEGMENTATION BY LOAN PORTFOLIO
-- ============================================================================
-- Purpose: Segment customers by borrowing behavior and payment reliability
-- Showcases: SUM with CASE for conditional aggregation, multi-level GROUP BY,
--            CASE for categorization into risk tiers
-- Business Context: Which customers are most/least reliable based on their portfolio?
--
-- Key Metrics:
-- - Number of loans per customer
-- - Total amount borrowed
-- - On-time payment percentage
-- - Risk classification (Excellent/Good/Fair/Poor)

SELECT 
    c.customer_id,
    c.name,
    b.branch_name,
    c.credit_score,
    c.employment_status,
    COUNT(DISTINCT l.loan_id) AS num_loans,
    ROUND(SUM(l.loan_amount), 2) AS total_borrowed,
    COUNT(DISTINCT l.loan_id) AS total_active_loans,
    COUNT(DISTINCT CASE WHEN l.status = 'Defaulted' THEN l.loan_id END) AS defaulted_loans,
    ROUND(100.0 * SUM(CASE WHEN p.status = 'On_Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT p.payment_id), 0), 2) AS on_time_pct,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN l.status = 'Defaulted' THEN l.loan_id END) > 0 THEN 'Poor'
        WHEN ROUND(100.0 * SUM(CASE WHEN p.status = 'On_Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT p.payment_id), 0), 2) >= 95 AND c.credit_score >= 750 THEN 'Excellent'
        WHEN ROUND(100.0 * SUM(CASE WHEN p.status = 'On_Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT p.payment_id), 0), 2) >= 90 AND c.credit_score >= 700 THEN 'Good'
        WHEN ROUND(100.0 * SUM(CASE WHEN p.status = 'On_Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT p.payment_id), 0), 2) >= 80 THEN 'Fair'
        ELSE 'Poor'
    END AS risk_category
FROM customers c
LEFT JOIN branches b ON c.branch_id = b.branch_id
LEFT JOIN loans l ON c.customer_id = l.customer_id
LEFT JOIN payments p ON l.loan_id = p.loan_id
WHERE c.customer_id IS NOT NULL
GROUP BY c.customer_id, c.name, b.branch_name, c.credit_score, c.employment_status
HAVING COUNT(DISTINCT l.loan_id) > 0
ORDER BY on_time_pct DESC, c.customer_id;

-- ============================================================================
-- QUERY 5: MONTHLY PERFORMANCE TRENDS
-- ============================================================================
-- Purpose: Track loan origination and payment trends over time
-- Showcases: STRFTIME for date extraction and grouping, 
--            Date aggregation, time-series analysis
-- Business Context: Are we seeing growth or decline in loan volume and payment reliability?
--
-- Key Metrics:
-- - New loans per month
-- - Total payments processed
-- - Default rate by month
-- - Average interest rate for new loans

SELECT 
    STRFTIME('%Y-%m', l.approval_date) AS month,
    COUNT(DISTINCT l.loan_id) AS new_loans,
    ROUND(AVG(l.interest_rate), 2) AS avg_interest_rate,
    COUNT(DISTINCT p.payment_id) AS total_payments,
    SUM(CASE WHEN p.status = 'On_Time' THEN 1 ELSE 0 END) AS on_time_payments,
    SUM(CASE WHEN p.status IN ('Late', 'Missed') THEN 1 ELSE 0 END) AS delinquent_payments,
    SUM(CASE WHEN l.status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(100.0 * SUM(CASE WHEN l.status = 'Defaulted' THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT l.loan_id), 0), 2) AS default_rate_pct
FROM loans l
LEFT JOIN payments p ON l.loan_id = p.loan_id
GROUP BY STRFTIME('%Y-%m', l.approval_date)
ORDER BY month DESC;

-- ============================================================================
-- QUERY 6: MAIN EXPORT QUERY (CTE - Ready for Excel Analysis)
-- ============================================================================
-- Purpose: Comprehensive dataset combining customer, loan, and payment metrics
-- Showcases: WITH clause (Common Table Expressions), 
--            Multiple JOINs with data cleaning (COALESCE, CASE),
--            Complex aggregations suitable for dashboarding
-- Business Context: Create analysis-ready dataset for Excel visualization
--
-- Key Columns:
-- - Customer demographics
-- - Loan details
-- - Payment summary metrics
-- - Risk indicators

WITH clean_loans AS (
    SELECT 
        l.loan_id,
        COALESCE(l.customer_id, -1) AS customer_id,
        l.branch_id,
        l.loan_amount,
        l.interest_rate,
        l.loan_type,
        l.approval_date,
        l.loan_term_months,
        l.status,
        ROUND(JULIANDAY('now') - JULIANDAY(l.approval_date), 1) AS loan_age_days
    FROM loans l
),
payment_summary AS (
    SELECT 
        cl.loan_id,
        COUNT(DISTINCT p.payment_id) AS total_payments,
        SUM(CASE WHEN p.status = 'On_Time' THEN 1 ELSE 0 END) AS on_time_count,
        SUM(CASE WHEN p.status = 'Late' THEN 1 ELSE 0 END) AS late_count,
        SUM(CASE WHEN p.status = 'Missed' THEN 1 ELSE 0 END) AS missed_count,
        SUM(CASE WHEN p.status = 'Pending' THEN 1 ELSE 0 END) AS pending_count,
        ROUND(100.0 * SUM(CASE WHEN p.status = 'On_Time' THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT p.payment_id), 0), 2) AS on_time_pct,
        MAX(CASE WHEN p.status = 'Late' THEN ROUND(JULIANDAY('now') - JULIANDAY(p.due_date), 1) ELSE 0 END) AS max_days_overdue
    FROM clean_loans cl
    LEFT JOIN payments p ON cl.loan_id = p.loan_id
    WHERE p.payment_date IS NOT NULL OR p.status IN ('Pending', 'Missed')
    GROUP BY cl.loan_id
)
SELECT 
    cl.loan_id,
    cl.customer_id,
    CASE WHEN c.name IS NULL THEN 'Unknown' ELSE c.name END AS customer_name,
    COALESCE(c.credit_score, 0) AS credit_score,
    COALESCE(c.employment_status, 'Unknown') AS employment_status,
    b.branch_id,
    CASE WHEN b.branch_name IS NULL THEN 'Unknown' ELSE b.branch_name END AS branch_name,
    CASE WHEN b.city IS NULL THEN 'Unknown' ELSE b.city END AS city,
    CASE WHEN b.region IS NULL THEN 'Unknown' ELSE b.region END AS region,
    cl.loan_type,
    cl.loan_amount,
    cl.interest_rate,
    cl.approval_date,
    cl.loan_term_months,
    cl.status AS loan_status,
    cl.loan_age_days,
    COALESCE(ps.total_payments, 0) AS total_payments_made,
    COALESCE(ps.on_time_count, 0) AS on_time_payments,
    COALESCE(ps.late_count, 0) AS late_payments,
    COALESCE(ps.missed_count, 0) AS missed_payments,
    COALESCE(ps.on_time_pct, 0) AS on_time_pct,
    ROUND(COALESCE(ps.max_days_overdue, 0), 1) AS max_days_overdue,
    CASE 
        WHEN cl.status = 'Defaulted' THEN 'High Risk'
        WHEN COALESCE(ps.on_time_pct, 100) >= 95 AND c.credit_score >= 750 THEN 'Low Risk'
        WHEN COALESCE(ps.on_time_pct, 100) >= 85 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_level
FROM clean_loans cl
LEFT JOIN customers c ON cl.customer_id = c.customer_id
LEFT JOIN branches b ON cl.branch_id = b.branch_id
LEFT JOIN payment_summary ps ON cl.loan_id = ps.loan_id
ORDER BY cl.loan_id;

-- ============================================================================
-- END OF QUERIES
-- ============================================================================
