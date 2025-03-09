
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create enum for schedule types if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'schedule_type') THEN
        CREATE TYPE schedule_type AS ENUM ('weekday', 'weekend', 'holiday');
    END IF;
END
$$;

-- Create bus_stops table first (no foreign key dependencies)
CREATE TABLE IF NOT EXISTS bus_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    location GEOGRAPHY(POINT) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create bus_routes table second (no foreign key dependencies)
CREATE TABLE IF NOT EXISTS bus_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    schedule_type schedule_type NOT NULL DEFAULT 'weekday',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(name)
);

-- Create buses table with foreign key references
CREATE TABLE IF NOT EXISTS buses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES bus_routes(id) ON DELETE CASCADE,
    current_stop_id UUID NOT NULL REFERENCES bus_stops(id) ON DELETE CASCADE,
    last_update TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create route_stops junction table with explicit foreign key constraints
CREATE TABLE IF NOT EXISTS route_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL,
    stop_id UUID NOT NULL,
    stop_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    FOREIGN KEY (route_id) REFERENCES bus_routes(id) ON DELETE CASCADE,
    FOREIGN KEY (stop_id) REFERENCES bus_stops(id) ON DELETE CASCADE,
    UNIQUE (route_id, stop_order)
);

-- Create route_schedules table with explicit foreign key constraints
CREATE TABLE IF NOT EXISTS route_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL,
    stop_id UUID NOT NULL,
    arrival_time TIME NOT NULL,
    schedule_type schedule_type NOT NULL DEFAULT 'weekday',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    FOREIGN KEY (route_id) REFERENCES bus_routes(id) ON DELETE CASCADE,
    FOREIGN KEY (stop_id) REFERENCES bus_stops(id) ON DELETE CASCADE,
    UNIQUE (route_id, stop_id, arrival_time, schedule_type)
);

-- Create bus_updates table with explicit foreign key constraints
CREATE TABLE IF NOT EXISTS bus_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id UUID NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    stop_id UUID NOT NULL REFERENCES bus_stops(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (bus_id, timestamp)
);

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_buses_route_id ON buses(route_id);
CREATE INDEX IF NOT EXISTS idx_buses_current_stop_id ON buses(current_stop_id);
CREATE INDEX IF NOT EXISTS idx_buses_last_update ON buses(last_update);
CREATE INDEX IF NOT EXISTS idx_bus_stops_location ON bus_stops USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_route_stops_stop_id ON route_stops(stop_id);
CREATE INDEX IF NOT EXISTS idx_route_stops_order ON route_stops(route_id, stop_order);
CREATE INDEX IF NOT EXISTS idx_route_schedules_route_stop ON route_schedules(route_id, stop_id);
CREATE INDEX IF NOT EXISTS idx_route_schedules_arrival ON route_schedules(arrival_time);
CREATE INDEX IF NOT EXISTS idx_bus_updates_bus_id ON bus_updates(bus_id);
CREATE INDEX IF NOT EXISTS idx_bus_updates_timestamp ON bus_updates(timestamp DESC);

-- Create trigger to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_buses_updated_at') THEN
    CREATE TRIGGER update_buses_updated_at
        BEFORE UPDATE ON buses
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_bus_stops_updated_at') THEN
    CREATE TRIGGER update_bus_stops_updated_at
        BEFORE UPDATE ON bus_stops
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_bus_routes_updated_at') THEN
    CREATE TRIGGER update_bus_routes_updated_at
        BEFORE UPDATE ON bus_routes
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at();
  END IF;
END
$$;

