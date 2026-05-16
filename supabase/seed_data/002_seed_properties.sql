-- Seed Properties Data
-- This file creates test properties with buildings, floors, and units

-- Properties
INSERT INTO public.properties (
    id,
    name,
    address,
    city,
    state,
    zip_code,
    company_id,
    service_window_start,
    service_window_end,
    free_comeback_pickups_per_month,
    comeback_pickup_fee,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '10000000-0000-0000-0000-000000000001',
    'Sunset Gardens Apartments',
    '1234 Sunset Boulevard',
    'Los Angeles',
    'CA',
    '90028',
    '00000000-0000-0000-0000-000000000002',
    '18:00:00',
    '22:00:00',
    3,
    15.00,
    true,
    NOW(),
    NOW()
),
(
    '10000000-0000-0000-0000-000000000002',
    'Oakwood Heights',
    '5678 Oak Street',
    'Austin',
    'TX',
    '78701',
    '00000000-0000-0000-0000-000000000003',
    '17:30:00',
    '21:30:00',
    2,
    12.00,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Buildings for Sunset Gardens
INSERT INTO public.buildings (
    id,
    property_id,
    name,
    floors,
    sort_order,
    created_at,
    updated_at
) VALUES 
(
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Building A',
    3,
    1,
    NOW(),
    NOW()
),
(
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'Building B',
    4,
    2,
    NOW(),
    NOW()
),
(
    '20000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000001',
    'Building C',
    3,
    3,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Buildings for Oakwood Heights
INSERT INTO public.buildings (
    id,
    property_id,
    name,
    floors,
    sort_order,
    created_at,
    updated_at
) VALUES 
(
    '20000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000002',
    'Building 1',
    2,
    1,
    NOW(),
    NOW()
),
(
    '20000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000002',
    'Building 2',
    2,
    2,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Floors for Sunset Gardens Building A
INSERT INTO public.floors (
    id,
    building_id,
    floor_number,
    sort_order,
    created_at,
    updated_at
) VALUES 
(
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    1,
    1,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    2,
    2,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000001',
    3,
    3,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Floors for Sunset Gardens Building B
INSERT INTO public.floors (
    id,
    building_id,
    floor_number,
    sort_order,
    created_at,
    updated_at
) VALUES 
(
    '30000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000002',
    1,
    1,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000005',
    '20000000-0000-0000-0000-000000000002',
    2,
    2,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000006',
    '20000000-0000-0000-0000-000000000002',
    3,
    3,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000007',
    '20000000-0000-0000-0000-000000000002',
    4,
    4,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Floors for Sunset Gardens Building C
INSERT INTO public.floors (
    id,
    building_id,
    floor_number,
    sort_order,
    created_at,
    updated_at
) VALUES 
(
    '30000000-0000-0000-0000-000000000008',
    '20000000-0000-0000-0000-000000000003',
    1,
    1,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000009',
    '20000000-0000-0000-0000-000000000003',
    2,
    2,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000010',
    '20000000-0000-0000-0000-000000000003',
    3,
    3,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Floors for Oakwood Heights Building 1
INSERT INTO public.floors (
    id,
    building_id,
    floor_number,
    sort_order,
    created_at,
    updated_at
) VALUES 
(
    '30000000-0000-0000-0000-000000000011',
    '20000000-0000-0000-0000-000000000004',
    1,
    1,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000012',
    '20000000-0000-0000-0000-000000000004',
    2,
    2,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Floors for Oakwood Heights Building 2
INSERT INTO public.floors (
    id,
    building_id,
    floor_number,
    sort_order,
    created_at,
    updated_at
) VALUES 
(
    '30000000-0000-0000-0000-000000000013',
    '20000000-0000-0000-0000-000000000005',
    1,
    1,
    NOW(),
    NOW()
),
(
    '30000000-0000-0000-0000-000000000014',
    '20000000-0000-0000-0000-000000000005',
    2,
    2,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;
