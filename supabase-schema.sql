-- ==============================================================================
-- ELLA TRAIN TIMETABLE & TRAIN TIMES (ellatraintimes.com)
-- Complete PostgreSQL / Supabase Schema, Indices, and Row Level Security (RLS)
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. ADMIN PROFILES & ROLES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    role VARCHAR(30) DEFAULT 'station_admin' CHECK (role IN ('station_admin', 'station_master', 'super_admin')),
    must_change_password BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 2. STATIONS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) UNIQUE NOT NULL, -- e.g. ELA, BDA, FOT, KDT
    name_en VARCHAR(100) NOT NULL,
    name_si VARCHAR(100),
    name_ta VARCHAR(100),
    line_name VARCHAR(50) DEFAULT 'Main Line',
    elevation_meters INT DEFAULT 1041,
    milepost_chains VARCHAR(50),
    latitude NUMERIC(10, 6),
    longitude NUMERIC(10, 6),
    is_major_junction BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 3. TRAINS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    train_number VARCHAR(20) UNIQUE NOT NULL, -- e.g. 1005, 1006, 1041
    name_en VARCHAR(100) NOT NULL,            -- e.g. Podi Menike, Ella Odyssey
    name_si VARCHAR(100),
    name_ta VARCHAR(100),
    train_type VARCHAR(50) DEFAULT 'Express', -- Express, Intercity, Night Mail, Tourist Special, Local
    classes_available TEXT[] NOT NULL DEFAULT ARRAY['2nd Class', '3rd Class'],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 4. TIMETABLE SERVICES (Ella Arrivals & Departures)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS timetable_services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    train_id UUID NOT NULL REFERENCES trains(id) ON DELETE CASCADE,
    direction VARCHAR(30) NOT NULL CHECK (direction IN ('to_badulla', 'to_colombo', 'to_kandy')),
    origin_station_id UUID NOT NULL REFERENCES stations(id),
    destination_station_id UUID NOT NULL REFERENCES stations(id),
    arrival_time_ella TIME NOT NULL,
    departure_time_ella TIME NOT NULL,
    operating_days TEXT[] NOT NULL DEFAULT ARRAY['Daily'],
    default_platform VARCHAR(20) DEFAULT 'Platform 1',
    current_status VARCHAR(30) DEFAULT 'On Time' CHECK (current_status IN ('On Time', 'Delayed', 'Cancelled', 'Scheduled', 'Platform Changed')),
    status_note TEXT,
    source_name VARCHAR(150) NOT NULL DEFAULT 'Official Sri Lanka Railways Main Line Working Timetable',
    last_verified_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 5. TIMETABLE STOPS (Intermediate Route Stations)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS timetable_stops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES timetable_services(id) ON DELETE CASCADE,
    station_id UUID NOT NULL REFERENCES stations(id),
    stop_sequence INT NOT NULL,
    arrival_time TIME,
    departure_time TIME,
    is_scenic_viewpoint_stop BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 6. SERVICE ALERTS (Delays, Cancellations & Maintenance Notices)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type VARCHAR(30) NOT NULL CHECK (alert_type IN ('delay', 'cancellation', 'advisory', 'maintenance')),
    title_en VARCHAR(200) NOT NULL,
    title_si VARCHAR(200),
    title_ta VARCHAR(200),
    message_en TEXT NOT NULL,
    message_si TEXT,
    message_ta TEXT,
    affected_train_id UUID REFERENCES trains(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    source_verification VARCHAR(150) NOT NULL DEFAULT 'Ella Station Master Office',
    last_verified_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 7. FARE RECORDS (Sri Lanka Railways Official Tariffs)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fare_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_station_id UUID NOT NULL REFERENCES stations(id),
    to_station_id UUID NOT NULL REFERENCES stations(id),
    distance_km NUMERIC(6, 2) NOT NULL,
    third_class_fare NUMERIC(10, 2) NOT NULL,
    second_class_fare NUMERIC(10, 2) NOT NULL,
    first_class_fare NUMERIC(10, 2),
    observation_fare NUMERIC(10, 2),
    tariff_gazette_reference VARCHAR(150) NOT NULL DEFAULT 'Ministry of Transport Railway Tariff Gazette 2025/2026',
    last_verified_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 8. TOURIST ATTRACTIONS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tourist_attractions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_en VARCHAR(150) NOT NULL,
    name_si VARCHAR(150),
    name_ta VARCHAR(150),
    distance_km NUMERIC(5, 2) NOT NULL,
    walking_time_minutes INT,
    driving_time_minutes INT,
    description_en TEXT NOT NULL,
    description_si TEXT,
    description_ta TEXT,
    image_url TEXT NOT NULL,
    image_attribution TEXT NOT NULL,
    maps_url TEXT NOT NULL,
    traveler_tip TEXT,
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 9. EMERGENCY & IMPORTANT CONTACTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name_en VARCHAR(150) NOT NULL,
    service_name_si VARCHAR(150),
    service_name_ta VARCHAR(150),
    phone_number VARCHAR(50) NOT NULL,
    alternate_number VARCHAR(50),
    description_en TEXT NOT NULL,
    physical_location VARCHAR(200) NOT NULL,
    operating_hours VARCHAR(100) NOT NULL DEFAULT '24 Hours / Daily',
    badge_tag VARCHAR(50),
    last_verified_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 10. FEEDBACK & PASSENGER INQUIRIES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS feedback_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    phone_number VARCHAR(50),
    category VARCHAR(50) NOT NULL CHECK (category IN ('Feedback', 'Complaint', 'Suggestion', 'Timetable Correction', 'Other')),
    message TEXT NOT NULL,
    status VARCHAR(30) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Resolved')),
    admin_private_notes TEXT,
    submitted_ip_hash VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 11. EMAIL NOTIFICATION LOGS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS email_notification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_email VARCHAR(150) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    related_feedback_id UUID REFERENCES feedback_submissions(id) ON DELETE SET NULL,
    dispatch_status VARCHAR(30) DEFAULT 'sent' CHECK (dispatch_status IN ('sent', 'failed', 'queued')),
    error_message TEXT,
    dispatched_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 12. AUDIT LOGS (Administrative Accountability Trail)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_user_id UUID REFERENCES admin_profiles(id) ON DELETE SET NULL,
    action_type VARCHAR(100) NOT NULL,
    details TEXT NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 13. WEBSITE SETTINGS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS website_settings (
    id INT PRIMARY KEY DEFAULT 1,
    site_title VARCHAR(150) DEFAULT 'Ella Train Timetable & Train Times',
    site_description TEXT DEFAULT 'Independent timetable, arrival & departure schedules, ticket fares, station guide, and travel alerts for Ella Railway Station, Sri Lanka.',
    official_railway_url VARCHAR(255) DEFAULT 'https://eservices.railway.gov.lk/schedule/homeAction.action?lag=en',
    station_master_email VARCHAR(150) DEFAULT 'ellastation.inquiries@gmail.com',
    notification_sender_email VARCHAR(150) DEFAULT 'alerts@ellatraintimes.com',
    email_notifications_enabled BOOLEAN DEFAULT TRUE,
    google_maps_directions_url TEXT DEFAULT 'https://maps.google.com/?q=Ella+Railway+Station+Sri+Lanka',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT single_row_check CHECK (id = 1)
);

-- ==============================================================================
-- INDEXES FOR HIGH-TRAFFIC SPEED
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_services_train ON timetable_services(train_id);
CREATE INDEX IF NOT EXISTS idx_services_arrival ON timetable_services(arrival_time_ella);
CREATE INDEX IF NOT EXISTS idx_services_departure ON timetable_services(departure_time_ella);
CREATE INDEX IF NOT EXISTS idx_services_direction ON timetable_services(direction);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON service_alerts(is_active);
CREATE INDEX IF NOT EXISTS idx_fares_stations ON fare_records(from_station_id, to_station_id);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback_submissions(status);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at DESC);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE trains ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE fare_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE tourist_attractions ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE website_settings ENABLE ROW LEVEL SECURITY;

