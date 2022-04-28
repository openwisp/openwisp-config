#!/usr/bin/env lua

-- returns a random number within the specified range
-- usage:
--   * openwisp-get-random-number <minimum_value> <maximum_value>
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

local function get_random(seed, minimum_value, maximum_value)
  math.randomseed(to_int(seed))
  return math.random(to_int(minimum_value), to_int(maximum_value))
end

local function get_seed()
  local command = 'head /dev/urandom | tr -dc "0123456789" | head -c9'
  local file_ = io.popen(command)
  local seed = file_:read("*a")
  file_:close()
  return seed
end

local seed = get_seed()
local minimum_value = test and arg[2] or arg[1]
local maximum_value = test and arg[3] or arg[2]

if minimum_value and maximum_value then
  local result = get_random(seed, minimum_value, maximum_value)
  if test then
    return result
  else
    print(result)
  end
else
  print('ERROR: not enough arguments supplied')
  os.exit(1)
end
