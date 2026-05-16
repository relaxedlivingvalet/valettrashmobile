-- Seed Users Data
-- This file creates test users for all roles

-- Super Admin
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    avatar_url,
    is_active,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'admin@relaxedlivingvalet.com',
    'Super',
    'Admin',
    '+1-555-0001',
    'super_admin',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=admin',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Property Managers
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    avatar_url,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '00000000-0000-0000-0000-000000000002',
    'manager1@relaxedlivingvalet.com',
    'Sarah',
    'Johnson',
    '+1-555-0002',
    'property_manager',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=sarah',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000003',
    'manager2@relaxedlivingvalet.com',
    'Michael',
    'Chen',
    '+1-555-0003',
    'property_manager',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=michael',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Drivers/Porters
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    avatar_url,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '00000000-0000-0000-0000-000000000004',
    'driver1@relaxedlivingvalet.com',
    'James',
    'Wilson',
    '+1-555-0004',
    'driver',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=james',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000005',
    'driver2@relaxedlivingvalet.com',
    'Maria',
    'Garcia',
    '+1-555-0005',
    'driver',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=maria',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000006',
    'driver3@relaxedlivingvalet.com',
    'Robert',
    'Taylor',
    '+1-555-0006',
    'driver',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=robert',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Residents
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    avatar_url,
    is_active,
    created_at,
    updated_at
) VALUES 
(
    '00000000-0000-0000-0000-000000000010',
    'resident1@relaxedlivingvalet.com',
    'Emily',
    'Davis',
    '+1-555-0010',
    'resident',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=emily',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000011',
    'resident2@relaxedlivingvalet.com',
    'David',
    'Miller',
    '+1-555-0011',
    'resident',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=david',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000012',
    'resident3@relaxedlivingvalet.com',
    'Lisa',
    'Anderson',
    '+1-555-0012',
    'resident',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=lisa',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000013',
    'resident4@relaxedlivingvalet.com',
    'John',
    'Smith',
    '+1-555-0013',
    'resident',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=john',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000014',
    'resident5@relaxedlivingvalet.com',
    'Jennifer',
    'Brown',
    '+1-555-0014',
    'resident',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=jennifer',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000015',
    'resident6@relaxedlivingvalet.com',
    'William',
    'Jones',
    '+1-555-0015',
    'resident',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=william',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000016',
    'resident7@relaxedlivingvalet.com',
    'Amanda',
    'White',
    '+1-555-0016',
    'resident',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=amanda',
    true,
    NOW(),
    NOW()
),
(
    '00000000-0000-0000-0000-000000000017',
    'resident8@relaxedlivingvalet.com',
    'Christopher',
    'Martin',
    '+1-555-0017',
    'resident',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=christopher',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;
