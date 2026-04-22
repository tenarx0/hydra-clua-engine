-- ==============================================================================
-- TABLES: base64, hex, zip, struct
-- ==============================================================================

-- base64.encode(raw_binary) / base64.decode(b64_string)
-- C++: Custom lookup table logic.
-- Returns: (string)

-- hex.encode(raw_binary) / hex.decode(hex_string)
-- C++: Bit-shifting array to lowercase hex characters.
-- Returns: (string) Throws error if decode string is odd length or invalid char.

-- zip.compress(raw_binary) / zip.decompress(zlib_binary)
-- C++: Uses native zlib `compress` and `uncompress`.
-- Returns: (string) Throws luaL_error if payload is corrupted/buffer fails.

-- struct.pack32(integer)
-- C++: Bitwise masks `val & 0xFF` into a 4-byte char array. Little-Endian.
-- Returns: (string) Exactly 4 bytes.

-- struct.unpack32(binary_string)
-- C++: Reassembles via `buf[0] | (buf[1] << 8)...`.
-- Constraints: Must be exactly 4 bytes.
-- Returns: (integer)


-- 1. Binary Struct Packing (Little-Endian)
-- Converts an integer to a raw 4-byte sequence
local byte_header = struct.pack32(4096)
local original_int = struct.unpack32(byte_header)

-- 2. Zlib Compression
local large_payload = "REPEATING_DATA_REPEATING_DATA_REPEATING_DATA"
local compressed = zip.compress(large_payload)
local decompressed = zip.decompress(compressed)

-- 3. Network Safe Transporters (Base64 & Hex)
local b64_string = base64.encode(compressed)
local raw_again = base64.decode(b64_string)

local hex_string = hex.encode(crypto.randomBytes(16))
local hex_raw = hex.decode(hex_string)