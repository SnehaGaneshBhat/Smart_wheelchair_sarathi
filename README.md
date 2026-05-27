# Saarthi

Saarthi is a Flutter-based smart wheelchair companion app. It connects patients and guardians through role-based sign-in, Bluetooth wheelchair controls, room-to-room navigation commands, emergency contact flows, chat, and medicine reminders backed by Firebase.

The app is designed around an ESP32-controlled wheelchair device named `ESP32-Car`.

## Features

- Role-based Firebase Authentication for patients and guardians.
- Firestore-backed user profiles and medicine reminder records.
- Patient dashboard with Bluetooth connection status, manual wheelchair controls, room navigation, SOS alert, emergency call, and chat access.
- Guardian dashboard with Bluetooth wheelchair controls, room navigation, patient contact action, and chat access.
- Patient profile page with medicine reminder add, edit, delete, search, and local notification scheduling.
- Android Bluetooth, location, notification, and phone-call permission handling.
- Firebase Analytics, Crashlytics, Messaging, Auth, Firestore, and Core dependencies are configured.

## Tech Stack

- Flutter / Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Analytics, Crashlytics, and Messaging
- `flutter_bluetooth_serial` for ESP32 Bluetooth communication
- `flutter_local_notifications` and `timezone` for medicine reminders
- `shared_preferences` for small local profile/contact values
- `url_launcher` for phone-call intents

## Project Structure

```text
lib/
  auth/
    login_page.dart          # Username/password login and role routing
    signup_page.dart         # Patient/guardian account creation
  data/
    app_data.dart            # Shared app data helpers/placeholders
  screens/
    SplashScreen.dart        # Initial splash screen
    patient_screen.dart      # Patient wheelchair controls and SOS flow
    guardian_screen.dart     # Guardian wheelchair controls and contact flow
    patient_profile_page.dart
    guardian_profile_page.dart
    patient_details_page.dart
    guardian_details_page.dart
    notification_screen.dart
    chat.dart
  firebase_options.dart      # FlutterFire-generated Firebase config
  main.dart                  # App initialization and route setup
android/                     # Android platform project
ios/                         # iOS platform project
web/                         # Web platform project
```

## Prerequisites

Install and configure:

- Flutter SDK 3.x
- Dart SDK compatible with `sdk: ^3.0.0`
- Android Studio or Android SDK command-line tools
- A Firebase project
- FlutterFire CLI, if regenerating Firebase config
- A paired ESP32 Bluetooth device named `ESP32-Car` for hardware testing

Check your local Flutter setup:

```bash
flutter doctor
```

## Firebase Setup

This repository does not commit real Firebase API keys. Generate these local-only files before running the app:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`

Use FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Alternatively, copy the example files and replace placeholders:

```bash
cp lib/firebase_options.example.dart lib/firebase_options.dart
cp android/app/google-services.example.json android/app/google-services.json
```

If a Google API key or Firebase config was committed to a public repository, rotate the key in Google Cloud Console and restrict the replacement key to the expected Android package/SHA certificate, iOS bundle id, and/or web referrers.

Expected Firestore collections:

- `users`
  - Document id: Firebase Auth `uid`
  - Fields used by the app include `uid`, `username`, `role`, `phone`, `name`, `age`, `gender`, `address`, `guardianPhone`, and `createdAt`.
- `medicines`
  - Fields used by the app include `uid`, `medicine_name`, and `time`.

The app creates Firebase Auth users by converting the entered username into an email address with the `@saarthi.app` domain.

## Installation

From the project root:

```bash
flutter pub get
```

Run on Android:

```bash
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## Hardware Notes

Bluetooth control expects the wheelchair controller to already be paired with the phone and exposed as:

```text
ESP32-Car
```

The current command protocol sends single-character manual movement commands and two-character room navigation commands:

| Action | Command |
| --- | --- |
| Forward | `F` |
| Backward | `D` |
| Left | `E` |
| Right | `R` |
| Stop | `P` |
| Room navigation | `<fromRoom><toRoom>\n` |

Configured room codes:

| Room | Code |
| --- | --- |
| Living Room | `L` |
| Bedroom | `B` |
| Kitchen | `K` |
| Bathroom | `S` |
| Study | `T` |

## Android Permissions

The Android app requests permissions for:

- Bluetooth scan/connect/advertise and legacy Bluetooth APIs
- Fine and coarse location, required by Bluetooth scanning on some Android versions
- Notifications for reminder alerts
- Phone call intents for emergency calling

For Android 12 and later, ensure Bluetooth permissions are granted before testing hardware control.

## Development Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The current release build configuration signs with the debug signing config. Replace this with a production keystore before publishing an APK outside development/testing.

## Git Push Checklist

Before pushing:

1. Run `flutter pub get`.
2. Run `flutter analyze` and fix any reported issues.
3. Run `flutter test` if tests are available.
4. Confirm generated folders such as `build/` and `.dart_tool/` are not staged.
5. Confirm local files such as `android/local.properties`, crash logs, IDE files, and signing keys are not staged.
6. Review Firebase config files before publishing to a public repository.

## Notes For Maintainers

- `pubspec.lock` should be committed for this app so builds use the same dependency versions.
- `android/local.properties` is machine-specific and must stay untracked.
- `build/`, `.dart_tool/`, and Flutter generated plugin dependency files should stay untracked.
- Firebase client configuration is not a secret by itself, but public repositories should still use strict Firebase Auth, Firestore, Storage, and API key restrictions.
