-- Insert sample bus stops
INSERT INTO bus_stops (id, name, location) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Central Station', ST_SetSRID(ST_MakePoint(77.5946, 12.9716), 4326)),
  ('22222222-2222-2222-2222-222222222222', 'Tech Park', ST_SetSRID(ST_MakePoint(77.5933, 12.9789), 4326)),
  ('33333333-3333-3333-3333-333333333333', 'Market Square', ST_SetSRID(ST_MakePoint(77.5871, 12.9791), 4326)),
  ('44444444-4444-4444-4444-444444444444', 'University Campus', ST_SetSRID(ST_MakePoint(77.5843, 12.9715), 4326)),
  ('55555555-5555-5555-5555-555555555555', 'Hospital', ST_SetSRID(ST_MakePoint(77.5799, 12.9682), 4326));

-- Insert sample bus routes
INSERT INTO bus_routes (id, name, description, schedule_type) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Route 1', 'Central Station to Hospital via Tech Park', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Route 2', 'University Loop', 'weekday'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Express 1', 'Direct Central to University', 'weekend');

-- Connect routes and stops
INSERT INTO route_stops (route_id, stop_id, stop_order) VALUES
  -- Route 1
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 1),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 2),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 3),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555', 4),
  -- Route 2
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', 1),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', 2),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 3),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', 4),
  -- Express 1
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 1),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', 2);

-- Insert sample schedules
INSERT INTO route_schedules (route_id, stop_id, arrival_time, schedule_type) VALUES
  -- Route 1 Weekday Schedule
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '07:00', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', '07:15', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', '07:30', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555', '07:45', 'weekday'),
  
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '08:00', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', '08:15', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', '08:30', 'weekday'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555', '08:45', 'weekday'),
  
  -- Route 2 Weekday Schedule
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', '07:00', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', '07:10', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', '07:20', 'weekday'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', '07:30', 'weekday'),
  
  -- Express 1 Weekend Schedule
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '09:00', 'weekend'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', '09:20', 'weekend'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '10:00', 'weekend'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444', '10:20', 'weekend');

-- Insert sample buses
INSERT INTO buses (id, route_id, current_stop_id, last_update) VALUES
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', NOW()),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', NOW()),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', NOW());