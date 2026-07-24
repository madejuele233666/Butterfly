-- Profile A: strict WAL durability
PRAGMA journal_mode = WAL;
PRAGMA synchronous = FULL;
PRAGMA foreign_keys = ON;

-- Profile B: writing latency candidate; test, do not assume
-- PRAGMA journal_mode = WAL;
-- PRAGMA synchronous = NORMAL;
-- PRAGMA foreign_keys = ON;

-- Profile C: rollback journal comparison
-- PRAGMA journal_mode = PERSIST;
-- PRAGMA synchronous = FULL;
-- PRAGMA foreign_keys = ON;
