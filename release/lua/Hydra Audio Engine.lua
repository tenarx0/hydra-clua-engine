-- ==============================================================================
-- Hydra Audio Engine - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `audio`
-- Metatable: `HydraAudioMeta` (Handles Garbage Collection via `__gc`)
--
-- Description:
-- A low-latency hardware audio engine built on Android's native AAudio API.
-- Supports concurrent voice playback (up to MAX_VOICES), dynamic waveform
-- synthesis, and direct-from-disk WAV loading (via dr_wav). Assets are
-- pushed to Lua as userdata and are safely garbage-collected when no longer referenced.
--
-- Constants:
-- - `audio.SINE`     (Integer)
-- - `audio.SQUARE`   (Integer)
-- - `audio.SAWTOOTH` (Integer)
-- - `audio.TRIANGLE` (Integer)
-- ==============================================================================

-- ==============================================================================
-- 1. Initialization & Teardown
-- ==============================================================================
-- The audio hardware MUST be initialized before loading or generating any assets.
-- Failing to do so throws a Lua error: "No initialization. run 'audio.init()' first."

-- Initialize the AAudio stream (Low Latency, PCM Float, Mono/Stereo mixed to Mono)
audio.init()

-- When the application backgrounds or exits, you should shut down the engine
-- to release hardware resources and flush the voice pool.
-- audio.shutdown()

-- ==============================================================================
-- 2. Loading and Playing Disk Assets (WAV)
-- ==============================================================================
-- `audio.load(absolute_path)`
-- Parses a WAV file from the physical disk into VRAM/Heap.
-- NOTE: Requires an absolute filesystem path. If using an APK asset, extract it
-- first using `getAssetPath(ctx, filename)` from the HydraAssetLoader.
-- Returns: Userdata (AudioAsset) or nil if loading fails.

local sfx_path = "/data/user/0/com.app.name/cache/explosion.wav"
local sfx_asset = audio.load(sfx_path)

if sfx_asset then
    -- `audio.play(asset, [volume])`
    -- Plays the asset on the next available voice channel.
    -- Volume is optional and defaults to 1.0.
    -- Returns: Integer (channel ID, 0 to MAX_VOICES-1), or -1 if all voices are busy.

    local channel_id = audio.play(sfx_asset, 0.8)

    if channel_id == -1 then
        print("Warning: Voice pool exhausted. Cannot play sound.")
    end
end

-- ==============================================================================
-- 3. Procedural Waveform Generation
-- ==============================================================================
-- `audio.generate(wave_type, frequency, duration_seconds)`
-- Synthesizes an audio asset in memory using mathematical oscillators.
-- Automatically applies a 10ms fade-in/fade-out envelope to prevent audio popping.
-- Returns: Userdata (AudioAsset)

-- Generate a 440Hz Sine wave (A4 note) lasting 2.5 seconds
local sine_wave = audio.generate(audio.SINE, 440.0, 2.5)
audio.play(sine_wave, 0.5)

-- Generate a 120Hz Square wave (bass/retro sound) lasting 0.5 seconds
local square_wave = audio.generate(audio.SQUARE, 120.0, 0.5)
audio.play(square_wave, 0.75)

-- Generate a 880Hz Sawtooth wave lasting 1.0 seconds
local saw_wave = audio.generate(audio.SAWTOOTH, 880.0, 1.0)
audio.play(saw_wave, 0.3)

-- Generate a 300Hz Triangle wave lasting 0.8 seconds
local tri_wave = audio.generate(audio.TRIANGLE, 300.0, 0.8)
audio.play(tri_wave, 1.0)

-- ==============================================================================
-- 4. Memory Management & Edge Cases
-- ==============================================================================
-- 1. Garbage Collection (`__gc`):
--    When a Lua variable holding an AudioAsset goes out of scope and is collected,
--    the C++ `l_audio_gc` metamethod is automatically triggered.
--    - It scans the active voice pool (`MAX_VOICES`).
--    - Instantly stops any hardware playback of that specific asset.
--    - Safely deletes the PCM float array from the C++ heap to prevent memory leaks.

-- Example of forcing GC cleanup:
sine_wave = nil
collectgarbage("collect") -- "Lua GC triggered. Hardware detached. VRAM freed." logged in logcat.

-- 2. Error Handling:
--    - Passing a destroyed or nil asset to `audio.play()` will throw:
--      "Attempt to play a destroyed AudioAsset".
--    - Forgetting `audio.init()` before calling `generate` or `load` will hard-crash
--      the Lua state with a luaL_error.
--    - Audio clipping: The C++ mixer automatically clamps output sums between -1.0f
--      and 1.0f, preventing hard hardware crashes during extreme volume overlaps,
--      though heavy distortion will still occur.
-- ==============================================================================