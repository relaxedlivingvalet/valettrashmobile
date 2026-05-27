# Current State

## Current Objective
**Owner login + workforce + billing QA** — unified owner login, OM timecards, owner labor $, door-count billing. Repo migrations through **013**; apply **012** and **013** on hosted Supabase if not yet run. Flutter web on port **8091**.

## Resume Here (next session)
1. **Owner login** — Staff → `relaxedlivingtx@gmail.com` / `RelaxedLiving2026!` → Owner dashboard (see `brain/test_credentials.md`). Run `013_unify_owner_role.sql` if role still `super_admin` only.
2. **Apply migrations `012` + `013`** on Supabase (labor rates + owner role).
3. **OM** → **Workforce & Timecards**; **Owner** → Financials → **Manage rates**.
4. **Stripe Connect** — webhooks for payouts/MRR.
5. Blockers: RLS on ~19 tables, Stripe checkout for paid comebacks, iOS signing.

## Run the App
```powershell
cd C:\Users\WeLovePQ\Desktop\CascadeProjects\windsurf-project\mobile
flutter pub get
flutter run -d web-server --web-port 8091 --no-pub
```

App: **http://localhost:8091** — hard refresh or `R` after pull.

---

## Supabase

| Item | Value |
|---|---|
| Project | `relaxedl-living` |
| Ref | `airpwzzkyjqzeeqizvft` |
| Region | AWS us-east-2 |
| MCP | `project_ref=airpwzzkyjqzeeqizvft` |

### Live migrations (hosted)
| Hosted name | Repo file | What it does |
|---|---|---|
| `007_service_requests` | `007_service_requests.sql` | `service_requests` + owner role |
| `resident_comeback_balance_service_time` | `008_...sql` | `purchased_comeback_balance`, `preferred_time` |
| `staff_invites` | `009_staff_invites.sql` | Staff self-signup RPCs |
| `property_billing_metrics` | `010_property_billing_metrics.sql` | `monthly_fee_per_door` (default $25), `minimum_billable_occupancy_percent` (default 0.85) |
| `property_door_counts` | `011_property_door_counts.sql` | `billing_total_doors`, `billing_occupied_doors` (manual entry per complex) |
| `workforce_labor` | `012_workforce_labor.sql` | `users.hourly_rate`, clock_events/worker_locations RLS, `set_worker_hourly_rate` RPC |
| `unify_owner_role` | `013_unify_owner_role.sql` | `relaxedlivingtx@gmail.com` → `owner`; optional `+owner` alias |

### Billing rules (app + DB)
- **Inputs (owner via Admin Portal):** total doors, occupied doors, $/billable door/month on **Property Billing Rates**.
- **Billable doors** = `max(occupied, ceil(total × 85%))` — app calculates occupancy % and monthly $.
- Falls back to counted units + `resident_units` when door counts not saved yet.
- **PM contract estimate** = billable doors × `monthly_fee_per_door`.
- **Owner revenue/door** = (contract + resident MRR + paid invoices + paid comebacks) ÷ billable doors per property.
- **Stripe Connect** — `contractor_payouts` listed on owner Financials; live sync pending webhook.

---

## Flutter App (`mobile/`)

### Role → Screen
| Role | Screen | Theme |
|---|---|---|
| `resident` | `ResidentDashboardScreen` | Dark |
| `driver` | `WorkerDashboardScreen` | Dark |
| `operations_manager` | `ManagerDashboardScreen` — **Workforce & Timecards**, Live Worker Map | Dark |
| `property_manager` | `PropertyManagerDashboardNewScreen` | Light |
| `owner` / `super_admin` | `OwnerDashboardScreen` — Admin Portal quick switch (top bar + More) | Light |

### Auth / routing
- Login: **Resident** | **Staff** buttons.
- **`owner` ≡ `super_admin`** — both → `OwnerDashboardScreen`; **Admin Portal** from More and top quick switch bar.
- **Owner test login:** `relaxedlivingtx@gmail.com` / `RelaxedLiving2026!` (Staff).
- `RoleHome` polls `fetchUserRole()` after signup (fixes PM landing as resident race).
- Staff: `staff_invites` + `register_staff_with_invite`.

