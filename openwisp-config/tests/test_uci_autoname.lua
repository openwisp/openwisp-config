-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
require('os')
require('io')
luaunit = require('luaunit')
name_anonymous_uci = assert(loadfile("../files/sbin/openwisp-uci-autoname.lua"))
write_dir = './anonymous/'

TestUciAutoname = {
    setUp = function()
        os.execute('mkdir -p ' .. write_dir)
        os.execute('cp ./config/system '..write_dir..'system')
        os.execute('cp ./config/network '..write_dir..'network')
    end,
    tearDown = function()
        os.remove(write_dir .. 'network')
        os.remove(write_dir .. 'system')
        os.remove(write_dir)
    end
}

function TestUciAutoname.test_default_behaviour()
    name_anonymous_uci('--test=1')
    -- check network
    local file = io.open(write_dir .. 'network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config switch 'cfg"))
    luaunit.assertNotNil(string.find(contents, "config switch_vlan 'cfg"))
    -- ensure rest of config options are present
    luaunit.assertNotNil(string.find(contents, "config interface 'loopback'"))
    luaunit.assertNotNil(string.find(contents, "config interface 'lan'"))
    -- check system
    local file = io.open(write_dir .. 'system')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config system 'system'"))
    -- ensure rest of config options are present
    luaunit.assertNotNil(string.find(contents, "config timeserver 'ntp'"))
    luaunit.assertNotNil(string.find(contents, "config led 'led_usb1'"))
end

os.exit(luaunit.LuaUnit.run())
