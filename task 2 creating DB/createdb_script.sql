-- ============================================================
-- Library Management System
-- Physical Database Implementation
-- Schema: library
-- Standard: 3NF
-- ============================================================

DROP SCHEMA IF EXISTS library CASCADE;
CREATE SCHEMA library;
SET search_path TO library;

-- ------------------------------------------------------------
-- GENRES
-- Stores book genre categories.
-- VARCHAR(100) — genre names are short strings, TEXT would be overkill.
-- UNIQUE on genre_name — prevents duplicate genre entries.
-- ------------------------------------------------------------
CREATE TABLE library.genres (
    genre_id    SERIAL PRIMARY KEY,                      -- auto-increment surrogate key
    genre_name  VARCHAR(100) NOT NULL UNIQUE,            -- NOT NULL: every genre must have a name; UNIQUE: no duplicates
    description TEXT                                     -- TEXT: descriptions can vary greatly in length
);

-- ------------------------------------------------------------
-- PUBLISHERS
-- Stores book publisher information.
-- ------------------------------------------------------------
CREATE TABLE library.publishers (
    publisher_id   SERIAL PRIMARY KEY,
    publisher_name VARCHAR(100) NOT NULL,                -- NOT NULL: publisher must have a name
    country        VARCHAR(50)                           -- nullable: country may be unknown
);

-- ------------------------------------------------------------
-- BRANCHES
-- Stores library branch locations.
-- BOOLEAN DEFAULT TRUE — new branches are active by default.
-- ------------------------------------------------------------
CREATE TABLE library.branches (
    branch_id   SERIAL PRIMARY KEY,
    branch_name VARCHAR(50)  NOT NULL,                   -- NOT NULL: branch must be named
    address     VARCHAR(100),                            -- nullable: address may be added later
    email       VARCHAR(50)  NOT NULL UNIQUE,            -- UNIQUE: each branch has its own email
    city        VARCHAR(50)  NOT NULL,                   -- NOT NULL: city is required for location
    phone       VARCHAR(50)  NOT NULL,                   -- NOT NULL: contact number is mandatory
    opened_date DATE,                                    -- DATE: only date needed, no time component
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE       -- DEFAULT TRUE: new branches assumed active
);

-- ------------------------------------------------------------
-- AUTHORS
-- GENERATED ALWAYS AS — avoids redundancy, full_name always
-- consistent with first/last name (3NF: no derived data stored manually).
-- ------------------------------------------------------------
CREATE TABLE library.authors (
    author_id  SERIAL PRIMARY KEY,
    first_name VARCHAR(50)  NOT NULL,                    -- NOT NULL: author must have first name
    last_name  VARCHAR(50)  NOT NULL,                    -- NOT NULL: author must have last name
    full_name  VARCHAR(102) GENERATED ALWAYS AS          -- 102 = 50 + 1 (space) + 50 + 1 (null)
                   (first_name || ' ' || last_name) STORED,
    birth_date DATE,                                     -- DATE: no time needed for birth date
    country    VARCHAR(50)                               -- nullable: origin may be unknown
);

-- ------------------------------------------------------------
-- BOOKS
-- ISBN is UNIQUE — each book edition has a globally unique identifier.
-- publisher_id SET NULL on delete — book record preserved even if publisher removed.
-- ------------------------------------------------------------
CREATE TABLE library.books (
    book_id      SERIAL PRIMARY KEY,
    isbn         VARCHAR(20)  NOT NULL UNIQUE,           -- UNIQUE: ISBN is a global unique identifier
    title        VARCHAR(225) NOT NULL,                  -- NOT NULL: every book must have a title
    publisher_id INT REFERENCES library.publishers(publisher_id) ON DELETE SET NULL,
    pub_year     INT,                                    -- INT: year as integer (e.g. 2023)
    edition      VARCHAR(50),                            -- nullable: some books have no edition info
    language     VARCHAR(50)                             -- nullable: language may be unspecified
);

