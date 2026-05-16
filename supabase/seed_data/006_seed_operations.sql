-- Seed Operations Data
-- This file creates nightly runs, pickups, violations, and missed pickup requests

-- Nightly Runs for recent dates
INSERT INTO public.nightly_runs (
    id,
    property_id,
    worker_id,
    run_date,
    started_at,
    completed_at,
    total_units,
    completed_units,
    missed_units,
    violations_count,
    status,
    notes,
    created_at
) VALUES 
-- Yesterday's completed run - Sunset Gardens
(
    '90000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000004',
    CURRENT_DATE - INTERVAL '1 day',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:00:00',
    CURRENT_DATE - INTERVAL '1 day' + TIME '21:45:00',
    12,
    10,
    2,
    1,
    'completed',
    'Good run, all units completed on time',
    NOW()
),
-- Today's active run - Sunset Gardens Building A
(
    '90000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000004',
    CURRENT_DATE,
    CURRENT_TIME - INTERVAL '2 hours',
    NULL,
    12,
    8,
    4,
    0,
    'in_progress',
    'Currently in progress',
    NOW()
),
-- Yesterday's completed run - Oakwood Heights
(
    '90000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000006',
    CURRENT_DATE - INTERVAL '1 day',
    CURRENT_DATE - INTERVAL '1 day' + TIME '17:30:00',
    CURRENT_DATE - INTERVAL '1 day' + TIME '20:30:00',
    16,
    15,
    1,
    2,
    'completed',
    'All units completed, 2 violations reported',
    NOW()
),
-- Today's active run - Oakwood Heights
(
    '90000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000006',
    CURRENT_DATE,
    CURRENT_TIME - INTERVAL '1 hour',
    NULL,
    16,
    10,
    6,
    0,
    'in_progress',
    'Currently in progress',
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Pickups for yesterday's Sunset Gardens run
INSERT INTO public.pickups (
    id,
    nightly_run_id,
    unit_id,
    resident_user_id,
    status,
    completed_at,
    notes,
    created_at,
    updated_at
) VALUES 
-- Completed pickups
(
    'a0000000-0000-0000-0000-0000000001',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000010',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:15:00',
    'Resident had trash ready',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000002',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000011',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:20:00',
    'Standard pickup',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000003',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000012',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:25:00',
    'No issues',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000004',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000009',
    '00000000-0000-0000-0000-000000000013',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:30:00',
    'Regular service',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000005',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000017',
    '00000000-0000-0000-0000-000000000015',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:35:00',
    'All good',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000006',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000021',
    '00000000-0000-0000-0000-000000000016',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:40:00',
    'Standard pickup',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000007',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000025',
    '00000000-0000-0000-0000-000000000017',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:45:00',
    'No problems',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000008',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000029',
    '00000000-0000-0000-0000-000000000018',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:50:00',
    'Regular service',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000009',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000033',
    '00000000-0000-0000-0000-000000000019',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '18:55:00',
    'All set',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000010',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000037',
    '00000000-0000-0000-0000-000000000020',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '19:00:00',
    'Good pickup',
    NOW(),
    NOW()
),
-- Missed pickups
(
    'a0000000-0000-0000-0000-0000000011',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000013',
    '00000000-0000-0000-0000-000000000014',
    'missed',
    NULL,
    'No trash outside door',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000012',
    '90000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000039',
    '00000000-0000-0000-0000-000000000021',
    'completed',
    CURRENT_DATE - INTERVAL '1 day' + TIME '19:05:00',
    'Comeback pickup completed',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Pickups for today's active Sunset Gardens run
INSERT INTO public.pickups (
    id,
    nightly_run_id,
    unit_id,
    resident_user_id,
    status,
    completed_at,
    notes,
    created_at,
    updated_at
) VALUES 
-- Completed pickups today
(
    'a0000000-0000-0000-0000-0000000013',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000010',
    'completed',
    CURRENT_TIME - INTERVAL '1 hour 45 minutes',
    'Completed early',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000014',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000011',
    'completed',
    CURRENT_TIME - INTERVAL '1 hour 40 minutes',
    'No issues',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000015',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000012',
    'completed',
    CURRENT_TIME - INTERVAL '1 hour 35 minutes',
    'Standard pickup',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000016',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000009',
    '00000000-0000-0000-0000-000000000013',
    'completed',
    CURRENT_TIME - INTERVAL '1 hour 30 minutes',
    'All good',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000017',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000017',
    '00000000-0000-0000-0000-000000000015',
    'completed',
    CURRENT_TIME - INTERVAL '1 hour 25 minutes',
    'Regular service',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000018',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000021',
    '00000000-0000-0000-0000-000000000016',
    'completed',
    CURRENT_TIME - INTERVAL '1 hour 20 minutes',
    'Standard pickup',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000019',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000025',
    '00000000-0000-0000-0000-000000000017',
    'completed',
    CURRENT_TIME - INTERVAL '1 hour 15 minutes',
    'No problems',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000020',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000029',
    '00000000-0000-0000-0000-000000000018',
    'completed',
    CURRENT_TIME - INTERVAL '1 hour 10 minutes',
    'Regular service',
    NOW(),
    NOW()
),
-- Pending pickups today
(
    'a0000000-0000-0000-0000-0000000021',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000033',
    '00000000-0000-0000-0000-000000000019',
    'pending',
    NULL,
    'Next in route',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000022',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000037',
    '00000000-0000-0000-0000-000000000020',
    'pending',
    NULL,
    'Last unit',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000023',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000013',
    '00000000-0000-0000-0000-000000000014',
    'missed',
    NULL,
    'No trash available',
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-0000000024',
    '90000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000039',
    '00000000-0000-0000-0000-000000000021',
    'comeback_requested',
    NULL,
    'Comeback requested by resident',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;