### Property manager dashboard
| Tab | Content |
|---|---|
| Dashboard | Pickup SLA, satisfaction, pending comebacks (no resident service requests) |
| Properties | Units list: **Occupied/Vacant**, invite codes, **85% billable** banner, est. monthly bill, **Export CSV** |
| Inbox | Pending comebacks only |
| More | Compliance reports, password, sign out |

### Owner dashboard
| Tab | Content |
|---|---|
| Overview | Portfolio summary |
| **Financials** | Contract revenue, **labor est from clock**, revenue/door, MRR, payouts, **Manage rates** → `OwnerWorkforceScreen`, **Export CSV** |
| Reports | Properties with occupancy + billable + $/door |
| More | **Admin Portal**, service requests inbox, role switchers (preview other dashboards) |

### Admin portal
| Area | Content |
|---|---|
| Top quick switch | **Owner Dashboard** button (returns without re-login) |
| Tools | Invite codes, billing rates, assignments, and **Owner Dashboard** switch tile |

### Owner onboarding (Admin Portal via More)
| Task | Where |
|---|---|
| Add property | Admin → Properties → Add |
| Units + resident codes | Admin → Tools → **Resident Invite Codes** (`brain/resident_invite_workflow.md`) |
| Staff codes | Admin → Tools → **Staff Invite Codes** |
| Link PM/OM/driver | Admin → Manager / Worker Assignments |
| **Door counts + $/door** | Admin → Tools → **Property Billing Rates** |
| **Driver pay rates** | Owner → Financials → **Manage rates** (or `OwnerWorkforceScreen`) |

### Workforce / labor
- **Worker** — Clock in/out → `clock_events`; Route → Share Location → `worker_locations`; More → Earnings (hours).
- **OM** — `OmWorkforceScreen`: on-duty, week hours, shift history, link to map.
- **Owner** — Financials labor tiles; `OwnerWorkforceScreen`: edit hourly rate via RPC, est week/month labor $.
- **Helper** — `mobile/lib/core/workforce/clock_hours.dart`.

### Key new files
- `mobile/lib/core/billing/property_billing.dart`
- `mobile/lib/core/workforce/clock_hours.dart`
- `mobile/lib/core/auth/user_profile.dart`
- `brain/resident_invite_workflow.md`
- `brain/test_credentials.md`
- `supabase/seed_data/013_owner_test_account.md`

### Recent GitHub (`main`)
| Commit | Summary |
|---|---|
| `TBD` | Owner/Admin two-way quick switch (top bars + admin tools link) |
| `eb29777` | Unify owner + super_admin → Owner dashboard |
| `401b13e` | OM workforce timecards + owner labor estimates |
| `48ec1cf` | Billing door counts UI |

---

## Retest Checklist

**Owner**
- [ ] Staff login → Owner dashboard (not resident)
- [ ] More → Admin Portal opens
- [ ] Admin top bar → Owner Dashboard returns to owner
- [ ] Financials: labor est + Manage rates
- [ ] Export financials CSV downloads

**PM**
- [ ] Properties shows occupied vs vacant per unit
- [ ] Billable count reflects 85% minimum when occupancy is low
- [ ] Export unit codes CSV

**Staff signup**
- [ ] Staff code → property manager dashboard (not resident)

**Accounts:** `brain/test_credentials.md` — owner `relaxedlivingtx@gmail.com` · OM/worker/PM `adam.grant824+*` · resident `+res2`

---

## Known Issues / Constraints
- **Stripe** — owner Financials reads DB; Connect webhooks not live; paid comebacks still placeholder checkout
- **RLS** — many tables RLS off on hosted DB
- **Web-only CSV** — `dart:html` download; native needs `share_plus` later
- Live DB may have **0** subscriptions/invoices until seed or Stripe — contract math still works from units + fee
