-- ==============================================================================
-- TABLE: file
-- ==============================================================================

-- file.readFile(absolute_path_string)
-- C++: `std::ifstream(ios::binary)`. Reads directly into a stringstream.
-- Returns: (string | nil) Raw binary content, or nil if missing/permission denied.

-- file.writeFile(absolute_path_string, raw_data_string)
-- C++: `std::ofstream(ios::binary)`. Overwrites target.
-- Returns: (boolean) true on successful write.

-- file.listDir(absolute_dir_path)
-- C++: `opendir` / `readdir`. Filters out `.` and `..`.
-- Returns: (table | nil) Array of filenames, or nil on failure.

-- file.stat(absolute_path_string)
-- C++: `stat()`. Fetches filesystem metadata without opening the file.
-- Returns: (table | nil) {size = int, mtime = int, isDirectory = bool}.

-- file.remove(absolute_path_string)
-- C++: `remove()`. Deletes file or empty directory.
-- Returns: (boolean) true on success.

-- file.mkdir(absolute_dir_path)
-- C++: `mkdir(path, 0777)`.
-- Returns: (boolean) true on success. Note: Does not create recursive directories.


local cache_dir = "/data/user/0/com.hydra.app/cache/assets/"

-- 1. Directory Management
file.mkdir(cache_dir)
local files_in_dir = file.listDir(cache_dir)

-- 2. Binary File Write
local target_file = cache_dir .. "payload.bin"
if file.writeFile(target_file, "RAW_BINARY_DATA") then

    -- 3. File Metadata
    local stat = file.stat(target_file)
    if stat then
        print(string.format("File Size: %d bytes, Modified: %d", stat.size, stat.mtime))
    end

    -- 4. Binary File Read
    local loaded_data = file.readFile(target_file)

    -- 5. File Deletion
    file.remove(target_file)
end