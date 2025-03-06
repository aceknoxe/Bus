-- Enable PostGIS extension for location data
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create enum for schedule types
CREATE TYPE schedule_type AS ENUM ('weekday', 'weekend', 'holiday');

-- Create bus_stops table first (no foreign key dependencies)
CREATE TABLE bus_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    location GEOGRAPHY(POINT) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create bus_routes table second (no foreign key dependencies)
CREATE TABLE bus_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    schedule_type schedule_type NOT NULL DEFAULT 'weekday',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(name)
);

-- Create buses table with foreign key references
CREATE TABLE buses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES bus_routes(id) ON DELETE CASCADE,
    current_stop_id UUID NOT NULL REFERENCES bus_stops(id) ON DELETE CASCADE,
    last_update TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create route_stops junction table with explicit foreign key constraints
CREATE TABLE route_stops (
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
CREATE TABLE route_schedules (
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
CREATE TABLE bus_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id UUID NOT NULL,
    stop_id UUID NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    FOREIGN KEY (bus_id) REFERENCES buses(id) ON DELETE CASCADE,
    FOREIGN KEY (stop_id) REFERENCES bus_stops(id) ON DELETE CASCADE,
    UNIQUE (bus_id, timestamp)
);

-- Add foreign key constraints to buses table
ALTER TABLE buses
    ADD CONSTRAINT fk_bus_route
    FOREIGN KEY (route_id)
    REFERENCES bus_routes(id)
    ON DELETE CASCADE;

ALTER TABLE buses
    ADD CONSTRAINT fk_bus_current_stop
    FOREIGN KEY (current_stop_id)
    REFERENCES bus_stops(id)
    ON DELETE CASCADE;

-- Create bus_updates table for realtime updates
CREATE TABLE bus_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id UUID NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    stop_id UUID NOT NULL REFERENCES bus_stops(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (bus_id, timestamp)
);

-- Create indexes
CREATE INDEX idx_buses_route_id ON buses(route_id);
CREATE INDEX idx_buses_current_stop_id ON buses(current_stop_id);
CREATE INDEX idx_buses_last_update ON buses(last_update);
CREATE INDEX idx_bus_stops_location ON bus_stops USING GIST(location);
CREATE INDEX idx_route_stops_stop_id ON route_stops(stop_id);
CREATE INDEX idx_route_stops_order ON route_stops(route_id, stop_order);
CREATE INDEX idx_route_schedules_route_stop ON route_schedules(route_id, stop_id);
CREATE INDEX idx_route_schedules_arrival ON route_schedules(arrival_time);
CREATE INDEX idx_bus_updates_bus_id ON bus_updates(bus_id);
CREATE INDEX idx_bus_updates_timestamp ON bus_updates(timestamp DESC);

-- Create trigger to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_buses_updated_at
    BEFORE UPDATE ON buses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_bus_stops_updated_at
    BEFORE UPDATE ON bus_stops
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_bus_routes_updated_at
    BEFORE UPDATE ON bus_routes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Create RLS policies
ALTER TABLE buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_schedules ENABLE ROW LEVEL SECURITY;

-- Allow read access to all authenticated users
CREATE POLICY "Allow read access to authenticated users" ON buses
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow read access to authenticated users" ON bus_stops
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow read access to authenticated users" ON bus_routes
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow read access to authenticated users" ON route_stops
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow read access to authenticated users" ON route_schedules
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow modification only by service role
CREATE POLICY "Allow modification by service role" ON buses
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Allow modification by service role" ON bus_stops
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Allow modification by service role" ON bus_routes
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Allow modification by service role" ON route_stops
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Allow modification by service role" ON route_schedules
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Enable RLS and add policies for bus_updates table
ALTER TABLE bus_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to authenticated users" ON bus_updates
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow modification by service role" ON bus_updates
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');