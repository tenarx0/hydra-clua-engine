-- ==============================================================================
-- TABLE: system
-- ==============================================================================

-- system.getProp(property_key_string)
-- C++: `__system_property_get()`.
-- Returns: (string | nil) Android kernel/build property (e.g., "ro.build.version.release").

-- system.getStorageInfo(mount_path_string)
-- C++: `statvfs()`. Calculates block size * available blocks.
-- Returns: (table | nil) {totalMB = float, freeMB = float}.

-- system.getCpuCount()
-- C++: `sysconf(_SC_NPROCESSORS_ONLN)`.
-- Returns: (integer) Active online core count (minimum 1).

-- system.uuid()
-- C++: Reads 16 bytes directly from `/dev/urandom` and bitmasks to RFC 4122 v4 spec.
-- Returns: (string) Formatted UUID (e.g., "123e4567-e89b-12d3-a456-426614174000").

-- system.now()
-- C++: `clock_gettime(CLOCK_MONOTONIC)`. Immune to wall-clock changes (NTP syncs).
-- Returns: (number) Sub-millisecond hardware uptime.

-- system.unixTimeMs()
-- C++: `gettimeofday()`. Epoch time.
-- Returns: (number) Exact Unix time in milliseconds.

-- system.getMemoryInfo()
-- C++: `sysinfo()`. Fetches OS-level RAM stats.
-- Returns: (table) {totalMB = float, freeMB = float, sharedMB = float}.

-- system.sleep(milliseconds_int)
-- C++: `usleep()`.
-- WARNING: Blocks the executing native thread. Do not use on the UI/Render thread.
-- Returns: nothing.

-- system.getBatteryInfo()
-- C++: Reads `capacity` and `temp` from `/sys/class/power_supply/battery/`.
-- Returns: (table) {level = int, temperature = float (Celsius)}. -1 if hardware unsupported.


-- 1. OS Properties & UUID
local device_model = system.getProp("ro.product.model")
local session_id = system.uuid()

-- 2. Hardware Capabilities
local cpu_cores = system.getCpuCount()
local storage = system.getStorageInfo("/data/user/0")
local memory = system.getMemoryInfo()
local battery = system.getBatteryInfo()

print(string.format("Cores: %d, Free RAM: %.1f MB", cpu_cores, memory.freeMB))

-- 3. High-Resolution Profiling (Monotonic Clock)
local start_time = system.now()

-- ... intense processing ...
system.sleep(50) -- Sleep native thread for 50ms

local duration = system.now() - start_time
print(string.format("Operation took %.3f ms", duration))

-- 4. Epoch Time
local epoch_ms = system.unixTimeMs()