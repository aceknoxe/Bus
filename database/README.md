# Bus Tracking System Database Setup

This directory contains the database schema and setup files for the bus tracking system.

## Files

- `schema.sql` - Contains the main database schema with tables, constraints, and indexes
- `functions.sql` - Contains stored procedures for common operations
- `seed.sql` - Contains sample data for testing

## Setup Instructions

1. Create a new Supabase project
2. Go to the SQL Editor in your Supabase dashboard
3. Run the scripts in the following order:
   ```bash
   # 1. Create schema
   schema.sql
   
   # 2. Create functions
   functions.sql
   
   # 3. (Optional) Add sample data
   seed.sql
   ```

## Database Structure

### Tables

- `buses` - Tracks all buses and their current locations
- `bus_stops` - Stores information about bus stops including geo-coordinates
- `bus_routes` - Contains bus route definitions
- `route_stops` - Junction table linking routes to stops with stop order
- `route_schedules` - Stores arrival times for each stop in a route

### Key Features

1. **Spatial Queries**
   - Uses PostGIS for location-based queries
   - `nearby_stops` function to find stops within a radius

2. **Real-time Tracking**
   - Tracks current location of each bus
   - Updates timestamp for last known position
   - Function to get active buses on a route

3. **Schedule Management**
   - Supports different schedule types (weekday/weekend/holiday)
   - Function to get next arrivals at a stop

4. **Security**
   - Row Level Security (RLS) policies for data protection
   - Read-only access for authenticated users
   - Write access restricted to service role

## Environment Setup

Add the following to your .env file:
```
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## API Usage

The database can be accessed through the `BusService` class in `lib/services/bus_service.dart`. Key methods include:

1. Bus Operations
   - `getAllBuses()`
   - `getBusById(String id)`
   - `getBusesByRoute(String routeId)`
   - `updateBusLocation(String busId, String stopId)`

2. Stop Operations
   - `getAllStops()`
   - `getStopById(String id)`
   - `getNearbyStops(double lat, double lng, double radiusInMeters)`

3. Route Operations
   - `getAllRoutes()`
   - `getRouteById(String id)`

## Schema Modifications

When modifying the schema:
1. Create a new migration file with the changes
2. Update the models in the Flutter app
3. Update the `BusService` class if needed
4. Test with sample data before deploying

## Backup and Restore

Supabase automatically handles backups, but you can also:
1. Export data using the Supabase dashboard
2. Use pg_dump for complete backups
3. Run the schema and seed scripts for a fresh setup