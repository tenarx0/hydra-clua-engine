-- ==============================================================================
-- Hydra Isolate API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `isolate`
--
-- Description:
-- A lightweight concurrency and threading framework. It combines Lua coroutines
-- with C++ detached `std::thread` workers and Android's native Main UI Thread.
-- This allows you to offload heavy computations to hardware background threads
-- without blocking the UI, and then safely synchronize the results back to the
-- UI thread.
--
-- Architectural Note:
-- The function passed to `isolate.await` is serialized into raw bytecode via
-- `lua_dump` and executed in a completely isolated Lua state on a C++ background
-- thread. Because of this serialization, the background function CANNOT access
-- external local variables (upvalues) or global state from the main thread.
-- ==============================================================================

-- ==============================================================================
-- Isolate Methods Reference:
-- ==============================================================================
-- isolate.start(async_function, ...) -> thread (coroutine)
--   Wraps the provided function in a Lua coroutine and immediately resumes it.
--   This establishes the async context required for `await` to yield properly.
--   Any extra arguments are passed directly into the coroutine.
--
-- isolate.await(worker_function) -> any
--   Serializes `worker_function` to bytecode, spawns a C++ `std::thread`, and
--   yields the current coroutine. Once the background C++ thread finishes execution,
--   it resumes the coroutine and returns the result.
--   *Constraint:* Must be called inside an `isolate.start` block.
--
-- isolate.mainThread(ui_function)
--   Registers a Lua closure in the registry and invokes Android's `runOnUiThread`
--   via JNI. This is mandatory for touching any Android View or UI component.
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Background Processing & UI Synchronization
-- ==============================================================================

-- 1. Define UI Mutator (Must run on Main UI Thread)
import("android.widget.Button")
import("android.widget.LinearLayout")
local layout = loadlayout({
    LinearLayout,
    layout_width = "fill",
    {
        Button,
        id = "testID",
        text = "Hello World.",     -- Bound directly to the HydraState userdata
        textSize = "24sp",
        textColor = "0xFFFFFFFF"
    },
})
this.setContentView(layout);
local function CircleButton(view_id, color_hex, radius, border_color)
    import("android.graphics.drawable.GradientDrawable")
    local drawable = GradientDrawable()
    drawable:setShape(GradientDrawable.RECTANGLE)

    -- Apply uniform corner radii (8 values for 4 corners: rx, ry)
    drawable:setCornerRadii({
       radius, radius, radius, radius,
       radius, radius, radius, radius
    })

    drawable:setColor(color_hex)

    if border_color then
        drawable:setStroke(3, border_color)
    end

    view_id:setBackgroundDrawable(drawable)
end

-- 2. Execute Async Workflow
isolate.start(function()

    -- Step A: Offload heavy lifting to a C++ background thread
    -- The coroutine yields here. The main thread is FREE to keep rendering at 60fps.
    local calculation_result = isolate.await(function()
       -- WARNING: Do not reference variables outside this scope!
       -- This block is executing in a separate OS thread and Lua state.
       local heavy_math = 100 + 20

       -- Simulate disk I/O or decryption delay
       -- system.sleep(500)

       return heavy_math
    end)

    -- Step B: The coroutine resumes automatically when the C++ thread finishes.
    -- We now transition to the Android Main Thread to update the UI safely.
    isolate.mainThread(function()
        -- In your example, you used 'HHH'. Assuming it's a valid Java View object.
        CircleButton(testID, "#000000", calculation_result, "#FF0000")
        logcat.warn("UI successfully updated with background result: " .. calculation_result)
    end)

end)

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Lexical Scoping (Upvalues): Because `isolate.await` uses `lua_dump(..., 0)`,
--    it strips upvalues. If your inner worker function tries to read a variable
--    defined outside of it, it will evaluate to `nil` on the background thread and
--    likely crash the isolated state. You must self-contain the logic or pass data
--    via arguments (if your C++ `WorkerThreadPayload` supports argument forwarding).
-- 2. Non-Yieldable Execution: Calling `isolate.await` outside of `isolate.start`
--    (e.g., directly in the main chunk) will trigger a fatal `luaL_error`:
--    "HydraBridge: exec function must be inside an 'isolate' block."
-- 3. JNI Thread Attachment: The `mainThread` function relies on `current_env`.
--    If the C++ thread calling this does not have a valid JNIEnv attached to the
--    JVM, it will throw an error and leak the Lua registry reference. Ensure your
--    C++ backend properly attaches/detaches native threads to the JVM.
-- ==============================================================================