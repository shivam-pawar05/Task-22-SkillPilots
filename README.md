# PostgreSQL Bulk Book CSV Import
PostgreSQL stored procedure project: stage CSV rows, validate required fields, log rejected rows, insert valid books, and report counts.

Requirements: PostgreSQL 11+, psql, and a database role permitted to read the CSV from the PostgreSQL server filesystem.

1. Create a practice database and connect with psql.
2. Run `sql/01_schema.sql` and `sql/02_import_procedure.sql`.
3. Put `sample_data/books.csv` in a directory readable by the PostgreSQL SERVER.
4. Call `CALL public.import_books_csv('/absolute/server/path/books.csv');`
5. Check `SELECT * FROM books;` and `SELECT * FROM book_import_errors;`.

Important: server-side COPY requires server filesystem access and elevated file-read privileges (often `pg_read_server_files`). Do not grant this broadly. This is a local educational demo; use trusted files and paths only.
