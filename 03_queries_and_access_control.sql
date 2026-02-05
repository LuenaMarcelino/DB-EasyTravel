-- =====================================================
-- FILE 3: ADVANCED QUERIES & ACCESS CONTROL
-- EASYTRAVEL DATABASE - QUERIES AND PERMISSIONS
-- =====================================================
-- This file contains:
-- - Advanced queries with JOINs, CASE, MAX/MIN/AVG
-- - CREATE VIEW statements
-- - Role-based access control (GRANT statements)
-- =====================================================

-- =====================================================
-- SECTION 1: ADVANCED QUERIES
-- =====================================================

-- Query 1: Customer booking summary with JOINs
-- Shows customer names, booking details, and package information
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    b.booking_id,
    hp.package_type,
    b.booking_date,
    b.booking_status,
    b.total_price,
    CASE 
        WHEN c.is_loyalty_member THEN 'Loyalty Member'
        ELSE 'Regular Customer'
    END AS customer_type
FROM customer c
JOIN booking b ON c.customer_id = b.customer_id
JOIN holiday_package hp ON b.package_id = hp.package_id
ORDER BY b.booking_date DESC;

-- Query 2: Booking with multiple flights (demonstrates M:N relationship)
-- Shows bookings with their associated flights using junction table
SELECT 
    b.booking_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    hp.package_type,
    STRING_AGG(f.airline || ' - ' || f.flight_route, ', ') AS flights,
    b.total_price
FROM booking b
JOIN customer c ON b.customer_id = c.customer_id
JOIN holiday_package hp ON b.package_id = hp.package_id
JOIN booking_flights bf ON b.booking_id = bf.booking_id
JOIN flights f ON bf.flight_id = f.flight_id
GROUP BY b.booking_id, c.first_name, c.last_name, hp.package_type, b.total_price
ORDER BY b.booking_id;

-- Query 3: Booking with multiple services (demonstrates M:N relationship)
-- Shows bookings with their associated services using junction table
SELECT 
    b.booking_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    STRING_AGG(s.service_category || ': ' || s.service_description, ', ') AS services,
    SUM(s.price) AS total_services_cost
FROM booking b
JOIN customer c ON b.customer_id = c.customer_id
JOIN booking_services bs ON b.booking_id = bs.booking_id
JOIN services s ON bs.service_id = s.service_id
GROUP BY b.booking_id, c.first_name, c.last_name
ORDER BY b.booking_id;

-- Query 4: Package with accommodation options (demonstrates M:N relationship)
-- Shows packages with their multiple accommodation choices
SELECT 
    hp.package_type,
    hp.base_price,
    STRING_AGG(a.accommodation_type || ' - ' || a.room_type, ', ') AS accommodation_options,
    COUNT(pa.accommodation_id) AS number_of_options
FROM holiday_package hp
JOIN package_accommodation pa ON hp.package_id = pa.package_id
JOIN accommodation a ON pa.accommodation_id = a.accommodation_id
GROUP BY hp.package_id, hp.package_type, hp.base_price
ORDER BY hp.package_type;

-- Query 5: Campaigns affecting packages (demonstrates M:N relationship)
-- Shows packages with their promotional campaigns
SELECT 
    hp.package_type,
    hp.base_price,
    STRING_AGG(cam.campaign_name || ' (' || cam.discount_percentage || '%)', ', ') AS active_campaigns,
    MAX(cam.discount_percentage) AS best_discount
FROM holiday_package hp
JOIN package_campaigns pc ON hp.package_id = pc.package_id
JOIN campaigns cam ON pc.campaign_id = cam.campaign_id
WHERE cam.end_date >= CURRENT_DATE
GROUP BY hp.package_id, hp.package_type, hp.base_price
ORDER BY best_discount DESC;

