USE opnv;

-- ===============================================
-- 2️⃣ Drop existing tables (safe for rerun)
-- ===============================================
DROP TABLE IF EXISTS stop_times, trips, stops, routes, calendar, calendar_dates;

-- ===============================================
-- 3️⃣ Create tables
-- ===============================================

-- stops
CREATE TABLE stops (
    stop_id VARCHAR(100) PRIMARY KEY,
    stop_code VARCHAR(50),
    stop_name VARCHAR(255) NOT NULL,
    stop_desc TEXT,
    stop_lat DECIMAL(10,7),
    stop_lon DECIMAL(10,7),
    zone_id VARCHAR(50),
    stop_url TEXT,
    location_type TINYINT DEFAULT 0,
    parent_station VARCHAR(100),
    wheelchair_boarding TINYINT
) ENGINE=InnoDB;
CREATE INDEX idx_stops_parent ON stops(parent_station);

-- routes
CREATE TABLE routes (
    route_id VARCHAR(100) PRIMARY KEY,
    agency_id VARCHAR(100),
    route_short_name VARCHAR(50),
    route_long_name VARCHAR(255),
    route_desc TEXT,
    route_type INT NULL,
    route_url TEXT,
    route_color VARCHAR(10),
    route_text_color VARCHAR(10)
) ENGINE=InnoDB;

-- trips
CREATE TABLE trips (
    trip_id VARCHAR(100) PRIMARY KEY,
    route_id VARCHAR(100) NOT NULL,
    service_id VARCHAR(100) NOT NULL,
    trip_headsign VARCHAR(255),
    trip_short_name VARCHAR(50),
    direction_id TINYINT,
    block_id VARCHAR(100),
    shape_id VARCHAR(100),
    wheelchair_accessible TINYINT,
    bikes_allowed TINYINT,
    FOREIGN KEY (route_id) REFERENCES routes(route_id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE INDEX idx_trips_service ON trips(service_id);

-- stop_times (arrival/departure as VARCHAR)
CREATE TABLE stop_times (
    trip_id VARCHAR(100) NOT NULL,
    arrival_time VARCHAR(12) NOT NULL,
    departure_time VARCHAR(12) NOT NULL,
    stop_id VARCHAR(100) NOT NULL,
    stop_sequence INT NOT NULL,
    stop_headsign VARCHAR(255),
    pickup_type TINYINT,
    drop_off_type TINYINT,
    shape_dist_traveled DECIMAL(10,3),
    PRIMARY KEY (trip_id, stop_sequence),
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
    FOREIGN KEY (stop_id) REFERENCES stops(stop_id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE INDEX idx_stop_times_stop_id ON stop_times(stop_id);
CREATE INDEX idx_stop_times_departure ON stop_times(departure_time);

-- calendar
CREATE TABLE calendar (
    service_id VARCHAR(100) PRIMARY KEY,
    monday TINYINT NOT NULL,
    tuesday TINYINT NOT NULL,
    wednesday TINYINT NOT NULL,
    thursday TINYINT NOT NULL,
    friday TINYINT NOT NULL,
    saturday TINYINT NOT NULL,
    sunday TINYINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
) ENGINE=InnoDB;

-- calendar_dates
CREATE TABLE calendar_dates (
    service_id VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    exception_type TINYINT NOT NULL,
    PRIMARY KEY (service_id, date)
) ENGINE=InnoDB;

-- Used in every departure query: JOIN trips ON trip_id, filter by service_id
CREATE INDEX idx_trips_route ON trips(route_id);
CREATE INDEX idx_trips_service ON trips(service_id);

-- Used in every departure query: JOIN routes ON route_id
-- route_id is already PRIMARY KEY so no index needed

-- The big one: stop_times is joined by stop_id AND we need departure_time
-- A composite index covers both the join and the ordering
CREATE INDEX idx_stop_times_stop_dep ON stop_times(stop_id, departure_time);

-- calendar lookups by service_id (JOIN from trips)
CREATE INDEX idx_calendar_service ON calendar(service_id);

-- calendar_dates lookups by service_id + date (both used in JOIN condition)
CREATE INDEX idx_calendar_dates_service_date ON calendar_dates(service_id, date);

-- stop name lookup (used in the stops query)
CREATE INDEX idx_stops_name ON stops(stop_name);

-- idx_stop_times_departure alone is useless since you always filter by stop_id first
DROP INDEX idx_stop_times_departure ON stop_times;



-- ===============================================
-- ✅ Done
-- ===============================================
SELECT 'Tables created!' AS status;