-- Helper function to check if the current user is an authenticated Station Admin
CREATE OR REPLACE FUNCTION is_station_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admin_profiles
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. PUBLIC READ ACCESS TO INFORMATION TABLES
CREATE POLICY "Public visitors can view stations" ON stations FOR SELECT USING (true);
CREATE POLICY "Public visitors can view trains" ON trains FOR SELECT USING (true);
CREATE POLICY "Public visitors can view timetable services" ON timetable_services FOR SELECT USING (true);
CREATE POLICY "Public visitors can view timetable stops" ON timetable_stops FOR SELECT USING (true);
CREATE POLICY "Public visitors can view active alerts" ON service_alerts FOR SELECT USING (is_active = true OR is_station_admin());
CREATE POLICY "Public visitors can view fares" ON fare_records FOR SELECT USING (true);
CREATE POLICY "Public visitors can view tourist attractions" ON tourist_attractions FOR SELECT USING (true);
CREATE POLICY "Public visitors can view emergency contacts" ON emergency_contacts FOR SELECT USING (true);
CREATE POLICY "Public visitors can view settings" ON website_settings FOR SELECT USING (true);

-- 2. PUBLIC CAN SUBMIT FEEDBACK (INSERT ONLY)
CREATE POLICY "Public can submit feedback" ON feedback_submissions FOR INSERT WITH CHECK (true);