-- Enable RLS and create policies if they don't exist
DO $$
BEGIN
    -- Enable RLS
    ALTER TABLE buses ENABLE ROW LEVEL SECURITY;
    ALTER TABLE bus_stops ENABLE ROW LEVEL SECURITY;
    ALTER TABLE bus_routes ENABLE ROW LEVEL SECURITY;
    ALTER TABLE route_stops ENABLE ROW LEVEL SECURITY;
    ALTER TABLE route_schedules ENABLE ROW LEVEL SECURITY;

    -- Create read access policies if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'buses' AND policyname = 'Allow read access to authenticated users') THEN
        CREATE POLICY "Allow read access to authenticated users" ON buses
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bus_stops' AND policyname = 'Allow read access to authenticated users') THEN
        CREATE POLICY "Allow read access to authenticated users" ON bus_stops
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bus_routes' AND policyname = 'Allow read access to authenticated users') THEN
        CREATE POLICY "Allow read access to authenticated users" ON bus_routes
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'route_stops' AND policyname = 'Allow read access to authenticated users') THEN
        CREATE POLICY "Allow read access to authenticated users" ON route_stops
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'route_schedules' AND policyname = 'Allow read access to authenticated users') THEN
        CREATE POLICY "Allow read access to authenticated users" ON route_schedules
            FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    -- Create modification policies if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'buses' AND policyname = 'Allow modification by service role') THEN
        CREATE POLICY "Allow modification by service role" ON buses
            FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bus_stops' AND policyname = 'Allow modification by service role') THEN
        CREATE POLICY "Allow modification by service role" ON bus_stops
            FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bus_routes' AND policyname = 'Allow modification by service role') THEN
        CREATE POLICY "Allow modification by service role" ON bus_routes
            FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'route_stops' AND policyname = 'Allow modification by service role') THEN
        CREATE POLICY "Allow modification by service role" ON route_stops
            FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'route_schedules' AND policyname = 'Allow modification by service role') THEN
        CREATE POLICY "Allow modification by service role" ON route_schedules
            FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
    END IF;
END
$$;

-- Enable RLS and add policies for bus_updates table if they don't exist
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

-- Function to find nearby bus stops within a radius
CREATE OR REPLACE FUNCTION nearby_stops(
  latitude double precision,
  longitude double precision,
  radius_meters double precision
)
RETURNS TABLE (
  id UUID,
  name VARCHAR,
  location GEOGRAPHY,
  route_ids UUID[],
  distance_meters double precision
) AS $$
BEGIN
  RETURN QUERY
  WITH stops_with_routes AS (
    SELECT 
      bs.id,
      bs.name,
      bs.location,
      array_agg(DISTINCT rs.route_id) as route_ids,
      bs.location::geography <-> ST_MakePoint(longitude, latitude)::geography as distance
    FROM bus_stops bs
    LEFT JOIN route_stops rs ON bs.id = rs.stop_id
    WHERE ST_DWithin(
      bs.location::geography,
      ST_MakePoint(longitude, latitude)::geography,
      radius_meters
    )
    GROUP BY bs.id, bs.name, bs.location
  )
  SELECT 
    swr.id,
    swr.name,
    swr.location,
    swr.route_ids,
    swr.distance as distance_meters
  FROM stops_with_routes swr
  ORDER BY distance_meters;
END;
$$ LANGUAGE plpgsql;

