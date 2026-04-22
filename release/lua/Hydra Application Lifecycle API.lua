-- ==============================================================================
-- Hydra Application Lifecycle API
-- ==============================================================================
--
-- Global Table: `app`
--
-- Description:
-- These functions are the "Nervous System" of the Hydra Engine. They are
-- EVENT HOOKS triggered directly by the Android OS via the MainActivity JNI.
--
-- Developers should override these functions to manage resource allocation,
-- state persistence, and hardware-specific events.
-- ==============================================================================

--- [Lifecycle: Visible]
--- Triggered when the Activity becomes visible to the user.
--- Use this to start UI animations or refresh data that was paused.
function app.onStart()
    logcat.info("System: Application Visible")
end

--- [Lifecycle: Foreground]
--- Triggered when the app enters the foreground and starts interacting with the user.
--- Use this to resume high-frequency tasks (Sensors, Audio, Render Timers).
function app.onResume()
    logcat.info("System: Application Resumed")
end

--- [Lifecycle: Partially Hidden]
--- Triggered when the app is losing focus (e.g., split-screen, notification shade).
--- CRITICAL: You must pause heavy CPU/GPU tasks here to conserve battery.
function app.onPause()
    logcat.warn("System: Application Pausing")
end

--- [Lifecycle: Hidden]
--- Triggered when the app is no longer visible to the user.
--- Release expensive resources here (Camera handles, heavy Bitmaps).
function app.onStop()
    logcat.warn("System: Application Stopped")
end

--- [Lifecycle: Termination]
--- Triggered when the OS or User is permanently killing the process.
--- Final chance to close database handles or flush sensitive cache to disk.
function app.onDestroy()
    logcat.error("System: Application Destroyed")
end

--- [Interaction: Navigation]
--- Triggered when the physical or gesture 'Back' button is pressed.
--- @return boolean (optional) If the engine supports it, returning true may consume the event.
function app.onBackPressed()
    logcat.info("Input: Back Button Pressed")
end

--- [System: Configuration Change]
--- Triggered when the device environment changes (Orientation, Dark Mode).
--- @param orientation string Returns "portrait" or "landscape".
--- @param isNightMode boolean Returns true if System Dark Theme is active.
function app.onConfigChanged(orientation, isNightMode)
    logcat.info(string.format("System: Config Changed | Orient: %s | DarkMode: %s", orientation, tostring(isNightMode)))
end

--- [System: Focus Change]
--- Triggered when the app window gains or loses input focus.
--- @param hasFocus boolean True if the app can receive touch/keyboard input.
function app.onWindowFocusChanged(hasFocus)
    logcat.info("System: Window Focus Changed: " .. tostring(hasFocus))
end

--- [System: Memory Pressure]
--- Triggered when the Android OS is running low on RAM.
--- @param level integer Standard Android Trim Level (15 = Critical, 20 = UI Hidden, etc).
--- Use this to call collectgarbage("collect") or clear asset caches.
function app.onTrimMemory(level)
    if level >= 15 then
        logcat.error("MEMORY CRITICAL: Purging Hydra Caches (Level " .. level .. ")")
        collectgarbage("collect")
    end
end
