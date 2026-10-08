CREATE TABLE IF NOT EXISTS scooters (
    scooter_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code_name VARCHAR(20) NOT NULL UNIQUE,
    model VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('available', 'in_use', 'maintenance', 'broken')),
    battery_level INT NOT NULL CHECK (battery_level BETWEEN 0 AND 100),
    specifications JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS users (
    user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    preferred_tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trips (
    trip_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    scooter_id UUID NOT NULL REFERENCES scooters(scooter_id),
    user_id INT NOT NULL REFERENCES users(user_id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    cost NUMERIC(8, 2) CHECK (cost >= 0),
    route_zones TEXT[] DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS telemetry_logs (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id BIGINT NOT NULL REFERENCES trips(trip_id) ON DELETE CASCADE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    payload JSONB NOT NULL
);