-- 3. STRICT PRIVACY: PUBLIC CANNOT READ FEEDBACK, AUDIT LOGS, EMAIL LOGS, OR ADMIN PROFILES
CREATE POLICY "Admins can view feedback submissions" ON feedback_submissions FOR SELECT USING (is_station_admin());
CREATE POLICY "Admins can update feedback submissions" ON feedback_submissions FOR UPDATE USING (is_station_admin());

CREATE POLICY "Only admins can view audit logs" ON audit_logs FOR SELECT USING (is_station_admin());
CREATE POLICY "Only admins can insert audit logs" ON audit_logs FOR INSERT WITH CHECK (is_station_admin());

CREATE POLICY "Only admins can view email logs" ON email_notification_logs FOR SELECT USING (is_station_admin());
CREATE POLICY "Only admins can view admin profiles" ON admin_profiles FOR SELECT USING (is_station_admin());

-- 4. ONLY AUTHORIZED ADMINS CAN INSERT/UPDATE/DELETE PUBLIC TABLES
CREATE POLICY "Admins can modify stations" ON stations FOR ALL USING (is_station_admin());
CREATE POLICY "Admins can modify trains" ON trains FOR ALL USING (is_station_admin());
CREATE POLICY "Admins can modify timetable services" ON timetable_services FOR ALL USING (is_station_admin());
CREATE POLICY "Admins can modify timetable stops" ON timetable_stops FOR ALL USING (is_station_admin());
CREATE POLICY "Admins can modify alerts" ON service_alerts FOR ALL USING (is_station_admin());
CREATE POLICY "Admins can modify fares" ON fare_records FOR ALL USING (is_station_admin());
CREATE POLICY "Admins can modify attractions" ON tourist_attractions FOR ALL USING (is_station_admin());
CREATE POLICY "Admins can modify emergency contacts" ON emergency_contacts FOR ALL USING (is_station_admin());
CREATE POLICY "Admins can modify settings" ON website_settings FOR ALL USING (is_station_admin());

-- ==============================================================================
-- INITIAL SEED DATA FOR ELLA RAILWAY STATION
-- ==============================================================================
INSERT INTO stations (id, code, name_en, name_si, name_ta, elevation_meters, milepost_chains)
VALUES
('a0000000-0000-0000-0000-000000000001', 'ELA', 'Ella', 'ඇල්ල', 'எல்ல', 1041, '166m 73c'),
('a0000000-0000-0000-0000-000000000002', 'BDA', 'Badulla', 'බදුල්ල', 'பதுளை', 680, '181m 20c'),
('a0000000-0000-0000-0000-000000000003', 'BWL', 'Bandarawela', 'බණ්ඩාරවෙල', 'பண்டாரவளை', 1225, '160m 58c'),
('a0000000-0000-0000-0000-000000000004', 'HPT', 'Haputale', 'හපුතලේ', 'ஹப்புத்தளை', 1431, '153m 44c'),
('a0000000-0000-0000-0000-000000000005', 'NNO', 'Nanu Oya', 'නානුඔය', 'நானு ஓயா', 1613, '128m 20c'),
('a0000000-0000-0000-0000-000000000006', 'HTN', 'Hatton', 'හැටන්', 'ஹட்டன்', 1262, '108m 16c'),
('a0000000-0000-0000-0000-000000000007', 'KDT', 'Kandy', 'මහනුවර', 'கண்டி', 500, '74m 12c'),
('a0000000-0000-0000-0000-000000000008', 'FOT', 'Colombo Fort', 'කොළඹ කොටුව', 'கொழும்பு கோட்டை', 5, '0m 0c')
ON CONFLICT (code) DO NOTHING;

INSERT INTO website_settings (id, site_title, official_railway_url, station_master_email)
VALUES (1, 'Ella Train Timetable & Train Times', 'https://eservices.railway.gov.lk/schedule/homeAction.action?lag=en', 'ellastation.inquiries@gmail.com')
ON CONFLICT (id) DO NOTHING;
