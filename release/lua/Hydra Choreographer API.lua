-- ==============================================================================
-- Hydra Choreographer API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `choreographer`
--
-- Description:
-- A high-performance render loop manager synchronized directly with the Android
-- hardware display refresh rate (via Android's native `Choreographer`). It computes
-- the precise delta time (`dt`) between frames in seconds and passes it to the
-- registered Lua callback.
--
-- Architectural Note:
-- The system enforces a strict single-loop policy. You cannot have multiple
-- render loops running concurrently via this module.
-- ==============================================================================

-- ==============================================================================
-- Choreographer Methods Reference:
-- ==============================================================================
-- choreographer.setRenderLoop(callback_function)
--   Registers a Lua closure to be fired on every vsync. The callback receives
--   a single argument `dt` (delta time in seconds). Throws a Lua error if a
--   loop is already running.
--
-- choreographer.stopRenderLoop()
--   Safely unregisters the Lua closure from the registry, halts the Java-side
--   Choreographer dispatch, and resets the engine state, freeing up the slot
--   for a new render loop.
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Main Game/Render Loop
-- ==============================================================================
import "com.hydra.hclc.HydraSurfaceView"
this.setContentView(HydraSurfaceView(this)--[[ graphics.ready = true. ]]);
local time_elapsed = 0.0
local entity_x = 0.0
local speed = 150.0 -- pixels per second

-- Define the render callback
-- @param dt (number) Fractional seconds since the last frame (e.g., 0.0166 for 60fps)
local function main_tick(dt)
    -- Accumulate total time
    time_elapsed = time_elapsed + dt

    -- Framerate-independent movement logic
    entity_x = entity_x + (speed * dt)

    -- Draw logic (assuming graphics API is initialized)
    if graphics.isReady() then
        graphics.clearColor(0.1, 0.1, 0.1, 1.0)
        -- graphics.drawSprite(texId, entity_x, 0, 100, 100)
        graphics.present()
    else
        logcat.error("Graphics aren't initialized.");
    end

    -- Example condition to halt the engine
    if time_elapsed > 10.0 then
        -- Safely terminate the render loop from within the loop itself
        choreographer.stopRenderLoop()
        logcat.info("Render loop terminated after 10 seconds.")
    end
end

-- Start the synchronized hardware loop
choreographer.setRenderLoop(main_tick)


-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Concurrency Prevention: Calling `setRenderLoop` while another loop is active
--    triggers a fatal Lua error: "setRenderLoop is being called somewhere else...".
--    Always call `stopRenderLoop` before transitioning scenes or changing loops.
-- 2. Exception Safety: If the Lua callback crashes (e.g., attempting to index a
--    nil value), the C++ `HydraChoreographer_nativeDoFrame` catches the `pcall`
--    failure, dumps the stack trace to Logcat ("Choreographer Crash: ..."), and
--    automatically invokes the Java `stop()` method to prevent runaway error spam
--    on the UI thread.
-- 3. Memory Leaks: Overwriting the callback without calling `stopRenderLoop`
--    (if the C++ lock was bypassed) would leak the closure in `LUA_REGISTRYINDEX`.
--    The `stopRenderLoop` function ensures `luaL_unref` is called safely.
-- 4. Initial Frame Delta: On the very first frame of execution, `dt` will be exactly
--    0.0, as `g_lastFrameTime` needs one cycle to initialize. Game logic should
--    handle `dt == 0` gracefully.
-- ==============================================================================