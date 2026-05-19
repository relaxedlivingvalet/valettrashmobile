# Change Log

## Format
Date | Change | Files Modified | Reason

---

### 2026-05-19 — Brain refresh (resident retest state)

- **Updated**: `brain/current_state.md` (resume notes, retest checklist, migration table, key files, uncommitted warning), `architecture.md`, `decisions.md`, `next_steps.md`
- **Reason**: Single source of truth before client QA

### 2026-05-18 — Applied migration `008` to live Supabase

- **MCP** `resident_comeback_balance_service_time` on `airpwzzkyjqzeeqizvft`: `purchased_comeback_balance`, `preferred_time`, resident UPDATE policy on `resident_units`
- **Verified**: columns present in `information_schema`

### 2026-05-18 — Resident dashboard: comebacks, clock-in status, UI fixes

- **Comebacks**: 1 free/month (no rollover); `purchased_comeback_balance` on `resident_units` (rolls over); packs 1/$5, 3/$14, 5/$20 via `BuyExtraPickupsSection`
- **Worker status**: `clock_events` last event per property (clock_in → ON DUTY)
- **UI**: `IndexedStack` tabs; `ExtraServicesGrid` fixed height; bell → notifications; countdown hours-only; service window 6–10 PM default
- **Service requests**: required date + time; optional message default text; `preferred_time` column (migration 008)
- **Files**: `008_resident_comeback_balance_service_time.sql`, `resident_dashboard_screen.dart`, `resident_comeback_request_screen.dart`, `service_request_sheet.dart`, `extra_services_grid.dart`, `buy_extra_pickups_section.dart`, `comeback_pricing.dart`, brain + `MIGRATIONS.md`
- **Reason**: Resident dashboard business rules + tab glitch / submit fixes from client feedback

### 2026-05-18 — Applied `service_requests` migration to live Supabase

- **MCP migrations** on `airpwzzkyjqzeeqizvft`:
  1. `add_owner_user_role` — `ALTER TYPE user_role ADD VALUE 'owner'` (required; policies failed without it)
  2. `007_service_requests` — table, indexes, RLS, 4 policies
- **Files Modified**: `supabase/migrations/007_service_requests.sql` (prepend enum fix), `brain/current_state.md`, `brain/next_steps.md`, `brain/change_log.md`
- **Reason**: Unblock resident extra-service requests (was 404)

### 2026-05-18 — Supabase MCP live project audit

- **Verified via Cursor Supabase plugin** (`list_tables`, `list_migrations`, `get_advisors`) on project `airpwzzkyjqzeeqizvft`:
  - `service_requests` table **not present** — confirms blocker for resident extra-service workflow
  - `list_migrations` returned empty (migration history not synced to hosted DB)
  - Security advisors: 19 tables RLS-disabled; several tables have policies but RLS off
- **Files Modified**: `brain/current_state.md`, `brain/next_steps.md`, `brain/change_log.md`
- **Reason**: Document live DB truth vs repo assumptions before store submission

---

### 2026-05-17 — Session 13: Brand mockup alignment across all 5 dashboards

- **Files Modified** (5 parallel agents, no conflicts):
  - `manager_dashboard_screen.dart` (OM) — "Operations Overview" header + Today pill; Communities/Routes stat row; large On-Time %; Missed count; Service Completion chart switched to 0-100% completion rate y-axis
  - `worker_dashboard_screen.dart` — "Hello [name]" + "You have N stops today" header; donut center % text overlay; "N of M Stops Complete" label; Next Stop card showing next unit + property name
  - `resident_dashboard_screen.dart` — Property name + dropdown chevron in header; bell notification icon; "All Clear / No missed collections" status when no active run
  - `property_manager_dashboard_new.dart` — "Property Manager View" title + "All Properties" filter pill; Open Requests count card (queries pending comebacks); Work Orders placeholder; Announcements list from `community_announcements`; compliance/satisfaction moved below
  - `owner_dashboard_screen.dart` — "Portfolio Summary" + "This Month" filter pill; Service Savings card with month-over-month % delta; Resident Satisfaction with delta; both query prior-month data from Supabase

