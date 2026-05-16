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

## Now — Feature Development
- [ ] OneSignal push notifications — collect device token on login, store in `users` table or dedicated `push_tokens` table, send from edge functions
- [ ] Stripe webhook edge function — `supabase functions deploy stripe-webhook` + set `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` env secrets
- [ ] Twilio SMS integration — pickup reminders for residents
- [ ] Mapbox route mapping for WorkerDashboard — show tonight's route on a map

## Technical Debt / Improvements
- [ ] Replace `withOpacity()` with `.withValues(alpha: ...)` throughout to fix deprecation warnings
- [ ] Remove `_legacyBuild()` and `_buildLegacyDashboard()` dead code from OM/PM dashboard files
- [ ] Upgrade `supabase_flutter` from v1.10.25 to v2 (plan carefully — many breaking changes)
- [ ] Add `.env.example` file so new developers know required variables
- [ ] Add integration tests for the invite code flow
- [ ] Clarify `main_simple.dart` — remove or document purpose
- [ ] Confirm admin_dashboard targets the correct Supabase project

## Blocked / Waiting
- Stripe integration blocked on Stripe account setup and webhook secret
- OneSignal blocked on OneSignal app ID / account setup
