-- ==============================================================================
-- Hydra SQLite Database Engine - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `database`
-- Metatable: `HydraDatabase_MT` (Handles Garbage Collection via `__gc`)
--
-- Description:
-- A secure, thread-safe (SQLITE_OPEN_FULLMUTEX) SQLite3 wrapper for local data
-- persistence. The database files are strictly sandboxed to the application's
-- secure storage directory (`g_storage_dir`), which must be initialized by the
-- Java bridge before calling any database functions.
-- ==============================================================================

-- ==============================================================================
-- Module Methods Reference (`database`):
-- ==============================================================================
-- database.open(dbName) -> userdata (HydraDB)
--   Opens or creates a SQLite database file inside the app's secure storage.
--   Throws a Lua error if `g_storage_dir` is empty or if the SQLite connection fails.

-- ==============================================================================
-- Instance Methods Reference (`HydraDB` userdata):
-- ==============================================================================
-- db:execute(sql_string) -> integer
--   Executes a non-query SQL statement (INSERT, UPDATE, DELETE, CREATE).
--   Returns the number of rows modified by the statement (`sqlite3_changes`).
--   Throws a Lua error on syntax or execution failure.
--
-- db:query(sql_string) -> table
--   Executes a SELECT query and fetches all rows into memory.
--   Returns an array-like table of rows. Each row is a dictionary-like table
--   mapping column names to their respective values.
--   Supported types: INTEGER, FLOAT, TEXT, NULL, BLOB (as Lua strings).
--   Throws a Lua error on syntax or execution failure.
--
-- db:close()
--   Safely closes the database connection and nullifies the internal pointer.
--   Calling this manually is recommended, but it will automatically trigger
--   during Lua Garbage Collection (`__gc`).
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Initialization, Execution, and Queries
-- ==============================================================================

-- 1. Open or create the database
-- The actual file path will be `g_storage_dir + "game_data.db"`
local db = database.open("game_data.db")

-- 2. Schema Creation (Using pcall for structured error handling)
local create_table_sql = [[
    CREATE TABLE IF NOT EXISTS players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        score INTEGER DEFAULT 0,
        health REAL DEFAULT 100.0,
        payload BLOB
    );
]]

local success, err = pcall(function()
    db:execute(create_table_sql)
end)

if not success then
    print("Failed to initialize schema: " .. tostring(err))
    return
end

-- 3. Inserting Data
-- DEFENSIVE ENGINEERING WARNING: The current C++ bindings do not support parameterized
-- prepared statements (e.g., `db:execute("INSERT...", bind_args)`).
-- You MUST manually sanitize user inputs in Lua before concatenating them into SQL
-- strings to prevent SQL Injection, or extend the C++ layer to support `sqlite3_bind_*`.

local username = "Tenar" -- Ensure this is sanitized if coming from user input
local insert_sql = string.format("INSERT OR IGNORE INTO players (username, score) VALUES ('%s', %d);", username, 2500)
local rows_changed = db:execute(insert_sql)
print("Rows inserted/updated: " .. rows_changed)

-- 4. Querying Data
local query_sql = "SELECT id, username, score, health FROM players ORDER BY score DESC LIMIT 10;"
local result_set = db:query(query_sql)

-- result_set is an array of tables: { {id=1, username="Tenar", score=2500, health=100.0}, ... }
for index, row in ipairs(result_set) do
    print(string.format("Rank %d: %s - Score: %d (Health: %.1f)",
        index,
        row.username,
        row.score,
        row.health
    ))
end

-- 5. BLOB Handling
-- BLOBs are returned as standard Lua strings containing raw bytes.
-- If you insert BLOB data, you must format it correctly as a hex literal in the SQL string
-- (e.g., x'FF00AA'), since parameterized binding is not yet implemented.

-- 6. Resource Teardown
-- While the `__gc` metamethod handles memory leaks if the variable goes out of scope,
-- explicitly closing the connection is best practice in mobile environments to release
-- the file lock (`SQLITE_OPEN_FULLMUTEX`) immediately.
db:close()

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Security/SQL Injection: The absence of `sqlite3_bind` exposure in `Database_execute`
--    and `Database_query` is a severe security constraint. Do not use direct string
--    concatenation with untrusted inputs. You must sanitize strings (escaping `'` to `''`)
--    before passing them to these methods.
-- 2. Memory Consumption: `db:query` fetches the *entire* result set into a Lua table
--    at once. Executing a `SELECT *` on a table with 100,000 rows will cause a massive
--    Lua heap allocation spike and likely crash the VM or trigger an Android OOM kill.
--    Always use `LIMIT` and pagination for large datasets.
-- 3. Thread Safety: The database is opened with `SQLITE_OPEN_FULLMUTEX`, making the
--    underlying SQLite connection thread-safe. However, passing the `HydraDB` userdata
--    between different Lua states on different threads without strict locking will
--    corrupt the Lua state itself.
-- ==============================================================================