-- Function to get a route's next arrivals at a stop
CREATE OR REPLACE FUNCTION get_next_arrivals(
  p_route_id UUID,
  p_stop_id UUID,
  p_schedule_type schedule_type,
  p_current_time TIME
)
RETURNS TABLE (
  arrival_time TIME,
  minutes_until_arrival integer
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rs.arrival_time,
    EXTRACT(EPOCH FROM (
      CASE
        WHEN rs.arrival_time < p_current_time 
        THEN rs.arrival_time + INTERVAL '1 day'
        ELSE rs.arrival_time
      END - p_current_time
    )/60)::integer as minutes_until_arrival
  FROM route_schedules rs
  WHERE 
    rs.route_id = p_route_id
    AND rs.stop_id = p_stop_id
    AND rs.schedule_type = p_schedule_type
    AND (
      rs.arrival_time > p_current_time
      OR p_current_time - rs.arrival_time > INTERVAL '22 hours'
    )
  ORDER BY minutes_until_arrival
  LIMIT 3;
END;
$$ LANGUAGE plpgsql;

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

-- Insert comprehensive bus stops if they don't exist
INSERT INTO bus_stops (id, name, location)
SELECT v.id::UUID, v.name, v.location
FROM (VALUES
  ('11111111-1111-1111-1111-111111111111', 'Central Station', ST_SetSRID(ST_MakePoint(77.5946, 12.9716), 4326)),
  ('22222222-2222-2222-2222-222222222222', 'Tech Park', ST_SetSRID(ST_MakePoint(77.5933, 12.9789), 4326)),
  ('33333333-3333-3333-3333-333333333333', 'Market Square', ST_SetSRID(ST_MakePoint(77.5871, 12.9791), 4326)),
  ('44444444-4444-4444-4444-444444444444', 'University Campus', ST_SetSRID(ST_MakePoint(77.5843, 12.9715), 4326)),
  ('55555555-5555-5555-5555-555555555555', 'Hospital', ST_SetSRID(ST_MakePoint(77.5799, 12.9682), 4326)),
  ('66666666-6666-6666-6666-666666666666', 'Shopping Mall', ST_SetSRID(ST_MakePoint(77.5912, 12.9755), 4326)),
  ('77777777-7777-7777-7777-777777777777', 'Airport Express', ST_SetSRID(ST_MakePoint(77.5982, 12.9698), 4326)),
  ('88888888-8888-8888-8888-888888888888', 'Business District', ST_SetSRID(ST_MakePoint(77.5891, 12.9734), 4326)),
  ('99999999-9999-9999-9999-999999999999', 'Sports Complex', ST_SetSRID(ST_MakePoint(77.5867, 12.9677), 4326)),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'Metro Station', ST_SetSRID(ST_MakePoint(77.5923, 12.9701), 4326))
) AS v(id, name, location)
WHERE NOT EXISTS (
  SELECT 1
  FROM bus_stops
  WHERE id = v.id::UUID
);

-- Insert comprehensive bus routes if they don't exist
INSERT INTO bus_routes (id, name, description, schedule_type)
SELECT v.id::uuid, v.name, v.description, v.schedule_type::schedule_type
FROM (VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Route 1', 'Central Station to Hospital via Tech Park', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Route 2', 'University Loop', 'weekday'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Express 1', 'Direct Central to University', 'weekend'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Route 3', 'Shopping Mall to Business District', 'weekday'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Airport Shuttle', 'Central Station to Airport Express', 'weekday'),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Metro Connect', 'Metro Station to Tech Park', 'weekday'),
  ('99999999-9999-9999-9999-999999999999', 'Sports Special', 'University to Sports Complex', 'weekend'),
  ('88888888-8888-8888-8888-888888888888', 'Night Bus 1', 'Central Station Loop', 'weekday'),
  ('77777777-7777-7777-7777-777777777777', 'Express 2', 'Airport to Business District', 'weekday'),
  ('66666666-6666-6666-6666-666666666666', 'Shopping Route', 'Market Square to Shopping Mall', 'weekend')
) AS v(id, name, description, schedule_type)
WHERE NOT EXISTS (
  SELECT 1
  FROM bus_routes
  WHERE id = v.id::uuid
);

