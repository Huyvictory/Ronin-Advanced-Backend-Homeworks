-- Composite index
DISCARD ALL;

CREATE INDEX idx_boarding_passes_boarding_seat_no ON bookings.boarding_passes USING btree (seat_no, boarding_no);

SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN ANALYSE
SELECT boarding_no, count(*) AS count
FROM bookings.boarding_passes
WHERE seat_no = '10A'
GROUP BY boarding_no;

SET enable_indexscan = on;
SET enable_bitmapscan = on;

SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN ANALYSE
SELECT *
FROM bookings.boarding_passes
WHERE seat_no = 'A11'
  AND boarding_no = 139;

SET enable_indexscan = on;
SET enable_bitmapscan = on;


-- Index Failure 01
DISCARD ALL;

-- index with collate
CREATE INDEX idx_boarding_passes_seat_no_collate ON bookings.boarding_passes USING btree (seat_no collate "C");

-- index with trigram
CREATE EXTENSION pg_trgm;

CREATE INDEX idx_boarding_passes_seat_no_trigram ON bookings.boarding_passes USING gin (seat_no gin_trgm_ops);

SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN ANALYSE
SELECT *
FROM bookings.boarding_passes
WHERE seat_no LIKE '11%';

SET enable_indexscan = on;
SET enable_bitmapscan = on;

-- Index Failure 02
DISCARD ALL;

EXPLAIN ANALYSE
SELECT *
FROM bookings.boarding_passes
WHERE seat_no = 'A11'
   OR boarding_no = 139;

-- Index Failure 03
DISCARD ALL;

CREATE INDEX idx_boarding_passes_boarding_no ON bookings.boarding_passes USING btree (boarding_no);

-- Index Failure 3.1

SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN ANALYSE
SELECT *
FROM bookings.boarding_passes
WHERE boarding_no = '139';

SET enable_indexscan = on;
SET enable_bitmapscan = on;

-- Index Failure 3.2

SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN ANALYSE
SELECT *
FROM bookings.boarding_passes
WHERE seat_no = 11
  AND boarding_no = '139';

SET enable_indexscan = on;
SET enable_bitmapscan = on;

-- Index Failure 04
DISCARD ALL;

SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN ANALYSE
SELECT *
FROM bookings.boarding_passes
WHERE length(seat_no) = 2;

SET enable_indexscan = on;
SET enable_bitmapscan = on;

-- Index Failure 05
DISCARD ALL;

CREATE INDEX idx_boarding_passes_boarding_no ON bookings.boarding_passes USING btree (seat_no, boarding_no);

EXPLAIN ANALYSE
SELECT *
FROM bookings.boarding_passes
WHERE boarding_no - 1 = 138
  AND seat_no = 'A11';

-- Clustered Index and Non-Clustered Index
DISCARD ALL;

SELECT relname,
       relclustered
FROM pg_class
WHERE relname = 'boarding_passes';

-- Query before clustering

-- Test Query 1: Range scan on boarding_no
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM boarding_passes
WHERE boarding_no BETWEEN 1 AND 100
ORDER BY boarding_no;

-- Test Query 2: Specific flight lookup
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM boarding_passes
WHERE flight_id = 169878
ORDER BY boarding_no;

-- Query after clustering index
CREATE INDEX idx_boarding_passes_boarding_no
    ON boarding_passes USING btree (boarding_no);

CLUSTER boarding_passes USING idx_boarding_passes_boarding_no;

ANALYZE boarding_passes;

ALTER TABLE boarding_passes
    SET WITHOUT CLUSTER;

-- set up non-clustered index
CREATE INDEX idx_boarding_passes_seat_no ON boarding_passes USING btree (seat_no);

-- Test Query:
EXPLAIN (ANALYZE, BUFFERS)
SELECT bp.*
FROM boarding_passes bp
WHERE seat_no = '30A'
ORDER BY boarding_no;

