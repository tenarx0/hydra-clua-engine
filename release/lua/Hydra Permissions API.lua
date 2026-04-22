-- ==============================================================================
-- Hydra Permissions API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `permission`
--
-- Description:
-- A native bridge to the Android OS PackageManager. It handles runtime permission
-- checks (API 23+) and dispatches asynchronous system dialogs to request user
-- authorization. The C++ layer automatically manages the lifecycle of the Lua
-- callback, ensuring memory is freed once the OS returns the user's decision.
--
-- Architectural Note:
-- This module requires the Java router `com.hydra.hclc.HydraPermissions` to be
-- initialized with the root Activity context, and for the Activity to override
-- `onRequestPermissionsResult` to feed the OS response back into the JNI layer.
-- ==============================================================================

-- ==============================================================================
-- Permission Methods Reference:
-- ==============================================================================
-- permission.can(permission_name) -> boolean
--   Synchronously checks if the application currently holds the specified Android permission.
--   - permission_name (string): The exact Android manifest permission string
--     (e.g., "android.permission.CAMERA").
--
-- permission.ask(permission_name, [callback_function])
--   Asynchronously requests the permission from the Android OS.
--   - permission_name (string): The permission to request.
--   - callback_function (function) [Optional]: A closure executed when the user
--     grants or denies the request.
--     Signature: `function(permission_name, is_granted)`
--       * `permission_name` (string): The requested permission.
--       * `is_granted` (boolean): True if allowed, false if denied.
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Guarding Hardware Access
-- ==============================================================================

local PERM_CAMERA = "android.permission.CAMERA"

-- 1. Synchronous Check
if permission.can(PERM_CAMERA) then
    logcat.info("Camera permission is already granted.")
else
    -- 2. Asynchronous Request
    logcat.warn("Camera permission missing. Triggering OS prompt.")
    permission.ask(PERM_CAMERA, function(perm_name, is_granted)
        if is_granted then
            logcat.info("User granted access to: " .. perm_name)
        else
            logcat.error("User denied access to: " .. perm_name)
            -- Execute fallback logic, show error UI, or disable camera features
        end
    end)
end

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Implicit Grants: If `permission.ask` is called but the permission is already
--    granted (or the device is running Android 5.1 / API 22 or lower), the Java
--    router will instantly fire the Lua callback with `is_granted = true` rather
--    than displaying a prompt.
-- 2. Memory Leaks: The C++ bridge uses `luaL_ref` to store the callback in the
--    registry. It is programmed to call `luaL_unref` exactly once when the JNI
--    result arrives. If the Android OS kills the Activity before the user answers
--    the prompt, the reference may leak until the app process restarts.
-- 3. Duplicate Requests: If you call `ask` for the same permission twice before
--    the first OS prompt is answered, the C++ layer safely unreferences the old
--    callback and replaces it with the new one, preventing duplicate executions
--    and registry leaks.
-- ==============================================================================