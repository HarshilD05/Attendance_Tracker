CREATE TABLE Semester(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
  min_attendance_req REAL NOT NULL DEFAULT 75.0,
  CHECK(min_attendance_req >= 0 AND min_attendance_req <= 100)
);

CREATE TABLE Holiday(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  name TEXT,
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE
);

CREATE TABLE Subject(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  teacher TEXT,
  min_attendance_req REAL NOT NULL DEFAULT 75.0,
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE,
  UNIQUE(sem_id, name),
  CHECK(min_attendance_req >= 0 AND min_attendance_req <= 100)
);

CREATE TABLE TimetableSlot(
  slot_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER NOT NULL,
  sub_id INTEGER NOT NULL,
  day_of_week INTEGER NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  class_room TEXT,
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE,
  FOREIGN KEY (sub_id) REFERENCES Subject (id) ON DELETE CASCADE,
  CHECK(0 <= day_of_week AND day_of_week <= 7)
);

CREATE TABLE ExtraLec (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER NOT NULL,
  sub_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  class_room TEXT,
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE,
  FOREIGN KEY (sub_id) REFERENCES Subject (id) ON DELETE CASCADE
);

CREATE TABLE Attendance(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER NOT NULL,
  sub_id INTEGER NOT NULL,
  slot_id INTEGER,
  extra_lec_id INTEGER,
  date TEXT NOT NULL,
  is_cancelled INTEGER NOT NULL DEFAULT 0,
  student_status TEXT NOT NULL DEFAULT 'U',
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE,
  FOREIGN KEY (sub_id) REFERENCES Subject (id) ON DELETE CASCADE,
  FOREIGN KEY (slot_id) REFERENCES TimetableSlot(slot_id) ON DELETE SET NULL,
  FOREIGN KEY (extra_lec_id) REFERENCES ExtraLec(id) ON DELETE CASCADE,
  CHECK(student_status IN ('A', 'P', 'U') ),
  CHECK(is_cancelled IN (0, 1) )
);
