-- ==============================================================================
-- Hydra Hardware Sensors API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `sensor`
--
-- Description:
-- A low-latency bridge to the Android NDK `ASensorManager`. It attaches hardware
-- event listeners directly to the thread's `ALooper`. Events are polled at a
-- hardcoded high-performance rate of 16.6ms (~60Hz).
--
-- Architectural Note:
-- The event routing currently utilizes a Java trampoline (`HydraSensors.trampoline`)
-- to bounce the NDK event back into the C++ `nativeExecute` method before firing
-- the Lua closure. While functional, polling 60 times a second across the JNI
-- boundary incurs overhead. Ensure your Lua callbacks are mathematically lightweight.
--
-- Hardware Constants (Android NDK standard mapping):
-- 1 = Accelerometer (m/s^2)
-- 4 = Gyroscope (rad/s)
-- ==============================================================================

-- ==============================================================================
-- Sensor Methods Reference:
-- ==============================================================================
-- sensor.start(sensor_type_int, callback_function)
--   Initializes the NDK sensor manager (if not already running), registers the
--   callback in `LUA_REGISTRYINDEX`, and activates hardware polling.
--   If a callback is already registered for that type, it is unreferenced and replaced.
--   - sensor_type_int (integer): 1 for Accelerometer, 4 for Gyroscope.
--   - callback_function (function): Executed ~60 times a second.
--     Signature: `function(x, y, z, type)`
--
-- sensor.stop(sensor_type_int)
--   Disables the hardware sensor at the NDK level to conserve battery and unreferences
--   the Lua closure from the registry to prevent memory leaks.
--   - sensor_type_int (integer): 1 or 4.
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Motion Tracking & Hardware Lifecycle
-- ==============================================================================

-- Define hardware constants locally since they aren't pushed to the Lua global state yet
local SENSOR_ACCELEROMETER = 1
local SENSOR_GYROSCOPE = 4

-- 1. Accelerometer Usage (Tilt / Gravity tracking)
-- Values represent acceleration on the X, Y, and Z axes in meters per second squared (m/s^2).
-- Resting flat on a table: X ≈ 0, Y ≈ 0, Z ≈ 9.81 (Gravity).
sensor.start(SENSOR_ACCELEROMETER, function(x, y, z, type)
    -- Example: Update a global game state or UI element based on device tilt
    logcat.verbose(string.format("Tilt X: %.2f, Y: %.2f, Z: %.2f", x, y, z))

    -- In a real app, you would likely write these to a shared table and read them
    -- inside your choreographer.setRenderLoop() to move a sprite.
    shared_game_state.tilt_x = x
    shared_game_state.tilt_y = y
end)

-- 2. Gyroscope Usage (Rotation tracking)
-- Values represent the rate of rotation around the X, Y, and Z axes in radians per second (rad/s).
sensor.start(SENSOR_GYROSCOPE, function(x, y, z, type)
    -- Trigger events based on sudden twisting or rotation
    if math.abs(z) > 2.0 then
        -- logcat.info("Sharp Z-axis twist detected!")
    end
end)

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Hardware Availability: Calling `sensor.start()` on a device lacking a physical
--    gyroscope will throw a fatal `luaL_error` ("Hardware sensor not available...").
--    You should wrap initialization in a `pcall` if you deploy to low-end hardware.
-- 2. Battery Drain: Leaving hardware sensors active in the background will severely
--    drain the device battery. You MUST call `sensor.stop()` when your Activity
--    is paused or backgrounded, and restart them when resumed.
-- 3. Garbage Collection: If you pass an anonymous closure to `sensor.start` and
--    never call `sensor.stop`, the closure and all its upvalues remain locked in
--    the Lua registry forever.
-- ==============================================================================