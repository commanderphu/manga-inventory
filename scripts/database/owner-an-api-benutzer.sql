-- Einmalig für Installationen von vor #12 (vor November 2026):
-- Tabellen und Funktionen, die per Hand als Superuser angelegt wurden,
-- an den DB-Benutzer der API übertragen. Danach kann die API ihre
-- Migrationen beim Start selbst ausführen.
--
-- Als Superuser ausführen, api_user = Wert von DB_USER:
--   psql -U <superuser> -d manga_inventory -v api_user=manga_admin -f owner-an-api-benutzer.sql
--
-- Funktionen von Erweiterungen (uuid-ossp) bleiben unberührt.

SELECT format('ALTER TABLE public.%I OWNER TO %I;', tablename, :'api_user')
FROM pg_tables
WHERE schemaname = 'public' AND tableowner <> :'api_user'
\gexec

SELECT format('ALTER FUNCTION %s OWNER TO %I;', p.oid::regprocedure, :'api_user')
FROM pg_proc p
WHERE p.pronamespace = 'public'::regnamespace
  AND pg_get_userbyid(p.proowner) <> :'api_user'
  AND NOT EXISTS (
    SELECT 1 FROM pg_depend d
    WHERE d.classid = 'pg_proc'::regclass AND d.objid = p.oid AND d.deptype = 'e'
  )
\gexec
