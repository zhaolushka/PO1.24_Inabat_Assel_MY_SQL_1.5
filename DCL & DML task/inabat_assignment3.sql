DROP USER IF EXISTS db_reader_user;
DROP USER IF EXISTS db_admin_user;

DROP ROLE IF EXISTS library_readonly;
DROP ROLE IF EXISTS library_admin;

SET search_path TO library;

-- =========================
-- ROLES
-- =========================

CREATE ROLE library_admin;
CREATE ROLE library_readonly;

GRANT USAGE ON SCHEMA library TO library_admin;
GRANT USAGE ON SCHEMA library TO library_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA library
TO library_admin;

GRANT SELECT
ON ALL TABLES IN SCHEMA library
TO library_readonly;

REVOKE UPDATE, DELETE
ON ALL TABLES IN SCHEMA library
FROM library_readonly;

-- \dp books
-- readonly role has only SELECT permission

-- =========================
-- USERS
-- =========================

CREATE USER db_admin_user
WITH PASSWORD 'admin123';

CREATE USER db_reader_user
WITH PASSWORD 'reader123';

GRANT library_admin TO db_admin_user;
GRANT library_readonly TO db_reader_user;

-- direct permissions to users

GRANT USAGE ON SCHEMA library TO db_admin_user;
GRANT USAGE ON SCHEMA library TO db_reader_user;

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA library
TO db_admin_user;

GRANT SELECT
ON ALL TABLES IN SCHEMA library
TO db_reader_user;

-- =========================
-- TRUNCATE
-- =========================

TRUNCATE TABLE reservations CASCADE;
TRUNCATE TABLE fines CASCADE;
TRUNCATE TABLE loans CASCADE;
TRUNCATE TABLE borrowers CASCADE;
TRUNCATE TABLE books CASCADE;
TRUNCATE TABLE branches CASCADE;

-- =========================
-- INSERTS: BRANCHES
-- =========================

INSERT INTO branches (
    branch_name,
    address,
    email,
    city,
    phone,
    opened_date
)
VALUES
(
    'Central Library',
    '12 Abay Street',
    'central@library.kz',
    'Almaty',
    '+77010000001',
    '2025-01-01'
),
(
    'West Library',
    '15 Satpayev Street',
    'west@library.kz',
    'Almaty',
    '+77011111111',
    '2025-02-01'
),
(
    'East Library',
    '20 Nazarbayev Street',
    'east@library.kz',
    'Astana',
    '+77012222222',
    '2025-03-01'
),
(
    'South Library',
    '8 Abai Avenue',
    'south@library.kz',
    'Shymkent',
    '+77013333333',
    '2025-04-01'
),
(
    'North Library',
    '45 Dostyk Street',
    'north@library.kz',
    'Karaganda',
    '+77014444444',
    '2025-05-01'
);

-- =========================
-- INSERTS: BOOKS
-- =========================

INSERT INTO books (
    isbn,
    title,
    publisher_id,
    pub_year,
    edition,
    language
)
VALUES
(
    '978000000001',
    'Database Systems',
    1,
    2020,
    '1st',
    'English'
),
(
    '978000000002',
    'Advanced SQL',
    1,
    2021,
    '2nd',
    'English'
),
(
    '978000000003',
    'PostgreSQL Guide',
    1,
    2022,
    '1st',
    'Russian'
),
(
    '978000000004',
    'Library Management',
    1,
    2023,
    '3rd',
    'Kazakh'
),
(
    '978000000005',
    'Data Modeling',
    1,
    2024,
    '1st',
    'English'
);

-- =========================
-- INSERTS: BORROWERS
-- =========================

INSERT INTO borrowers (
    first_name,
    last_name,
    email,
    phone
)
VALUES
(
    'Aruzhan',
    'Nurmukhambet',
    'aruzhan@mail.kz',
    '+77070000001'
),
(
    'Dias',
    'Sarsenov',
    'dias@mail.kz',
    '+77070000002'
),
(
    'Amina',
    'Kaliyeva',
    'amina@mail.kz',
    '+77070000003'
),
(
    'Nursultan',
    'Bekov',
    'nursultan@mail.kz',
    '+77070000004'
),
(
    'Dana',
    'Tulegenova',
    'dana@mail.kz',
    '+77070000005'
);

-- =========================
-- SELECT
-- =========================

SELECT *
FROM branches;

SELECT *
FROM books;

SELECT *
FROM borrowers;

-- =========================
-- UPDATE #1
-- =========================

-- preview rows before update

SELECT *
FROM books
WHERE book_id = 1;

UPDATE books
SET language = 'Kazakh'
WHERE book_id = 1;

-- rows updated: 1

-- =========================
-- UPDATE #2
-- =========================

-- preview rows before update

SELECT *
FROM branches
WHERE city = 'Almaty';

UPDATE branches
SET phone = '+77019999999'
WHERE city = 'Almaty';

-- rows updated: 2

-- =========================
-- UPDATE FROM
-- =========================

-- preview before update

SELECT b.book_id, b.language
FROM books b;

UPDATE books b
SET language = 'Russian'
FROM branches br
WHERE br.city = 'Almaty'
AND b.book_id = 1;

-- rows updated: 1

-- =========================
-- DELETE + TRANSACTION
-- =========================

-- deleting cancelled reservations because they are no longer active

BEGIN;

DELETE FROM reservations
WHERE status = 'Cancelled';

SELECT COUNT(*)
FROM reservations;

-- rows affected: 0

ROLLBACK;

-- =========================
-- ADMIN TEST
-- =========================

SET ROLE db_admin_user;

SELECT CURRENT_USER;

SELECT COUNT(*)
FROM books;

INSERT INTO branches (
    branch_name,
    address,
    email,
    city,
    phone,
    opened_date
)
VALUES (
    'Admin Test Library',
    '1 Test Street',
    'admintest@library.kz',
    'Almaty',
    '+77015555555',
    '2025-06-01'
);

UPDATE books
SET language = 'English'
WHERE book_id = 1;

DELETE FROM branches
WHERE email = 'admintest@library.kz';

RESET ROLE;

-- =========================
-- READER TEST
-- =========================

SET ROLE db_reader_user;

SELECT CURRENT_USER;

SELECT COUNT(*)
FROM books;

BEGIN;

INSERT INTO branches (
    branch_name,
    address,
    email,
    city,
    phone,
    opened_date
)
VALUES (
    'Reader Test',
    'Test Street',
    'reader@library.kz',
    'Almaty',
    '+77010000000',
    '2025-01-01'
);

-- expected error:
-- permission denied for table branches

ROLLBACK;

BEGIN;

UPDATE books
SET language = 'German'
WHERE book_id = 1;

-- expected error:
-- permission denied for table books

ROLLBACK;

BEGIN;

DELETE FROM branches
WHERE branch_name = 'Central Library';

-- expected error:
-- permission denied for table branches

ROLLBACK;

RESET ROLE;

-- =========================
-- RETURN TO POSTGRES
-- =========================

SET ROLE postgres;

SELECT CURRENT_USER;