-- ------------------------------------------------------------
-- BOOK_AUTHORS (junction table)
-- Many-to-many: one book can have multiple authors and vice versa.
-- CASCADE: if book or author deleted, the link is removed.
-- ------------------------------------------------------------
CREATE TABLE library.book_authors (
    author_id INT NOT NULL REFERENCES library.authors(author_id) ON DELETE CASCADE,
    book_id   INT NOT NULL REFERENCES library.books(book_id)     ON DELETE CASCADE,
    PRIMARY KEY (author_id, book_id)                    -- composite PK prevents duplicate pairs
);

-- ------------------------------------------------------------
-- BOOK_GENRES (junction table)
-- Many-to-many: one book can belong to multiple genres.
-- ------------------------------------------------------------
CREATE TABLE library.book_genres (
    book_id  INT NOT NULL REFERENCES library.books(book_id)   ON DELETE CASCADE,
    genre_id INT NOT NULL REFERENCES library.genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, genre_id)                     -- composite PK prevents duplicate pairs
);

-- ------------------------------------------------------------
-- BOOK_COPIES
-- Tracks physical copies of books per branch.
-- Needed for availability control — same book can have multiple copies.
-- status CHECK — restricts to known lifecycle values only.
-- ------------------------------------------------------------
CREATE TABLE library.book_copies (
    copy_id       SERIAL PRIMARY KEY,
    book_id       INT NOT NULL REFERENCES library.books(book_id)      ON DELETE CASCADE,
    branch_id     INT          REFERENCES library.branches(branch_id)  ON DELETE SET NULL,
    status        VARCHAR(20)  NOT NULL DEFAULT 'Available'
                      CHECK (status IN ('Available', 'Loaned', 'Reserved', 'Damaged', 'Lost')),
                      -- CHECK: restricts to valid statuses only (specific value constraint)
    condition     VARCHAR(50),                           -- nullable: condition assessed later
    acquired_date DATE                                   -- DATE: only date needed, no time
);

-- ------------------------------------------------------------
-- BORROWERS
-- gender CHECK — domain constraint, only accepted values allowed (specific value constraint).
-- registration_date CHECK > '2026-01-01' — ensures no legacy/test data inserted (date constraint).
-- GENERATED full_name — consistent with 3NF (no manual redundancy).
-- ------------------------------------------------------------
CREATE TABLE library.borrowers (
    borrower_id       SERIAL PRIMARY KEY,
    first_name        VARCHAR(50)  NOT NULL,
    last_name         VARCHAR(50)  NOT NULL,
    full_name         VARCHAR(102) GENERATED ALWAYS AS
                          (first_name || ' ' || last_name) STORED,
    gender            VARCHAR(10)  NOT NULL
                          CHECK (gender IN ('Male', 'Female', 'Other')),
                          -- CHECK: only valid gender values accepted (specific value constraint)
    email             VARCHAR(100) UNIQUE,               -- UNIQUE: one account per email
    phone             VARCHAR(50),                       -- VARCHAR: phones may include +, (), -
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
                          CHECK (registration_date > '2026-01-01'),
                          -- CHECK: system launched after 2026-01-01, earlier dates invalid (date constraint)
    birth_date        DATE,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE      -- DEFAULT TRUE: new borrowers are active
);

-- ------------------------------------------------------------
-- STAFF
-- hire_date CHECK — staff cannot be hired before system launch date.
-- branch_id SET NULL — staff record kept if branch is closed.
-- ------------------------------------------------------------
CREATE TABLE library.staff (
    staff_id   SERIAL PRIMARY KEY,
    branch_id  INT REFERENCES library.branches(branch_id) ON DELETE SET NULL,
    first_name VARCHAR(50)  NOT NULL,
    last_name  VARCHAR(50)  NOT NULL,
    full_name  VARCHAR(102) GENERATED ALWAYS AS
                   (first_name || ' ' || last_name) STORED,
    position   VARCHAR(50),
    hire_date  DATE CHECK (hire_date > '2026-01-01'),    -- CHECK: no pre-system hire dates (date constraint)
    phone      VARCHAR(50)
);

