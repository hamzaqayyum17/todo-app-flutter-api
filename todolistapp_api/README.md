# Todo App (Flutter)

A mobile todo list with email login. Each user registers with a unique email,
confirms it with a one-time code sent by email, and sees only their own tasks.
The app talks to an ASP.NET Core Web API (in the `TodoApi/` folder of this repository).

## Features
- Register with a unique email and confirm it with a 6-digit code (OTP) sent by email
- Log in, log out, and stay logged in after closing the app
- Short-lived access token that is renewed silently with a refresh token
- Automatic return to the login screen when the session can no longer be renewed
- Add, edit, delete, and complete tasks
- Priority (Low, Medium, High) and due date
- Filter by All, Pending, or Done, with the most important tasks first
- Clear error messages and a Retry button when the server cannot be reached

## Screenshots
<!-- Add your own, for example: -->
<!-- ![Login](docs/screenshots/login.png) -->
<!-- ![Tasks](docs/screenshots/tasks.png) -->

## Tech stack
Flutter, Dart, `http`, `shared_preferences`

## Project structure
```
lib/
├── main.dart                  App start, session check, auto-logout hook
├── config.dart                API address (change this to your own)
├── AppTheme/appTheme.dart     Colors and component styles
├── model/task.dart            Task class with JSON conversion
├── db/task_repository.dart    Task requests to the API
├── services/
│   ├── api_client.dart        Adds the token, refreshes it on a 401, retries
│   ├── auth_service.dart      Register, verify, login, logout
│   └── session.dart           Stores the tokens on the phone
└── Screens/
    ├── auth_screen.dart       Login and register
    ├── otp_screen.dart        Enter the email code
    ├── homescreen.dart        Task list, filter, edit, delete, complete
    └── addnewtask.dart        Add and edit form
```

## How to run

**1. Start the API.** Follow the instructions in the `TodoApi/` folder
(SQL Server connection string, JWT key, and optional SMTP settings).

**2. Set the API address.** Open `lib/config.dart` and set `baseUrl`:

- Same Wi-Fi: use your computer's IP, for example `http://192.168.0.101:5219`
- USB cable: run `adb reverse tcp:5219 tcp:5219` and use `http://localhost:5219`

**3. Run the app** on an Android phone or emulator:

```bash
flutter pub get
flutter run
```

## Notes
- The Android manifest allows plain `http://` traffic for local development.
  Use HTTPS for anything that is published.
- Tokens are stored with `shared_preferences`. For a production app, use
  `flutter_secure_storage` so they are encrypted on the phone.
- If an Android build fails with "Could not close incremental caches" and the
  project and the Pub cache are on different drives, set
  `kotlin.incremental=false` in `android/gradle.properties` (already done here).

## Author
[HAMZA QAYYUM] · [https://github.com/hamzaqayyum17/todo-app-flutter-api]