#!/usr/bin/env lua

-- returns the random number using the specified seed
-- usage:
--   * openwisp-get-random-num <seed>

local os = require('os')
local math = require('math')
local seed = arg[1]
if seed then
    math.randomseed(seed)
    print(math.floor(math.random()*10^9))
else
    os.exit(1)
end
