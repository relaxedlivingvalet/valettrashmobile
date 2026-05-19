# Current State

## Current Objective
**Store-ready with resident mock layout + service request workflow.** Final RLV icon installed. Resident home matches client mock (pickup card, stats, quick actions, services grid, support bar). Extra-service requests persist to `service_requests` and appear on **owner** and **super_admin** inboxes. Apply migration `007_service_requests.sql` in Supabase before testing requests in production.

## Run the App
```powershell
cd C:\Users\WeLovePQ\Desktop\CascadeProjects\windsurf-project\mobile
flutter pub get
flutter run -d web-server --web-port 8091 --no-pub
# or
flutter run -d chrome --no-pub
```

App: **http://localhost:8091**

---

## Supabase

| Item | Value |
|---|---|
| Project | `relaxedl-living` |
| Ref | `airpwzzkyjqzeeqizvft` |
| Region | AWS us-east-2 |
| Site URL | `http://localhost:8091` |
| Redirect URLs | `http://localhost:8091`, `com.relaxedliving.valet://login-callback` |

- All core tables migrated, RLS enabled, SECURITY DEFINER RPCs in place
- **`service_requests`** — migration file `007_service_requests.sql` (must be applied manually in Supabase SQL editor if not yet run)
- **`resident_concerns`** — support/Q&A messages from residents (Support tab)
- `violations` storage bucket with RLS policies
- Seed data: property `10000000-0000-0000-0000-000000000001` (Sunset Gardens), unit 104, invite code `WELCOME104`
- Email confirmation **disabled** — re-enable when a real email provider is configured
- **No email on service submit** — dashboard inbox only (owner + admin)

---

## Flutter App (`mobile/`)

- **Package name**: `valet`
- **Entry**: `main.dart` → `ValetApp` → `AuthGate` → `RoleHome` → role dashboard

### Role → Screen Routing

| Role | Screen | Theme |
|---|---|---|
| `resident` | `ResidentDashboardScreen` | Dark |
| `driver` | `WorkerDashboardScreen` | Dark |
| `operations_manager` | `ManagerDashboardScreen` | Dark |
| `property_manager` | `PropertyManagerDashboardNewScreen` | Light |
| `owner` | `OwnerDashboardScreen` | Light |
| `super_admin` | `AdminDashboardScreen` | Light |

### Resident Dashboard (May 2026)

**Bottom nav:** Home | Extra Services | Support | Profile (Messages tab removed)

**Home tab:** mock-aligned layout using existing `AppColors` (dark + `rlvBlue` / `success` accents):
- Welcome + worker status + notifications icon
- Next pickup card (date, service window, countdown to window start)
- Free comebacks / violations stat tiles (live from Supabase)
- Quick actions: Request Pickup → `ResidentComebackRequestScreen`, Service History / Buy Extras → Extra Services tab
- Available services 2×2 grid → `showServiceRequestSheet()`
- Support bar → Support tab

**Extra Services tab:** service grid + `ResidentPickupHistoryView`

**Support tab:** `ResidentSupportPanel` — topic dropdown + message → `resident_concerns`

**Service requests:** `lib/features/resident/widgets/service_request_sheet.dart` — dropdown, date picker, message → `service_requests`

### Owner / Admin Inboxes

| Role | Where | What |
|---|---|---|
| `super_admin` | Admin → **Resident Inbox** tab | Segments: **Concerns** \| **Service Requests**; status filters; full inbox link |
| `owner` | Owner → More → **Service Requests Inbox** | `ServiceRequestsInboxScreen` — mark in review / fulfilled / cancelled |

Shared screen: `lib/features/shared/screens/service_requests_inbox_screen.dart`

### Design System
- Tokens: `core/theme/app_colors.dart` — dark surfaces, `rlvBlue` brand, semantic success/warning/error
- Shared widgets: `BentoCard`, `MetricTile`, `GlowBadge`, `PrimaryButton`, `RoleBottomNav`, Lottie feedback

### Auth Flow
- Password recovery → `ChangePasswordScreen`; mobile deep link `com.relaxedliving.valet://login-callback`
- `supabase_flutter` v1.10.25 — use `.filter()` not `.inFilter()`; `auth.updateUser()` not `.update()`

---

## Native Platform (Android + iOS)

- Bundle ID: `com.relaxedliving.valet`
- Android release signing configured (`upload-keystore.jks` + `key.properties`, repo private)
- Final RLV icon + splash regenerated
- **iOS:** requires Mac + Xcode + Apple Developer account

---

## Test Accounts

See `brain/test_credentials.md`. Quick reference:

| Email | Password | Role |
|---|---|---|
| `relaxedlivingtx@gmail.com` | `RelaxedLiving2026!` | `super_admin` |
| `adam.grant824+res2@gmail.com` | `TestPass123!` | `resident` (unit 104) |

---

## Known Issues / Constraints

- **Apply `007_service_requests.sql`** before service request submit works against hosted Supabase
- `supabase_flutter` v1 → v2 upgrade deferred (network/deps)
- `PmComplianceReportScreen` / worker map: `dart:html` on web only — need native helpers for store builds
- Direct messages UI removed from resident nav; `direct_messages` table still exists if re-enabled later
- Stripe paid comebacks not wired
