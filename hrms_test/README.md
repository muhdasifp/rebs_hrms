# REBS HRMS Flutter App

This project implements a lightweight employee workspace for attendance tracking and leave applications with offline-first behavior.

## Architecture

- Flutter + Riverpod for UI state and repository orchestration
- `LocalDatabase` for persistent SQLite cache and pending sync queue
- `ApiClient` for HTTP calls using the configured base URL
- `LocationService` for proximity validation
- `ConnectivityService` for online/offline checks
- `BaseUrlScreen` as the initial configuration screen before the app starts

## Setup

1. Start the mock API server:
   - Open a terminal in the `hrms-api` folder.
   - Run `npm install` if needed.
   - Run `node src/server.js`.
2. On the first launch, enter the API base URL in the app setup screen.
   - Example: `http://10.0.2.2:3000/api` for Android emulator
   - Example: `http://192.168.1.5:3000/api` for a real device on the same LAN
3. Launch the Flutter app from the `hrms_test` folder with:
   - `flutter pub get`
   - `flutter run`

## Offline-first behavior

- Employee, attendance history, and leave data are cached locally.
- Offline actions are persisted with `sync_status` values such as `pending`, `synced`, and `rejected`.
- A `pending_sync` table stores the table name and record id for every unsynced item so it can be replayed after reconnect.
- Manual sync is available from the attendance screen when connectivity is restored.

## API notes

The app targets the mock HTTP API for:

- `GET /employee/me`
- `GET /attendance?month=YYYY-MM`
- `POST /attendance/events`
- `GET /leave/balance`
- `GET /leave/requests`
- `POST /leave/requests`

The mock server supports repeatable scenarios through the `x-mock-scenario` header, including:

- `success`
- `slow`
- `timeout`
- `server_error`
- `duplicate`
- `validation_error`

## Assumptions and trade-offs

- One employee is configured for the assignment.
- Login and multi-tenant auth are outside scope.
- Attendance is treated as a single session per day.
- Background sync while the app is terminated is intentionally not implemented.
- The app validates location and leave rules locally before server submission, while the server remains the final authority.

## Completed features

- Base URL configuration screen
- Dashboard with employee summary, attendance status, and recent history
- Offline-capable attendance check-in/check-out flow
- Local queue with pending-sync tracking
- Leave request form and local validation
- Tests covering attendance rejection, duplicate prevention, pending sync order, leave overlap validation, and a pending-sync widget state

## Limitations

- This is a mock implementation and not a production HRMS backend.
- Real GPS and permission behavior depends on device settings and platform permissions.
- Notification/background sync after app termination is intentionally omitted.

## Time spent

- Initial project review and app wiring: 1–2 hours
- Offline persistence and sync logic: 3 hours
- UI polish and validation: 2 hours
- Testing and verification: 1 hour
