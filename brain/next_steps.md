# Next Steps

## Before Submitting to Stores (action required from you)

- [x] **Final app icon** — RLV logo installed at `mobile/assets/icon/`; launcher icons + splash regenerated (May 2026)
- [ ] **iOS signing** — requires macOS + Xcode + Apple Developer account ($99/yr):
  1. Open `ios/Runner.xcworkspace` in Xcode
  2. Set your Apple team under Signing & Capabilities
  3. `flutter build ipa` to produce the `.ipa` for App Store Connect
- [ ] **Android release build** — keystore already configured, run from a machine with Android SDK:
  ```
  flutter build appbundle
  ```
  Upload the `.aab` to Google Play Console
- [x] **Apply migration `007_service_requests.sql`** — applied live May 18 via Supabase MCP (also added `owner` to `user_role` enum). Test: resident Extra Services submit → Admin/Owner inbox.
- [x] **Apply migration `008_resident_comeback_balance_service_time.sql`** — applied live May 18 via Supabase MCP (`resident_comeback_balance_service_time`).
- [x] **Apply migration `009_staff_invites.sql`** — applied live May 19 via Supabase MCP (`staff_invites`).
- [x] **Apply migration `010_property_billing_metrics.sql`** — applied live May 19 (`monthly_fee_per_door`, `minimum_billable_occupancy_percent`).
- [ ] **Staff invite QA** — super admin generates code → Staff signup → lands on correct role dashboard (sign out/in if cached wrong role).
- [ ] **Owner Financials QA** — per-property revenue/door, export CSV, Stripe payout section when data exists.
- [ ] **PM occupancy billing QA** — vacant/occupied per unit; billable ≥ 85% of total units; export unit codes CSV.
- [ ] **Onboard a property end-to-end** — follow `brain/resident_invite_workflow.md` (units → codes → PM export → resident signup).
- [ ] **Re-enable RLS on core tables** — MCP security advisor: 19 `public` tables have RLS off; `users`, `properties`, `resident_units`, `missed_pickup_requests`, `worker_assignments` have policies defined but RLS disabled. Run remediation from dashboard Database Linter or match repo migration SQL; test resident signup + admin flows after each batch.
- [ ] **Production Supabase config** — when deploying to a real domain:
  - Update Site URL from `http://localhost:8091` to `https://yourdomain.com`
  - Add `https://yourdomain.com` to Redirect URLs
  - Enable a real email provider (Resend / SendGrid) for confirmation and reset emails
- [ ] **App Store / Play Store listing** — screenshots (6.7" iPhone, 12.9" iPad for iOS; multiple densities for Android), app description, keywords, age rating, privacy policy URL

---

## QA (in progress)

- [ ] **Resident dashboard retest** — use checklist in `brain/current_state.md` (tabs, bell, countdown, clock-in status, comebacks, extra service → inbox)
- [x] **Commit & push** staff invites — `2a996f7` on `main` (May 19, 2026)
- [x] **Commit & push** owner financials + PM billing + invite playbook — `b41ae6a` on `main` (May 19, 2026)

---

## Next Features (prioritized)

- [x] **Super admin: edit `monthly_fee_per_door` and 85% per property** — Tools → Property Billing Rates; also on Add Property form
- [ ] **Bulk unit import + bulk invite code generate** — CSV upload for apartment unit lists
- [ ] **Stripe Connect webhooks** — populate `contractor_payouts`, subscriptions, invoices from live Stripe
- [ ] **Stripe paid comeback requests + pickup packs** — `ResidentComebackRequestScreen` and `BuyExtraPickupsSection` record DB state; wire Stripe Checkout + webhook. Blocked on Stripe account + webhook secret.
- [ ] **Push notifications** — defer until native build is in TestFlight / Play Store internal testing:
  - Android: FCM (Firebase Cloud Messaging) — free
  - iOS: APNs via FCM or OneSignal — requires Apple Developer account
- [ ] **Worker location on native** — currently uses `dart:html` (web only). Swap to `geolocator` package for iOS/Android builds
- [ ] **CSV export on native** — `PmComplianceReportScreen` uses `dart:html` for download. Swap to `path_provider` + `share_plus` for native builds

---

## Technical Debt

- [ ] `supabase_flutter` v1 → v2 upgrade — **BLOCKED** in this environment (missing transitive deps). Try on a machine with full internet/VPN access
- [ ] `main_simple.dart` — unclear purpose, remove or document
- [ ] Integration tests for invite code flow
- [ ] Confirm `AdminDashboardScreen` RLS policies cover all edge cases with real data at scale

---

## Completed Sessions (summary)

All prior work is complete and documented in `brain/change_log.md`. Summary:

| Session | Key deliverable |
|---|---|
| 1–3 | Initial setup, Supabase schema, seed data, all 6 dashboards connected to real data |
| 4 | Auth bug fixes, OM/PM/Worker test accounts, role routing |
| 5–7 | Dark redesign (all dashboards), violation report, map, worker earnings, vacation hold, CSV export, realtime worker map |
| 8 | Comeback request flow, resident concerns, admin portal (5 tabs), admin RLS |
| 9 | super_admin account, password reset + visibility toggle (all dashboards), Supabase URL config |
| 10 | Owner routing fix, Android + iOS platform setup, permissions, signing, icons, splash, deep links |
| 11 | Owner handoff README rewrite, keystore committed |
| 12 | Full dashboard rebuild — RLV brand spec, BentoCard system, fl_chart, realtime DMs |
| 13 | Brand mockup pixel-alignment (all 5 dashboards), comeback card restored, lint cleanup |
| 14 | Resident mock home layout, Support nav, `service_requests` + owner/admin inboxes |
| 15 | Comeback rules (1 free/mo, banked packs), clock-in worker status, tab/grid fixes, date+time service requests, migrations 007+008 live |
