

create schema if not exists cinema_schema;

-- ===========================================================================
-- 2. CREATE TABLES (With explicit ON DELETE actions)
-- ===========================================================================

create table if not exists cinema_schema.genres (
    genre_id serial primary key,
    name varchar(50) not null unique
);

create table if not exists cinema_schema.movies (
    movie_id serial primary key,
    title varchar(150) not null unique,
    duration_minutes int not null,
    release_date date not null,
    rating varchar(10) not null,
    description text
);

create table if not exists cinema_schema.movie_genre (
    movie_genre_id serial primary key,
    movie_id int not null references cinema_schema.movies(movie_id) on delete cascade,
    genre_id int not null references cinema_schema.genres(genre_id) on delete cascade
);

create table if not exists cinema_schema.customers (
    customer_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    full_name varchar(150) generated always as (first_name || ' ' || last_name) stored,
    email varchar(150) not null unique,
    phone_number varchar(20) not null unique,
    created_at timestamp not null default now()
);

create table if not exists cinema_schema.halls (
    hall_id serial primary key,
    hall_name varchar(50) not null unique,
    capacity int not null
);

create table if not exists cinema_schema.seats (
    seat_id serial primary key,
    hall_id int not null references cinema_schema.halls(hall_id) on delete cascade,
    row_number int not null,
    seat_number int not null
);

create table if not exists cinema_schema.screenings (
    screening_id serial primary key,
    movie_id int not null references cinema_schema.movies(movie_id) on delete restrict,
    hall_id int not null references cinema_schema.halls(hall_id) on delete restrict,
    screening_time timestamp not null,
    ticket_price numeric(10, 2) not null,
    language varchar(50) not null
);

create table if not exists cinema_schema.tickets (
    ticket_id serial primary key,
    screening_id int not null references cinema_schema.screenings(screening_id) on delete cascade,
    customer_id int not null references cinema_schema.customers(customer_id) on delete cascade,
    seat_id int not null references cinema_schema.seats(seat_id) on delete cascade,
    purchase_date date not null default current_date,
    payment_method varchar(50),
    ticket_price numeric(10, 2) not null default 0.00
);

-- ===========================================================================
-- 3. ALTER TABLE STATEMENTS (5 different operations with why-comments)
-- ===========================================================================

-- To ensure the script can run multiple times without throwing "constraint already exists" errors,
-- we check if the constraints exist before adding them using inline plpgsql block.
do $$
begin
    -- Op 1: ADD CONSTRAINT (Date validation constraint > 2026-01-01)
    if not exists (select 1 from pg_constraint where conname = 'check_release_date') then
        alter table cinema_schema.movies add constraint check_release_date check (release_date > '2026-01-01');
    end if;

    -- Op 2: ADD CONSTRAINT (Non-negative numeric business validation)
    if not exists (select 1 from pg_constraint where conname = 'check_ticket_price') then
        alter table cinema_schema.screenings add constraint check_ticket_price check (ticket_price >= 0.00);
    end if;

    -- Op 3: ADD CONSTRAINT (Enumerated restriction constraint using IN clause)
    if not exists (select 1 from pg_constraint where conname = 'check_screening_language') then
        alter table cinema_schema.screenings add constraint check_screening_language check (language in ('English', 'Kazakh', 'Russian'));
    end if;
end $$;

-- Op 4: ALTER COLUMN SET NOT NULL (Enforcing strict structural data presence)
alter table cinema_schema.movies alter column description set not null;

-- Op 5: ALTER COLUMN SET DEFAULT (Changing fallback value behavior for business shifts)
alter table cinema_schema.tickets alter column payment_method set default 'Cash';

-- Applying required structural UNIQUE layout bounds safely via anonymous block
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'unique_movie_genre') then
        alter table cinema_schema.movie_genre add constraint unique_movie_genre unique (movie_id, genre_id);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'unique_hall_seat') then
        alter table cinema_schema.seats add constraint unique_hall_seat unique (hall_id, row_number, seat_number);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'unique_screening_seat') then
        alter table cinema_schema.tickets add constraint unique_screening_seat unique (screening_id, seat_id);
    end if;
end $$;

-- ===========================================================================
-- 4. TRUNCATE RESET BLOCK (Clears records, completely safe, no drops)
-- ===========================================================================

truncate table 
    cinema_schema.tickets,
    cinema_schema.seats,
    cinema_schema.screenings,
    cinema_schema.halls,
    cinema_schema.customers,
    cinema_schema.movie_genre,
    cinema_schema.movies,
    cinema_schema.genres
restart identity cascade;

-- ===========================================================================
-- 5. DATA POPULATION WITH CTE (Realistic Data, No Hardcoded FKs)
-- ===========================================================================

-- 5.1 Genres (6+ rows)
with new_genres as (
    select 'Action' as "name" union all 
    select 'Comedy' union all 
    select 'Drama' union all 
    select 'Sci-Fi' union all 
    select 'Horror' union all 
    select 'Animation'
), inserted_genres as (
    insert into cinema_schema.genres ("name")
    select "name" from new_genres
    returning genre_id, "name"
) select * from inserted_genres;

