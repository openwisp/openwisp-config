require('os')
require('io')
local luaunit = require('luaunit')
local get_random_delay = assert(
  loadfile("../files/sbin/openwisp-get-random-delay.lua"))

local seed = os.time()
local delay = 20

TestRandomDelay = {}

function TestRandomDelay.test_default()
  -- testing casting error
  luaunit.assertErrorMsgMatches(".*Could not cast 'delay' to number.*",
    get_random_delay, "--test=1", seed, "delay")
  -- testing random value must be in range 0 to delay
  luaunit.assertTrue(get_random_delay('--test=1', seed, delay) <= delay)
  luaunit.assertTrue(get_random_delay('--test=1', seed, delay) > 0)
  -- testing delay changes on changing seed value
  local first_device_delay = get_random_delay('--test=1', seed, delay)
  local device_2_seed = 123456789
  local second_device_delay = get_random_delay('--test=1', device_2_seed, delay)
  luaunit.assertNotEquals(first_device_delay, second_device_delay)
end

os.exit(luaunit.LuaUnit.run())
