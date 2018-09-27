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
        os.execute('cp ./config/wireless-autoname '..write_dir..'wireless')
        os.execute('cp ./config/firewall '..write_dir..'firewall')
    end,
    tearDown = function()
        os.remove(write_dir .. 'system')
        os.remove(write_dir .. 'network')
        os.remove(write_dir .. 'wireless')
        os.remove(write_dir .. 'firewall')
        os.remove(write_dir)
    end
}

function TestUciAutoname.test_default_behaviour()
    name_anonymous_uci('--test=1')
    -- check network
    local file = io.open(write_dir .. 'network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config switch 'switch"))
    luaunit.assertNotNil(string.find(contents, "config switch_vlan 'switch0_vlan1"))
    luaunit.assertNotNil(string.find(contents, "config switch_port 'switch0_port1"))
    luaunit.assertNotNil(string.find(contents, "config globals 'globals"))
    luaunit.assertNotNil(string.find(contents, "config route 'route1"))
    luaunit.assertNotNil(string.find(contents, "config route 'route2"))
    -- ensure rest of config options are present
    luaunit.assertNotNil(string.find(contents, "config interface 'loopback'"))
    luaunit.assertNotNil(string.find(contents, "config interface 'lan'"))
    -- check wireless
    local file = io.open(write_dir .. 'wireless')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config wifi-iface 'wifi_wlan0", nil, true))
    luaunit.assertNotNil(string.find(contents, "config wifi-iface 'wifi_wlan1", nil, true))
    -- check system
    local file = io.open(write_dir .. 'system')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config system 'system'"))
    luaunit.assertNotNil(string.find(contents, "config led 'led_test1'"))
    -- ensure rest of config options are present
    luaunit.assertNotNil(string.find(contents, "config timeserver 'ntp'"))
    luaunit.assertNotNil(string.find(contents, "config led 'led_usb1'"))
    -- check firewall
    local file = io.open(write_dir .. 'firewall')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config defaults 'defaults'"))
end

os.exit(luaunit.LuaUnit.run())
