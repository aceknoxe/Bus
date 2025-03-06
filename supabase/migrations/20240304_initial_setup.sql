-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;

-- Import schema
\ir ../../database/schema.sql

-- Import functions
\ir ../../database/functions.sql

-- Import seed data
\ir ../../database/seed.sql
