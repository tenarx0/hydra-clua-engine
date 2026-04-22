-- ==============================================================================
-- TABLE: json
-- C++ Backend: nlohmann/json with RFC 6901 JSON Pointer support.
-- ==============================================================================

-- json.encode(lua_table)
-- C++: Recursively builds a `json` object/array and calls `.dump()`.
-- Returns: (string) Minified JSON string. Throws Lua error on cyclic tables.

-- json.decode(json_string)
-- C++: `.parse()`. Converts to a Lua table structure.
-- Returns: (table) Parsed structure. Throws Lua error with exact byte index on failure.

-- json.get(json_string, rfc6901_path_string)
-- C++: Parses string, accesses DOM via `json::json_pointer(path)`, converts target to Lua.
-- Analysis: Extremely fast for extracting one deep value without parsing everything to Lua.
-- Returns: (any | nil) The specific string/number/boolean/table, or nil if path invalid.

-- json.put(json_string, rfc6901_path_string, lua_value)
-- C++: Parses string, mutates DOM at pointer, calls `.dump()`.
-- Returns: (string) The new minified JSON string.

-- json.isValid(json_string)
-- C++: `json::accept()`. SAX parser that validates structure without DOM memory allocation.
-- Returns: (boolean) true if string is valid JSON.

-- json.format(json_string, [indent_int])
-- C++: Parses and dumps with indentation (default 4).
-- Returns: (string) Pretty-printed JSON string.


local raw_network_data = '{"user": {"id": 1042, "role": "admin"}, "inventory": ["sword", "shield"]}'

-- 1. Fast Validation (No DOM allocation)
if not json.isValid(raw_network_data) then
    print("Dropped malformed network packet.")
    return
end

-- 2. Direct Pointer Extraction (Bypasses Lua table creation)
local role = json.get(raw_network_data, "/user/role")
if role == "admin" then
    -- 3. Direct Pointer Mutation (Returns updated minified JSON string)
    raw_network_data = json.put(raw_network_data, "/user/id", 9999)
end

-- 4. Standard Lua Table Conversion
local parsed_table = json.decode(raw_network_data)
local stringified = json.encode(parsed_table)

-- 5. Pretty Printing
print(json.format(stringified, 4)) -- Indent with 4 spaces