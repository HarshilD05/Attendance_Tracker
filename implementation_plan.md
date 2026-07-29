# Flutter Local Attendance Tracker Implementation Plan

This plan outlines the architecture, database schema, and development roadmap for building a fully functional, local-first Flutter attendance tracker using SQLite.

## Open Questions

> [!IMPORTANT]
> - **State Management**: Do you have a preferred state management solution (e.g., `Riverpod`, `Provider`, `BLoC`, or `GetX`) for the `controllers` layer? `Riverpod` or `Provider` is highly recommended for this type of app.
> - **Missable/Remaining Lectures Math**: To calculate "Remaining lectures", we'll need to calculate all future dates matching the timetable between today and `Semester.end_date` minus `Holidays`. Is this the intended logic?

## 1. Database Schema (Revised)

As requested, all primary keys will be `INTEGER AUTO_INCREMENT`. We've updated the `Timetable` and `Attendance` column names.

- **Semester**
  - `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
  - `name` (TEXT)
  - `start_date` (TEXT, YYYY-MM-DD)
  - `end_date` (TEXT, YYYY-MM-DD)

- **Holidays**
  - `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
  - `sem_id` (INTEGER, FOREIGN KEY)
  - `date` (TEXT, YYYY-MM-DD)
  - `name` (TEXT)

- **Subjects**
  - `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
  - `sem_id` (INTEGER, FOREIGN KEY)
  - `name` (TEXT)
  - `teacher` (TEXT)
  - `min_attendance_req` (REAL) - e.g., 75.0

- **Timetable**
  - `slot_id` (INTEGER PRIMARY KEY AUTOINCREMENT)
  - `sem_id` (INTEGER, FOREIGN KEY)
  - `sub_id` (INTEGER, FOREIGN KEY)
  - `day_of_week` (INTEGER) - 1 (Mon) to 7 (Sun)
  - `start_time` (TEXT)
  - `end_time` (TEXT)
  - `class_room` (TEXT)

- **Attendance**
  - `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
  - `sem_id` (INTEGER, FOREIGN KEY)
  - `sub_id` (INTEGER, FOREIGN KEY)
  - `slot_id` (INTEGER, FOREIGN KEY) - *Nullable (for extra/makeup lectures)*
  - `date` (TEXT, YYYY-MM-DD)
  - `lec_status` (TEXT) - 'Conducted' | 'Cancelled'
  - `student_status` (TEXT) - 'Present' | 'Absent' | 'Late'

## 2. JSON Import/Export Strategy (ID Mapping)

Because we are using `INTEGER AUTOINCREMENT`, importing data across devices requires **ID Mapping** so foreign keys don't break. 
When importing a JSON payload:
1. Insert the `Semester`. SQLite returns the newly generated `new_sem_id`.
2. Iterate through `Subjects`. For each subject, store the `old_sub_id` from JSON, insert it using `new_sem_id`, and get the `new_sub_id`. Keep a map: `{old_sub_id: new_sub_id}`.
3. Iterate through `Timetable`. Replace the old `sem_id` and `sub_id` with the new mapped ones before inserting. 

## 3. App Architecture (Layer-First)

```text
lib/
├── config/              # theme.dart, database.dart, routes.dart
├── models/              # semester.dart, subject.dart, attendance.dart, etc.
├── repositories/        # semester_repo.dart, attendance_repo.dart
├── controllers/         # logic and state management
├── screens/             # UI screens
├── widgets/             # Reusable UI components
└── utils/               # Helpers, formatters, JSON import ID mappers
```

## 4. Development Phases

### Phase 1: Foundation & Setup
- Initialize the Flutter project and add dependencies (`sqflite`, `path_provider`, state management).
- Build the `config/database.dart` to initialize SQLite and create the 5 tables.
- Implement the `models/` with `fromJson` and `toJson` methods.
- Build the UI & Repositories for Semester, Subjects, and Timetable setup.

### Phase 2: Daily Attendance Tracking
- Build the Home Screen that displays today's schedule by joining `Timetable` and `Subjects` for the current day.
- Build the logic to insert/update `Attendance` records.
- Handle "Extra Lectures" (inserting attendance with `slot_id = null`).

### Phase 3: Data Analytics & Views
Implement complex SQLite queries and Dart logic to calculate the following:
- **Current Overall Attendance**: Group by `sub_id` to get `COUNT(Present) / COUNT(Conducted)`.
- **Monthly Attendance**: Group by `strftime('%Y-%m', date)` to get percentage per month.
- **Subject-wise Analysis**:
  - Total percentage.
  - **Remaining Lectures**: Calculate total future dates in the timetable for this subject, excluding holidays.
  - **Missable Lectures**: Mathematical formula based on `min_attendance_req`, total conducted, total present, and remaining lectures.

### Phase 4: Import / Export
- Add UI to export a semester configuration as a JSON file.
- Implement the ID Mapping import logic to safely ingest shared configurations.

## Verification Plan
- Unit tests for the Analytics logic (Missable lectures math is notoriously tricky).
- Manual testing of the JSON Import/Export to ensure no SQLite `FOREIGN KEY` constraint violations occur.
- Manual verification of today's schedule rendering correctly based on the day of the week.
