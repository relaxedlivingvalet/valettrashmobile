# Current State

## Current Objective
**Owner/PM financial & onboarding QA** — staff invite flow, resident invite playbook, PM occupancy/billing (85% rule), owner Financials tab. Live Supabase migrations through **010**. Flutter web on port **8091**.

## Resume Here (next session)
1. **Owner** → Financials + Reports — confirm per-property revenue/door; Export CSV.
2. **PM** → Properties — occupied/vacant, billable doors, est. monthly bill; Export unit codes CSV.
3. **Super admin** — Add units + Resident Invite Codes; see `brain/resident_invite_workflow.md`.
4. **Stripe Connect** — wire webhooks so payouts/MRR populate from live Stripe (UI ready).
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

### Billing rules (app + DB)
- **Billable doors** = `max(occupied_units, ceil(total_units × min_billable_%))` — default **85%** minimum.
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
| `operations_manager` | `ManagerDashboardScreen` | Dark |
| `property_manager` | `PropertyManagerDashboardNewScreen` | Light |
| `owner` | `OwnerDashboardScreen` | Light |
| `super_admin` | `AdminDashboardScreen` | Light |

### Auth / routing
- Login: **Resident** | **Staff** buttons.
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
| **Financials** | Contract revenue, revenue/door, MRR, per-property breakdown, Stripe payout list, **Export CSV** |
| Reports | Properties with occupancy + billable + $/door |
| More | Service requests inbox, role switchers |

### Super admin onboarding
| Task | Where |
|---|---|
| Add property | Properties → Add / Tools → Add Property |
| Units + resident codes | Tools → **Resident Invite Codes** (see `brain/resident_invite_workflow.md`) |
| Staff codes | Tools → **Staff Invite Codes** |
| Link PM/OM/driver | Manager / Worker Assignments |

### Key new files
- `mobile/lib/core/billing/property_billing.dart`
- `mobile/lib/core/auth/user_profile.dart`
- `brain/resident_invite_workflow.md`

---

## Retest Checklist

**Owner**
- [ ] Financials shows billable doors and $/door per property
- [ ] Export financials CSV downloads

**PM**
- [ ] Properties shows occupied vs vacant per unit
- [ ] Billable count reflects 85% minimum when occupancy is low
- [ ] Export unit codes CSV

**Staff signup**
- [ ] Staff code → property manager dashboard (not resident)

**Accounts:** `relaxedlivingtx@gmail.com` / `RelaxedLiving2026!` (super_admin) · `relaxedlivingtx+824@gmail.com` (PM test) · resident test in `brain/test_credentials.md`

---

## Known Issues / Constraints
- **Stripe** — owner Financials reads DB; Connect webhooks not live; paid comebacks still placeholder checkout
- **RLS** — many tables RLS off on hosted DB
- **Web-only CSV** — `dart:html` download; native needs `share_plus` later
- Live DB may have **0** subscriptions/invoices until seed or Stripe — contract math still works from units + fee
