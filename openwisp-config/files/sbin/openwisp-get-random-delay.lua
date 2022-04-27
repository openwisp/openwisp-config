#!/usr/bin/env lua

-- returns the random number using the specified seed
-- usage:
--   * openwisp-get-random-delay <seed> <delay>
local os = require('os')
local math = require('math')
local test
local arg = {...}
for _, value in pairs(arg) do
  -- test argument
  if value == '--test=1' then test = true; end
end

local function to_int(str)
  return math.floor(tonumber(str) or
                      error("Could not cast '" .. tostring(str) .. "' to number.'"))
end

local function get_random(seed, range_start, range_end)
  math.randomseed(to_int(seed))
  return math.random(to_int(range_start), to_int(range_end))
end

local seed = test and arg[2] or arg[1]
local delay = test and arg[3] or arg[2]

if seed and delay then
  if test then
    return (get_random(seed, 0, delay))
  else
    print(get_random(seed, 0, delay))
  end
else
  os.exit(1)
end
