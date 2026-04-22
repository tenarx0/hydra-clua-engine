-- ==============================================================================
-- Hydra Animation Manager - Lua Bindings Documentation
-- ==============================================================================
-- 
-- Registered Global Function: `animate`
-- C++ Binding: `HydraAnimationManager::l_animate`
-- 
-- Description:
-- Animates a specific float property of a Java object (wrapped as a HydraJObject 
-- userdata) over a given duration. The C++ backend automatically constructs the 
-- Java setter method name (e.g., "alpha" becomes "setAlpha") and expects a 
-- JNI signature of `(F)V`. The animation uses a native cubic ease-out curve.
--
-- Signature:
-- animate(target_object, property_name, start_value, end_value, duration_ms, [autoreverse])
--
-- Parameters:
-- 1. target_object (userdata): The Java object wrapper (must have metatable "HydraJObject_MT").
-- 2. property_name (string): Base name of the property to animate (e.g., "alpha", "translationX").
-- 3. start_value   (number): The initial float value.
-- 4. end_value     (number): The final float value.
-- 5. duration_ms   (integer): Duration in milliseconds. If <= 0, property is set instantly to end_value.
-- 6. autoreverse   (boolean) [Optional]: If true, plays forward then immediately backward. Default: false.
--
-- Returns:
-- Nothing.
--
-- Errors:
-- - Throws a Lua error if the property setter is not found: "HydraAnimator: Property '<name>' not found."
-- - Throws a Lua error if a Java exception occurs during method invocation.
-- - Throws standard Lua argument errors if types are mismatched or nil.
-- ==============================================================================

-- Assume `targetView` is a previously instantiated HydraJObject userdata (e.g., a UI View)
local targetView = get_ui_element() 

-- ==============================================================================
-- Usage 1: Standard Animation
-- Animates the "alpha" property (calls `setAlpha(float)` in Java) from 0.0 to 1.0 
-- over 500 milliseconds.
-- ==============================================================================
animate(targetView, "alpha", 0.0, 1.0, 500)

-- ==============================================================================
-- Usage 2: Autoreverse Animation
-- Animates "scaleX" (calls `setScaleX(float)`) from 1.0 to 1.5 over 300ms, 
-- then automatically reverses from 1.5 back to 1.0 over another 300ms.
-- ==============================================================================
animate(targetView, "scaleX", 1.0, 1.5, 300, true)

-- ==============================================================================
-- Usage 3: Instant State Change (Zero Duration)
-- If duration is 0 (or negative), the animation queue is bypassed. The property 
-- is synchronously and immediately set to the `end_value`. Useful for resets.
-- ==============================================================================
animate(targetView, "translationY", 100.0, 0.0, 0)

-- ==============================================================================
-- Edge Cases & Architectural Notes:
-- ==============================================================================
-- 1. Property Type Restriction: Because the C++ binding explicitly looks up the 
--    method ID using the signature "(F)V", this function ONLY works for Java 
--    setters that take a single primitive `float` parameter. Passing a property 
--    that requires an `int` or `Object` will result in a "Property not found" error.
--
-- 2. Memory Management: The C++ layer takes out a `NewGlobalRef` on the Java object 
--    while the animation is active. You do not need to worry about the Java object 
--    being Garbage Collected mid-animation. The reference is safely deleted 
--    (`DeleteGlobalRef`) when the animation completes.
--
-- 3. Thread Safety: The C++ backend pushes to `g_animations` using a `std::mutex`, 
--    making it safe to register animations even if the Java UI thread (`nativeOnFrame`) 
--    is actively ticking.
-- ==============================================================================