-- Migration timestamp: 20240305

-- Create schedule_type enum if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'schedule_type') THEN
        CREATE TYPE schedule_type AS ENUM ('weekday', 'weekend');
    END IF;
END$$;

-- Create bus_routes table if not exists
CREATE TABLE IF NOT EXISTS bus_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    schedule_type schedule_type NOT NULL DEFAULT 'weekday',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(name)
);

-- Create bus_stops table if not exists
CREATE TABLE IF NOT EXISTS bus_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    location GEOGRAPHY(POINT) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create buses table if not exists
CREATE TABLE IF NOT EXISTS buses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES bus_routes(id) ON DELETE CASCADE,
    current_stop_id UUID NOT NULL REFERENCES bus_stops(id) ON DELETE CASCADE,
    last_update TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create bus_updates table if not exists
CREATE TABLE IF NOT EXISTS bus_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id UUID NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    stop_id UUID NOT NULL REFERENCES bus_stops(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (bus_id, timestamp)
);

-- Enable RLS and add policies for bus_updates table
DO $$
BEGIN
    ALTER TABLE bus_updates ENABLE ROW LEVEL SECURITY;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bus_updates' AND policyname = 'Allow read access to authenticated users') THEN
        CREATE POLICY "Allow read access to authenticated users" ON bus_updates
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bus_updates' AND policyname = 'Allow modification by service role') THEN
        CREATE POLICY "Allow modification by service role" ON bus_updates
            FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
    END IF;
END
$$;

-- Insert bus routes first
INSERT INTO bus_routes (id, name, description, schedule_type) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Route 1', 'Main city route', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Route 2', 'Secondary city route', 'weekday'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Express Route', 'Fast connection between major hubs', 'weekday'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Airport Shuttle', 'Direct service to airport', 'weekday'),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Metro Connect', 'Connecting metro stations', 'weekday'),
  ('88888888-8888-8888-8888-888888888888', 'Night Bus', 'Late night service', 'weekday'),
  ('66666666-6666-6666-6666-666666666666', 'Shopping Route', 'Weekend shopping centers route', 'weekend');

-- Insert bus stops
INSERT INTO bus_stops (id, name, location) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Central Station', ST_Point(0, 0)),
  ('22222222-2222-2222-2222-222222222222', 'Market Square', ST_Point(1, 1)),
  ('33333333-3333-3333-3333-333333333333', 'University', ST_Point(2, 2)),
  ('44444444-4444-4444-4444-444444444444', 'Hospital', ST_Point(3, 3)),
  ('66666666-6666-6666-6666-666666666666', 'Shopping Mall', ST_Point(4, 4)),
  ('77777777-7777-7777-7777-777777777777', 'Airport Terminal', ST_Point(5, 5)),
  ('88888888-8888-8888-8888-888888888888', 'Sports Complex', ST_Point(6, 6)),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'Metro Station', ST_Point(7, 7));

-- Insert active buses across routes
INSERT INTO buses (id, route_id, current_stop_id, last_update) VALUES
  -- Route 1 Buses
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', NOW()),
  ('dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', NOW()),
  
  -- Route 2 Buses
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', NOW()),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', NOW()),
  
  -- Airport Shuttle Buses
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', NOW()),
  ('ffffffff-ffff-ffff-ffff-ffffffffff01', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '77777777-7777-7777-7777-777777777777', NOW()),
  
  -- Metro Connect Buses
  ('99999999-9999-9999-9999-999999999999', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NOW()),
  ('99999999-9999-9999-9999-99999999ff01', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '88888888-8888-8888-8888-888888888888', NOW()),
  
  -- Night Bus
  ('88888888-8888-8888-8888-888888888888', '88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', NOW()),
  ('88888888-8888-8888-8888-88888888ff01', '88888888-8888-8888-8888-888888888888', '33333333-3333-3333-3333-333333333333', NOW()),
  
  -- Shopping Route Buses (Weekend)
  ('77777777-7777-7777-7777-777777777777', '66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333', NOW()),
  ('77777777-7777-7777-7777-77777777ff01', '66666666-6666-6666-6666-666666666666', '66666666-6666-6666-6666-666666666666', NOW()),

  -- Express Route Buses
  ('66666666-6666-6666-6666-666666666666', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', NOW()),
  ('66666666-6666-6666-6666-66666666ff01', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', NOW());

-- Function to get all active buses for a route
CREATE OR REPLACE FUNCTION get_active_buses(
  p_route_id UUID,
  p_inactive_threshold_minutes integer DEFAULT 10
)
RETURNS TABLE (
  bus_id UUID,
  current_stop_name VARCHAR,
  last_update TIMESTAMP WITH TIME ZONE,
  minutes_since_update integer,
  next_stop_name VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.id as bus_id,
    current_stop.name as current_stop_name,
    b.last_update,
    EXTRACT(EPOCH FROM (NOW() - b.last_update))/60::integer as minutes_since_update,
    next_stop.name as next_stop_name
  FROM buses b
  JOIN bus_stops current_stop ON b.current_stop_id = current_stop.id
  LEFT JOIN route_stops rs ON
    b.route_id = rs.route_id
    AND b.current_stop_id = rs.stop_id
  LEFT JOIN route_stops next_rs ON
    b.route_id = next_rs.route_id
    AND next_rs.stop_order = rs.stop_order + 1
  LEFT JOIN bus_stops next_stop ON next_rs.stop_id = next_stop.id
  WHERE
    b.route_id = p_route_id
    AND b.last_update > NOW() - (p_inactive_threshold_minutes || ' minutes')::interval
  ORDER BY b.last_update DESC;
END;
$$ LANGUAGE plpgsql;