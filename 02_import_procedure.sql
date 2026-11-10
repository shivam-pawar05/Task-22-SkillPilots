CREATE OR REPLACE PROCEDURE public.import_books_csv(IN p_file_path TEXT)
LANGUAGE plpgsql
AS $proc$
DECLARE v_total BIGINT; v_inserted BIGINT; v_rejected BIGINT;
BEGIN
 IF p_file_path IS NULL OR btrim(p_file_path)='' THEN
   RAISE EXCEPTION 'CSV file path must not be empty';
 END IF;

 CREATE TEMP TABLE IF NOT EXISTS book_import_stage (
   source_row_number BIGINT GENERATED ALWAYS AS IDENTITY,
   title TEXT, author TEXT, isbn TEXT, price TEXT, published_year TEXT
 ) ON COMMIT DROP;
 TRUNCATE pg_temp.book_import_stage RESTART IDENTITY;

 EXECUTE format(
  'COPY pg_temp.book_import_stage(title,author,isbn,price,published_year)
   FROM %L WITH (FORMAT csv, HEADER true, ENCODING ''UTF8'')', p_file_path);

 SELECT count(*) INTO v_total FROM pg_temp.book_import_stage;

 INSERT INTO public.book_import_errors
  (import_file,source_row_number,raw_title,raw_author,raw_isbn,raw_price,raw_published_year,error_reason)
 SELECT p_file_path,s.source_row_number,s.title,s.author,s.isbn,s.price,s.published_year,
 CASE
  WHEN NULLIF(btrim(s.title),'') IS NULL THEN 'Title is required'
  WHEN NULLIF(btrim(s.author),'') IS NULL THEN 'Author is required'
  WHEN NULLIF(btrim(s.isbn),'') IS NULL THEN 'ISBN is required'
  WHEN NULLIF(btrim(s.price),'') IS NULL THEN 'Price is required'
  WHEN btrim(s.price) !~ '^[0-9]+([.][0-9]{1,2})?$' THEN 'Invalid price'
  WHEN NULLIF(btrim(s.published_year),'') IS NOT NULL AND btrim(s.published_year) !~ '^[0-9]{4}$' THEN 'Invalid published year'
  WHEN EXISTS(SELECT 1 FROM public.books b WHERE b.isbn=btrim(s.isbn)) THEN 'ISBN already exists'
  ELSE 'Duplicate ISBN in CSV'
 END
 FROM pg_temp.book_import_stage s
 WHERE NULLIF(btrim(s.title),'') IS NULL
 OR NULLIF(btrim(s.author),'') IS NULL
 OR NULLIF(btrim(s.isbn),'') IS NULL
 OR NULLIF(btrim(s.price),'') IS NULL
 OR btrim(s.price) !~ '^[0-9]+([.][0-9]{1,2})?$'
 OR (NULLIF(btrim(s.published_year),'') IS NOT NULL AND btrim(s.published_year) !~ '^[0-9]{4}$')
 OR EXISTS(SELECT 1 FROM public.books b WHERE b.isbn=btrim(s.isbn))
 OR (SELECT count(*) FROM pg_temp.book_import_stage d WHERE btrim(d.isbn)=btrim(s.isbn))>1;

 GET DIAGNOSTICS v_rejected=ROW_COUNT;

 INSERT INTO public.books(title,author,isbn,price,published_year)
 SELECT btrim(s.title),btrim(s.author),btrim(s.isbn),btrim(s.price)::numeric(10,2),
        NULLIF(btrim(s.published_year),'')::integer
 FROM pg_temp.book_import_stage s
 WHERE NULLIF(btrim(s.title),'') IS NOT NULL
 AND NULLIF(btrim(s.author),'') IS NOT NULL
 AND NULLIF(btrim(s.isbn),'') IS NOT NULL
 AND NULLIF(btrim(s.price),'') IS NOT NULL
 AND btrim(s.price) ~ '^[0-9]+([.][0-9]{1,2})?$'
 AND (NULLIF(btrim(s.published_year),'') IS NULL OR btrim(s.published_year) ~ '^[0-9]{4}$')
 AND NOT EXISTS(SELECT 1 FROM public.books b WHERE b.isbn=btrim(s.isbn))
 AND (SELECT count(*) FROM pg_temp.book_import_stage d WHERE btrim(d.isbn)=btrim(s.isbn))=1;

 GET DIAGNOSTICS v_inserted=ROW_COUNT;
 RAISE NOTICE 'Import complete. Total: %, inserted: %, rejected: %',v_total,v_inserted,v_rejected;
END;
$proc$;
