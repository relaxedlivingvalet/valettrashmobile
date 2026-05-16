-- Seed Units Data
-- This file creates test units for all floors

-- Units for Sunset Gardens Building A - Floor 1
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    '101',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    '102',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000003',
    '30000000-0000-0000-0000-000000000001',
    '103',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000004',
    '30000000-0000-0000-0000-000000000001',
    '104',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building A - Floor 2
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000005',
    '30000000-0000-0000-0000-000000000002',
    '201',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000006',
    '30000000-0000-0000-0000-000000000002',
    '202',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000007',
    '30000000-0000-0000-0000-000000000002',
    '203',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000008',
    '30000000-0000-0000-0000-000000000002',
    '204',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building A - Floor 3
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000009',
    '30000000-0000-0000-0000-000000000003',
    '301',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000010',
    '30000000-0000-0000-0000-000000000003',
    '302',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000011',
    '30000000-0000-0000-0000-000000000003',
    '303',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000012',
    '30000000-0000-0000-0000-000000000003',
    '304',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building B - Floor 1
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000013',
    '30000000-0000-0000-0000-000000000004',
    '105',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000014',
    '30000000-0000-0000-0000-000000000004',
    '106',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000015',
    '30000000-0000-0000-0000-000000000004',
    '107',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000016',
    '30000000-0000-0000-0000-000000000004',
    '108',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building B - Floor 2
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000017',
    '30000000-0000-0000-0000-000000000005',
    '205',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000018',
    '30000000-0000-0000-0000-000000000005',
    '206',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000019',
    '30000000-0000-0000-0000-000000000005',
    '207',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000020',
    '30000000-0000-0000-0000-000000000005',
    '208',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building B - Floor 3
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000021',
    '30000000-0000-0000-0000-000000000006',
    '305',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000022',
    '30000000-0000-0000-0000-000000000006',
    '306',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000023',
    '30000000-0000-0000-0000-000000000006',
    '307',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000024',
    '30000000-0000-0000-0000-000000000006',
    '308',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building B - Floor 4
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000025',
    '30000000-0000-0000-0000-000000000007',
    '405',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000026',
    '30000000-0000-0000-0000-000000000007',
    '406',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000027',
    '30000000-0000-0000-0000-000000000007',
    '407',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000028',
    '30000000-0000-0000-0000-000000000007',
    '408',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building C - Floor 1
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000029',
    '30000000-0000-0000-0000-000000000008',
    '109',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000030',
    '30000000-0000-0000-0000-000000000008',
    '110',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000031',
    '30000000-0000-0000-0000-000000000008',
    '111',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000032',
    '30000000-0000-0000-0000-000000000008',
    '112',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building C - Floor 2
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000033',
    '30000000-0000-0000-0000-000000000009',
    '209',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000034',
    '30000000-0000-0000-0000-000000000009',
    '210',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000035',
    '30000000-0000-0000-0000-000000000009',
    '211',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000036',
    '30000000-0000-0000-0000-000000000009',
    '212',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Sunset Gardens Building C - Floor 3
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000037',
    '30000000-0000-0000-0000-000000000010',
    '309',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000038',
    '30000000-0000-0000-0000-000000000010',
    '310',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000039',
    '30000000-0000-0000-0000-000000000010',
    '311',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000040',
    '30000000-0000-0000-0000-000000000010',
    '312',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Oakwood Heights Building 1 - Floor 1
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000041',
    '30000000-0000-0000-0000-000000000011',
    'A101',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000042',
    '30000000-0000-0000-0000-000000000011',
    'A102',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000043',
    '30000000-0000-0000-0000-000000000011',
    'A103',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000044',
    '30000000-0000-0000-0000-000000000011',
    'A104',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Oakwood Heights Building 1 - Floor 2
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000045',
    '30000000-0000-0000-0000-000000000012',
    'A201',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000046',
    '30000000-0000-0000-0000-000000000012',
    'A202',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000047',
    '30000000-0000-0000-0000-000000000012',
    'A203',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000048',
    '30000000-0000-0000-0000-000000000012',
    'A204',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Oakwood Heights Building 2 - Floor 1
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000049',
    '30000000-0000-0000-0000-000000000013',
    'B101',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000050',
    '30000000-0000-0000-0000-000000000013',
    'B102',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000051',
    '30000000-0000-0000-0000-000000000013',
    'B103',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000052',
    '30000000-0000-0000-0000-000000000013',
    'B104',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Units for Oakwood Heights Building 2 - Floor 2
INSERT INTO public.units (
    id,
    floor_id,
    unit_number,
    sort_order,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '40000000-0000-0000-0000-000000000053',
    '30000000-0000-0000-0000-000000000014',
    'B201',
    1,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000054',
    '30000000-0000-0000-0000-000000000014',
    'B202',
    2,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000055',
    '30000000-0000-0000-0000-000000000014',
    'B203',
    3,
    true,
    NOW(),
    NOW()
),
(
    '40000000-0000-0000-0000-000000000056',
    '30000000-0000-0000-0000-000000000014',
    'B204',
    4,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;
