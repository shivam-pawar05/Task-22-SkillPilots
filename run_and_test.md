# Run and Test
1. `CREATE DATABASE bookstore_import_demo;`
2. Connect: `psql -U postgres -d bookstore_import_demo`
3. Run schema and procedure files using psql `\i /full/path/sql/01_schema.sql` and `\i /full/path/sql/02_import_procedure.sql`.
4. Copy the sample CSV to a path readable by the PostgreSQL server process.
5. Run: `CALL public.import_books_csv('/server/readable/path/books.csv');`
6. Verify: `SELECT * FROM public.books;` and `SELECT * FROM public.book_import_errors;`

Expected on a fresh database with the supplied sample: 6 input rows, 5 inserted, 1 rejected (missing title).
CSV header/order: title,author,isbn,price,published_year. A blank published year is allowed.
Server-side COPY reads the server machine's filesystem, not the client machine. The caller needs appropriate privileges. Use a separate practice database.
