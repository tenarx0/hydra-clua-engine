-- ==============================================================================
-- Hydra Network API - Lua Bindings Documentation
-- ==============================================================================
--
-- Registered Global Table: `network`
--
-- Description:
-- A high-performance, asynchronous WebSocket client powered by a background
-- C++ `std::thread` and the Mongoose networking library. It features thread-safe
-- message queueing, automatic exponential backoff reconnection (up to 8 seconds),
-- and a built-in JSON Pub/Sub router.
--
-- Architectural Note:
-- The C++ background thread handles the actual TCP/WS sockets and queues messages.
-- To trigger your Lua callbacks on the main thread, you MUST poll `network.processEvents()`
-- continuously inside your game loop or choreographer tick.
-- ==============================================================================

-- ==============================================================================
-- Network Methods Reference:
-- ==============================================================================
-- network.connect(ws_url)
--   Initiates a background connection to the WebSocket endpoint.
--   Throws a Lua error if called while already connected.
--
-- network.disconnect()
--   Safely closes the socket, clears the outbound queue, and disables auto-reconnect.
--
-- network.isConnected() -> boolean
--   Returns true ONLY if the TCP connection is alive AND the WS Handshake is complete.
--
-- network.subscribe(channel_name, callback_function)
--   Registers a Lua function to be fired when an inbound message matches the `channel_name`.
--   The callback receives a single argument: the stringified `payload`.
--
-- network.send(json_envelope_string)
--   Pushes a string to the C++ outbound queue. Max queue size is 500. If the queue
--   fills up while offline, the oldest messages are dropped.
--
-- network.processEvents()
--   Locks the inbound queue, parses any pending messages using cJSON, and executes
--   the mapped Lua callbacks synchronously.
--
-- network.injectTestMessage(json_envelope_string)
--   Pushes a mock message directly into the inbound queue to test routing without
--   a live server connection.
-- ==============================================================================


-- ==============================================================================
-- Production Usage: Pub/Sub WebSocket Architecture
-- ==============================================================================

-- 1. Establish connection to your backend (e.g., Spring Boot, Node.js)
network.connect("ws://10.0.2.2:9000/hydra")

-- 2. Subscribe to incoming channels BEFORE polling events
-- The C++ router expects strict JSON envelopes: {"channel": "...", "payload": {...}}
network.subscribe("player_movement", function(payload_string)
    -- The C++ layer extracts the "payload" key and passes it here as a string.
    -- You must decode it back into a Lua table if it's an object.
    local data = json.decode(payload_string)

    if data and data.x and data.y then
        logcat.info(string.format("Server moved player to X:%d Y:%d", data.x, data.y))
    end
end)

local time_since_last_telemetry = 0.0

-- 3. The Tick Loop: Polling and Transmitting
choreographer.setRenderLoop(function(dt)

    -- Accumulate delta time
    time_since_last_telemetry = time_since_last_telemetry + dt

    -- Transmit telemetry every 2.0 seconds
    if time_since_last_telemetry > 2.0 then

        if network.isConnected() then
            -- Note: `network.send` requires a string. It will NOT automatically encode Lua tables.
            -- You must format the envelope exactly as the router expects.
            local envelope = {
                channel = "player_movement",
                payload = { x = 800, y = 900 }
            }

            network.send(json.encode(envelope))
            logcat.info("Telemetry dispatched to outbound queue.")
        else
            logcat.warn("Network offline. Telemetry paused. Auto-reconnect is handling it.")
        end

        time_since_last_telemetry = 0.0
    end

    -- 4. CRITICAL: Drain the inbound queue and trigger Lua callbacks
    -- If you forget this, incoming messages will build up in RAM forever.
    network.processEvents()

    -- Optional: Render logic
    if graphics.isReady() then
        graphics.clearColor(0.1, 0.1, 0.15, 1.0)
        graphics.present()
    end
end)

-- ==============================================================================
-- Edge Cases & Production Notes:
-- ==============================================================================
-- 1. Envelope Strictness: The `cJSON_Parse` implementation in `processEvents` is
--    unforgiving. If an inbound message is not valid JSON, or if it lacks the
--    exact keys `"channel"` and `"payload"` (case-sensitive), the C++ router drops
--    the message instantly and logs a warning.
-- 2. Outbound Queue Dropping: If the server goes offline, `autoReconnect` takes over.
--    If your Lua loop keeps calling `network.send()` during this downtime, the
--    `MAX_OUTBOUND_QUEUE_SIZE` (500) will be hit. C++ will start `pop()`ing the
--    oldest messages to prevent memory leaks.
-- 3. Heartbeats: The C++ loop automatically fires an empty `WEBSOCKET_OP_PING`
--    every 15 seconds if the line is idle. You do not need to implement application-level
--    ping/pong unless your specific backend requires a formatted JSON heartbeat.
-- ==============================================================================