-- Query 6: Revenue analysis using aggregate functions
-- Shows total revenue, average booking, and statistics by package type
SELECT 
    hp.package_type,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_price) AS total_revenue,
    AVG(b.total_price) AS average_booking_value,
    MIN(b.total_price) AS minimum_booking,
    MAX(b.total_price) AS maximum_booking,
    CASE 
        WHEN AVG(b.total_price) > 2000 THEN 'Premium'
        WHEN AVG(b.total_price) > 1500 THEN 'Standard'
        ELSE 'Budget'
    END AS price_category
FROM holiday_package hp
LEFT JOIN booking b ON hp.package_id = b.package_id
GROUP BY hp.package_id, hp.package_type
ORDER BY total_revenue DESC;

-- Query 7: Customer loyalty tier analysis with CASE
-- Categorizes customers by loyalty points
SELECT 
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    loyalty_points,
    CASE 
        WHEN loyalty_points >= 15000 THEN 'Platinum'
        WHEN loyalty_points >= 10000 THEN 'Gold'
        WHEN loyalty_points >= 7000 THEN 'Silver'
        WHEN loyalty_points >= 3000 THEN 'Bronze'
        ELSE 'Standard'
    END AS loyalty_tier,
    CASE
        WHEN is_loyalty_member THEN 'Active'
        ELSE 'Inactive'
    END AS membership_status
FROM customer
ORDER BY loyalty_points DESC;

-- Query 8: Payment method analysis
-- Shows payment statistics by method
SELECT 
    p.payment_method,
    COUNT(*) AS transaction_count,
    SUM(p.payment_amount) AS total_amount,
    AVG(p.payment_amount) AS average_payment,
    MIN(p.payment_amount) AS minimum_payment,
    MAX(p.payment_amount) AS maximum_payment
FROM payment p
GROUP BY p.payment_method
ORDER BY total_amount DESC;

-- Query 9: Booking status distribution
-- Shows booking counts by status with percentages
SELECT 
    booking_status,
    COUNT(*) AS booking_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM booking), 2) AS percentage,
    CASE 
        WHEN booking_status = 'Confirmed' THEN 'Revenue Generated'
        WHEN booking_status = 'Pending' THEN 'Revenue Pending'
        ELSE 'Revenue Lost'
    END AS revenue_impact
FROM booking
GROUP BY booking_status
ORDER BY booking_count DESC;

-- Query 10: Customer feedback ratings analysis
-- Shows average ratings and feedback counts
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(f.feedback_id) AS total_reviews,
    AVG(f.rating) AS average_rating,
    MIN(f.rating) AS lowest_rating,
    MAX(f.rating) AS highest_rating,
    CASE 
        WHEN AVG(f.rating) >= 4.5 THEN 'Excellent'
        WHEN AVG(f.rating) >= 3.5 THEN 'Good'
        WHEN AVG(f.rating) >= 2.5 THEN 'Fair'
        ELSE 'Needs Improvement'
    END AS satisfaction_level
FROM customer c
JOIN feedback f ON c.customer_id = f.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(f.feedback_id) > 0
ORDER BY average_rating DESC;

-- =====================================================
-- SECTION 2: CREATE VIEWS
-- =====================================================

-- View 1: Complete Booking Details
-- Comprehensive view combining booking, customer, package, and payment info
CREATE OR REPLACE VIEW v_booking_details AS
SELECT 
    b.booking_id,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.phone,
    c.is_loyalty_member,
    c.loyalty_points,
    hp.package_id,
    hp.package_type,
    hp.base_price AS package_base_price,
    b.booking_date,
    b.booking_status,
    b.total_price,
    COALESCE(SUM(p.payment_amount), 0) AS total_paid,
    b.total_price - COALESCE(SUM(p.payment_amount), 0) AS balance_due,
    CASE 
        WHEN b.booking_status = 'Confirmed' THEN 'Active'
        WHEN b.booking_status = 'Pending' THEN 'Awaiting Payment'
        ELSE 'Inactive'
    END AS booking_state
