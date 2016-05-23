require('os')
require('io')
-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
local luaunit = require('luaunit')
local name_anonymous_uci = assert(loadfile("../files/name_anonymous_uci.lua"))
local string = string
local prefix = './anonymous/'
assertNotNil = luaunit.assertNotNil
assertNil = luaunit.assertNil
assertEquals = luaunit.assertEquals

local function _setup()
    os.execute('mkdir -p ' .. prefix)
    os.execute('cp ./config/system '..prefix..'system')
    os.execute('cp ./config/network '..prefix..'network')
end

local function _clean()
    os.remove(prefix .. 'network')
    os.remove(prefix .. 'system')
    os.remove(prefix)
end

TestStoreUnmanaged = {}

TestStoreUnmanaged.setUp = _setup
TestStoreUnmanaged.tearDown = _clean

function TestStoreUnmanaged.test_default_behaviour()
    name_anonymous_uci('--test=1')
    -- check network
    local file = io.open(prefix .. 'network')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNotNil(string.find(contents, "config switch 'cfg"))
    assertNotNil(string.find(contents, "config switch_vlan 'cfg"))
    -- ensure rest of config options are present
    assertNotNil(string.find(contents, "config interface 'loopback'"))
    assertNotNil(string.find(contents, "config interface 'lan'"))
    -- check system
    local file = io.open(prefix .. 'system')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNotNil(string.find(contents, "config system 'system'"))
    -- ensure rest of config options are present
    assertNotNil(string.find(contents, "config timeserver 'ntp'"))
    assertNotNil(string.find(contents, "config led 'led_usb1'"))
end

os.exit(luaunit.LuaUnit.run())
