-- ==============================================================================
-- Hydra Canvas API & Declarative UI Integration - Lua Bindings Documentation
-- ==============================================================================
--
-- Java Class: `com.hydra.hclc.HydraCanvasView`
-- Metatable: `HydraCanvas_MT`
--
-- Description:
-- A zero-allocation, pooled JNI bridge to the Android `android.graphics.Canvas` API.
-- The hardware rendering lifecycle is driven by the Android UI thread. This framework
-- utilizes a declarative UI pattern (`loadlayout`) where the `onDraw` callback is
-- bound inline. The engine automatically maps this callback to `setOnDrawRef` in
-- the underlying Java View, injecting the pooled `HydraCanvasProxy` during render passes.
-- ==============================================================================

-- ==============================================================================
-- Canvas Methods Reference:
-- ==============================================================================
-- State & Transformations:
-- canvas:save() -> integer
-- canvas:restore()
-- canvas:translate(dx, dy)
-- canvas:scale(sx, sy)
-- canvas:rotate(degrees)
--
-- Drawing Operations:
-- canvas:drawColor(color_int)
-- canvas:drawARGB(a, r, g, b)
-- canvas:drawRect(left, top, right, bottom, paint)
-- canvas:drawRoundRect(left, top, right, bottom, rx, ry, paint)
-- canvas:drawCircle(cx, cy, radius, paint)
-- canvas:drawLine(startX, startY, stopX, stopY, paint)
-- canvas:drawPath(path, paint)
-- canvas:drawText(text_string, x, y, paint)
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Declarative Layout & Render Loop
-- ==============================================================================

-- 1. Import required Java classes into the Lua environment
import("android.graphics.Paint")
import("android.graphics.Color")
import("com.hydra.hclc.HydraCanvasView")

-- 2. Pre-allocate Paint objects outside the render loop.
-- Allocating Java objects inside `onDraw` will cause GC thrashing and drop frames.
local fillPaint = Paint()
fillPaint:setAntiAlias(true)
fillPaint:setColor(Color.parseColor("#FFD700"))
fillPaint:setStyle(Paint.Style.FILL)

local strokePaint = Paint()
strokePaint:setAntiAlias(true)
strokePaint:setColor(Color.parseColor("#00E5FF"))
strokePaint:setStyle(Paint.Style.STROKE)
strokePaint:setStrokeWidth(12.0)

local textPaint = Paint()
textPaint:setAntiAlias(true)
textPaint:setColor(Color.parseColor("#FFFFFF"))
textPaint:setTextSize(72.0)
textPaint:setTextAlign(Paint.Align.CENTER)

-- 3. Define the UI layout declaratively and bind the render callback
local layout = loadlayout({
    HydraCanvasView,
    layout_width = "fill",
    layout_height = "fill",

    -- The engine automatically registers this closure via `LUA_REGISTRYINDEX`
    -- and triggers `nativeDispatchDraw` every time the view invalidates.
    onDraw = function(canvas, width, height)
        -- Clear the background entirely
        canvas:drawColor(Color.parseColor("#121212"))

        -- Calculate dynamic center points
        local cx = width / 2
        local cy = height / 2

        -- Draw absolute crosshairs
        strokePaint:setColor(Color.parseColor("#333333"))
        canvas:drawLine(0, cy, width, cy, strokePaint)
        canvas:drawLine(cx, 0, cx, height, strokePaint)

        -- Draw an absolute circle
        strokePaint:setColor(Color.parseColor("#00E5FF"))
        canvas:drawCircle(cx, cy, 350, strokePaint)

        -- Draw a rounded rectangle centered on cx, cy
        local boxSize = 200
        canvas:drawRoundRect(cx - boxSize, cy - boxSize, cx + boxSize, cy + boxSize, 40, 40, fillPaint)

        -- Apply Matrix Transformations
        canvas:save()             -- Push current matrix to stack
        canvas:translate(cx, cy)  -- Shift origin (0,0) to the center of the view
        canvas:rotate(45)         -- Rotate coordinate system by 45 degrees

        -- Draw relative to the newly translated and rotated origin
        strokePaint:setColor(Color.parseColor("#FF1744"))
        canvas:drawRect(-150, -150, 150, 150, strokePaint)

        -- Restore original matrix (origin returns to top-left)
        canvas:restore()

        -- Draw text using the restored coordinate system
        canvas:drawText("HYDRA ENGINE", cx, cy + 500, textPaint)
    end
})

-- 4. Apply the constructed layout to the main Android Activity
activity.setContentView(layout)


-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. UI Thread Blocking: The `onDraw` function runs synchronously on Android's
--    Main UI Thread. Do NOT perform file I/O, heavy mathematical calculations,
--    or allocate Java objects (`Paint()`, `Color.parseColor()`) inside this block.
-- 2. Object Persistence: The `canvas` object is transient. The C++ bridge nullifies
--    the proxy immediately after `onDraw` completes. Caching `canvas` globally
--    will lead to silent failures or JNI crashes on the next frame.
-- 3. Dynamic Rendering: To trigger this drawing routine continuously (e.g., for
--    a game loop or animation), you must call `.invalidate()` on the View instance
--    from an external tick mechanism.
-- ==============================================================================