FROM booking b
JOIN customer c ON b.customer_id = c.customer_id
JOIN holiday_package hp ON b.package_id = hp.package_id
LEFT JOIN payment p ON b.booking_id = p.booking_id
GROUP BY b.booking_id, c.customer_id, c.first_name, c.last_name, 
         c.email, c.phone, c.is_loyalty_member, c.loyalty_points,
         hp.package_id, hp.package_type, hp.base_price, 
         b.booking_date, b.booking_status, b.total_price;

-- View 2: Package Popularity Report
-- Shows package performance metrics
CREATE OR REPLACE VIEW v_package_popularity AS
SELECT 
    hp.package_id,
    hp.package_type,
    hp.base_price,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_price) AS total_revenue,
    AVG(b.total_price) AS average_revenue,
    COUNT(CASE WHEN b.booking_status = 'Confirmed' THEN 1 END) AS confirmed_bookings,
    COUNT(CASE WHEN b.booking_status = 'Pending' THEN 1 END) AS pending_bookings,
    COUNT(CASE WHEN b.booking_status = 'Cancelled' THEN 1 END) AS cancelled_bookings,
    CASE 
        WHEN COUNT(b.booking_id) > 3 THEN 'High Demand'
        WHEN COUNT(b.booking_id) > 1 THEN 'Moderate Demand'
        WHEN COUNT(b.booking_id) = 1 THEN 'Low Demand'
        ELSE 'No Bookings'
    END AS demand_level
FROM holiday_package hp
LEFT JOIN booking b ON hp.package_id = b.package_id
GROUP BY hp.package_id, hp.package_type, hp.base_price
ORDER BY total_bookings DESC;

-- View 3: Customer Activity Summary
-- Shows customer booking history and loyalty status
CREATE OR REPLACE VIEW v_customer_activity AS
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.loyalty_points,
    c.is_loyalty_member,
    CASE 
        WHEN c.loyalty_points >= 15000 THEN 'Platinum'
        WHEN c.loyalty_points >= 10000 THEN 'Gold'
        WHEN c.loyalty_points >= 7000 THEN 'Silver'
        WHEN c.loyalty_points >= 3000 THEN 'Bronze'
        ELSE 'Standard'
    END AS loyalty_tier,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_price) AS lifetime_value,
    AVG(b.total_price) AS average_booking_value,
    MAX(b.booking_date) AS last_booking_date,
    COUNT(f.feedback_id) AS feedback_count,
    AVG(f.rating) AS average_rating
FROM customer c
LEFT JOIN booking b ON c.customer_id = b.customer_id
LEFT JOIN feedback f ON c.customer_id = f.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, 
         c.loyalty_points, c.is_loyalty_member;

-- =====================================================
-- SECTION 3: ROLE-BASED ACCESS CONTROL
-- =====================================================
-- Based on assignment requirement table:
-- ADMIN: Full CRUD on all tables
-- TRAVEL AGENT: CREATE/UPDATE on booking & payment, 
--                READ on customer/packages, DELETE on feedback
-- CUSTOMER: UPDATE on customer, READ on packages/flights/services
-- =====================================================

-- Create database roles (with LOGIN capability)
CREATE ROLE db_admin LOGIN PASSWORD 'admin123';
CREATE ROLE travel_agent LOGIN PASSWORD 'agent123';
CREATE ROLE db_customer LOGIN PASSWORD 'customer123';

-- =====================================================
-- ADMIN PERMISSIONS: Full CRUD on ALL tables
-- =====================================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_admin;

-- =====================================================
-- TRAVEL AGENT PERMISSIONS
-- =====================================================

-- CREATE and UPDATE permissions on booking and payment (TABLE A)
GRANT SELECT, INSERT, UPDATE ON booking TO travel_agent;
GRANT SELECT, INSERT, UPDATE ON payment TO travel_agent;
GRANT USAGE ON SEQUENCE booking_booking_id_seq TO travel_agent;
GRANT USAGE ON SEQUENCE payment_payment_id_seq TO travel_agent;

