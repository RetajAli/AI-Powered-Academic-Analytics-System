-- ============================================================
--  Academic Analytics System — MySQL Database Schema
--  Version 1.0
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS academic_analytics;
CREATE DATABASE academic_analytics CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE academic_analytics;

-- ============================================================
-- USERS & ROLES
-- ============================================================

CREATE TABLE roles (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name       ENUM('admin','doctor','student','parent') NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (name) VALUES ('admin'),('doctor'),('student'),('parent');

CREATE TABLE users (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id         INT UNSIGNED NOT NULL,
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(191) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    phone           VARCHAR(20),
    avatar_url      VARCHAR(500),
    is_active       TINYINT(1) DEFAULT 1,
    last_login_at   TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id)
);

CREATE TABLE password_resets (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id    INT UNSIGNED NOT NULL,
    token      VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used       TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE api_tokens (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED NOT NULL,
    token       VARCHAR(500) NOT NULL UNIQUE,
    device_info VARCHAR(255),
    expires_at  TIMESTAMP NULL,
    revoked     TINYINT(1) DEFAULT 0,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- ACADEMIC STRUCTURE
-- ============================================================

CREATE TABLE faculties (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(150) NOT NULL,
    code       VARCHAR(20) NOT NULL UNIQUE,
    dean_id    INT UNSIGNED NULL,       -- references users(id) — set after insert
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE departments (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    faculty_id  INT UNSIGNED NOT NULL,
    name        VARCHAR(150) NOT NULL,
    code        VARCHAR(20) NOT NULL UNIQUE,
    head_id     INT UNSIGNED NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (faculty_id) REFERENCES faculties(id)
);

CREATE TABLE academic_years (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    label      VARCHAR(20) NOT NULL,   -- e.g. "2024-2025"
    start_date DATE NOT NULL,
    end_date   DATE NOT NULL,
    is_current TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE semesters (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    name             VARCHAR(50) NOT NULL,  -- e.g. "Fall", "Spring"
    start_date       DATE NOT NULL,
    end_date         DATE NOT NULL,
    is_current       TINYINT(1) DEFAULT 0,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id)
);

CREATE TABLE courses (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id  INT UNSIGNED NOT NULL,
    code           VARCHAR(20) NOT NULL UNIQUE,
    name           VARCHAR(200) NOT NULL,
    description    TEXT,
    credit_hours   TINYINT UNSIGNED DEFAULT 3,
    level          TINYINT UNSIGNED DEFAULT 1,  -- year level 1-5
    is_active      TINYINT(1) DEFAULT 1,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

CREATE TABLE course_sections (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    course_id    INT UNSIGNED NOT NULL,
    semester_id  INT UNSIGNED NOT NULL,
    doctor_id    INT UNSIGNED NOT NULL,
    section_code VARCHAR(20) NOT NULL,
    room         VARCHAR(50),
    max_capacity SMALLINT UNSIGNED DEFAULT 40,
    schedule     JSON,               -- [{day:"Monday", time:"09:00", duration:90}]
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id)   REFERENCES courses(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (doctor_id)   REFERENCES users(id)
);

-- ============================================================
-- STUDENTS
-- ============================================================

CREATE TABLE students (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id          INT UNSIGNED NOT NULL UNIQUE,
    student_number   VARCHAR(30) NOT NULL UNIQUE,
    department_id    INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    level            TINYINT UNSIGNED DEFAULT 1,
    enrollment_date  DATE NOT NULL,
    gpa              DECIMAL(4,2) DEFAULT 0.00,
    status           ENUM('active','suspended','graduated','withdrawn') DEFAULT 'active',
    face_encoding    LONGTEXT NULL,   -- JSON encoded face vector for AI camera
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)          REFERENCES users(id),
    FOREIGN KEY (department_id)    REFERENCES departments(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id)
);

CREATE TABLE student_enrollments (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id       INT UNSIGNED NOT NULL,
    course_section_id INT UNSIGNED NOT NULL,
    enrolled_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status           ENUM('enrolled','dropped','completed') DEFAULT 'enrolled',
    UNIQUE KEY uq_enrollment (student_id, course_section_id),
    FOREIGN KEY (student_id)        REFERENCES students(id),
    FOREIGN KEY (course_section_id) REFERENCES course_sections(id)
);

-- ============================================================
-- PARENTS
-- ============================================================

CREATE TABLE parents (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id      INT UNSIGNED NOT NULL UNIQUE,
    relation     ENUM('father','mother','guardian') DEFAULT 'father',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE parent_student_links (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_id  INT UNSIGNED NOT NULL,
    student_id INT UNSIGNED NOT NULL,
    verified   TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_link (parent_id, student_id),
    FOREIGN KEY (parent_id)  REFERENCES parents(id),
    FOREIGN KEY (student_id) REFERENCES students(id)
);

-- ============================================================
-- SESSIONS & ATTENDANCE
-- ============================================================

CREATE TABLE lecture_sessions (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    course_section_id INT UNSIGNED NOT NULL,
    title            VARCHAR(200),
    scheduled_at     DATETIME NOT NULL,
    started_at       DATETIME NULL,
    ended_at         DATETIME NULL,
    duration_minutes SMALLINT UNSIGNED,
    room             VARCHAR(50),
    status           ENUM('scheduled','ongoing','completed','cancelled') DEFAULT 'scheduled',
    camera_enabled   TINYINT(1) DEFAULT 0,
    session_token    VARCHAR(100) UNIQUE,   -- for AI camera handshake
    notes            TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_section_id) REFERENCES course_sections(id)
);

CREATE TABLE attendance_records (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id       INT UNSIGNED NOT NULL,
    student_id       INT UNSIGNED NOT NULL,
    status           ENUM('present','absent','late','excused') DEFAULT 'absent',
    check_in_time    DATETIME NULL,
    method           ENUM('manual','ai_camera','qr_code') DEFAULT 'manual',
    notes            VARCHAR(500),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_attendance (session_id, student_id),
    FOREIGN KEY (session_id)  REFERENCES lecture_sessions(id),
    FOREIGN KEY (student_id)  REFERENCES students(id)
);

-- ============================================================
-- GRADES & ASSESSMENTS
-- ============================================================

CREATE TABLE assessment_types (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,    -- Quiz, Midterm, Final, Assignment, Project
    weight     DECIMAL(5,2) NOT NULL,   -- percentage weight
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assessments (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    course_section_id INT UNSIGNED NOT NULL,
    assessment_type_id INT UNSIGNED NOT NULL,
    title            VARCHAR(200) NOT NULL,
    max_grade        DECIMAL(6,2) NOT NULL DEFAULT 100,
    due_date         DATETIME NULL,
    is_published     TINYINT(1) DEFAULT 0,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_section_id)   REFERENCES course_sections(id),
    FOREIGN KEY (assessment_type_id)  REFERENCES assessment_types(id)
);

CREATE TABLE student_grades (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    assessment_id  INT UNSIGNED NOT NULL,
    student_id     INT UNSIGNED NOT NULL,
    grade          DECIMAL(6,2),
    feedback       TEXT,
    graded_at      TIMESTAMP NULL,
    graded_by      INT UNSIGNED NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_grade (assessment_id, student_id),
    FOREIGN KEY (assessment_id) REFERENCES assessments(id),
    FOREIGN KEY (student_id)    REFERENCES students(id),
    FOREIGN KEY (graded_by)     REFERENCES users(id)
);

-- ============================================================
-- AI CAMERA & ENGAGEMENT
-- ============================================================

CREATE TABLE ai_camera_frames (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id       INT UNSIGNED NOT NULL,
    captured_at      DATETIME NOT NULL,
    total_detected   SMALLINT UNSIGNED DEFAULT 0,
    total_recognized SMALLINT UNSIGNED DEFAULT 0,
    engagement_avg   DECIMAL(5,2),     -- 0-100 score
    frame_metadata   JSON,             -- raw AI output summary
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES lecture_sessions(id)
);

CREATE TABLE student_engagement_logs (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id       INT UNSIGNED NOT NULL,
    student_id       INT UNSIGNED NOT NULL,
    frame_id         INT UNSIGNED NOT NULL,
    emotion          ENUM('focused','distracted','confused','happy','bored','neutral','unknown') DEFAULT 'neutral',
    engagement_score DECIMAL(5,2),
    is_participating TINYINT(1) DEFAULT 0,
    raised_hand      TINYINT(1) DEFAULT 0,
    logged_at        DATETIME NOT NULL,
    FOREIGN KEY (session_id) REFERENCES lecture_sessions(id),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (frame_id)   REFERENCES ai_camera_frames(id)
);

CREATE TABLE session_engagement_summary (
    id                     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id             INT UNSIGNED NOT NULL UNIQUE,
    avg_engagement         DECIMAL(5,2),
    dominant_emotion       VARCHAR(50),
    total_participations   SMALLINT UNSIGNED DEFAULT 0,
    total_hand_raises      SMALLINT UNSIGNED DEFAULT 0,
    focus_timeline         JSON,   -- [{minute:5, score:82}, ...]
    emotion_distribution   JSON,   -- {focused:40, distracted:10, ...}
    computed_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES lecture_sessions(id)
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        TEXT NOT NULL,
    type        VARCHAR(50) DEFAULT 'info',   -- info, warning, alert, grade, attendance
    is_read     TINYINT(1) DEFAULT 0,
    action_url  VARCHAR(500),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- ANNOUNCEMENTS
-- ============================================================

CREATE TABLE announcements (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    author_id   INT UNSIGNED NOT NULL,
    target_role ENUM('all','student','parent','doctor') DEFAULT 'all',
    title       VARCHAR(200) NOT NULL,
    body        TEXT NOT NULL,
    is_pinned   TINYINT(1) DEFAULT 0,
    published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES users(id)
);

-- ============================================================
-- FOREIGN KEYS deferred
-- ============================================================

ALTER TABLE faculties    ADD CONSTRAINT fk_faculty_dean   FOREIGN KEY (dean_id)  REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE departments  ADD CONSTRAINT fk_dept_head      FOREIGN KEY (head_id)  REFERENCES users(id) ON DELETE SET NULL;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- USEFUL VIEWS
-- ============================================================

CREATE OR REPLACE VIEW v_student_attendance_summary AS
SELECT
    s.id                            AS student_id,
    s.student_number,
    u.full_name,
    cs.id                           AS section_id,
    c.name                          AS course_name,
    COUNT(ar.id)                    AS total_sessions,
    SUM(ar.status = 'present')      AS present_count,
    SUM(ar.status = 'absent')       AS absent_count,
    SUM(ar.status = 'late')         AS late_count,
    ROUND(SUM(ar.status = 'present') / COUNT(ar.id) * 100, 2) AS attendance_pct
FROM students s
JOIN users u ON u.id = s.user_id
JOIN attendance_records ar ON ar.student_id = s.id
JOIN lecture_sessions ls ON ls.id = ar.session_id
JOIN course_sections cs ON cs.id = ls.course_section_id
JOIN courses c ON c.id = cs.course_id
GROUP BY s.id, cs.id;

CREATE OR REPLACE VIEW v_student_grade_summary AS
SELECT
    sg.student_id,
    cs.id    AS section_id,
    c.name   AS course_name,
    at.name  AS assessment_type,
    a.title  AS assessment_title,
    sg.grade,
    a.max_grade,
    ROUND(sg.grade / a.max_grade * 100, 2) AS percentage
FROM student_grades sg
JOIN assessments a       ON a.id  = sg.assessment_id
JOIN assessment_types at ON at.id = a.assessment_type_id
JOIN course_sections cs  ON cs.id = a.course_section_id
JOIN courses c           ON c.id  = cs.course_id;