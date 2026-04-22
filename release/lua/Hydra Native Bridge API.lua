-- ==============================================================================
-- Hydra Native Bridge API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Functions: `invokeStatic`, `newInstance`, `invokeMethod`
-- Metatable: `HydraNativeObject` (Handles Garbage Collection via `__gc`)
--
-- Description:
-- The core JNI reflection router. This bridge allows Lua to dynamically instantiate
-- Java classes, invoke static methods, and call instance methods directly. It
-- automatically marshals Lua types (string, number, boolean) into Java objects
-- (`java.lang.String`, `java.lang.Double`, `java.lang.Boolean`) and wraps returned
-- Java objects in a `HydraJObject` userdata. Memory management is automatic; when
-- the userdata is garbage collected in Lua, the underlying JNI `GlobalRef` is deleted.
--
-- Dependencies:
-- This module relies on a corresponding Java class (defined by `HydraBridge::g_HydraReflectionRouterClass`)
-- that actually performs the `java.lang.reflect` lookups.
-- ==============================================================================

-- ==============================================================================
-- Bridge Methods Reference:
-- ==============================================================================
-- invokeStatic(class_name, method_name, ...) -> any | (nil, error_string)
--   Invokes a static method on the specified Java class.
--   Parameters:
--     1. class_name (string): Fully qualified Java class name (e.g., "java.lang.System").
--     2. method_name (string): The static method to call.
--     3... (varargs): Arguments to pass to the method.
--
-- newInstance(class_name, ...) -> userdata (HydraJObject) | (nil, error_string)
--   Invokes the constructor of the specified Java class and returns a wrapped instance.
--   Parameters:
--     1. class_name (string): Fully qualified Java class name.
--     2... (varargs): Arguments to pass to the constructor.
--
-- invokeMethod(target_instance, method_name, ...) -> any | (nil, error_string)
--   Invokes an instance method on a previously instantiated Java object.
--   Parameters:
--     1. target_instance (userdata): The `HydraJObject` returned by `newInstance` or a previous invocation.
--     2. method_name (string): The instance method to call.
--     3... (varargs): Arguments to pass to the method.
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Java Reflection
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Example 1: Static Method Invocation (java.lang.System)
-- ------------------------------------------------------------------------------
-- Call `System.currentTimeMillis()`
local time_ms, err = invokeStatic("java.lang.System", "currentTimeMillis")
if time_ms then
    logcat.info("Java System Time: " .. time_ms)
else
    logcat.error("Failed to invoke static: " .. tostring(err))
end

-- ------------------------------------------------------------------------------
-- Example 2: Instantiation & Instance Methods (android.graphics.Paint)
-- ------------------------------------------------------------------------------
-- Equivalent to Java: Paint myPaint = new Paint();
local myPaint, err = newInstance("android.graphics.Paint")

if myPaint then
    -- Equivalent to Java: myPaint.setColor(0xFFFF0000);
    invokeMethod(myPaint, "setColor", 0xFFFF0000)

    -- Return values are automatically unmarshalled if they are primitive wrappers.
    -- Equivalent to Java: boolean isAA = myPaint.isAntiAlias();
    local is_aa = invokeMethod(myPaint, "isAntiAlias")
    logcat.info(tostring(is_aa))
else
    logcat.error("Failed to create Paint instance: " .. tostring(err))
end

-- ------------------------------------------------------------------------------
-- Example 3: Nested Object Creation & Passing Userdata
-- ------------------------------------------------------------------------------
-- Create an Android Rect
local rect = newInstance("android.graphics.Rect", 10, 10, 100, 100)

-- Create a Path and add the Rect to it.
-- The C++ bridge detects `rect` is a userdata and extracts its JNI reference automatically.
local path = newInstance("android.graphics.Path")
-- Assuming Path.Direction.CW evaluates to a specific enum object or integer you have mapped.
-- invokeMethod(path, "addRect", rect, enum_cw_instance)

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Error Handling: All bridge functions return `nil` followed by an error string
--    if a JNI exception occurs. You should generally check for `nil` returns when
--    interfacing with risky Java APIs.
-- 2. Performance Overhead: JNI Reflection is inherently slow. If you are calling
--    `invokeMethod` thousands of times per frame (e.g., inside the `choreographer`
--    render loop), you will cause severe UI jank. Use declarative layouts or batch
--    operations on the C++ side for performance-critical tasks.
-- 3. Overloaded Methods: The C++ implementation delegates the actual method resolution
--    to the Java-side `HydraReflectionRouterClass`. Depending on how that router is
--    written, overloaded methods (e.g., `drawRect(Rect, Paint)` vs `drawRect(float, float...)`)
--    may fail to resolve correctly if the marshalled types (Double vs Float, Integer vs Long)
--    do not match exactly.
-- 4. Garbage Collection: When `myPaint` goes out of scope and is collected by Lua,
--    the C++ `__gc` metamethod attaches to the JVM (if needed) and calls `DeleteGlobalRef`.
--    This ensures you do not leak JNI references, which are strictly capped by the OS.
-- ==============================================================================