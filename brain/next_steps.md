# Next Steps

## Completed (2026-05-16)
- [x] `mobile/.env` written with Supabase URL + anon key
- [x] Seed data applied: property `10000000...0001`, unit `104`, invite code `WELCOME104`
- [x] `verify_invite_code` RPC confirmed returning `is_valid=true` for `WELCOME104`
- [x] Flutter added to PATH (`C:\Users\e159305\Apps\flutter\bin`)
- [x] `flutter config --enable-web` — done
- [x] App compiles and runs: `flutter run -d chrome`
- [x] Resident signup end-to-end verified (Sunset Gardens → unit 104 → WELCOME104 → dashboard)
- [x] All 6 dashboards confirmed loading with real Supabase data

## Completed (2026-05-16 session 4)
- [x] Fixed `SimpleAuthScreen` Form widget bug (null crash on every sign-in attempt)
- [x] Fixed `AuthGate` routing — added `operations_manager` case + import for `ManagerDashboardScreen`
- [x] Added `operations_manager` to `user_role` DB enum
- [x] Created PM, OM, and worker test accounts with proper `user_properties`/`worker_assignments` rows
- [x] Verified all 5 role dashboards with real Supabase data (PM, OM, Worker, Resident, Owner)

## Completed — Full Redesign (Phases 1–5) (2026-05-16)
- [x] Phase 1: Design token system (AppColors, AppTypography, AppTheme.dark), shared widget library (GlowBadge, StatTile, SkeletonCard, RoleHeroCard, PrimaryButton, RoleBottomNav)
- [x] Phase 2: ResidentDashboardScreen — 4-tab dark redesign (Home, History, Alerts, Profile)
- [x] Phase 3: WorkerDashboardScreen — 4-tab dark redesign (Route, Comebacks, Violations, Profile)
- [x] Phase 3: ViolationReportScreen — multi-step form (photo → type → details → confirm) with LottieSuccessView on submit
- [x] Phase 4: PropertyManagerDashboardNewScreen — 4-tab dark redesign (Portfolio, Residents/Codes, Notify, Settings)
- [x] Phase 4: ManagerDashboardScreen (OM) — 4-tab dark redesign (Dashboard, Workers, Comebacks, Notify)
- [x] Phase 4: OwnerDashboardScreen — 4-tab dark redesign (Overview, Properties, Analytics, Settings)
- [x] Phase 5: SharedAxisPageRoute — smooth horizontal screen transitions wired into Violation Report, Comebacks, Notification Sender
- [x] Phase 5: Lottie assets created (success.json, error.json) + LottieSuccessView/LottieErrorView widgets
- [x] Phase 5: All analyzer errors fixed — zero errors, clean build

## Completed (2026-05-16 session 5)
- [x] Redesigned 3 old-style screens to dark design system: ResidentViolationsScreen, SimpleNotificationSenderScreen, TodayComebacksScreen
- [x] Added OM Profile tab with sign-out button (5th tab)
- [x] flutter_map route map for workers — WorkerRouteMapScreen (OpenStreetMap, no API key, route stops list)
- [x] Resident missed-pickup reporting — ResidentReportMissedPickupScreen (photo + notes → missed_pickup_requests)
- [x] Worker proof-of-pickup photo — bottom sheet on comeback completion with optional photo upload to violations bucket
- [x] Pickup status banner — resident Home tab polls nightly_runs every 30s, shows "porter is collecting" / "pickup complete" banner

## Schema Changes Applied (2026-05-16)
- `missed_pickup_requests`: `notes text`, `photo_url text` — added via SQL editor
- `properties`: `latitude double precision`, `longitude double precision` — added via SQL editor

## Now — Feature Development (all completed 2026-05-16 session 7)
- [x] Resident: vacation/hold service — ResidentVacationHoldScreen, writes is_on_hold/hold_note to resident_units
- [x] Worker: earnings dashboard — WorkerEarningsScreen reads clock_events; _toggleDuty() persists clock in/out
- [x] PM compliance/SLA reporting — PmComplianceReportScreen with date range picker + CSV export via dart:html
- [x] OM live worker location map — OmWorkerMapScreen with Supabase Realtime stream on worker_locations
- [x] Worker: location sharing button — calls dart:html geolocation + upserts to worker_locations
- [x] Light mode theme for PM/Owner roles — implemented via AppColorsScheme ThemeExtension

## Push Notifications (when ready to ship native)
- Flutter compiles to native iOS + Android — push notifications ARE relevant for mobile
- **Android:** FCM (Firebase Cloud Messaging) — free, no third-party needed
- **iOS:** APNs — requires Apple Developer account ($99/yr); OneSignal simplifies setup
- **Web:** Service Worker + Web Push API — no external service needed
- Defer until preparing for App Store / Play Store submission

## Payments (when ready)
- [ ] Stripe webhook edge function — blocked on Stripe account + webhook secret
- SMS pickup reminders (Twilio) — deprioritized; in-app banner + email covers the use case

## Technical Debt / Improvements
- [x] Replace `withOpacity()` with `.withValues(alpha: ...)` throughout — 23 files, 0 remaining
- [x] Remove `_legacyBuild()` and `_buildLegacyDashboard()` dead code — 867 lines deleted
- [x] Add `.env.example` file for developer onboarding
- [ ] Upgrade `supabase_flutter` from v1.10.25 to v2 — **BLOCKED**: transitive deps `app_links-7.0.0` and `sign_in_with_apple_web` not resolving in this environment (missing from pub cache, `pub cache repair` didn't fix it). Try on a machine with full internet access or VPN.
- [ ] Add integration tests for the invite code flow
- [ ] Clarify `main_simple.dart` — remove or document purpose
- [ ] Confirm admin_dashboard targets the correct Supabase project

## Blocked / Waiting
- Stripe integration blocked on Stripe account setup and webhook secret
- OneSignal blocked on OneSignal app ID / account setup
