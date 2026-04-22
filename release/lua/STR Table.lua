-- ==============================================================================
-- TABLE: str
-- ==============================================================================

-- str.split(target_string, delimiter_string)
-- C++: `std::string::find`.
-- Returns: (table) Array of string segments. If delimiter is empty, splits by char.

-- str.trim(target_string)
-- C++: Iterates with `std::isspace` to erase ends.
-- Returns: (string) Cleaned string.

-- str.startsWith(target_string, prefix_string) / str.endsWith(target_string, suffix_string)
-- C++: Direct pointer offset `strncmp`. Extremely fast.
-- Returns: (boolean)

-- str.replace(target_string, from_string, to_string)
-- C++: `std::string::replace`. Replaces all occurrences.
-- Returns: (string) Modified string.

-- str.xorMask(target_string, key_string)
-- C++: Bitwise XOR iteration `data[i] ^ key[i % key_len]`. Symmetric mutation.
-- Returns: (string) Mutated binary string.

-- str.urlEncode(target_string) / str.urlDecode(target_string)
-- C++: RFC 3986 hex escaping (`%20`).
-- Returns: (string)

-- str.distance(string_a, string_b)
-- C++: Levenshtein dynamic programming matrix algorithm.
-- Returns: (integer) Minimum number of single-character edits to match strings.


local dirty_input = "   hydra,engine,core   "

-- 1. Trimming & Splitting
local clean = str.trim(dirty_input)
local parts = str.split(clean, ",") -- {"hydra", "engine", "core"}

-- 2. Fast Prefix/Suffix checks (No regex overhead)
if str.startsWith(parts[1], "hyd") and str.endsWith(parts[3], "ore") then
    print("Match found.")
end

-- 3. Global Replacement
local url = str.replace("http://localhost", "http", "https")

-- 4. Fast XOR Obfuscation (Symmetrical)
local cheap_mask = str.xorMask("SELECT * FROM users", "0xDEAD")
local unmasked = str.xorMask(cheap_mask, "0xDEAD")

-- 5. URL Encoding
local safe_url = str.urlEncode("user=Tenar&id=123")
local decoded = str.urlDecode(safe_url)

-- 6. Levenshtein Distance (Typo detection)
local edits_needed = str.distance("kitten", "sitting") -- 3