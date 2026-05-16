-- Seed Billing Data
-- This file creates subscriptions and invoices for testing

-- Subscriptions for residents
INSERT INTO public.subscriptions (
    id,
    resident_user_id,
    property_id,
    stripe_subscription_id,
    status,
    monthly_fee,
    current_period_start,
    current_period_end,
    created_at,
    updated_at
) VALUES 
-- Active subscriptions for Sunset Gardens residents
(
    'e0000000-0000-0000-0000-0000000001',
    '00000000-0000-0000-0000-000000000010',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sXx2eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'e0000000-0000-0000-0000-0000000002',
    '00000000-0000-0000-0000-000000000011',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sYy3eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'e0000000-0000-0000-0000-0000000003',
    '00000000-0000-0000-0000-000000000012',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sZz4eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'e0000000-0000-0000-0000-0000000004',
    '00000000-0000-0000-0000-000000000013',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sAa5eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'e0000000-0000-0000-0000-0000000005',
    '00000000-0000-0000-0000-000000000014',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sBb6eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE)
),
(
    'e0000000-0000-0000-0000-0000000006',
    '00000000-0000-0000-0000-000000000015',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sCc7eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'e0000000-0000-0000-0000-0000000007',
    '00000000-0000-0000-0000-000000000016',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sDd8eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'e0000000-0000-0000-0000-0000000008',
    '00000000-0000-0000-0000-000000000017',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sEe9eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'e0000000-0000-0000-0000-0000000009',
    '00000000-0000-0000-0000-000000000018',
    '10000000-0000-0000-0000-000000000001',
    'sub_1O2sFf10eZvKYlo2C7x2eZvK',
    'active',
    25.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE'
),
-- Active subscriptions for Oakwood Heights residents
(
    'e0000000-0000-0000-0000-0000000010',
    '00000000-0000-0000-0000-000000000019',
    '10000000-0000-0000-0000-000000000002',
    'sub_1O2sGg11eZvKYlo2C7x2eZvK',
    'active',
    20.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'e0000000-0000-0000-0000-0000000011',
    '00000000-0000-0000-0000-000000000020',
    '10000000-0000-0000-0000-000000000002',
    'sub_1O2sHh12eZvKYlo2C7x2eZvK',
    'active',
    20.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'e0000000-0000-0000-0000-0000000012',
    '00000000-0000-0000-0000-000000000021',
    '10000000-0000-0000-0000-000000000002',
    'sub_1O2sIi13eZvKYlo2C7x2eZvK',
    'active',
    20.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE'
),
(
    'e0000000-0000-0000-0000-0000000013',
    '00000000-0000-0000-0000-000000000022',
    '10000000-0000-0000-0000-000000000002',
    'sub_1O2sJj14eZvKYlo2C7x2eZvK',
    'active',
    20.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE'
)
ON CONFLICT (id) DO NOTHING;

-- Invoices for various charges
INSERT INTO public.invoices (
    id,
    resident_user_id,
    property_id,
    stripe_invoice_id,
    amount,
    description,
    due_date,
    paid_at,
    status,
    created_at,
    updated_at
) VALUES 
-- Monthly subscription invoices
(
    'f0000000-0000-0000-0000-0000000001',
    '00000000-0000-0000-0000-000000000010',
    '10000000-0000-0000-0000-000000000001',
    'in_1O2sKk15eZvKYlo2C7x2eZvK',
    25.00,
    'Monthly valet trash service - April 2024',
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '5 days',
    'paid',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '5 days',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
),
(
    'f0000000-0000-0000-0000-0000000002',
    '00000000-0000-0000-0000-000000000011',
    '10000000-0000-0000-0000-000000000001',
    'in_1O2sLl16eZvKYlo2C7x2eZvK',
    25.00,
    'Monthly valet trash service - April 2024',
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '3 days',
    'paid',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '3 days',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
),
-- Violation fee invoices
(
    'f0000000-0000-0000-0000-0000000003',
    '00000000-0000-0000-0000-000000000018',
    '10000000-0000-0000-0000-000000000001',
    'in_1O2sMm17eZvKYlo2C7x2eZvK',
    15.00,
    'Violation fee - Untied bags (April 15, 2024)',
    CURRENT_DATE + INTERVAL '5 days',
    CURRENT_DATE - INTERVAL '1 day',
    'paid',
    CURRENT_DATE - INTERVAL '1 day',
    CURRENT_DATE - INTERVAL '1 day'
),
(
    'f0000000-0000-0000-0000-0000000004',
    '00000000-0000-0000-0000-000000000019',
    '10000000-0000-0000-0000-000000000002',
    'in_1O2sNn18eZvKYlo2C7x2eZvK',
    10.00,
    'Violation fee - Untied bags (April 18, 2024)',
    CURRENT_DATE + INTERVAL '5 days',
    NULL,
    'pending',
    CURRENT_DATE - INTERVAL '1 day',
    CURRENT_DATE - INTERVAL '1 day'
),
-- Comeback pickup fee invoices
(
    'f0000000-0000-0000-0000-0000000005',
    '00000000-0000-0000-0000-000000000013',
    '10000000-0000-0000-0000-000000000001',
    'in_1O2sOo19eZvKYlo2C7x2eZvK',
    15.00,
    'Missed pickup comeback fee - April 16, 2024',
    CURRENT_DATE + INTERVAL '5 days',
    CURRENT_DATE - INTERVAL '3 days',
    'paid',
    CURRENT_DATE - INTERVAL '3 days',
    CURRENT_DATE - INTERVAL '3 days'
),
-- Pending monthly invoices
(
    'f0000000-0000-0000-0000-0000000006',
    '00000000-0000-0000-0000-000000000012',
    '10000000-0000-0000-0000-000000000001',
    'in_1O2sPp20eZvKYlo2C7x2eZvK',
    25.00,
    'Monthly valet trash service - April 2024',
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    NULL,
    'pending',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
),
(
    'f0000000-0000-0000-0000-0000000007',
    '00000000-0000-0000-0000-000000000020',
    '10000000-0000-0000-0000-000000000002',
    'in_1O2sQq21eZvKYlo2C7x2eZvK',
    20.00,
    'Monthly valet trash service - April 2024',
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    NULL,
    'pending',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
),
(
    'f0000000-0000-0000-0000-0000000008',
    '00000000-0000-0000-0000-000000000021',
    '10000000-0000-0000-0000-000000000002',
    'in_1O2sRr22eZvKYlo2C7x2eZvK',
    20.00,
    'Monthly valet trash service - April 2024',
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    NULL,
    'pending',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
),
(
    'f0000000-0000-0000-0000-0000000009',
    '00000000-0000-0000-0000-000000000022',
    '10000000-0000-0000-0000-000000000002',
    'in_1O2sSs23eZvKYlo2C7x2eZvK',
    20.00,
    'Monthly valet trash service - April 2024',
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    NULL,
    'pending',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month',
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
)
ON CONFLICT (id) DO NOTHING;
