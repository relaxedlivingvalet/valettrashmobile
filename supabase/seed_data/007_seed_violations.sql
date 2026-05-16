-- Seed Violations Data
-- This file creates sample violations for testing

-- Violations from recent runs
INSERT INTO public.violations (
    id,
    pickup_id,
    unit_id,
    resident_user_id,
    worker_user_id,
    violation_type,
    description,
    photo_url,
    is_warning,
    fee_amount,
    status,
    created_at,
    updated_at
) VALUES 
-- Violation from yesterday's Sunset Gardens run
(
    'b0000000-0000-0000-0000-0000000001',
    'a0000000-0000-0000-0000-0000000001',
    '40000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000004',
    'too_many_bags',
    'Resident left 4 bags instead of allowed 2 bags',
    'https://example.com/violation-photos/sample1.jpg',
    true,
    0.00,
    'confirmed',
    CURRENT_DATE - INTERVAL '1 day',
    CURRENT_DATE - INTERVAL '1 day'
),
-- Violations from yesterday's Oakwood Heights run
(
    'b0000000-0000-0000-0000-0000000002',
    'a0000000-0000-0000-0000-0000000003',
    '40000000-0000-0000-0000-000000000042',
    '00000000-0000-0000-0000-000000000018',
    '00000000-0000-0000-0000-000000000006',
    'untied_bags',
    'Trash bags were not properly tied, causing spillage',
    'https://example.com/violation-photos/sample2.jpg',
    false,
    10.00,
    'confirmed',
    CURRENT_DATE - INTERVAL '1 day',
    CURRENT_DATE - INTERVAL '1 day'
),
(
    'b0000000-0000-0000-0000-0000000003',
    'a0000000-0000-0000-0000-0000000004',
    '40000000-0000-0000-0000-000000000046',
    '00000000-0000-0000-0000-000000000019',
    '00000000-0000-0000-0000-000000000006',
    'prohibited_items',
    'Cardboard boxes found in trash (recycling only)',
    'https://example.com/violation-photos/sample3.jpg',
    true,
    0.00,
    'pending',
    CURRENT_DATE - INTERVAL '1 day',
    CURRENT_DATE - INTERVAL '1 day'
),
-- Pending violation from today's run
(
    'b0000000-0000-0000-0000-0000000004',
    'a0000000-0000-0000-0000-0000000023',
    '40000000-0000-0000-0000-000000000013',
    '00000000-0000-0000-0000-000000000014',
    '00000000-0000-0000-0000-000000000004',
    'leaking_bags',
    'Trash bag is leaking and creating mess',
    'https://example.com/violation-photos/sample4.jpg',
    false,
    15.00,
    'pending',
    CURRENT_TIME - INTERVAL '30 minutes',
    CURRENT_TIME - INTERVAL '30 minutes'
)
ON CONFLICT (id) DO NOTHING;

-- Missed Pickup Requests
INSERT INTO public.missed_pickup_requests (
    id,
    pickup_id,
    resident_user_id,
    requested_at,
    completed_at,
    is_free,
    fee_amount,
    status,
    notes,
    created_at
) VALUES 
-- Comeback request from yesterday (completed)
(
    'c0000000-0000-0000-0000-0000000001',
    'a0000000-0000-0000-0000-0000000011',
    '00000000-0000-0000-0000-000000000014',
    CURRENT_DATE - INTERVAL '1 day' + TIME '20:30:00',
    CURRENT_DATE - INTERVAL '1 day' + TIME '21:15:00',
    true,
    0.00,
    'completed',
    'Resident called and requested comeback',
    CURRENT_DATE - INTERVAL '1 day' + TIME '20:30:00'
),
-- Comeback request from today (pending)
(
    'c0000000-0000-0000-0000-0000000002',
    'a0000000-0000-0000-0000-0000000024',
    '00000000-0000-0000-0000-000000000021',
    CURRENT_TIME - INTERVAL '45 minutes',
    NULL,
    true,
    0.00,
    'pending',
    'Resident requested comeback via app',
    CURRENT_TIME - INTERVAL '45 minutes'
),
-- Paid comeback request example
(
    'c0000000-0000-0000-0000-0000000003',
    'a0000000-0000-0000-0000-0000000005',
    '40000000-0000-0000-0000-000000000009',
    '00000000-0000-0000-0000-000000000013',
    CURRENT_DATE - INTERVAL '3 days',
    CURRENT_DATE - INTERVAL '3 days' + TIME '21:30:00',
    false,
    15.00,
    'completed',
    'Third missed pickup this month, charged fee',
    CURRENT_DATE - INTERVAL '3 days' + TIME '20:45:00'
)
ON CONFLICT (id) DO NOTHING;

-- Resident Monthly Usage Tracking
INSERT INTO public.resident_monthly_usage (
    id,
    resident_user_id,
    property_id,
    month,
    free_comeback_used,
    paid_comeback_used,
    violations_count,
    total_fees,
    created_at,
    updated_at
) VALUES 
-- Current month usage for various residents
(
    'd0000000-0000-0000-0000-0000000001',
    '00000000-0000-0000-0000-000000000010',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    1,
    0,
    1,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'd0000000-0000-0000-0000-0000000002',
    '00000000-0000-0000-0000-000000000011',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'd0000000-0000-0000-0000-0000000003',
    '00000000-0000-0000-0000-000000000012',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'd0000000-0000-0000-0000-0000000004',
    '00000000-0000-0000-0000-000000000013',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'd0000000-0000-0000-0000-0000000005',
    '00000000-0000-0000-0000-000000000014',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'd0000000-0000-0000-0000-0000000006',
    '00000000-0000-0000-0000-000000000015',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'd0000000-0000-0000-0000-0000000007',
    '00000000-0000-0000-0000-000000000016',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'd0000000-0000-0000-0000-0000000008',
    '00000000-0000-0000-0000-000000000017',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    1,
    0,
    1,
    15.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'd0000000-0000-0000-0000-0000000009',
    '00000000-0000-0000-0000-000000000018',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'd0000000-0000-0000-0000-00000000010',
    '00000000-0000-0000-0000-000000000019',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'd0000000-0000-0000-0000-00000000011',
    '00000000-0000-0000-0000-000000000020',
    '10000000-0000-0000-0000-000000000001',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE'
),
-- Oakwood Heights residents
(
    'd0000000-0000-0000-0000-00000000012',
    '00000000-0000-0000-0000-000000000018',
    '10000000-0000-0000-0000-000000000002',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    1,
    10.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'd0000000-0000-0000-0000-00000000013',
    '00000000-0000-0000-0000-000000000019',
    '10000000-0000-0000-0000-000000000002',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    1,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'd0000000-0000-0000-0000-00000000014',
    '00000000-0000-0000-0000-000000000020',
    '10000000-0000-0000-0000-000000000002',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'd0000000-0000-0000-0000-00000000015',
    '00000000-0000-0000-0000-000000000021',
    '10000000-0000-0000-0000-000000000002',
    DATE_TRUNC('month', CURRENT_DATE)
    0,
    0,
    0,
    0.00,
    DATE_TRUNC('month', CURRENT_DATE)
    DATE_TRUNC('month', CURRENT_DATE'
)
ON CONFLICT (id) DO NOTHING;