-- Connect routes and stops with comprehensive network if they don't exist
INSERT INTO route_stops (route_id, stop_id, stop_order)
SELECT v.route_id::UUID, v.stop_id::UUID, v.stop_order
FROM (VALUES
  -- Route 1: Central -> Tech Park -> Market -> Hospital
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 1),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 2),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 3),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555', 4),
  
  -- Route 2: University Loop
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', 1),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', 2),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 3),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', 4),
  
  -- Route 3: Shopping Mall -> Business District
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '66666666-6666-6666-6666-666666666666', 1),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '33333333-3333-3333-3333-333333333333', 2),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '88888888-8888-8888-8888-888888888888', 3),
  
  -- Airport Shuttle
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', 1),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '77777777-7777-7777-7777-777777777777', 2),
  
  -- Metro Connect
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 1),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '88888888-8888-8888-8888-888888888888', 2),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '22222222-2222-2222-2222-222222222222', 3),
  
  -- Sports Special
  ('99999999-9999-9999-9999-999999999999', '44444444-4444-4444-4444-444444444444', 1),
  ('99999999-9999-9999-9999-999999999999', '99999999-9999-9999-9999-999999999999', 2),
  
  -- Night Bus
  ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', 1),
  ('88888888-8888-8888-8888-888888888888', '33333333-3333-3333-3333-333333333333', 2),
  ('88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555', 3),
  ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', 4),
  
  -- Express 2
  ('77777777-7777-7777-7777-777777777777', '77777777-7777-7777-7777-777777777777', 1),
  ('77777777-7777-7777-7777-777777777777', '88888888-8888-8888-8888-888888888888', 2),
  
  -- Shopping Route
  ('66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333', 1),
  ('66666666-6666-6666-6666-666666666666', '66666666-6666-6666-6666-666666666666', 2)
) AS v(route_id, stop_id, stop_order)
WHERE NOT EXISTS (
  SELECT 1
  FROM route_stops
  WHERE route_id = v.route_id::uuid::UUID
  AND stop_id = v.stop_id::UUID
  AND stop_order = v.stop_order
);

-- Insert comprehensive route schedules if they don't exist
INSERT INTO route_schedules (route_id, stop_id, arrival_time, schedule_type)
SELECT v.route_id, v.stop_id, v.arrival_time, v.schedule_type
FROM (VALUES
  -- Route 1 Weekday Schedule - Early Morning
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, '06:00'::time, 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', '06:15', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', '06:30', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555', '06:45', 'weekday'),
  
  -- Morning Peak
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '08:00', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', '08:15', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', '08:30', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555', '08:45', 'weekday'),
  
  -- Route 2 Weekday Schedule - Morning Peak
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', '07:00', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', '07:10', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', '07:20', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', '07:30', 'weekday'),
  
  -- Evening Peak
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', '17:00', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', '17:10', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', '17:20', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', '17:30', 'weekday'),
  
  -- Airport Shuttle (Every hour)
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', '06:00'::time, 'weekday'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '77777777-7777-7777-7777-777777777777', '06:30', 'weekday'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', '07:00', 'weekday'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '77777777-7777-7777-7777-777777777777', '07:30', 'weekday'),
  
  -- Night Bus Service
  ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', '23:00', 'weekday'),
  ('88888888-8888-8888-8888-888888888888', '33333333-3333-3333-3333-333333333333', '23:20', 'weekday'),
  ('88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555', '23:40', 'weekday'),
  ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', '00:00', 'weekday'),
  
  -- Weekend Express Service
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '09:00', 'weekend'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', '09:20', 'weekend'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '10:00', 'weekend'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', '10:20', 'weekend'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '11:00', 'weekend'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', '11:20', 'weekend'),
  
  -- Shopping Route (Weekend)
  ('66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333', '10:00', 'weekend'),
  ('66666666-6666-6666-6666-666666666666', '66666666-6666-6666-6666-666666666666', '10:15', 'weekend'),
  ('66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333', '11:00', 'weekend'),
  ('66666666-6666-6666-6666-666666666666', '66666666-6666-6666-6666-666666666666', '11:15', 'weekend')
) AS v(route_id, stop_id, arrival_time, schedule_type)
WHERE NOT EXISTS (
  SELECT 1
  FROM route_schedules
  WHERE route_id = v.route_id::uuid
  AND stop_id = v.stop_id
  AND arrival_time = v.arrival_time::time
  AND schedule_type = v.schedule_type
);

-- Insert sample buses if they don't exist
INSERT INTO buses (id, route_id, current_stop_id, last_update)
SELECT v.id, v.route_id, v.current_stop_id, NOW()
FROM (VALUES
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333')
) AS v(id, route_id, current_stop_id)
WHERE NOT EXISTS (
  SELECT 1
  FROM buses
  WHERE id = v.id
);