-- ------------------------------------------------------------
-- LOANS
-- copy_id NOT NULL — loan must be tied to a specific physical copy.
-- chk_dates — due_date cannot be before loan_date (logical constraint).
-- loan_date CHECK > '2026-01-01' — system start date boundary (date constraint).
-- ------------------------------------------------------------
CREATE TABLE library.loans (
    loan_id     SERIAL PRIMARY KEY,
    copy_id     INT  NOT NULL REFERENCES library.book_copies(copy_id) ON DELETE RESTRICT,
                     -- RESTRICT: cannot delete a copy that has loan history
    borrower_id INT  NOT NULL REFERENCES library.borrowers(borrower_id),
    staff_id    INT           REFERENCES library.staff(staff_id) ON DELETE SET NULL,
    loan_date   DATE NOT NULL DEFAULT CURRENT_DATE
                     CHECK (loan_date > '2026-01-01'),   -- date constraint
    due_date    DATE NOT NULL
                     CHECK (due_date > '2026-01-01'),    -- date constraint
    return_date DATE,                                    -- nullable: null means not yet returned
    CONSTRAINT chk_dates CHECK (due_date >= loan_date)  -- due date must be after or equal loan date
);

-- ------------------------------------------------------------
-- RESERVATIONS
-- Allows borrowers to reserve books before picking them up.
-- status CHECK — only valid reservation states allowed.
-- chk_expiry — expiry cannot be before reservation date.
-- ------------------------------------------------------------
CREATE TABLE library.reservations (
    reservation_id   SERIAL PRIMARY KEY,
    book_id          INT NOT NULL REFERENCES library.books(book_id)        ON DELETE CASCADE,
    borrower_id      INT NOT NULL REFERENCES library.borrowers(borrower_id) ON DELETE CASCADE,
    branch_id        INT          REFERENCES library.branches(branch_id)    ON DELETE SET NULL,
    reservation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date      DATE,                               -- nullable: may be open-ended
    status           VARCHAR(20) NOT NULL DEFAULT 'Pending'
                         CHECK (status IN ('Pending', 'Fulfilled', 'Cancelled', 'Expired')),
                         -- CHECK: specific value constraint
    CONSTRAINT chk_expiry CHECK (expiry_date IS NULL OR expiry_date >= reservation_date)
);

-- ------------------------------------------------------------
-- FINES
-- amount CHECK >= 0 — fine cannot be negative (non-negative value constraint).
-- due_date — deadline by which the fine must be paid.
-- paid_status DEFAULT FALSE — new fines are unpaid by default.
-- ------------------------------------------------------------
CREATE TABLE library.fines (
    fine_id     SERIAL PRIMARY KEY,
    loan_id     INT          NOT NULL REFERENCES library.loans(loan_id),
    borrower_id INT          NOT NULL REFERENCES library.borrowers(borrower_id),
    amount      DECIMAL(8,2) NOT NULL CHECK (amount >= 0),
                             -- CHECK: financial amount cannot be negative (non-negative constraint)
                             -- DECIMAL(8,2): precise monetary value, avoids float rounding errors
    paid_status BOOLEAN      NOT NULL DEFAULT FALSE,     -- DEFAULT FALSE: fines start as unpaid
    due_date    DATE,                                    -- payment deadline
    fine_reason TEXT                                     -- TEXT: reason can be long and variable
);

-- ------------------------------------------------------------
-- PAYMENTS
-- Records actual payments made against fines.
-- RESTRICT on fine_id — cannot delete a fine that has a payment record.
-- payment_method CHECK — only accepted payment methods allowed (specific value constraint).
-- amount CHECK > 0 — payment must be a positive value.
-- ------------------------------------------------------------
CREATE TABLE library.payments (
    payment_id     SERIAL PRIMARY KEY,
    fine_id        INT          NOT NULL REFERENCES library.fines(fine_id)       ON DELETE RESTRICT,
    borrower_id    INT          NOT NULL REFERENCES library.borrowers(borrower_id),
    payment_date   DATE         NOT NULL DEFAULT CURRENT_DATE,
    amount         DECIMAL(8,2) NOT NULL CHECK (amount > 0),
                                -- CHECK: payment must be positive (non-negative constraint)
    payment_method VARCHAR(30)  CHECK (payment_method IN ('Cash', 'Card', 'Online', 'Other')),
                                -- CHECK: specific value constraint
    notes          TEXT         -- TEXT: optional free-form notes
);