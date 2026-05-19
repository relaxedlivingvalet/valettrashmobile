# Current State

## Current Objective
**QA / client retest of resident dashboard** — mock-aligned home, comeback rules, extra services, support, and owner/admin inboxes. Live Supabase has migrations through **008**. Flutter web dev server typically on port **8091**.

## Resume Here (next session)
1. **Uncommitted work on `main`** (as of May 19, 2026): resident comeback/dashboard widgets + `008_*.sql` + brain edits — commit/push when retest passes.
2. Retest as resident → confirm tab glitch gone, service submit with date+time, buy banked comebacks, request pickup tiers.
3. Confirm owner/admin inbox receives `service_requests` after submit.
4. Blockers before store: RLS on 19 tables, Stripe for paid comebacks, iOS signing.

## Run the App
```powershell
cd C:\Users\WeLovePQ\Desktop\CascadeProjects\windsurf-project\mobile
flutter pub get
flutter run -d web-server --web-port 8091 --no-pub
# or
flutter run -d chrome --no-pub
```

App: **http://localhost:8091** — hard refresh or `R` hot restart after pulling code.

---

## Supabase

| Item | Value |
|---|---|
| Project | `relaxedl-living` |
| Ref | `airpwzzkyjqzeeqizvft` |
| Region | AWS us-east-2 |
| Site URL | `http://localhost:8091` |
| Redirect URLs | `http://localhost:8091`, `com.relaxedliving.valet://login-callback` |
| MCP | `.cursor/mcp.json` → `project_ref=airpwzzkyjqzeeqizvft` |

### Live migrations (hosted DB history via MCP)
| Version (hosted name) | Repo file | What it does |
|---|---|---|
| `add_owner_user_role` | (enum fix) | `user_role` + `'owner'` |
| `007_service_requests` | `007_service_requests.sql` | `service_requests` table + RLS |
| `resident_comeback_balance_service_time` | `008_resident_comeback_balance_service_time.sql` | `purchased_comeback_balance`, `preferred_time`, resident UPDATE on `resident_units` |

- **`service_requests`** — resident insert/read; owner + `super_admin` read/update. Columns: `preferred_date`, `preferred_time`, `message`, `service_type`, `status`.
- **`resident_units.purchased_comeback_balance`** — INTEGER default 0; purchased comebacks roll over; residents can UPDATE own row (policy from 008).
- **Free monthly comeback** — tracked in `resident_monthly_usage.free_comeback_used`; app enforces **1/month** (does not roll over).
- **RLS drift (May 18 MCP audit)** — ~19 tables still have RLS disabled while policies exist on some. **Critical before production**; fix in batches with signup/resident/admin smoke tests.
- **`resident_concerns`** — Support tab messages.
- **`clock_events`** — worker clock in/out; resident dashboard worker badge reads latest event per `property_id`.
- Seed: property `10000000-0000-0000-0000-000000000001` (Sunset Gardens), unit 104, invite `WELCOME104`.
- Email confirmation **disabled** until real provider configured.
- Service/extra requests: **inbox only** (no email).

---

## Flutter App (`mobile/`)

- **Package**: `valet`
- **Entry**: `main.dart` → `ValetApp` → `AuthGate` → `RoleHome`

### Role → Screen

| Role | Screen | Theme |
|---|---|---|
| `resident` | `ResidentDashboardScreen` | Dark |
| `driver` | `WorkerDashboardScreen` | Dark |
| `operations_manager` | `ManagerDashboardScreen` | Dark |
| `property_manager` | `PropertyManagerDashboardNewScreen` | Light |
| `owner` | `OwnerDashboardScreen` | Light |
| `super_admin` | `AdminDashboardScreen` | Light |

### Resident dashboard (Session 14–15)

**Nav:** Home | Extra Services | Support | Profile

| Area | Implementation |
|---|---|
| Tabs | `IndexedStack` — prevents grid overlay glitch on tab switch |
| Worker status | Latest `clock_events` for property → `clock_in` = **ON DUTY**, else **SCHEDULED** |
| Next pickup | Countdown in hours (`12h`, `<1h`, `Now`); window default **6:00 PM – 10:00 PM** if property unset |
| Comebacks | 1 free/month (no rollover); banked `purchased_comeback_balance`; paid single **$5**; packs **1/$5, 3/$14, 5/$20** |
| Bell | → `ResidentNotificationsScreen` |
| Home services | `ExtraServicesGrid` (compact) + link to Extra Services tab |
| Extra Services | `ExtraServicesGrid` + `BuyExtraPickupsSection` + `ResidentPickupHistoryView` |
| Support | `ResidentSupportPanel` → `resident_concerns` |
| Service sheet | `service_request_sheet.dart` — date + time required, message optional |

**Key files**
- `mobile/lib/features/resident/screens/resident_dashboard_screen.dart`
- `mobile/lib/features/resident/screens/resident_comeback_request_screen.dart`
- `mobile/lib/features/resident/widgets/service_request_sheet.dart`
- `mobile/lib/features/resident/widgets/extra_services_grid.dart`
- `mobile/lib/features/resident/widgets/buy_extra_pickups_section.dart`
- `mobile/lib/features/resident/models/comeback_pricing.dart`
- `mobile/lib/features/shared/screens/service_requests_inbox_screen.dart`

### Owner / Admin inboxes

| Role | Path | Content |
|---|---|---|
| `super_admin` | Admin → Resident Inbox | Concerns \| Service Requests |
| `owner` | More → Service Requests Inbox | Fulfill / cancel service requests |

---

## Retest Checklist (resident)

- [ ] Tab switch Home ↔ Extra Services — no duplicate grid overlay
- [ ] Notification bell opens list
- [ ] Countdown shows hours; service window 6–10 PM (or property times)
- [ ] Worker **ON DUTY** only after driver clocks in at property
- [ ] Request Pickup: free monthly → banked → $5 paid path
- [ ] Buy Extra Pickups increments `purchased_comeback_balance`
- [ ] Extra service: date + time → submit OK → visible in owner/admin inbox
- [ ] Support concern still submits

**Accounts:** `adam.grant824+res2@gmail.com` / `TestPass123!` (resident) · `relaxedlivingtx@gmail.com` / `RelaxedLiving2026!` (super_admin)

---

## Native Platform

- Bundle ID: `com.relaxedliving.valet`
- Android: release keystore configured
- RLV icon + splash in `mobile/assets/icon/`
- iOS: needs Mac + Xcode + Apple Developer account

---

## Known Issues / Constraints

- **Stripe** — paid comeback + pack purchase UI records DB changes; payment is placeholder
- **`supabase_flutter` v1** — upgrade deferred
- **Web-only** — worker map / PM CSV use `dart:html`; need native alternatives for store builds
- **RLS** — many tables not enforcing RLS on hosted DB despite policies in repo
- **Notifications screen** — loads all active notifications; not yet filtered tightly by resident `property_id`
