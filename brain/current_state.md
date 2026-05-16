# Current State

## Current Objective
- DB migrations are fully applied and in sync. Next priority: validate the resident signup flow end-to-end (invite code → account → dashboard).

## Next Action
- Test the resident signup screen with a real invite code from `seed_data/010_seed_invite_codes.sql` (code: `WELCOME104`)

## What Exists

- **Supabase DB** (project: `relaxedl-living`, ref: `airpwzzkyjqzeeqizvft`, AWS us-east-2)
  - Status: Fully migrated — migrations 001, 004, 005, 006 applied
  - All tables exist with correct schema, RLS enabled, SECURITY DEFINER RPCs in place
  - `violations` storage bucket created with RLS policies for residents and workers

- **Flutter mobile app** (`mobile/`)
  - Status: Implemented — auth, role routing, all four dashboards, violation report screen, all screens wired to Supabase (no remaining hardcoded mock data)
  - Entry: `main.dart` → `ValetApp` → `AuthGate` → role-based screen
  - Key screens: SimpleAuthScreen, ResidentSignupScreen, ResidentDashboardScreen, WorkerDashboardScreen, ViolationReportScreen, PropertyManagerDashboardNewScreen, OwnerDashboardScreen, ManagerDashboardScreen, TodayComebacksScreen
  - Rewrites completed (2026-05-16): ManagerDashboardScreen, TodayComebacksScreen, PropertyManagerDashboardNewScreen, OwnerDashboardScreen, WorkerDashboardScreen (comeback fix)
  - Fixes applied: ResidentViolationsScreen (correct field name), ResidentNotificationsScreen (removed debug panel, fixed type mapping, added is_active filter), SimpleNotificationSenderScreen (initialPropertyId/initialMode params)

- **Supabase migrations** (`supabase/migrations/`)
  - Status: Applied to remote DB (done 2026-05-15 via SQL editor)
  - 001: base schema, 004: RLS, 005: invites + user_properties + notifications fix, 006: storage

- **Seed data**
  - `010_seed_invite_codes.sql` — provides invite code `WELCOME104` (not yet confirmed applied to remote)

- **Admin dashboard** (`admin_dashboard/`)
  - Status: Scaffolded but not validated against current DB schema

- **Stripe edge function** (`supabase/functions/stripe-webhook/`)
  - Status: Scaffold only — not deployed

## In Progress / Likely Active Work
- Resident signup flow — screens exist but end-to-end not verified with live DB
- `main_simple.dart` — alternate entry point; purpose unclear, may be a dev artifact

## Known Issues
- `mobile/lib/features/test/screens/test_connection_screen_old.dart` was deleted (D in git status) — may still be imported somewhere
- `supabase_flutter` is pinned at v1.10.25 — v2 migration is a future breaking change
- No `.env` file committed — new developers need to create `mobile/.env` manually

## Open Questions
- Has `seed_data/010_seed_invite_codes.sql` been applied to the remote DB?
- What is `main_simple.dart` used for — should it be removed?
- Is OneSignal token collection planned for Phase 1 or Phase 2?
- Does the admin dashboard target the same Supabase project?

## Resume Instructions
1. Read this file first, then `brain/next_steps.md`
2. Check if seed data (`010_seed_invite_codes.sql`) has been applied
3. Pick up at resident signup end-to-end validation
