-- ==============================================================================
-- Hydra Logcat API - Lua Bindings Documentation
-- ==============================================================================
-- 
-- Registered Global Table: `logcat`
-- 
-- Description:
-- A direct bridge to Android's native logging facility (`__android_log_print`).
-- All logs emitted through this module are tagged with "HydraLua" in the Android 
-- logcat output. The functions accept a variable number of arguments and concatenate 
-- them with a space separator.
-- ==============================================================================

-- ==============================================================================
-- Logcat Methods Reference:
-- ==============================================================================
-- logcat.verbose(...) -> outputs as ANDROID_LOG_VERBOSE
-- logcat.debug(...)   -> outputs as ANDROID_LOG_DEBUG
-- logcat.info(...)    -> outputs as ANDROID_LOG_INFO
-- logcat.warn(...)    -> outputs as ANDROID_LOG_WARN
-- logcat.error(...)   -> outputs as ANDROID_LOG_ERROR
-- logcat.fatal(...)   -> outputs as ANDROID_LOG_FATAL
-- logcat.default(...) -> outputs as ANDROID_LOG_DEFAULT
-- logcat.silent(...)  -> outputs as ANDROID_LOG_SILENT
-- logcat.unknown(...) -> outputs as ANDROID_LOG_UNKNOWN


-- 1. Standard Single-String Logging
logcat.info("Hydra Engine initialized successfully.")

-- 2. Multi-Argument Logging
-- The C++ bridge automatically concatenates multiple arguments with a space.
local player_x = 150
local player_y = 300
logcat.debug("Player spawned at coordinates:", player_x, player_y)

-- 3. Error and Warning Reporting
local status = false
if not status then
    logcat.error("Failed to load critical texture atlas.")
    logcat.warn("Falling back to default textures.")
end

-- 4. Fatal Exceptions
-- Triggers a fatal log in Android. (Note the spelling matching the C++ binding).
logcat.fatal("Out of VRAM! Engine crash imminent.")

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Type Coercion Limitation: The C++ loop uses `lua_isstring` to validate arguments. 
--    While this automatically coerces Lua numbers to strings, it will silently IGNORE 
--    booleans, nils, tables, and userdata. 
--    Example: `logcat.info("Status:", true)` will only print "Status: " because `true` 
--    fails the `lua_isstring` check. 
--    Fix: Always wrap non-string/non-number types in Lua's `tostring()` before logging.
--    Example: `logcat.info("Status:", tostring(true))`
--
-- 2. Performance: Avoid heavy string concatenation or logging inside tight loops 
--    (like `choreographer`'s render loop or `graphics.drawCamera`), as the JNI 
--    overhead and native string allocations (`msg +=`) will severely impact framerate.
-- ==============================================================================