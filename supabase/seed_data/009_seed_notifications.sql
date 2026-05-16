-- Seed Notifications Data
-- This file creates sample notifications for testing

-- Notifications for various users and scenarios
INSERT INTO public.notifications (
    id,
    user_id,
    type,
    title,
    message,
    data,
    is_read,
    push_sent,
    sms_sent,
    created_at
) VALUES 
-- Pickup reminders for residents
(
    'g0000000-0000-0000-0000-0000000001',
    '00000000-0000-0000-0000-000000000010',
    'pickup_reminder',
    'Trash Pickup Tonight',
    'Your valet trash service will start at 6:00 PM. Please have your trash ready outside your door.',
    '{"property_id": "10000000-0000-0000-0000-000000000001", "service_window_start": "18:00"}',
    false,
    true,
    false,
    CURRENT_TIME - INTERVAL '3 hours'
),
(
    'g0000000-0000-0000-0000-0000000002',
    '00000000-0000-0000-0000-000000000011',
    'pickup_reminder',
    'Trash Pickup Tonight',
    'Your valet trash service will start at 6:00 PM. Please have your trash ready outside your door.',
    '{"property_id": "10000000-0000-0000-0000-000000000001", "service_window_start": "18:00"}',
    false,
    true,
    false,
    CURRENT_TIME - INTERVAL '3 hours'
),
(
    'g0000000-0000-0000-0000-0000000003',
    '00000000-0000-0000-0000-000000000018',
    'pickup_reminder',
    'Trash Pickup Tonight',
    'Your valet trash service will start at 5:30 PM. Please have your trash ready outside your door.',
    '{"property_id": "10000000-0000-0000-0000-000000000002", "service_window_start": "17:30"}',
    false,
    true,
    false,
    CURRENT_TIME - INTERVAL '2 hours'
),
-- Team arrived notifications
(
    'g0000000-0000-0000-0000-0000000004',
    '00000000-0000-0000-0000-000000000010',
    'team_arrived',
    'Valet Team Has Arrived',
    'Our valet team has arrived at Sunset Gardens and is starting pickups.',
    '{"property_id": "10000000-0000-0000-0000-000000000001", "worker_name": "James Wilson"}',
    false,
    true,
    false,
    CURRENT_TIME - INTERVAL '1 hour 30 minutes'
),
(
    'g0000000-0000-0000-0000-0000000005',
    '00000000-0000-0000-0000-000000000018',
    'team_arrived',
    'Valet Team Has Arrived',
    'Our valet team has arrived at Oakwood Heights and is starting pickups.',
    '{"property_id": "10000000-0000-0000-0000-000000000002", "worker_name": "Robert Taylor"}',
    false,
    true,
    false,
    CURRENT_TIME - INTERVAL '30 minutes'
),
-- Missed pickup available notifications
(
    'g0000000-0000-0000-0000-0000000006',
    '00000000-0000-0000-0000-000000000014',
    'missed_pickup_available',
    'Missed Pickup - Still Available',
    'Our team is still on site at Sunset Gardens. You can request a missed pickup comeback.',
    '{"property_id": "10000000-0000-0000-0000-000000000001", "expires_in": "45 minutes"}',
    false,
    true,
    false,
    CURRENT_TIME - INTERVAL '45 minutes'
),
-- Violation reported notifications
(
    'g0000000-0000-0000-0000-0000000007',
    '00000000-0000-0000-0000-000000000010',
    'violation_reported',
    'Violation Reported',
    'A violation was reported for your unit: Too many bags. Please review our community guidelines.',
    '{"violation_id": "b0000000-0000-0000-0000-0000000001", "violation_type": "too_many_bags", "fee_amount": 0.00}',
    false,
    true,
    false,
    CURRENT_DATE - INTERVAL '1 day'
),
(
    'g0000000-0000-0000-0000-0000000008',
    '00000000-0000-0000-0000-000000000018',
    'violation_reported',
    'Violation Reported',
    'A violation was reported for your unit: Untied bags. A $10.00 fee has been applied.',
    '{"violation_id": "b0000000-0000-0000-0000-0000000002", "violation_type": "untied_bags", "fee_amount": 10.00}',
    false,
    true,
    false,
    CURRENT_DATE - INTERVAL '1 day'
),
-- Billing alerts
(
    'g0000000-0000-0000-0000-0000000009',
    '00000000-0000-0000-0000-000000000012',
    'billing_alert',
    'Monthly Invoice Available',
    'Your monthly invoice for April 2024 is now available. Amount: $25.00',
    '{"invoice_id": "f0000000-0000-0000-0000-0000000006", "amount": 25.00, "due_date": "2024-05-01"}',
    false,
    true,
    false,
    CURRENT_DATE - INTERVAL '3 days'
),
(
    'g0000000-0000-0000-0000-0000000010',
    '00000000-0000-0000-0000-000000000019',
    'billing_alert',
    'Payment Due Soon',
    'Your monthly payment of $20.00 is due in 5 days. Please ensure your payment method is up to date.',
    '{"invoice_id": "f0000000-0000-0000-0000-0000000007", "amount": 20.00, "due_date": "2024-05-01"}',
    false,
    true,
    false,
    CURRENT_DATE - INTERVAL '5 days'
),
-- Driver notifications
(
    'g0000000-0000-0000-0000-0000000011',
    '00000000-0000-0000-0000-000000000004',
    'pickup_reminder',
    'Route Starting Soon',
    'Your route for Sunset Gardens Building A starts in 30 minutes. 12 units assigned.',
    '{"route_id": "70000000-0000-0000-0000-000000000001", "total_units": 12}',
    false,
    true,
    false,
    CURRENT_TIME - INTERVAL '30 minutes'
),
(
    'g0000000-0000-0000-0000-0000000012',
    '00000000-0000-0000-0000-000000000006',
    'pickup_reminder',
    'Route Starting Soon',
    'Your route for Oakwood Heights starts in 15 minutes. 16 units assigned.',
    '{"route_id": "70000000-0000-0000-0000-000000000003", "total_units": 16}',
    false,
    true,
    false,
    CURRENT_TIME - INTERVAL '15 minutes'
),
-- Property manager notifications
(
    'g0000000-0000-0000-0000-0000000013',
    '00000000-0000-0000-0000-000000000002',
    'violation_reported',
    'New Violation Reported',
    'A new violation requires your review: Untied bags in Building 2, Unit 206.',
    '{"violation_id": "b0000000-0000-0000-0000-0000000003", "property_id": "10000000-0000-0000-0000-000000000002"}',
    false,
    true,
    false,
    CURRENT_DATE - INTERVAL '1 day'
),
(
    'g0000000-0000-0000-0000-0000000014',
    '00000000-0000-0000-0000-000000000003',
    'billing_alert',
    'Monthly Service Report',
    'Yesterday''s service completion: 93.75% completion rate, 2 violations reported.',
    '{"property_id": "10000000-0000-0000-0000-000000000002", "completion_rate": 93.75, "violations": 2}',
    false,
    true,
    false,
    CURRENT_DATE - INTERVAL '1 day'
)
ON CONFLICT (id) DO NOTHING;
