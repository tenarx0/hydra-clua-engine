-- ==============================================================================
-- Hydra Key-Value Storage API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `storage`
--
-- Description:
-- A lightweight, persistent Key-Value storage engine mapped directly to the
-- physical file system (POSIX I/O). Files are stored in a dedicated `hydrakv`
-- directory within the application's secure storage. Keys are automatically
-- hex-encoded (sanitized) by the C++ bridge to prevent path-traversal attacks
-- and allow special characters in key names.
--
-- Architectural Note:
-- The Java wrapper MUST call `HydraBridge.nativeInitStorage(path)` to set
-- `g_storage_dir` before any Lua script attempts to read or write, otherwise
-- the engine will throw a fatal `luaL_error`.
-- ==============================================================================

-- ==============================================================================
-- Storage Methods Reference:
-- ==============================================================================
-- storage.set(key_string, value_string_or_binary) -> boolean
--   Writes the raw string or binary payload to disk. Overwrites if it exists.
--   Returns `true` if all bytes were successfully written, `false` otherwise.
--
-- storage.get(key_string) -> string | nil
--   Reads the exact binary size of the file into a Lua string.
--   Returns the string, or `nil` if the key does not exist or read fails.
--
-- storage.delete(key_string) -> boolean
--   Deletes the underlying `.kv` file from the physical disk.
--   Returns `true` on success, `false` if the file didn't exist or deletion failed.
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Persistent State & Preferences
-- ==============================================================================

-- 1. Standard Key-Value Storage (Strings)
local success = storage.set("player_username", "Tenar")
if success then
    -- logcat.info("Username saved to disk.")
end

-- 2. Retrieval
local username = storage.get("player_username")
if username then
    logcat.info("Welcome back, " .. username)
else
    logcat.info("No username found.")
end

-- 3. Storing Serialized Tables (JSON)
-- The storage engine accepts raw strings, so you must serialize Lua tables first.
local game_settings = {
    audio_volume = 0.8,
    graphics_quality = "High",
    invert_y = false
}

-- Assumes the `json` module is available
storage.set("config_settings", json.encode(game_settings))

-- 4. Storing Encrypted Binary Payloads
-- The C++ `fwrite` / `fread` uses raw binary buffers, making it completely
-- safe to store encrypted Libsodium blobs without string encoding corruption.
-- local ciphertext = crypto.encrypt("secret_data", master_key)
-- storage.set("secure_vault", ciphertext)

-- 5. Deletion
storage.delete("player_username")

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Thread Blocking: `storage.set` and `storage.get` execute synchronous POSIX
--    file I/O (`fopen`, `fread`, `fwrite`) directly on the calling thread. If
--    used inside the Main UI thread or a high-speed `choreographer` loop, reading/writing
--    large payloads (e.g., Megabytes) will cause the UI to stutter and drop frames.
-- 2. Nil Returns: Always check if `storage.get()` returns `nil`. Feeding a `nil`
--    value into `json.decode` or `crypto.decrypt` will crash the Lua state.
-- ==============================================================================