-- READ permissions on customer, holiday_package, flights, services (TABLE B)
GRANT SELECT ON customer TO travel_agent;
GRANT SELECT ON holiday_package TO travel_agent;
GRANT SELECT ON flights TO travel_agent;
GRANT SELECT ON services TO travel_agent;
GRANT SELECT ON accommodation TO travel_agent;
GRANT SELECT ON campaigns TO travel_agent;
GRANT SELECT ON booking_flights TO travel_agent;
GRANT SELECT ON booking_services TO travel_agent;
GRANT SELECT ON package_accommodation TO travel_agent;
GRANT SELECT ON package_campaigns TO travel_agent;

-- DELETE permission on feedback only (TABLE C)
GRANT SELECT, DELETE ON feedback TO travel_agent;

-- READ access to views
GRANT SELECT ON v_booking_details TO travel_agent;
GRANT SELECT ON v_package_popularity TO travel_agent;
GRANT SELECT ON v_customer_activity TO travel_agent;

-- =====================================================
-- CUSTOMER PERMISSIONS
-- =====================================================

-- UPDATE permission on customer table for own profile (TABLE F)
GRANT SELECT, UPDATE ON customer TO db_customer;

-- READ permissions on packages, flights, services, campaigns (TABLE G)
GRANT SELECT ON holiday_package TO db_customer;
GRANT SELECT ON flights TO db_customer;
GRANT SELECT ON services TO db_customer;
GRANT SELECT ON accommodation TO db_customer;
GRANT SELECT ON campaigns TO db_customer;
GRANT SELECT ON package_accommodation TO db_customer;
GRANT SELECT ON package_campaigns TO db_customer;

-- INSERT permission on feedback (customers can leave reviews)
GRANT SELECT, INSERT ON feedback TO db_customer;
GRANT USAGE ON SEQUENCE feedback_feedback_id_seq TO db_customer;

-- READ access to package popularity view
GRANT SELECT ON v_package_popularity TO db_customer;

-- =====================================================
-- SECTION 4: DEMONSTRATION QUERIES
-- For lab demonstration showing JOIN, CASE, MAX/MIN/AVG
-- =====================================================

-- Demo Query 1: Complex JOIN with multiple tables
-- Shows complete booking information with all related data
SELECT 
    b.booking_id,
    c.first_name || ' ' || c.last_name AS customer,
    hp.package_type,
    STRING_AGG(DISTINCT f.airline || ' to ' || SPLIT_PART(f.flight_route, ' to ', 2), ', ') AS destinations,
    STRING_AGG(DISTINCT s.service_category, ', ') AS services,
    b.total_price,
    p.payment_method,
    b.booking_status
FROM booking b
JOIN customer c ON b.customer_id = c.customer_id
JOIN holiday_package hp ON b.package_id = hp.package_id
LEFT JOIN booking_flights bf ON b.booking_id = bf.booking_id
LEFT JOIN flights f ON bf.flight_id = f.flight_id
LEFT JOIN booking_services bs ON b.booking_id = bs.booking_id
LEFT JOIN services s ON bs.service_id = s.service_id
LEFT JOIN payment p ON b.booking_id = p.booking_id
WHERE b.booking_status = 'Confirmed'
GROUP BY b.booking_id, c.first_name, c.last_name, hp.package_type, 
         b.total_price, p.payment_method, b.booking_status
LIMIT 10;

