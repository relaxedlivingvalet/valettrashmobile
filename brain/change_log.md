# Change Log

## Format
Date | Change | Files Modified | Reason

---

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

### 2026-05-15
- **Change**: Installed Repo OS brain scaffold (brain/, .cursor/rules/, cursor-os/, scripts/).
- **Files Modified**: `brain/project_context.md`, `brain/architecture.md`, `brain/current_state.md`, `brain/decisions.md`, `brain/next_steps.md`, `brain/change_log.md`, `.cursor/rules/00-repo-brain.mdc` (+ 3 more rules), `cursor-os/` (6 docs), `scripts/init-cursor-os.js`, `README.md`
- **Reason**: Establish persistent project memory for resumable AI-assisted development sessions.
