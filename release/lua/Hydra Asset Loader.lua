-- ==============================================================================
-- Hydra Asset Loader - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Functions:
-- 1. `getAssetPath` (C++ Binding: `HydraAssetLoader::l_getAssetPath`)
-- 2. `readAsset`    (C++ Binding: `HydraAssetLoader::l_readAsset`)
--
-- Architectural Note:
-- The C++ implementation also contains `HandleImageSource` for asynchronous,
-- threaded image loading with a global mutex-protected cache (`g_image_cache`).
-- However, this function is NOT exposed to Lua in this specific registration block.
-- ==============================================================================


-- ==============================================================================
-- Function 1: getAssetPath
-- ==============================================================================
-- Description:
-- Extracts an asset from the APK's read-only asset manager, copies it to the
-- application's physical cache directory (if it hasn't been extracted already),
-- and returns the absolute path to the cached file on disk.
--
-- Signature:
-- local path = getAssetPath(android_context, filename)
--
-- Parameters:
-- 1. android_context (userdata): A Hydra wrapper around the Android `Context` jobject.
-- 2. filename (string): The relative path/name of the file inside the APK assets folder.
--
-- Returns:
-- - (string) The absolute filesystem path to the extracted file in the cache directory.
--
-- Exceptions (Throws Lua Errors via luaL_error):
-- - Invalid arguments (missing context or filename).
-- - `g_asset_manager` is null (not initialized).
-- - File does not exist in the APK assets.
-- - File I/O failure (failed to write to physical cache).
-- - Generic C++ standard exceptions caught during JNI reflection.
-- ==============================================================================

-- Usage Example: getAssetPath
local success, result = pcall(getAssetPath, this, "models/geometry.obj")

if success then
    -- result is the absolute path string (e.g., "/data/user/0/com.app/cache/models/geometry.obj")
    print("Asset successfully cached at: " .. result)
    -- You can now pass this path to C++ libraries that require standard POSIX file paths (like Assimp, SQLite, etc.)
else
    -- result contains the error string
    print("Failed to extract asset: " .. tostring(result))
end


-- ==============================================================================
-- Function 2: readAsset
-- ==============================================================================
-- Description:
-- Reads the raw byte contents of a file directly from the APK's AAssetManager
-- into memory and returns it as a Lua string. This avoids writing to disk entirely.
--
-- Signature:
-- local data, err = readAsset(filename)
--
-- Parameters:
-- 1. filename (string): The relative path/name of the file inside the APK assets folder.
--
-- Returns (Idiomatic Lua multi-return):
-- - Success: (string) The raw binary or text data of the file.
-- - Failure: (nil, string) Returns nil followed by the error message.
--
-- Edge Cases & Production Notes:
-- - Memory constraints: This allocates `malloc(file_length)` directly in C++
--   and then pushes it to the Lua stack. Do not use this for massive files (e.g., 50MB+ videos)
--   as it duplicates the memory (once in C++ heap, once in Lua VM) before freeing the C++ buffer.
-- - It handles binary data safely because it uses `lua_pushlstring`.
-- ==============================================================================

-- Usage Example: readAsset
local file_data, err = readAsset("config/settings.json")

if file_data then
    -- successfully loaded into memory
    print("Read " .. string.len(file_data) .. " bytes from assets.")

    -- If it's a string/text file, you can parse it directly
    -- local settings = json.decode(file_data)
else
    -- Graceful error handling (no pcall required for this specific function)
    print("Error reading asset: " .. tostring(err))
end

-- Example of reading a compiled Lua script or binary payload
local chunk, load_err = readAsset("scripts/payload.luac")
if chunk then
    -- loadstring handles the binary chunk securely
    local func = loadstring(chunk)
    if func then func() end
end