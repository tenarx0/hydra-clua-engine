-- ==============================================================================
-- Hydra Reactive State API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Function: `state`
-- Metatable: `HydraState_MT` (Handles Garbage Collection via `__gc`)
--
-- Description:
-- A reactive data primitive that bridges Lua variables directly to the Android
-- Java UI layer. When a `HydraState` object is updated via its `set` method,
-- the underlying C++ pointer signals the JVM, automatically invalidating and
-- redrawing any native Android Views bound to this state.
--
-- Architectural Note:
-- The C++ implementation stores the value internally as a `std::string`. If you
-- initialize it with a Lua number, it is automatically converted to a string,
-- and trailing fractional zeros (e.g., "10.000") are truncated cleanly to "10".
-- ==============================================================================

-- ==============================================================================
-- State Methods Reference:
-- ==============================================================================
-- state(initial_value) -> userdata (HydraState)
--   Allocates a new C++ HydraState object and wraps it in a Lua userdata.
--   - initial_value (string | number): The starting value.
--
-- state_instance:set(new_value)
--   Updates the internal C++ string and invokes `setValue(env, newVal)` to trigger
--   Java-side UI reactivity.
--   - new_value (string): The new state value.
--
-- state_instance:get() -> string
--   Retrieves the current value directly from the C++ pointer.
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Reactive UI Binding
-- ==============================================================================

-- 1. Initialization
-- Creates a reactive state initialized to the string "100"
local player_health = state(100)
local status_message = state("Idle")

-- 2. Declarative UI Binding
-- As seen in the declarative UI framework, you pass the raw state object
-- to View properties. The Java bridge resolves the pointer and sets up the observer.
import("android.widget.Button")
import("android.widget.LinearLayout")
import("android.widget.TextView")
import("android.view.View$OnClickListener")
local layout = loadlayout({
    LinearLayout,
    layout_width = "fill",
    {
        TextView,
        id = "health_display",
        text = player_health,     -- Bound directly to the HydraState userdata
        textSize = "24sp"
    },
    {
        Button,
        text = "Take Damage",
        OnClickListener = OnClickListener {
            onClick = function(view)
                -- 3. Mutating State
                -- Retrieve the current value, cast it, modify it, and set it back.
                local current_hp = tonumber(player_health:get())
                logcat.info(current_hp)
                logcat.info(status_message:get())
                if current_hp > 0 then
                    -- Calling :set() automatically notifies the Java TextView to redraw
                    -- with the new value. No manual UI invalidation required.
                    player_health:set(tostring(current_hp - 10))
                else
                    status_message:set("Player Defeated")
                end
            end
        }
    }
})

this.setContentView(layout);

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Number Coercion: If you pass a float like `10.5` to `state()`, it becomes
--    the string `"10.5"`. If you pass `10.0`, the C++ engine trims the trailing
--    `.0` and stores `"10"`.
-- 2. Type Restriction: The `set` method relies on `lua_tostring`, which means
--    passing booleans or tables directly to `myState:set(true)` will result in
--    unexpected behavior or strings like "nil". Always explicitly cast non-string
--    types before setting them.
-- 3. Memory Management: The `__gc` metamethod handles `delete *statePtr`. When
--    the Lua variable `player_health` goes out of scope, the C++ memory is freed.
--    Ensure your Java-side observers use WeakReferences, or unbind them when the
--    View is destroyed, to prevent segfaults when Java tries to read a deleted C++ state.
-- ==============================================================================