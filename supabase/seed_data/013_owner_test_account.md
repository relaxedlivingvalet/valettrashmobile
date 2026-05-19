# Owner test account (business owner)

**Owner** and **super_admin** use the same app experience: **Owner dashboard** (Financials, labor, portfolio).  
**Admin Portal** (invite codes, users, billing tools) is under Owner → **More** → **Admin Portal**.

## Primary login (recommended)

| Email | Password | Role | Screen |
|---|---|---|---|
| `relaxedlivingtx@gmail.com` | `RelaxedLiving2026!` | `owner` | Owner dashboard |

After migration `013_unify_owner_role.sql`, this account’s DB role is `owner`.  
If it still shows Admin-only or wrong screen, run:

```sql
UPDATE public.users SET role = 'owner' WHERE email = 'relaxedlivingtx@gmail.com';
```

Sign in with **Staff** on the login screen (not Resident).

## Optional alias

| Email | Password | Notes |
|---|---|---|
| `relaxedlivingtx+owner@gmail.com` | `RelaxedLiving2026!` | Same inbox as primary; create in **Supabase Auth** first, then run migration 013 or insert `public.users` row with `role = owner`. |

## Create alias in Supabase Auth (one-time)

1. Authentication → Users → Add user  
2. Email: `relaxedlivingtx+owner@gmail.com`  
3. Password: `RelaxedLiving2026!`  
4. Auto-confirm user  
5. SQL Editor:

```sql
INSERT INTO public.users (id, email, first_name, last_name, role)
VALUES (
  '<auth-user-uuid>',
  'relaxedlivingtx+owner@gmail.com',
  'RLV',
  'Owner',
  'owner'
)
ON CONFLICT (id) DO UPDATE SET role = 'owner';
```
