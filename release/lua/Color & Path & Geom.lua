-- ==============================================================================
-- TABLES: color, path, geom
-- ==============================================================================

-- color.parse(string_or_int)
-- C++: Parses hex lengths (6 or 8 chars) or casts int. Forces 0xFF alpha if missing.
-- Returns: (integer) 32-bit ARGB.

-- color.rgba(r, g, b, [a=255])
-- C++: Packs via bit shifting `(a << 24) | (r << 16) | (g << 8) | b`.
-- Returns: (integer) 32-bit ARGB.

-- color.extract(argb_int)
-- C++: Reverses packing via bitmasking.
-- Returns: (int, int, int, int) R, G, B, A.

-- path.basename(path_string) / path.extension(path_string)
-- C++: Looks for trailing `/`, `\`, or `.`
-- Returns: (string)

-- geom.pointInPoly(px_float, py_float, vertex_table)
-- C++: Ray-casting algorithm traversing a flat table `{x1, y1, x2, y2, ...}`.
-- Constraints: Table must have even length >= 6 (triangle minimum).
-- Returns: (boolean) true if the point lies within the defined polygon.


-- 1. Color Parsing & Packing
local argb_hex = color.parse("#FF0055")
local argb_int = color.rgba(255, 0, 85, 255)

-- Extract channels back out
local r, g, b, a = color.extract(argb_int)

-- 2. Path Routing
local full_path = "assets/models/character.obj"
local filename = path.basename(full_path)   -- "character.obj"
local extension = path.extension(full_path) -- "obj"

-- 3. Polygon Ray-Casting (Hit Detection)
local touch_x, touch_y = 150.0, 150.0

-- Define polygon bounds: {x1, y1, x2, y2, x3, y3, x4, y4}
local bounds = {100, 100,  200, 100,  200, 200,  100, 200}

if geom.pointInPoly(touch_x, touch_y, bounds) then
    print("Touch inside polygon boundary.")
end