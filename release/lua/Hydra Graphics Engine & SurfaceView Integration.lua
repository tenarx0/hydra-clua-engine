-- ==============================================================================
-- Hydra Graphics Engine & SurfaceView Integration - Lua Bindings Documentation
-- ==============================================================================
--
-- Java Class: `com.hydra.hclc.HydraSurfaceView`
-- Registered Global Table: `graphics`
--
-- Description:
-- A bare-metal, high-performance OpenGL ES 3.0 rendering pipeline. The Java
-- `HydraSurfaceView` manages the EGL lifecycle context. The rendering loop is
-- driven by the `choreographer` module, which provides the delta time (`dt`)
-- per frame. Capabilities include real-time YUV_420_888 to RGB hardware
-- conversion for camera feeds and instanced sprite rendering.
-- ==============================================================================

-- ==============================================================================
-- Graphics Methods Reference:
-- ==============================================================================
-- graphics.isReady() -> boolean
-- graphics.clearColor(r, g, b, [a])
-- graphics.loadSprite(absolute_path) -> integer
-- graphics.drawSpriteBatch(texID, instance_table)
-- graphics.drawCamera()
-- graphics.present()
-- ==============================================================================


-- ==============================================================================
-- Production Usage: View Initialization & Render Loops
-- ==============================================================================

-- 1. Initialize the Hardware Surface
import "com.hydra.hclc.HydraSurfaceView"
this.setContentView(HydraSurfaceView(this)--[[ graphics.ready = true. ]])

-- ==============================================================================
-- Example A: Procedural Color Clear Loop
-- Pulses the background color smoothly using delta time.
-- ==============================================================================
--[[
local time = 0
choreographer.setRenderLoop(function(dt)
    time = time + dt
    local r = (math.sin(time) + 1.0) / 2.0
    local g = (math.cos(time * 1.5) + 1.0) / 2.0
    local b = 0.5
    graphics.clearColor(r, g, b, 1.0)
end)
]]

-- ==============================================================================
-- Example B: Hardware Camera Feed Loop
-- Streams the NDK camera directly to the EGL surface.
-- ==============================================================================
--[[
if permission.can("android.permission.CAMERA") then
    camera.start(1280, 720)
    choreographer.setRenderLoop(function(dt)
        -- drawCamera automatically handles buffer swapping internally
        graphics.drawCamera()
    end)
end
]]

-- ==============================================================================
-- Example C: Hardware Instanced Sprite Rendering
-- Asynchronously loads a texture into VRAM once the GPU is ready, then animates
-- a large sprite in a circular path.
-- ==============================================================================
local heroPath = "/sdcard/hero.png"
local heroTex = 0
local gpuReady = false
local time = 0

-- Pre-allocate the batch table to prevent garbage collection frame drops
local batchData = {}

import "java.io.File"
choreographer.setRenderLoop(function(dt)
    -- Abort frame if the Android OS has destroyed or suspended the EGL context
    if not graphics.isReady() then return end

    if not File(heroPath).exists() then logcat.error("Hero file doesn't exist.") return end
    -- 1. Late-Initialization: Load texture only after EGL context is verified
    if not gpuReady then
       heroTex = graphics.loadSprite(heroPath)
       if heroTex ~= 0 then gpuReady = true end
       return
    end

    -- 2. Update state
    time = time + dt

    -- 3. Clear previous frame
    graphics.clearColor(0.1, 0.1, 0.15, 1.0)

    -- 4. Mutate batch data (x, y, w, h in Normalized Device Coordinates)
    batchData[1] = math.sin(time) * 0.3  -- x: gentle circular orbit
    batchData[2] = math.cos(time) * 0.3  -- y: gentle circular orbit
    batchData[3] = 0.4                   -- w: 40% of screen dimension
    batchData[4] = 0.4                   -- h: 40% of screen dimension

    -- 5. Dispatch instanced draw call
    graphics.drawSpriteBatch(heroTex, batchData)

    -- 6. Swap EGL buffers to present the frame
    graphics.present()
end)

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Table Allocation: Instantiating new tables (`{}`) inside the `choreographer`
--    tick function will cause Lua Garbage Collection spikes, resulting in dropped frames.
--    Always pre-allocate arrays like `batchData` globally or as file-local upvalues.
-- 2. EGL State Checking: Checking `graphics.isReady()` at the start of the render
--    loop is critical. Android Activity transitions (like locking the screen) destroy
--    the EGL surface, and issuing draw calls without it will crash the application.
-- ==============================================================================