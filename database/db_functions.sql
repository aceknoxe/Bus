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