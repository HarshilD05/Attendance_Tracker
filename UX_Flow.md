# Attendance Tracker - UX & Screen Flow

This document outlines all the screens in the Flutter application, their primary purpose, and how the user navigates between them.

## 1. Global Navigation (Bottom Navigation Bar)
To keep the app accessible, the primary screens will be accessible via a Bottom Navigation Bar:
- **Home** (Daily Attendance & Today's Schedule)
- **Analytics** (Overall stats and insights)
- **Semesters** (Configuration & Setup)

---

## 2. Screen Breakdown & Flow

### Screen A: Home Screen (Default Route)
**Purpose:** The daily dashboard where students actually mark attendance.
**UI Elements:**
- **Top Bar:** Date selector (`< Date >`) to move backward and forward by day.
- **Top Right:** Calendar Icon. Tapping opens a Date Picker modal to jump to any date in the active semester.
- **Body:** Vertical scrollable list of `TimetableSlot` cards for the selected date.
  - Each card shows: Subject Name, Time, Classroom.
  - Interactive Actions: **[Present]**, **[Absent]**, **[Late]**, **[Cancel Class]**.
  - Tapping an action instantly updates the UI.

---

### Screen B: Semesters List Screen (Via Bottom Nav)
**Purpose:** View all existing semesters and switch between them.
**UI Elements:**
- **Body:** List of Semester Cards (e.g., "Fall 2024").
  - Card shows brief stats: Start Date, End Date.
  - Tapping a card sets it as the `activeSemester` and opens the **Semester Details Screen (C)**.
- **Bottom Right FAB (Floating Action Button):** `+` icon. 
  - Tapping redirects to **Create Semester Screen (D)**.

---

### Screen C: Semester Details Screen (Navigated from B)
**Purpose:** The central hub for configuring a specific semester.
**UI Elements:**
- **Header:** Semester Name, Start/End dates.
- **Action Buttons / Grid:**
  1. **[Manage Subjects]** -> Opens **Subjects Screen (E)**
  2. **[Manage Holidays]** -> Opens **Holidays Screen (F)**
  3. **[Manage Timetable]** -> Opens **Timetable Screen (G)**
- **Top Right:** "Export JSON" option to share this semester setup.

---

### Screen D: Create Semester Screen (Navigated from B)
**Purpose:** Spin up a new semester instance.
**UI Elements:**
- **Top Right:** "Import from JSON" button (auto-fills database and redirects to Semesters List).
- **Form:**
  - Semester Name (Textfield)
  - Start Date (Date Picker)
  - End Date (Date Picker)
- **Action:** **[Save]** button. Inserts the Semester, auto-generates Sundays as holidays, and pops back to the **Semesters List Screen (B)**.

---

### Screen E: Subjects Management Screen (Navigated from C)
**Purpose:** Add, edit, or remove subjects for the semester.
**UI Elements:**
- **Body:** List of Subject cards (Name, Teacher, Target %).
  - Pressing a subject card opens a Popup to view and edit details.
  - The Popup contains a **[Delete]** button to remove the subject.
- **Bottom Right FAB:** `+` icon. Opens a modal/bottom sheet to add a new Subject.

---

### Screen F: Holidays Management Screen (Navigated from C)
**Purpose:** Add or remove holidays so attendance isn't expected on these days.
**UI Elements:**
- **Body:** A full-screen interactive Calendar view highlighting all current holidays.
- **Interaction:** 
  - Single tap on a day cell opens a Popup.
  - **Popup Info:** Date, Day, status ("HOLIDAY" or "REGULAR DAY").
  - If "HOLIDAY": Shows Holiday name and a **[Remove Holiday]** button.
  - If "REGULAR DAY": Shows an **[Add as Holiday]** button which asks for a Holiday Name (can be left null/empty).

---

### Screen G: Timetable Setup Screen (Navigated from C)
**Purpose:** Define the recurring weekly schedule.
**UI Elements:**
- **Top Tabs:** Monday | Tuesday | Wednesday | Thursday | Friday | Saturday
- **Body:** List of slots for the selected day, **ordered by start_time**.
- **Bottom Right FAB:** `+` icon. Opens a modal to add a slot:
  - Dropdown to select Subject.
  - Start Time & End Time pickers.
  - Classroom string.
  - **Validation:** Must check for overlaps with existing slots on that day (it is acceptable if the `endTime` of one slot equals the `startTime` of the next).

---

### Screen H: Analytics Dashboard (Via Bottom Nav)
**Purpose:** Data visualization to track attendance requirements.
**UI Elements:**
- **Top Selector:** A toggle or dropdown with options: `< Monthly | Subjects | OverAll >`.
  - Defaults to **OverAll**.
- *(Sub-section details will be finalized when creating the actual Analytics Screen).*

---

## Flow Summary
1. User opens app -> Lands on **Home (A)**. If no semester exists, prompted to go to **Semesters (B)**.
2. User taps `+` -> Goes to **Create Semester (D)** -> Saves and returns to **Semesters (B)**.
3. User taps the new Semester -> Goes to **Semester Details (C)**.
4. User clicks **Subjects** -> Configures subjects in **(E)** -> Returns to **(C)**.
5. User clicks **Timetable** -> Configures weekly schedule in **(G)** -> Returns to **(C)**.
6. Setup is complete! User navigates back to **Home (A)** to mark daily attendance.
