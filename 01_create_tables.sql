-- =====================================================
-- EASYTRAVEL DATABASE - COMPLETE SETUP
-- =====================================================
-- This file does everything in one go:
-- 1. Drops all existing tables
-- 2. Creates all 16 tables (12 main + 4 junction)
-- 3. Inserts all data in correct dependency order
-- =====================================================

-- =====================================================
-- STEP 1: DROP ALL EXISTING TABLES
-- =====================================================

DROP TABLE IF EXISTS package_campaigns CASCADE;
DROP TABLE IF EXISTS package_accommodation CASCADE;
DROP TABLE IF EXISTS booking_services CASCADE;
DROP TABLE IF EXISTS booking_flights CASCADE;
DROP TABLE IF EXISTS feedback CASCADE;
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS booking CASCADE;
DROP TABLE IF EXISTS taxi_transfers CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS flights CASCADE;
DROP TABLE IF EXISTS accommodation CASCADE;
DROP TABLE IF EXISTS holiday_package CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS role CASCADE;

-- =====================================================
-- STEP 2: CREATE ALL TABLES
-- =====================================================

-- Table 1: role
CREATE TABLE role (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

-- Table 2: users
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL,
    FOREIGN KEY (role_id) REFERENCES role(role_id) ON DELETE CASCADE
);

-- Table 3: customer
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    is_loyalty_member BOOLEAN DEFAULT FALSE,
    loyalty_points INTEGER DEFAULT 0 CHECK (loyalty_points >= 0),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Table 4: holiday_package
CREATE TABLE holiday_package (
    package_id SERIAL PRIMARY KEY,
    package_type VARCHAR(100) NOT NULL,
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
    description TEXT
);

-- Table 5: accommodation
CREATE TABLE accommodation (
    accommodation_id SERIAL PRIMARY KEY,
    accommodation_type VARCHAR(100) NOT NULL,
    room_type VARCHAR(100),
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
    amenities TEXT
);

-- Table 6: flights
CREATE TABLE flights (
    flight_id SERIAL PRIMARY KEY,
    airline VARCHAR(100) NOT NULL,
    flight_route VARCHAR(255) NOT NULL,
    class_type VARCHAR(50) NOT NULL,
    seat_capacity INTEGER NOT NULL CHECK (seat_capacity > 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0)
);

-- Table 7: services
CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_category VARCHAR(100) NOT NULL,
    service_description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0)
);

-- Table 8: taxi_transfers
CREATE TABLE taxi_transfers (
    transfer_id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL,
    transfer_type VARCHAR(50) NOT NULL,
    passenger_capacity INTEGER NOT NULL CHECK (passenger_capacity > 0),
    route_description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE
);

-- Table 9: booking
CREATE TABLE booking (
    booking_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL,
    booking_date DATE NOT NULL DEFAULT CURRENT_DATE,
    booking_status VARCHAR(50) NOT NULL CHECK (booking_status IN ('Pending', 'Confirmed', 'Cancelled')),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES holiday_package(package_id) ON DELETE CASCADE
);

-- Table 10: payment
CREATE TABLE payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL CHECK (payment_amount >= 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE
);

-- Table 11: feedback
CREATE TABLE feedback (
    feedback_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comments TEXT,
    feedback_date DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE
);

-- Table 12: campaigns
CREATE TABLE campaigns (
    campaign_id SERIAL PRIMARY KEY,
    campaign_name VARCHAR(255) NOT NULL,
    discount_percentage DECIMAL(5,2) NOT NULL CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_loyalty_exclusive BOOLEAN DEFAULT FALSE
);

-- JUNCTION TABLE 1: booking_flights (Booking M:N Flights)
CREATE TABLE booking_flights (
    booking_id INTEGER NOT NULL,
    flight_id INTEGER NOT NULL,
    PRIMARY KEY (booking_id, flight_id),
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id) ON DELETE CASCADE
);

-- JUNCTION TABLE 2: booking_services (Booking M:N Services)
CREATE TABLE booking_services (
    booking_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    PRIMARY KEY (booking_id, service_id),
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE
);

-- JUNCTION TABLE 3: package_accommodation (Holiday_Package M:N Accommodation)
CREATE TABLE package_accommodation (
    package_id INTEGER NOT NULL,
    accommodation_id INTEGER NOT NULL,
    PRIMARY KEY (package_id, accommodation_id),
    FOREIGN KEY (package_id) REFERENCES holiday_package(package_id) ON DELETE CASCADE,
    FOREIGN KEY (accommodation_id) REFERENCES accommodation(accommodation_id) ON DELETE CASCADE
);