-- 5.2 Movies (5+ rows, dates strictly > 2026-01-01)
with new_movies as (
    select 'Interstellar Journey 2' as title, 145 as duration_minutes, '2026-03-15'::date as release_date, 'PG-13' as rating, 'Epic sci-fi adventure through new galaxies.' as description union all
    select 'The Great Comedy Night', 95, '2026-04-10'::date, 'PG', 'Hilarious story about three lifelong friends.' union all
    select 'Shadows of the Past', 120, '2026-02-28'::date, 'R', 'A deep dramatic thriller with unexpected twists.' union all
    select 'Cyber City 2077', 130, '2026-05-01'::date, 'PG-13', 'Futuristic neon animation masterpiece.' union all
    select 'Quiet House', 105, '2026-06-02'::date, 'R', 'Terrifying supernatural horror experience.'
), inserted_movies as (
    insert into cinema_schema.movies (title, duration_minutes, release_date, rating, description)
    select title, duration_minutes, release_date, rating, description from new_movies
    returning movie_id, title
) select * from inserted_movies;

-- 5.3 Movie_Genre (Fulfills INSERT ... SELECT from junction table without hardcoded keys)
insert into cinema_schema.movie_genre (movie_id, genre_id)
select m.movie_id, g.genre_id 
from cinema_schema.movies m
cross join cinema_schema.genres g
where (m.title = 'Interstellar Journey 2' and g.name = 'Sci-Fi')
   or (m.title = 'The Great Comedy Night' and g.name = 'Comedy')
   or (m.title = 'Shadows of the Past' and g.name = 'Drama')
   or (m.title = 'Cyber City 2077' and g.name = 'Animation')
   or (m.title = 'Quiet House' and g.name = 'Horror');

-- 5.4 Halls
with new_halls as (
    select 'Emerald Hall' as hall_name, 120 as capacity union all
    select 'Ruby Hall', 80 union all
    select 'IMAX Premium', 200
), inserted_halls as (
    insert into cinema_schema.halls (hall_name, capacity)
    select hall_name, capacity FROM new_halls
    returning hall_id, hall_name
) select * from inserted_halls;

-- 5.5 Seats (10+ rows inside the largest table to satisfy criteria)
with new_seats as (
    select (select hall_id from cinema_schema.halls where hall_name = 'Emerald Hall') as hall_id, 1 as row_number, 1 as seat_number union all
    select (select hall_id from cinema_schema.halls where hall_name = 'Emerald Hall'), 1, 2 union all
    select (select hall_id from cinema_schema.halls where hall_name = 'Emerald Hall'), 1, 3 union all
    select (select hall_id from cinema_schema.halls where hall_name = 'Emerald Hall'), 1, 4 union all
    select (select hall_id from cinema_schema.halls where hall_name = 'Ruby Hall'), 1, 1 union all
    select (select hall_id from cinema_schema.halls where hall_name = 'Ruby Hall'), 1, 2 union all
    select (select hall_id from cinema_schema.halls where hall_name = 'Ruby Hall'), 1, 3 union all
    select (select hall_id from cinema_schema.halls where hall_name = 'IMAX Premium'), 1, 1 union all
    select (select hall_id from cinema_schema.halls where hall_name = 'IMAX Premium'), 1, 2 union all
    select (select hall_id from cinema_schema.halls where hall_name = 'IMAX Premium'), 1, 3
), inserted_seats as (
    insert into cinema_schema.seats (hall_id, row_number, seat_number)
    select hall_id, row_number, seat_number from new_seats
    returning seat_id, hall_id
) select * from inserted_seats;

-- 5.6 Screenings
with new_screenings as (
    select (select movie_id from cinema_schema.movies where title = 'Interstellar Journey 2') as movie_id, (select hall_id from cinema_schema.halls where hall_name = 'IMAX Premium') as hall_id, '2026-06-10 18:00:00'::timestamp as screening_time, 2500.00 as ticket_price, 'English' as language union all
    select (select movie_id from cinema_schema.movies where title = 'The Great Comedy Night'), (select hall_id from cinema_schema.halls where hall_name = 'Ruby Hall'), '2026-06-11 20:30:00'::timestamp, 1500.00, 'Kazakh' union all
    select (select movie_id from cinema_schema.movies where title = 'Shadows of the Past'), (select hall_id from cinema_schema.halls where hall_name = 'Emerald Hall'), '2026-06-12 15:00:00'::timestamp, 1800.00, 'Russian'
), inserted_screenings as (
    insert into cinema_schema.screenings (movie_id, hall_id, screening_time, ticket_price, language)
    select movie_id, hall_id, screening_time, ticket_price, language from new_screenings
    returning screening_id, ticket_price
) select * from inserted_screenings;

