-- ==============================================================================
-- Hydra Camera Subsystem - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `camera`
--
-- Description:
-- A high-performance, native hardware camera interface built on Android's NDK
-- Camera2 API (ACameraManager). It streams raw YUV_420_888 frames directly into
-- the `HydraGraphics` pipeline, bypassing the JVM entirely for zero-copy
-- performance (or near zero-copy depending on the graphics backend).
-- ==============================================================================


-- ==============================================================================
-- Function 1: start
-- ==============================================================================
-- Description:
-- Initializes the camera hardware, opens the first available camera device (usually
-- the rear main camera), sets up the AImageReader, and begins a repeating capture
-- session.
--
-- Signature:
-- local success = camera.start([width], [height])
--
-- Parameters:
-- 1. width  (integer) [Optional]: Requested frame width. Default: 1280.
-- 2. height (integer) [Optional]: Requested frame height. Default: 720.
--
-- Returns:
-- - (boolean) `true` if the camera stream successfully started, `false` otherwise.
--
-- Note: The requested resolution must be supported by the device hardware.
-- The NDK framework often falls back or scales if the exact resolution isn't met,
-- but requesting non-standard aspect ratios may lead to stretched frames.
-- ==============================================================================

-- Usage Example: start
if permission.can("android.permission.CAMERA") then
    local is_streaming = camera.start(1920, 1080)
end
if is_streaming then
    print("Camera stream active at 1080p. Frames are being pushed to HydraGraphics.")
else
    print("Failed to initialize camera hardware or stream already active.")
end

-- Fallback to default 720p (1280x720) if no arguments are provided
-- camera.start()


-- ==============================================================================
-- Function 2: getBrightness
-- ==============================================================================
-- Description:
-- Returns the current calculated brightness of the camera feed.
-- Note: Based on the C++ source, `currentBrightness` is an atomic float. While
-- the getter is exposed, the actual computational update of this value happens
-- externally (likely via luma plane analysis in `HydraGraphics` or an OpenCV thread).
--
-- Signature:
-- local brightness = camera.getBrightness()
--
-- Returns:
-- - (number) A float representing the atomic brightness value.
-- ==============================================================================

-- Usage Example: getBrightness
-- Can be used in a tick/update loop to adjust UI elements based on ambient light
local ambient_light = camera.getBrightness()
if ambient_light < 0.2 then
    -- Trigger low-light UI mode or prompt user to turn on flash
    print("Low light detected.")
end


-- ==============================================================================
-- Function 3: stop
-- ==============================================================================
-- Description:
-- Safely halts the repeating capture request, closes the capture session,
-- disconnects the camera device, and frees all associated NDK memory structures
-- (AImageReader, OutputTargets, etc.).
--
-- Signature:
-- camera.stop()
--
-- Returns:
-- Nothing.
-- ==============================================================================

-- Usage Example: stop
-- Always call this when backgrounding the app or destroying the view to release
-- the hardware lock, otherwise other apps (or the OS) will fail to access the camera.
camera.stop()


-- ==============================================================================
-- Edge Cases & Architectural Notes:
-- ==============================================================================
-- 1. State Management: Calling `camera.start()` while `isStreaming` is true will
--    safely early-exit and return `false`. It will not cause a memory leak or crash.
-- 2. Frame Processing: The `OnImageAvailable` callback intercepts YUV_420_888 data.
--    The U and V planes have varying pixel strides depending on the Android device
--    (some interleave UV, some don't). `HydraGraphics::PushCameraFrame` must properly
--    handle these strides, or you will experience chrominance tearing in the render.
-- 3. Error Handling: Hardware disconnects (e.g., physical damage, OS preemption)
--    trigger `OnDeviceDisconnected` or `OnDeviceError`, which internally call
--    `StopStream()`. From Lua, you may want to poll `camera.start()` again to
--    attempt recovery, as there are no async error callbacks exposed to Lua yet.
-- ==============================================================================