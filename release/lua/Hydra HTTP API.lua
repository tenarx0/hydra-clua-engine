-- ==============================================================================
-- Hydra HTTP API - Advanced Lua Bindings Documentation
-- ==============================================================================
--
-- Global Table: `http`
--
-- The Hydra HTTP subsystem is a high-performance, context-aware networking
-- engine. It provides a unified interface to both native C++ (libcurl) and
-- Android OS (Java) networking stacks, handling complex multi-threading
-- invisibly to provide a smooth Developer Experience (DX).
-- ==============================================================================

-- ==============================================================================
-- 1. BACKEND ENGINES: 'curl' vs 'java'
-- ==============================================================================
-- You can specify the backend via the 'engine' field in the config table.
--
-- 'curl' (Default):
--   - Tech: Native C++ libcurl + BoringSSL.
--   - Why: Maximum performance, lowest memory overhead, bypasses Java GC.
--   - When: 95% of all tasks. Use for high-frequency API calls and heavy data.
--
-- 'java':
--   - Tech: Android OS HttpURLConnection.
--   - Why: Uses System-level configurations (VPNs, Proxies, Root CAs).
--   - When: When you need to respect user-installed security certificates or
--           corporate network proxy settings (PAC files) that bypass libcurl.
-- ==============================================================================

-- ==============================================================================
-- 2. EXECUTION MODES: WITH vs WITHOUT ISOLATE
-- ==============================================================================
-- The engine dynamically detects the execution context to ensure stability.
--
-- MODE A: WITHOUT Isolate (Asynchronous / Main Thread)
--   - Requirement: A callback function is MANDATORY.
--   - Behavior: The call returns immediately (nil). The request runs in the
--     background. When finished, the engine "trampolines" the result back to
--     the Main UI Thread to safely execute your callback.
--   - Best For: UI updates, fire-and-forget pings, single API fetches.
--
-- MODE B: WITH Isolate (Synchronous / Background Thread)
--   - Behavior: If called inside `isolate.await()`, the engine BLOCKS the
--     background thread until the request finishes.
--   - Returns:
--     1. If no callback: Returns (status, body, error).
--     2. If callback provided: Executes callback inline and returns its result.
--   - Best For: Sequential logic, heavy data processing, multi-step API chains.
-- ==============================================================================

-- ==============================================================================
-- API REFERENCE
-- ==============================================================================
-- http.request(config, [callback])
--
-- [Config Fields]:
--   url        (string)  : Required. The target URL.
--   method     (string)  : "GET", "POST", "PUT", "DELETE" (Default: "GET").
--   engine     (string)  : "curl" or "java" (Default: "curl").
--   headers    (table)   : Dictionary of string keys/values.
--   body       (string)  : Payload for POST/PUT.
--   timeout    (number)  : Timeout in milliseconds (Default: 10000).
--   verify_ssl (boolean) : Verify certificates (curl engine only, Default: true).
-- ==============================================================================

-- ==========================
-- EXAMPLE: ASYNC (Main Thread)
-- ==========================
http.request({
    url = "https://google.com",
    method = "GET"
}, function(code, body, err)
    if code == 200 then
        logcat.info("Server is Online")
    else
        logcat.error("Connection Failed: " .. tostring(err))
    end
end)

-- ==========================
-- EXAMPLE: SYNC (In Isolate)
-- ==========================
isolate.start(function()
    -- Sequential, non-nested logic
    local result = isolate.await(function()
        local res = "";
        http.request({
            url = "https://google.com",
            engine = "curl"
        }, function(code, body, err)
            if code == 200 then
                res = body
            end
            return nil
        end)
        return res
    end)

    -- Back to UI thread to use the data
    isolate.mainThread(function()
        if result then logcat.info("Fetched: " .. result) end
    end)
end)

-- ==============================================================================
-- CRITICAL SECURITY & STABILITY RULES
-- ==============================================================================
-- 1. NO BLOCKING ON MAIN: If you call http.request on the main thread without
--    a callback, the engine will throw a Lua error to prevent ANR (App Not Responding).
-- 2. THREAD SAFETY: Do not attempt to share Lua tables between the main thread
--    and isolates. Use `json.encode/decode` to pass data safely.
-- 3. HEADER TYPES: Headers MUST be strings. `headers = { ["ID"] = 123 }` will fail.
--    Use `headers = { ["ID"] = tostring(123) }`.
-- ==============================================================================