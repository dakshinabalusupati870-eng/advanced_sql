-- ============================================
-- SQL Data Analysis Internship — Task 5 (MySQL 8)
-- ============================================

-- SCHEMA (only if you need to test quickly)
CREATE TABLE students (
  id INT PRIMARY KEY,
  name VARCHAR(100),
  gender VARCHAR(10),
  admission_date DATE
);

CREATE TABLE courses (
  id INT PRIMARY KEY,
  name VARCHAR(100),
  credits INT
);

CREATE TABLE enrollments (
  id INT PRIMARY KEY,
  student_id INT,
  course_id INT,
  grade DECIMAL(5,2),
  semester VARCHAR(20),
  enrollment_date DATE,
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (course_id) REFERENCES courses(id)
);

-- SAMPLE DATA (you can change it)
INSERT INTO students VALUES
(1, 'Alice', 'F', '2022-06-01'),
(2, 'Bob', 'M', '2022-06-01'),
(3, 'Charlie', 'M', '2023-06-01'),
(4, 'Diana', 'F', '2023-06-01');

INSERT INTO courses VALUES
(1, 'SQL Basics', 3),
(2, 'Data Analytics', 4);

INSERT INTO enrollments VALUES
(1, 1, 1, 88.5, '2023-01', '2023-01-10'),
(2, 2, 1, 91.0, '2023-01', '2023-01-11'),
(3, 3, 1, 78.0, '2023-02', '2023-02-12'),
(4, 4, 1, 95.0, '2023-02', '2023-02-13'),
(5, 1, 2, 82.0, '2023-03', '2023-03-05'),
(6, 2, 2, 89.0, '2023-03', '2023-03-06'),
(7, 3, 2, 75.0, '2023-04', '2023-04-07'),
(8, 4, 2, 92.0, '2023-04', '2023-04-08');

-- =====================================================
-- 1️⃣ Top 3 Performers per Course (ROW_NUMBER)
-- =====================================================

WITH ranked AS (
  SELECT
    c.name AS course_name,
    s.name AS student_name,
    e.grade,
    ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY e.grade DESC) AS rank_in_course
  FROM enrollments e
  JOIN students s ON e.student_id = s.id
  JOIN courses c ON e.course_id = c.id
)
SELECT course_name, student_name, grade
FROM ranked
WHERE rank_in_course <= 3
ORDER BY course_name, grade DESC;

-- =====================================================
-- 2️⃣ Grade Distribution (PERCENT_RANK + NTILE)
-- =====================================================

WITH distribution AS (
  SELECT
    c.name AS course_name,
    s.name AS student_name,
    e.grade,
    PERCENT_RANK() OVER (PARTITION BY c.id ORDER BY e.grade) AS percentile_rank,
    NTILE(4) OVER (PARTITION BY c.id ORDER BY e.grade DESC) AS quartile
  FROM enrollments e
  JOIN students s ON e.student_id = s.id
  JOIN courses c ON e.course_id = c.id
)
SELECT
  course_name,
  student_name,
  grade,
  ROUND(percentile_rank * 100, 2) AS percentile,
  quartile
FROM distribution
ORDER BY course_name, percentile;

-- =====================================================
-- 3️⃣ Student Improvement (LAG)
-- =====================================================

WITH per_sem AS (
  SELECT
    s.id AS student_id,
    s.name AS student_name,
    e.semester,
    ROUND(AVG(e.grade), 2) AS avg_grade
  FROM enrollments e
  JOIN students s ON e.student_id = s.id
  GROUP BY s.id, s.name, e.semester
)
SELECT
  student_id,
  student_name,
  semester,
  avg_grade,
  LAG(avg_grade) OVER (PARTITION BY student_id ORDER BY semester) AS prev_avg,
  ROUND(avg_grade - LAG(avg_grade) OVER (PARTITION BY student_id ORDER BY semester), 2) AS improvement
FROM per_sem
ORDER BY student_name, semester;

-- =====================================================
-- 4️⃣ Cumulative Performance (Running Average)
-- =====================================================

SELECT
  s.name AS student_name,
  e.enrollment_date,
  e.grade,
  ROUND(AVG(e.grade) OVER (
    PARTITION BY s.id
    ORDER BY e.enrollment_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ), 2) AS running_avg
FROM enrollments e
JOIN students s ON e.student_id = s.id
ORDER BY student_name, e.enrollment_date;

-- =====================================================
-- 5️⃣ CREATE VIEWS
-- =====================================================

CREATE OR REPLACE VIEW v_top_performers AS
WITH ranked AS (
  SELECT
    c.name AS course_name,
    s.name AS student_name,
    e.grade,
    ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY e.grade DESC) AS rank_in_course
  FROM enrollments e
  JOIN students s ON e.student_id = s.id
  JOIN courses c ON e.course_id = c.id
)
SELECT course_name, student_name, grade
FROM ranked
WHERE rank_in_course <= 3;

CREATE OR REPLACE VIEW v_grade_percentiles AS
SELECT
  c.name AS course_name,
  s.name AS student_name,
  e.grade,
  ROUND(PERCENT_RANK() OVER (PARTITION BY c.id ORDER BY e.grade) * 100, 2) AS percentile
FROM enrollments e
JOIN students s ON e.student_id = s.id
JOIN courses c ON e.course_id = c.id;

CREATE OR REPLACE VIEW v_student_improvement AS
WITH per_sem AS (
  SELECT
    s.id AS student_id,
    s.name AS student_name,
    e.semester,
    ROUND(AVG(e.grade), 2) AS avg_grade
  FROM enrollments e
  JOIN students s ON e.student_id = s.id
  GROUP BY s.id, s.name, e.semester
)
SELECT
  student_id,
  student_name,
  semester,
  avg_grade,
  LAG(avg_grade) OVER (PARTITION BY student_id ORDER BY semester) AS prev_avg,
  ROUND(avg_grade - LAG(avg_grade) OVER (PARTITION BY student_id ORDER BY semester), 2) AS improvement
FROM per_sem;

CREATE OR REPLACE VIEW v_cumulative_performance AS
SELECT
  s.name AS student_name,
  e.enrollment_date,
  e.grade,
  ROUND(AVG(e.grade) OVER (
    PARTITION BY s.id
    ORDER BY e.enrollment_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ), 2) AS running_avg
FROM enrollments e
JOIN students s ON e.student_id = s.id;
