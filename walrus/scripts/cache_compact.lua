-- walrus cache compaction script.
--
-- Atomically scans the active cache namespace for entries whose
-- TTL is less than `min_remaining_seconds` (ARGV[1]) and DELs them.
-- Designed to be EVALSHA-loaded once by Cache._ensure_scripts() and
-- triggered by Cache.compact(min_remaining_seconds=300).
--
-- KEYS[1]: cache namespace prefix
-- ARGV[1]: min remaining TTL in seconds (integer)
--
-- Returns: integer count of keys deleted.

local prefix = KEYS[1]
local min_ttl = tonumber(ARGV[1])
local deleted = 0
local cursor = "0"
repeat
    local res = redis.call("SCAN", cursor, "MATCH", prefix .. "*", "COUNT", 200)
    cursor = res[1]
    for _, k in ipairs(res[2]) do
        local ttl = redis.call("TTL", k)
        if ttl ~= -1 and ttl < min_ttl then
            redis.call("DEL", k)
            deleted = deleted + 1
        end
    end
until cursor == "0"
return deleted
