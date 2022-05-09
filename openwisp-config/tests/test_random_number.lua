require('os')
require('io')
local luaunit = require('luaunit')
local get_random_number = assert(
  loadfile("../files/sbin/openwisp-get-random-number.lua"))

TestRandomDelay = {}

function TestRandomDelay.test_default()
  -- testing casting error
  luaunit.assertErrorMsgMatches(".*Could not cast 'delay' to number.*",
    get_random_number, "--test=1", 0, "delay")
  -- testing random value must be in range min to max
  local min = 0
  local max = 20
  luaunit.assertTrue(get_random_number('--test=1', min, max) <= max)
  luaunit.assertTrue(get_random_number('--test=1', min, max) >= min)

  min = 40
  max = 50
  luaunit.assertTrue(get_random_number('--test=1', min, max) <= max)
  luaunit.assertTrue(get_random_number('--test=1', min, max) >= min)
end

os.exit(luaunit.LuaUnit.run())
