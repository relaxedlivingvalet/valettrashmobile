# Mobile (Flutter)

## Configuration

Place `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `mobile/.env` (the file is listed as a Flutter asset in `pubspec.yaml`).

Dependencies include `supabase_flutter`, `flutter_dotenv`, and `image_picker` for violation photos.

## App entry

- **`lib/main.dart`** — initializes Supabase, runs **`ValetApp`** (`lib/valet_app.dart`).
- **`lib/valet_app.dart`** — `AuthGate` follows the Supabase auth stream; **`RoleHome`** loads `users.role` and sends:
  - `resident` → resident home
  - `driver` → worker dashboard
  - `property_manager` → manager dashboard shell
  - `super_admin` → owner dashboard
- **`/test` route** — `TestConnectionScreen` for sanity checks against your project.

On the login screen, “Test navigation” links only appear in **debug** builds.
