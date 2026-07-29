CREATE TABLE Semester(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  start_date TEXT,
  end_date TEXT,
  min_attendance_req REAL NOT NULL DEFAULT 75.0
);

CREATE TABLE Holidays(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER,
  date TEXT,
  name TEXT,
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE
);

CREATE TABLE Subjects(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER,
  name TEXT,
  teacher TEXT,
  min_attendance_req REAL,
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE,
  UNIQUE(sem_id, name)
);

CREATE TABLE TimetableSlot(
  slot_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER,
  sub_id INTEGER,
  day_of_week INTEGER,
  start_time TEXT,
  end_time TEXT,
  class_room TEXT,
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE,
  FOREIGN KEY (sub_id) REFERENCES Subjects (id) ON DELETE CASCADE
);

CREATE TABLE Attendance(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sem_id INTEGER,
  sub_id INTEGER,
  slot_id INTEGER,
  date TEXT,
  lec_status TEXT,
  student_status TEXT,
  FOREIGN KEY (sem_id) REFERENCES Semester (id) ON DELETE CASCADE,
  FOREIGN KEY (sub_id) REFERENCES Subjects (id) ON DELETE CASCADE,
  FOREIGN KEY (slot_id) REFERENCES TimetableSlot(slot_id) ON DELETE SET NULL
);