- **Colors**: All dashboards already used correct brand palette — no AppColors changes needed (#0A0A0A, #1A1A1A, #3A3A3A, #6B6B6B, #E5E5E5, #0A84FF)

- **Result**: `flutter test` — All tests passed. `flutter analyze` — 0 errors, 0 new warnings in any edited file.

---

### 2026-05-17 — Session 13: Comeback entry point restored + lint finalization

- **Files Modified**:
  - `resident_dashboard_screen.dart` — added `_buildComebackCard()` to Home tab ListView; reads `comeback_pickup_fee` from `properties` row in `_load()`; navigates to `ResidentComebackRequestScreen(freeRemain: _freeRemain, comebackFee: _comebackFee)`; fixed `curly_braces_in_flow_control_structures` lint in `_load()` catch block; added import for `resident_comeback_request_screen.dart`

- **Why**: Session 12 dashboard rebuild dropped the comeback quick-action tile that was wired in Session 8. The `ResidentComebackRequestScreen` existed but was unreachable from the UI.

- **Result**: `flutter analyze lib/features/resident/screens/resident_dashboard_screen.dart` → No issues found. Resident can now tap "Request a Comeback" from the Home tab.

---

### 2026-05-17 — Lint cleanup: warnings + async context bugs

- **Files Modified**:
  - `admin_dashboard_screen.dart` — removed 4 unused imports (`dart:math`, `role_theme.dart`, `glow_badge.dart`, `primary_button.dart`); fixed 4× `use_build_context_synchronously` with `if (!mounted) return;` guards
  - `resident_extra_services_screen.dart` — removed unused `supabase_flutter` import
  - `resident_service_calendar_screen.dart` — removed unused `supabase_flutter` import + dead `lastDayOfMonth` variable
  - `resident_services_screen.dart` — removed unused `supabase_flutter` import
  - `property_manager_dashboard_screen.dart` — removed unused `_email` field + dead `initState` assignment block
  - `manager_property_services_screen.dart` — removed unused `supabase_flutter` import

- **Result**: `flutter analyze lib/` — 0 errors, 0 actionable warnings. Only 2 remaining warnings are `signInWithIdToken is experimental` in `simple_auth_screen.dart` (Supabase-controlled API, not fixable on our end)

---

### 2026-05-17 — Session 12: Full dashboard rebuild (RLV brand sheet + Supabase integration)

- **Goal**: Complete rebuild of all 5 role dashboards to match brand mockups. No Stripe.

- **Files Created**:
  - `mobile/lib/core/widgets/bento_card.dart` — shared dark card (surface1 bg, 16px radius, border)
  - `mobile/lib/core/widgets/metric_tile.dart` — label (9px Inter caps) + value (28px Montserrat w800) + optional subtitle

- **Files Rebuilt** (all zero errors/warnings in `flutter analyze`):
  - `mobile/lib/features/worker/screens/worker_dashboard_screen.dart` — Amazon Flex-style Scan tab (photo confirm OR manual mark done, flag comeback, auto-advance), fl_chart donut for stop progress, realtime direct messaging, clock in/out
  - `mobile/lib/features/manager/screens/manager_dashboard_screen.dart` — BentoCard 2×2 metrics, fl_chart 7-day LineChart for completion trend
  - `mobile/lib/features/owner/screens/owner_dashboard_screen.dart` — BentoCard metrics including "Earned from Comebacks" (completedComebacks × $15)
  - `mobile/lib/features/manager/screens/property_manager_dashboard_new.dart` — community health bento grid, Send Announcement bottom sheet → community_announcements table
  - `mobile/lib/features/resident/screens/resident_dashboard_screen.dart` — fixed subscribe() void result, isFilter → .filter(), removed unused import

- **Critical v1 patterns applied everywhere**:
  - `subscribe()` returns void — must separate from channel chain: `_channel = ...on(...); _channel?.subscribe();`
  - `.isFilter()` is v2-only — use `.filter('col', 'is', 'null')`

- **Verified**: `flutter analyze lib/` — 0 errors, 0 warnings in all 5 dashboard files; `flutter test` — All tests passed

---

### 2026-05-19 — Resident dashboard layout + service requests

- **Supabase**: `007_service_requests.sql` — `service_requests` table (service type, preferred date, message, status) + RLS for residents, owner, super_admin
- **Resident**: Home tab matches mock layout (pickup card, stats, quick actions, services grid, support bar); bottom nav **Support** replaces Messages; service request bottom sheet with dropdown + calendar
- **Admin**: Concerns tab → **Resident Inbox** with Concerns / Service Requests segments
- **Owner**: More tab → **Service Requests Inbox**
- **Files**: `resident_dashboard_screen.dart`, `service_request_sheet.dart`, `resident_concerns_screen.dart` (`ResidentSupportPanel`), `service_requests_inbox_screen.dart`, `admin_dashboard_screen.dart`, `owner_dashboard_screen.dart`

---

### 2026-05-17 — Final app icon

- **Files Modified**:
  - `mobile/assets/icon/app_icon.png`, `app_icon_foreground.png`, `splash_logo.png` — final RLV logo from owner
  - `mobile/pubspec.yaml` — adaptive icon background `#10B981` → `#000000`
  - Regenerated Android mipmaps/adaptive icons, iOS AppIcon, and native splash assets via `flutter_launcher_icons` + `flutter_native_splash`
  - `brain/next_steps.md`, `brain/current_state.md`

- **Reason**: Store submission checklist — replace placeholder icon with production artwork

---

### 2026-05-16 (Session 11 — Owner handoff prep)

- **Files Modified**:
  - `mobile/README.md` — full rewrite as owner handoff guide: feature walkthrough per role, test credentials, step-by-step App Store + Google Play submission guide, Supabase production config steps, future features list
  - `mobile/android/.gitignore` — commented out keystore/jks/key.properties exclusions so signing artifacts are committed (repo is private)
  - `brain/test_credentials.md` — fixed stale `owner` role mapping (was "falls through to resident", now correctly `OwnerDashboardScreen`)
  - `brain/current_state.md` — updated Known Issues to reflect `.env`, keystore, and `key.properties` are all committed

- **Committed to repo**: `mobile/android/upload-keystore.jks` and `mobile/android/key.properties` (previously gitignored)

---

### 2026-05-16 (Session 9 — super_admin account, password reset flow, visibility toggles)

- **DB changes** (Supabase dashboard):
  - Created auth user `relaxedlivingtx@gmail.com` (UID: `14e75f4c-29de-4516-b8d1-7bebe963535d`, pass: `RelaxedLiving2026!`) — business owner / super_admin
  - `INSERT INTO public.users ... role='super_admin'` for that UID
  - Supabase Auth → URL Configuration: Site URL updated to `http://localhost:8091`; `http://localhost:8091` added to Redirect URLs (previously no redirect URLs and wrong port 3000)

- **Files Created**:
  - `mobile/lib/features/auth/screens/change_password_screen.dart` — three-state screen: (1) "Send reset email" with email display, (2) email-sent confirmation with resend button, (3) "Set new password" form (isRecovery=true, launched from AuthGate passwordRecovery event). Password fields have visibility toggles.

- **Files Modified**:
  - `mobile/lib/valet_app.dart` — `AuthGate` StreamBuilder intercepts `AuthChangeEvent.passwordRecovery` → shows `ChangePasswordScreen(isRecovery: true)` before routing to role home
  - `mobile/lib/features/auth/screens/simple_auth_screen.dart` — password field now has `_obscurePassword` state + `suffixIcon` visibility toggle; `_darkField()` extended to accept `Widget? suffixIcon`
  - `mobile/lib/features/auth/screens/resident_signup_screen.dart` — password field has `_obscurePassword` state + visibility toggle; `_field()` helper extended with `VoidCallback? onToggleObscure`
  - `mobile/lib/features/resident/screens/resident_dashboard_screen.dart` — "Change Password" PrimaryButton added before Sign Out in Profile tab
  - `mobile/lib/features/worker/screens/worker_dashboard_screen.dart` — "Change Password" PrimaryButton added before Sign Out in Profile tab
  - `mobile/lib/features/manager/screens/manager_dashboard_screen.dart` — "Change Password" PrimaryButton added before Sign Out in Profile tab
  - `mobile/lib/features/manager/screens/property_manager_dashboard_new.dart` — "Change Password" PrimaryButton added before Sign Out in Settings tab
  - `mobile/lib/features/admin/screens/admin_dashboard_screen.dart` — "Change Password" `_toolTile` added before Sign Out tile in Tools tab

- **Bug fixes**:
  - `change_password_screen.dart` line 78: `supabase.auth.update()` → `supabase.auth.updateUser()` (gotrue-1.12.6 API)

- **Verified**: `flutter build web --no-tree-shake-icons` → `✓ Built build/web` (clean, no errors)
- Added "Forgot password?" link on login screen (right-aligned, below password field, login mode only) → navigates to `ChangePasswordScreen`
- Created `brain/test_credentials.md` — all test accounts, passwords, role→screen mapping, test data

### 2026-05-16 (Session 10 — Owner routing fix + App Store / Play Store prep)

- **Owner routing**: Added `case 'owner':` in `RoleHome` switch → `OwnerDashboardScreen` (light theme). Previously fell through to resident dashboard.

- **Native platform generation**: Ran `flutter create --platforms=android,ios --org com.relaxedliving --project-name valet .`
  - Created `android/` and `ios/` directories
  - Bundle ID / applicationId: `com.relaxedliving.valet`

- **Android** (`android/app/`):
  - `build.gradle.kts` — minSdk 21, release signing via `key.properties`, R8 minification + resource shrinking enabled
  - `src/main/AndroidManifest.xml` — app label "Relaxed Living Valet", added CAMERA, READ_MEDIA_IMAGES, READ_EXTERNAL_STORAGE (maxSdk 32), WRITE_EXTERNAL_STORAGE (maxSdk 28), ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION permissions; deep link intent filter for `com.relaxedliving.valet://login-callback`
  - `app/proguard-rules.pro` — created with Flutter + Supabase/okhttp rules
  - `key.properties` + `upload-keystore.jks` generated (both gitignored); password: `RLValet2026!Key`

- **iOS** (`ios/Runner/Info.plist`):
  - `CFBundleDisplayName` / `CFBundleName` → "Relaxed Living Valet"
  - Added `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, `NSLocationWhenInUseUsageDescription`
  - Added `CFBundleURLTypes` with scheme `com.relaxedliving.valet` for deep links
  - Portrait-only for phones (`UISupportedInterfaceOrientations`)

- **pubspec.yaml**: renamed package `mobile` → `valet`, updated description, added `flutter_launcher_icons ^0.14.3` and `flutter_native_splash ^2.4.3` dev deps with full config

- **App icons**: Created placeholder PNGs at `assets/icon/` (emerald circle with "RL" monogram, dark bg); ran `flutter pub run flutter_launcher_icons` — icons generated for Android (standard + adaptive) and iOS

- **Splash screen**: Configured dark background `#0A0C0F` with splash logo; ran `flutter pub run flutter_native_splash:create` — splash generated for Android (including API 31+) and iOS

- **Deep links**: 
  - `main.dart` — added `authCallbackUrlHostname: 'login-callback'` to `Supabase.initialize()`
  - `change_password_screen.dart` — platform-aware `redirectTo`: `null` on web, `com.relaxedliving.valet://login-callback` on mobile
  - Supabase Auth → Redirect URLs: added `com.relaxedliving.valet://login-callback` (Total: 2 URLs)

- **Verified**: `flutter build web --no-tree-shake-icons` → `✓ Built build/web` (clean after `flutter clean`)

---

### 2026-05-16 (Session 8 — Comeback Requests, Concerns, Admin Portal)

- **DB changes** (Supabase SQL editor):
  - `ALTER TABLE missed_pickup_requests ADD COLUMN IF NOT EXISTS is_free boolean DEFAULT true, payment_status text DEFAULT 'free', payment_amount_cents int, stripe_payment_intent_id text`
  - `ALTER TABLE properties ADD COLUMN IF NOT EXISTS free_comeback_pickups_per_month int DEFAULT 1, comeback_pickup_fee numeric(10,2) DEFAULT 15.00`
  - `CREATE TABLE resident_concerns (id uuid PK, resident_user_id uuid FK users, property_id uuid FK properties, subject text, message text, status text DEFAULT 'open', created_at timestamptz)` + RLS
  - `CREATE TABLE resident_monthly_usage (user_id uuid, year_month text, comeback_count int DEFAULT 0, PRIMARY KEY(user_id, year_month))` + RLS
  - Added `FOR ALL TO authenticated` admin RLS policies on `users`, `properties`, `resident_units`, `resident_concerns`, `missed_pickup_requests`, `invite_codes`, `worker_assignments`

- **Files Created**:
  - `mobile/lib/features/resident/screens/resident_comeback_request_screen.dart` — quota-aware comeback flow (1 free/month, Stripe-ready paid path with placeholder dialog, LottieSuccessView)
  - `mobile/lib/features/resident/screens/resident_concerns_screen.dart` — subject dropdown + message textarea, submits to resident_concerns, LottieSuccessView
  - `mobile/lib/features/admin/screens/admin_dashboard_screen.dart` — full 5-tab admin portal (Users, Properties, Residents, Concerns, Tools); inline `_AdminComebacksScreen` and `_AdminWorkerAssignmentsScreen`
  - `mobile/lib/features/admin/screens/admin_invite_codes_screen.dart` — per-property invite code list, generate sheet, copy/revoke actions

- **Files Modified**:
  - `mobile/lib/features/resident/screens/resident_dashboard_screen.dart` — replaced "Report Missed Pickup" with "Request a Comeback" + "Questions & Concerns" quick action tiles; loads free_comeback_pickups_per_month and resident_monthly_usage on init
  - `mobile/lib/features/auth/screens/resident_signup_screen.dart` — full dark redesign (was light mode); uses AppColors tokens, PrimaryButton, GlowBadge, dark field helper; business logic unchanged
  - `mobile/lib/features/worker/screens/worker_dashboard_screen.dart` — added clock state restoration on login (queries clock_events for last event; if clock_in, sets _isOnDuty = true)
  - `mobile/lib/valet_app.dart` — added super_admin case routing to AdminDashboardScreen (AppTheme.light)

- **Verified** (2026-05-16): Admin portal end-to-end with super_admin role:
  - Users tab: 7 accounts loaded, role pills correct, edit sheet pre-fills all fields
  - Properties tab: 3 properties loaded with service window and comeback fee config
  - Residents tab: active assignments with property filter chips working
  - Concerns tab: Open/In Review/Resolved filters, empty state working
  - Tools tab: Invite Codes nav, Comeback Requests nav, Worker Assignments nav, Sign Out
  - Invite Codes sub-screen: property filter chips, empty state, generate sheet with pre-filled property/unit/max-uses/validity

---

### 2026-05-16 (Session 7 — Features + Tech Debt)
- **Change**: Implemented 4 new user-facing features and completed major tech debt cleanup.
- **DB changes** (Supabase SQL editor):
  - `ALTER TABLE resident_units ADD COLUMN IF NOT EXISTS is_on_hold boolean DEFAULT false, ADD COLUMN IF NOT EXISTS hold_note text`
  - `CREATE TABLE clock_events` (uuid PK, user_id, property_id, event_type CHECK IN ('clock_in','clock_out'), created_at) + RLS
  - `CREATE TABLE worker_locations` (user_id PK, property_id, latitude, longitude, updated_at) + RLS
- **Files Created**:
  - `mobile/lib/features/resident/screens/resident_vacation_hold_screen.dart` — toggle is_on_hold on resident_units
  - `mobile/lib/features/worker/screens/worker_earnings_screen.dart` — reads clock_events, computes weekly/monthly hours
  - `mobile/lib/features/manager/screens/pm_compliance_report_screen.dart` — nightly_runs history, date range, CSV export via dart:html
  - `mobile/lib/features/manager/screens/om_worker_map_screen.dart` — flutter_map + Supabase Realtime stream on worker_locations
  - `mobile/.env.example` — onboarding template for new developers
- **Files Modified**:
  - `resident_dashboard_screen.dart` — added Vacation Hold tile in Profile tab
  - `worker_dashboard_screen.dart` — _toggleDuty() persists to clock_events; _shareLocation() upserts to worker_locations; Earnings tile in Profile tab; Share Location button in Route tab; removed unused _propertyIds field
  - `property_manager_dashboard_new.dart` — added Compliance Reports section in Settings tab
  - `manager_dashboard_screen.dart` — added Live Worker Map button in Dashboard tab; deleted _legacyBuild() + _chip() + _actionTile() (569 lines)
  - `property_manager_dashboard_new.dart` — deleted _buildLegacyDashboard() (298 lines)
  - 23 dart files — replaced withOpacity() with withValues(alpha:) throughout (0 remaining)
  - `test_connection_screen.dart` — fixed supabaseUrl/supabaseKey removed in v2 API
- **Blocked**: supabase_flutter v1→v2 upgrade blocked by missing pub cache entries for app_links-7.0.0 and sign_in_with_apple_web; remains at v1.10.25.

### 2026-05-16 (Phase 1 Redesign)
- **Change**: Implemented complete Phase 1 redesign foundation across 12 commits. App is now dark-first with a full design system.
- **Files Created**:
  - `mobile/lib/core/theme/app_colors.dart` — AppColors token constants (OLED dark palette)
  - `mobile/lib/core/theme/app_typography.dart` — DM Sans text theme via google_fonts
  - `mobile/lib/core/theme/role_theme.dart` — AppRole enum + per-role accent resolver (emerald/amber/indigo/purple)
  - `mobile/lib/core/theme/app_theme.dart` — Full dark ThemeData via flex_color_scheme
  - `mobile/lib/core/widgets/glow_badge.dart` — Accent-colored status pill with glow dot
  - `mobile/lib/core/widgets/stat_tile.dart` — Single-stat display with label
  - `mobile/lib/core/widgets/skeleton_card.dart` — Shimmer loading placeholder
  - `mobile/lib/core/widgets/role_hero_card.dart` — Glassmorphism status hero card
  - `mobile/lib/core/widgets/primary_button.dart` — Press-animated full-width CTA
  - `mobile/lib/core/widgets/role_bottom_nav.dart` — Role-accented bottom nav
  - `mobile/assets/lottie/`, `mobile/assets/rive/` — Asset directories (empty, for Phase 5)
- **Files Modified**:
  - `mobile/pubspec.yaml` — Added 11 new packages (shadcn_flutter, flex_color_scheme, flutter_animate, shimmer, gap, phosphor_flutter, lottie, rive, fl_chart, animations, cached_network_image)
  - `mobile/lib/valet_app.dart` — Switched to MaterialApp + AppTheme.dark (was: light ColorScheme.fromSeed)
  - `mobile/lib/features/auth/screens/simple_auth_screen.dart` — Full redesign: dark background, dark fields, GlowBadge errors, PrimaryButton, flutter_animate staggered entry
  - `mobile/lib/features/worker/screens/worker_dashboard_screen.dart` — Updated imports (BrandColors → AppColors)
  - `mobile/lib/features/owner/screens/owner_dashboard_screen.dart` — Updated imports (BrandColors → AppColors)
- **Files Deleted**:
  - `mobile/lib/core/brand_colors.dart` — Superseded by AppColors
  - `mobile/lib/core/app_theme.dart` — Superseded by core/theme/app_theme.dart
- **Tests**: 43 unit/widget tests passing. Pre-existing widget_test.dart requires live Supabase (expected failure).
- **Reason**: 2026 redesign initiative — dark-first, role-accented, premium valet service aesthetic.

### 2026-05-16 (Phases 2–5 — Full Dashboard Redesign)
- **Change**: Complete dark redesign of all 5 role dashboards. Each screen now has 4-tab bottom navigation, role-accented hero cards, stat tiles, skeleton loading, and dark surface system. Phase 5 polish adds Lottie animations and SharedAxisTransition page transitions.
- **Files Created**:
  - `mobile/lib/core/utils/page_transitions.dart` — `SharedAxisPageRoute` using `animations` package
  - `mobile/lib/core/widgets/lottie_feedback.dart` — `LottieSuccessView` + `LottieErrorView` widgets
  - `mobile/assets/lottie/success.json` — minimal Lottie success animation (circle + checkmark)
  - `mobile/assets/lottie/error.json` — minimal Lottie error animation (red circle + X with shake)
- **Files Rewritten**:
  - `mobile/lib/features/resident/screens/resident_dashboard_screen.dart` — 4-tab layout (Home/History/Alerts/Profile), emerald accent, pre-loads notifications
  - `mobile/lib/features/worker/screens/worker_dashboard_screen.dart` — 4-tab layout (Route/Comebacks/Violations/Profile), amber accent, SharedAxisPageRoute for Violation Report
  - `mobile/lib/features/worker/screens/violation_report_screen.dart` — multi-step wizard (0=photo, 1=type, 2=details, 3=confirm), LottieSuccessView on submit
  - `mobile/lib/features/owner/screens/owner_dashboard_screen.dart` — 4-tab layout (Overview/Properties/Analytics/Settings), purple accent, occupancy bars, role switcher
- **Files Significantly Modified**:
  - `mobile/lib/features/manager/screens/manager_dashboard_screen.dart` — added 4-tab layout; _DarkSectionLabel class added; SharedAxisPageRoute wired for Comebacks + Notify nav
  - `mobile/lib/features/manager/screens/property_manager_dashboard_new.dart` — added 4-tab layout; `Icons.door_front` → `Icons.meeting_room` fix
  - `mobile/lib/features/manager/screens/manager_alerts_screen.dart` — `const Text` with `.shade700` → non-const fix
  - `mobile/lib/features/manager/screens/property_manager_dashboard_screen.dart` — `Icons.door_front` → `Icons.meeting_room` fix
- **Result**: Zero analyzer errors, clean `flutter build web` output.
- **Reason**: Full redesign per spec in `docs/superpowers/specs/2026-05-16-valet-app-redesign-design.md`.

### 2026-05-16 (session 4)
- **Change**: Fixed two bugs blocking auth; added `operations_manager` to DB enum; created 3 test accounts; verified all 5 role-based dashboards with real data.
- **Files Modified**:
  - `mobile/lib/features/auth/screens/simple_auth_screen.dart` — wrapped Column in `Form(key: _formKey, ...)` — bug caused null crash (`_formKey.currentState!.validate()`) on every sign-in attempt
  - `mobile/lib/valet_app.dart` — added `'operations_manager'` case to `RoleHome` switch + `import 'features/manager/screens/manager_dashboard_screen.dart'` — ManagerDashboardScreen was unreachable via real auth routing
- **DB changes** (Supabase SQL editor):
  - `ALTER TYPE user_role ADD VALUE 'operations_manager'` (enum was missing this value)
  - Inserted auth users + `public.users` profiles for PM (`+pm`), OM (`+om`), Worker (`+worker`) accounts
  - `user_properties` rows for PM and OM linking to Sunset Gardens
  - `worker_assignments` row for worker linking to Sunset Gardens
- **Test results**:
  - ✅ PM → PropertyManagerDashboardNewScreen: 1 property, 1 unit, 1 resident, service window, notify buttons
  - ✅ OM → ManagerDashboardScreen: Test Worker shown, 1 property/1 worker footer, all sections load
  - ✅ Worker → WorkerDashboardScreen: Sunset Gardens assignment, Clock In, Report Violation
- **Reason**: Dashboards had never been tested with real auth — PM/OM showed "No properties assigned" and auth itself was broken (Form bug meant sign-in never called Supabase).

### 2026-05-16 (session 3)
- **Change**: Fixed 3 categories of compile errors, ran full end-to-end test across all 6 dashboards.
- **Files Modified**:
  - `mobile/lib/features/manager/screens/manager_dashboard_screen.dart` — `.inFilter()` → `.filter()`, `Future.wait` explicit type
  - `mobile/lib/features/manager/screens/property_manager_dashboard_new.dart` — `.inFilter()` → `.filter()` (5 calls), `Future.wait` explicit type
  - `mobile/lib/features/owner/screens/owner_dashboard_screen.dart` — `.inFilter()` → `.filter()` (2 calls), `Future.wait` explicit type
  - `mobile/lib/features/worker/screens/violation_report_screen.dart` — removed `dart:io` import, `uploadBinary` + `readAsBytes()` for Flutter web compat
- **Config change**: Disabled Supabase email confirmation (Authentication → Providers → Email) to allow immediate session after signup
- **Test results**: All 6 dashboards confirmed loading; resident signup flow verified end-to-end with `adam.grant824+res2@gmail.com` / `TestPass123!`
- **Reason**: Compile errors from postgrest v1 vs v2 API differences and Flutter web platform constraints.

### 2026-05-16 (session 2)
- **Change**: Applied seed data to remote Supabase DB; verified `verify_invite_code` RPC end-to-end.
- **Files Modified**: Remote Supabase DB (SQL editor)
- **Data inserted**: `properties` (Sunset Gardens, UUID `10000000...0001`), `buildings` (Building A), `floors` (Floor 1), `units` (unit 104, UUID `40000000...0004`), `invite_codes` (`WELCOME104`, property+unit linked, 10 max uses, 365d expiry)
- **RPC test result**: `verify_invite_code('WELCOME104', '10000000-0000-0000-0000-000000000001', '104')` → `is_valid=true, message=OK`
- **Reason**: Complete DB-side setup so resident signup flow can be tested on device.
- **Blocker**: Flutter SDK not found on this machine — device test deferred to user.

### 2026-05-16
- **Change**: Replaced all remaining hardcoded mock data with real Supabase queries across manager and resident screens.
- **Files Modified**:
  - `mobile/lib/features/manager/screens/manager_dashboard_screen.dart` — Full rewrite: loads workers from `worker_assignments`, tonight's runs from `nightly_runs`, comeback counts from `missed_pickup_requests`, comeback history (7 days), and sent notifications from `notifications.sender_id`
  - `mobile/lib/features/manager/screens/today_comebacks_screen.dart` — Full rewrite: queries `missed_pickup_requests` for today with nested join through `pickups → units` and `pickups → nightly_runs → properties` for unit/property names
  - `mobile/lib/features/resident/screens/resident_violations_screen.dart` — Fixed field name `user_id` → `resident_user_id`; fixed `is_warning` boolean display logic
  - `mobile/lib/features/resident/screens/resident_notifications_screen.dart` — Removed debug panel; fixed notification type mapping to DB enum values; added `is_active` filter
- **Reason**: Complete the application so all data shown is real — no mock lists anywhere in the codebase.

### 2026-05-15
- **Change**: Applied migration 006 — `violations` storage bucket + 5 RLS policies on `storage.objects`.
- **Files Modified**: Remote Supabase DB (applied via SQL editor in browser)
- **Reason**: Workers need to upload violation photos to a private bucket; residents need their own folder.

### 2026-05-15
- **Change**: Applied migration 005 — `user_properties` table, invite_codes (new schema), `verify_invite_code` + `claim_invite_code` RPCs, resident self-register policy, notifications schema extensions, `violations.pickup_id` nullable.
- **Files Modified**: Remote Supabase DB (applied via SQL editor in browser)
- **Reason**: Bridge gaps between Flutter app expectations and DB schema after a prior iteration left incompatible objects.
- **Pre-work required**: Dropped legacy `invite_codes` table (incompatible schema), dropped old `verify_invite_code` + `claim_invite_code` functions (incompatible return types).

### 2026-05-16 (Session 6)
- **Change**: Ran schema migrations, implemented light mode for PM/Owner, completed all 4 "free" features from session 5.
- **DB changes** (Chrome automation → Supabase SQL editor):
  - `ALTER TABLE missed_pickup_requests ADD COLUMN IF NOT EXISTS notes text, ADD COLUMN IF NOT EXISTS photo_url text`
  - `ALTER TABLE properties ADD COLUMN IF NOT EXISTS latitude double precision, ADD COLUMN IF NOT EXISTS longitude double precision`
- **Light mode implementation** (`property_manager` and `super_admin` roles now default to light theme):
  - `core/theme/app_colors.dart` — added `AppColorsScheme` ThemeExtension (dark + light const instances) + `BuildContext.roleColors` extension
  - `core/theme/app_theme.dart` — added `AppTheme.light` using FlexColorScheme.light; both themes register `AppColorsScheme` extension
  - `valet_app.dart` — PM and Owner routes wrapped in `Theme(data: AppTheme.light, child: ...)`
  - `property_manager_dashboard_new.dart` — `_c = context.roleColors` via `didChangeDependencies`; all surface/text color refs use `_c.*`
  - `owner_dashboard_screen.dart` — same pattern; `_OwnerSectionLabel` uses `context.roleColors.textMuted`
  - `core/widgets/stat_tile.dart` — uses `context.roleColors` (theme-aware, adapts to light/dark)
  - `core/widgets/role_bottom_nav.dart` — uses `context.roleColors` (theme-aware)

### 2026-05-15
- **Change**: Installed Repo OS brain scaffold (brain/, .cursor/rules/, cursor-os/, scripts/).
- **Files Modified**: `brain/project_context.md`, `brain/architecture.md`, `brain/current_state.md`, `brain/decisions.md`, `brain/next_steps.md`, `brain/change_log.md`, `.cursor/rules/00-repo-brain.mdc` (+ 3 more rules), `cursor-os/` (6 docs), `scripts/init-cursor-os.js`, `README.md`
- **Reason**: Establish persistent project memory for resumable AI-assisted development sessions.
