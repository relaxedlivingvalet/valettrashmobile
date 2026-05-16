# Next Steps

## Now (requires env vars from user)
- [ ] Add `mobile/.env` with `SUPABASE_URL` and `SUPABASE_ANON_KEY` to run the app
- [ ] Apply `seed_data/010_seed_invite_codes.sql` to the remote DB (provides `WELCOME104` invite code for testing)
- [ ] Test resident signup end-to-end: `WELCOME104` invite code → unit number → create account → land on ResidentDashboardScreen

## Next
- [ ] Validate WorkerDashboardScreen with a driver account — verify route display and pickup marking
- [ ] Test ViolationReportScreen: photo pick → upload to `violations/workers/<uid>/...` → insert violations row
- [ ] Validate PropertyManagerDashboardNewScreen and SimpleNotificationSenderScreen with a `property_manager` account
- [ ] Validate ManagerDashboardScreen with a `property_manager` account — check worker/run queries return real data
- [ ] Confirm admin_dashboard targets the correct Supabase project and schema
- [ ] Clarify `main_simple.dart` — remove it or document its purpose (currently an alternate entry point identical to main.dart)

## Phase 2 Backlog
- [ ] Wire up OneSignal push notifications (collect token on login, store in users table or dedicated table)
- [ ] Deploy Stripe webhook edge function: `supabase functions deploy stripe-webhook` + set `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` secrets
- [ ] Twilio SMS integration for pickup reminders
- [ ] Mapbox route mapping for WorkerDashboardScreen
- [ ] Stripe Connect for contractor payouts

## Blocked / Waiting
- Stripe integration blocked on Stripe account setup and webhook secret
- OneSignal blocked on OneSignal app ID / account setup

## Suggested Improvements
- [ ] Upgrade `supabase_flutter` from v1.10.25 to v2 (breaking change — plan carefully)
- [ ] Add a `.env.example` file so new developers know required variables
- [ ] Add integration tests for the invite code flow
- [ ] Consider adding `supabase db pull` to CI to detect schema drift
