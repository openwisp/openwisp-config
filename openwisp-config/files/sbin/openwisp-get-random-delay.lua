#!/usr/bin/env lua

-- returns the random number using the specified seed
-- usage:
--   * openwisp-get-random-delay <seed>

function to_int(str)
    return math.floor(tonumber(str) or error("Could not cast '" .. tostring(str) .. "' to number.'"))
end

local os = require('os')
local math = require('math')
local seed = to_int(arg[1])
local delay = to_int(arg[2])
if seed then
    math.randomseed(seed)
    print(math.random(0, arg[2]))
else
    os.exit(1)
end