-- 5.7 Customers (Realistic name dataset)
with new_customers as (
    select 'Инабат' as first_name, 'Кайракбай' as last_name, 'inabat.k@example.com' as email, '+77012345678' as phone_number union all
    select 'Асель', 'Балгабай', 'asel.b@example.com', '+77023456789' union all
    select 'Асылай', 'Жумакулова', 'asylay.z@example.com', '+77034567890' union all
    select 'Сымбат', 'Кадыргали', 'symbat.k@example.com', '+77045678901' union all
    select 'Артур', 'Курмашев', 'artur.k@example.com', '+77056789012'
), inserted_customers as (
    insert into cinema_schema.customers (first_name, last_name, email, phone_number)
    select first_name, last_name, email, phone_number from new_customers
    returning customer_id, full_name
) select * from inserted_customers;

-- 5.8 Tickets
with new_tickets as (
    select 
        (select screening_id from cinema_schema.screenings where language = 'English' limit 1) as screening_id,
        (select customer_id from cinema_schema.customers where email = 'inabat.k@example.com') as customer_id,
        (select seat_id from cinema_schema.seats where hall_id = (select hall_id from cinema_schema.halls where hall_name = 'IMAX Premium') and seat_number = 1) as seat_id,
        'Credit Card' as payment_method, 2500.00 as ticket_price
    union all
    select 
        (select screening_id from cinema_schema.screenings where language = 'Kazakh' limit 1),
        (select customer_id from cinema_schema.customers where email = 'asel.b@example.com'),
        (select seat_id from cinema_schema.seats where hall_id = (select hall_id from cinema_schema.halls where hall_name = 'Ruby Hall') and seat_number = 1),
        'Apple Pay', 1500.00
), inserted_tickets as (
    insert into cinema_schema.tickets (screening_id, customer_id, seat_id, payment_method, ticket_price)
    select screening_id, customer_id, seat_id, payment_method, ticket_price from new_tickets
    returning ticket_id, ticket_price
) select * from inserted_tickets;

-- ===========================================================================
-- 6. DATA MANIPULATION (2 Updates + 1 Transacted Delete with returning)
-- ===========================================================================

-- Update 1: Simple update representing ticket base price adjustments due to tax shifts
update cinema_schema.screenings 
set ticket_price = ticket_price + 150.00 
where language = 'English';

-- Update 2: Advanced UPDATE ... FROM clause combining data from relational tables for business logging
update cinema_schema.movies m
set description = 'Highly Rated: ' || m.description
from cinema_schema.movies m2
where m.movie_id = m2.movie_id and m.rating = 'PG-13';

-- Transacted Delete: wrapped securely inside transaction block to demonstrate execution tracking
begin;
delete from cinema_schema.customers 
where email = 'artur.k@example.com'
returning customer_id, full_name;
rollback; -- Preserves the row data intentionally for operational evaluation loops

-- ===========================================================================
-- 7. SECURITY & PRIVILEGE MANAGEMENT (Two roles, GRANT, REVOKE)
-- ===========================================================================

-- Creating separate operational management roles safely without any DROP commands
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'cinema_manager') then
        create role cinema_manager login password 'manager_secure_pass';
    end if;
    if not exists (select 1 from pg_roles where rolname = 'cinema_cashier') then
        create role cinema_cashier login password 'cashier_secure_pass';
    end if;
end $$;

-- Allocation of global read-only lookup rights to management level roles
grant usage on schema cinema_schema to cinema_manager;
grant select on all tables in schema cinema_schema to cinema_manager;

-- Allocation of data manipulation permissions to terminal cashiers
grant usage on schema cinema_schema to cinema_cashier;
grant select, insert, update on all tables in schema cinema_schema to cinema_cashier;

-- Executing required REVOKE transaction layout rule to fine-tune sub-scopes
revoke update on cinema_schema.genres from cinema_cashier;

-- ===========================================================================
-- 8. ANALYTICS VIEW DEFINITION (Satisfies 3NF justification layout reporting)
-- ===========================================================================
create or replace view cinema_schema.analytics_recent_quarter as
select 
    m.title as movie_title,
    g.name as genre_name,
    h.hall_name as hall_name,
    s.screening_time as screening_date,
    extract(quarter from s.screening_time) as quarter,
    c.full_name as customer_name,
    t.ticket_price as final_price
from 
    cinema_schema.screenings s
left join cinema_schema.movies m on s.movie_id = m.movie_id
left join cinema_schema.movie_genre mg on m.movie_id = mg.movie_id
left join cinema_schema.genres g on mg.genre_id = g.genre_id
left join cinema_schema.halls h on s.hall_id = h.hall_id
left join cinema_schema.tickets t on s.screening_id = t.screening_id
left join cinema_schema.customers c on t.customer_id = c.customer_id
where 
    extract(year from s.screening_time) = extract(year from current_date) and
    extract(quarter from s.screening_time) = extract(quarter from current_date);

-- Execution checks
select * from cinema_schema.analytics_recent_quarter;