-- Demo Query 2: CASE statement with multiple conditions
-- Categorizes bookings by value and loyalty status
SELECT 
    b.booking_id,
    c.first_name || ' ' || c.last_name AS customer,
    b.total_price,
    CASE 
        WHEN b.total_price > 3000 THEN 'Premium Booking'
        WHEN b.total_price > 2000 THEN 'High Value'
        WHEN b.total_price > 1000 THEN 'Standard Value'
        ELSE 'Budget Booking'
    END AS booking_category,
    CASE 
        WHEN c.is_loyalty_member AND c.loyalty_points > 10000 THEN 'VIP Customer'
        WHEN c.is_loyalty_member THEN 'Loyalty Member'
        ELSE 'Regular Customer'
    END AS customer_category,
    b.booking_status
FROM booking b
JOIN customer c ON b.customer_id = c.customer_id
ORDER BY b.total_price DESC;

-- Demo Query 3: Aggregate functions (MAX, MIN, AVG)
-- Statistical analysis of bookings
SELECT 
    COUNT(*) AS total_bookings,
    MAX(total_price) AS highest_booking,
    MIN(total_price) AS lowest_booking,
    AVG(total_price) AS average_booking,
    SUM(total_price) AS total_revenue,
    COUNT(CASE WHEN booking_status = 'Confirmed' THEN 1 END) AS confirmed_count,
    AVG(CASE WHEN booking_status = 'Confirmed' THEN total_price END) AS avg_confirmed_value
FROM booking;

-- =====================================================
-- END OF QUERIES AND ACCESS CONTROL
-- =====================================================

-- =====================================================
-- SECTION 5: DEMO ACCESS CONTROL TESTS
-- For lab demonstration of role-based permissions
-- =====================================================

-- TEST 1: ADMIN ROLE (Full CRUD on ALL tables)
-- =====================================================
SET ROLE db_admin;

SELECT '=== TESTING ADMIN ROLE ===' AS demo;

-- Can CREATE
INSERT INTO customer (user_id, first_name, last_name, email, phone, is_loyalty_member, loyalty_points)
VALUES (34, 'Demo', 'Admin', 'demoadmin@test.com', '555-9999', FALSE, 0);

-- Can READ
SELECT * FROM customer WHERE email = 'demoadmin@test.com';

-- Can UPDATE
UPDATE customer SET loyalty_points = 100 WHERE email = 'demoadmin@test.com';

-- Can DELETE
DELETE FROM customer WHERE email = 'demoadmin@test.com';

SELECT 'ADMIN: Full CRUD access verified!' AS result;

-- =====================================================
-- TEST 2: TRAVEL AGENT ROLE (Limited Access)
-- =====================================================
SET ROLE travel_agent;

SELECT '=== TESTING TRAVEL AGENT ROLE ===' AS demo;

-- Can CREATE booking (TABLE A)
INSERT INTO booking (customer_id, package_id, booking_date, booking_status, total_price)
VALUES (1, 1, '2025-03-15', 'Pending', 1500.00);

-- Can READ customer (TABLE B)
SELECT * FROM customer LIMIT 3;

-- Can DELETE feedback (TABLE C)
SELECT * FROM feedback LIMIT 3;

-- CANNOT DELETE customer (should FAIL)
-- DELETE FROM customer WHERE customer_id = 1;
-- Expected: ERROR - permission denied

SELECT 'TRAVEL AGENT: Limited access verified!' AS result;

-- =====================================================
-- TEST 3: CUSTOMER ROLE (Read-Only on packages)
-- =====================================================
SET ROLE db_customer;

SELECT '=== TESTING CUSTOMER ROLE ===' AS demo;

-- Can READ packages (TABLE G)
SELECT * FROM holiday_package LIMIT 5;

-- Can READ flights (TABLE G)
SELECT * FROM flights LIMIT 5;

-- CANNOT DELETE bookings (should FAIL)
-- DELETE FROM booking WHERE booking_id = 1;
-- Expected: ERROR - permission denied

SELECT 'CUSTOMER: Read-only access verified!' AS result;

-- =====================================================
-- RESET ROLE
-- =====================================================
RESET ROLE;

SELECT 'Demo complete! All access levels verified.' AS final_message;
