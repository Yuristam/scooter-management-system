-- 1. Создаем тестовых пользователей
INSERT INTO users (email, full_name, preferred_tags, created_at)
SELECT
    lower(random_names.first_name || '.' || random_names.last_name) || '_' || i || '@example.com' AS email,
    random_names.first_name || ' ' || random_names.last_name AS full_name,
    ARRAY[
        CASE WHEN i % 2 = 0 THEN 'eco_mode' ELSE 'sport_mode' END,
        CASE WHEN i % 3 = 0 THEN 'helmet_agreed' ELSE 'no_helmet' END
    ],
    NOW() - (i || ' hours')::interval
FROM generate_series(1, 100) AS i
CROSS JOIN LATERAL (
    SELECT
        (ARRAY['John', 'Elena', 'Alex', 'Maria', 'Dmitry', 'Sophie', 'Liam', 'Emma'])[floor(random() * 8 + 1)] AS first_name,
        (ARRAY['Smith', 'Johnson', 'Ivanov', 'Brown', 'Garcia', 'Miller', 'Davis', 'Wilson'])[floor(random() * 8 + 1)] AS last_name
    WHERE i IS NOT NULL
) AS random_names;

-- 2. Создаем тестовые самокаты
INSERT INTO scooters (code_name, model, status, battery_level, specifications)
SELECT
    'SCOOT-' || LPAD(i::text, 4, '0'),
    CASE WHEN i % 2 = 0 THEN 'Ninebot Max G30' ELSE 'Xiaomi Pro 2' END,
    (ARRAY['available', 'in_use', 'maintenance', 'broken'])[1 + (i % 4)],
    (10 + (i * 7) % 91), -- уровень заряда 10-100%
    jsonb_build_object(
        'firmware', 'v' || (1 + i % 3) || '.' || (i %10),
        'max_speed', CASE WHEN i % 2 = 0 THEN 25 ELSE 20 END,
        'has_helmet', (i % 2= 0)
    )
FROM generate_series(1, 50) AS i;

-- 3. Создание поездок
INSERT INTO trips (scooter_id, user_id, started_at, ended_at, cost, route_zones)
SELECT
    s.scooter_id,
    u.user_id,
    NOW() - (i || ' hours')::interval AS started,
    NOW() - (i || ' hours')::interval + ((10 + i % 50) || ' minutes')::interval AS ended,
    (5 + (i % 30) * 1.5)::numeric(8,2) AS cost,
    ARRAY[
        (ARRAY['center', 'park', 'river_side', 'old_town', 'station'])[1 + (i % 5)],
        (ARRAY['center', 'park', 'river_side', 'old_town', 'station'])[1 + ((i + 2) % 5)]
    ]
FROM generate_series(1, 500) AS i
JOIN (SELECT scooter_id, ROW_NUMBER() OVER () AS rn FROM scooters) s ON s.rn = (i % 50) + 1
JOIN (SELECT user_id, ROW_NUMBER() OVER () AS rn FROM users) u ON u.rn = (i % 100) + 1;

-- 4. Создаем логи телеметрии под поездки
INSERT INTO telemetry_logs (trip_id, recorded_at, payload)
SELECT
    t.trip_id,
    t.started_at + (step || ' minutes')::interval,
    jsonb_build_object(
        'speed_kmh', 10 + (step * 3) %16,
        'battery_level', 90 - step,
        'engine_temp_c', 35 + step %15,
        'errors', CASE WHEN step = 5 AND t.trip_id % 10 = 0 THEN jsonb_build_array('BRAKE_WARMING') ELSE '[]'::jsonb END
    )
FROM trips t
CROSS JOIN generate_series(1, 5) AS step;
