-- ==============================================================================
-- Hydra Navigator API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `navigator`
--
-- Description:
-- Hardware-accelerated screen router managing View transitions within a
-- single Android Activity stack.
-- ==============================================================================

-- ==============================================================================
-- Methods Reference:
-- ==============================================================================
-- navigator.init(activity_instance)
--   Initializes the native router. Must be called once before routing.
--   - activity_instance (userdata): The `HydraJObject` wrapping the current Activity.
--
-- navigator.push(view_instance, [animation_config])
--   Pushes a new View onto the stack.
--   - view_instance (userdata): An inflated Android View object.
--   - animation_config (table) [Optional]: { type = "string", duration = integer }.
--     Defaults: type = "slide_left", duration = 300.
--
-- navigator.pop([animation_config])
--   Removes the current View from the stack, restoring the previous one.
--   - animation_config (table) [Optional]: { type = "string", duration = integer }.
--     Defaults: type = "slide_right", duration = 300.
-- ==============================================================================

-- ==============================================================================
-- Production Usage:
-- ==============================================================================

-- 1. Initialize the router with the root Activity context (typically 'this')
navigator.init(this)

-- Assuming `screen1` and `screen2` are compiled View objects ready for display:

-- 2. Push the initial screen onto the stack (using default animation)
navigator.push(screen1)

-- 3. Push a second screen on top with a custom transition
navigator.push(screen2, {
    type = "zoom",
    duration = 500
})

-- 4. Pop the current screen (screen2) off the stack to return to screen1
navigator.pop({
    type = "fade",
    duration = 200
})