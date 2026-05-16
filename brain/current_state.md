# Current State

## Current Objective
**Redesign complete (Phases 1–5).** All 5 role dashboards now use the dark design system with consistent tab navigation, AppColors token system, and shared widgets. App builds cleanly with zero errors.

## Next Action
```powershell
# Run the app:
cd C:\Users\e159305\Projects\valettrashmobile\mobile
flutter run -d web-server --web-port 8090 --no-pub
# OR: flutter run -d chrome --no-pub
```

## What Exists

- **Supabase DB** (project: `relaxedl-living`, ref: `airpwzzkyjqzeeqizvft`, AWS us-east-2)
  - Status: Fully migrated — migrations 001, 004, 005, 006 applied
  - All tables exist with correct schema, RLS enabled, SECURITY DEFINER RPCs in place
  - `violations` storage bucket created with RLS policies for residents and workers
  - Seed data applied (2026-05-16): property `10000000...0001` (Sunset Gardens), building, floor, unit 104, invite code `WELCOME104`

- **Flutter mobile app** (`mobile/`)
  - Status: **FULLY REDESIGNED** — compiles, all dashboards rebuilt with dark UI. Zero analyzer errors.
  - Flutter SDK: `C:\Users\e159305\Apps\flutter\bin` (Flutter 3.41.9)
  - Entry: `main.dart` → `ValetApp` → `AuthGate` → role-based screen

  ### Design System (Phase 1 — complete)
  - Tokens: `core/theme/app_colors.dart` — background, surface1/2, border, textPrimary/Secondary/Muted, role accents (resident=emerald, worker=amber, manager=indigo, owner=purple)
  - Shared widgets: `glow_badge`, `stat_tile`, `skeleton_card`, `role_hero_card`, `primary_button`, `role_bottom_nav`
  - Utility: `core/utils/page_transitions.dart` — `SharedAxisPageRoute` for animated screen pushes
  - Lottie assets: `assets/lottie/success.json`, `assets/lottie/error.json`
  - `core/widgets/lottie_feedback.dart` — `LottieSuccessView`, `LottieErrorView`

  ### Role Dashboards (Phases 2–4 — complete)
  - **Resident** (`resident_dashboard_screen.dart`): 4 tabs — Home (RoleHeroCard + stats + quick actions + notifications preview), History (pickup history), Alerts (notifications), Profile
  - **Worker** (`worker_dashboard_screen.dart`): 4 tabs — Route (amber hero + Clock In/Out + stats), Comebacks, Violations (Report Violation → SharedAxisPageRoute → multi-step form + LottieSuccessView), Profile
  - **Operations Manager** (`manager_dashboard_screen.dart`): 4 tabs — Dashboard (tonight's runs + comeback history), Workers (list with amber avatars), Comebacks (stats + View Full List), Notify (Alert All + 1 Resident)
  - **Property Manager** (`property_manager_dashboard_new.dart`): 4 tabs — Portfolio (property cards), Residents (invite codes), Notify, Settings
  - **Owner** (`owner_dashboard_screen.dart`): 4 tabs — Overview (KPI grid + property snapshots), Properties (detail cards), Analytics (occupancy bars + activation gauge), Settings (role switcher + sign out)

  ### Polish (Phase 5 — complete)
  - `SharedAxisPageRoute` wired: Violation Report, Notification Sender, Comebacks
  - `LottieSuccessView` used on violation submission success
  - `animations` package: SharedAxisTransition utility in `core/utils/page_transitions.dart`
  - All analyzer errors fixed including pre-existing `Icons.door_front` and `const Colors.grey.shade700`

  ### Key Technical Notes
  - Supabase filter syntax: `.filter('col', 'in', '(${ids.join(',')})')` — not `.inFilter()` (v1 compat)
  - `Future.wait(<Future<dynamic>>[...])` — typed generic required for Flutter web
  - GlowBadge requires `accent` (required param) and `showDot` (default true)

- **Test accounts** (all password `TestPass123!`):
  - `adam.grant824+res2@gmail.com` — resident, unit 104, Sunset Gardens
  - `adam.grant824+pm@gmail.com` — property_manager
  - `adam.grant824+om@gmail.com` — operations_manager
  - `adam.grant824+worker@gmail.com` — driver

- **Known Issues** (pre-existing, not introduced by redesign)
  - `supabase_flutter` pinned at v1.10.25 — v2 migration is a future breaking change
  - No `.env` committed — developers need `mobile/.env` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`
  - Supabase email confirmation disabled — re-enable when email provider configured
  - `withOpacity` is deprecated in Flutter 3.x — use `.withValues(alpha: ...)` to silence warnings (info only, not errors)
  - `_legacyBuild()` / `_buildLegacyDashboard()` in OM/PM files are dead code (warnings only)

## Resume Instructions
1. Read this file first, then `brain/next_steps.md`
2. `flutter run -d web-server --web-port 8090 --no-pub` from `mobile/`
3. All redesign complete — next: push notifications, Stripe webhook, or OneSignal integration
