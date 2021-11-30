-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
require('os')
require('io')
local luaunit = require('luaunit')
local name_anonymous_uci = assert(loadfile("../files/sbin/openwisp-uci-autoname.lua"))
local write_dir = './anonymous/'

TestUciAutoname = {
  setUp = function()
    os.execute('mkdir -p ' .. write_dir)
    os.execute('cp ./config/system ' .. write_dir .. 'system')
    os.execute('cp ./config/network ' .. write_dir .. 'network')
    os.execute('cp ./config/wireless-autoname ' .. write_dir .. 'wireless')
    os.execute('cp ./config/firewall ' .. write_dir .. 'firewall')
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
  local networkFile = io.open(write_dir .. 'network')
  luaunit.assertNotNil(networkFile)
  local networkContents = networkFile:read('*all')
  luaunit.assertNotNil(string.find(networkContents, "config switch 'switch"))
  luaunit.assertNotNil(string.find(networkContents,
    "config switch_vlan 'switch0_vlan1"))
  luaunit.assertNotNil(string.find(networkContents,
    "config switch_port 'switch0_port1"))
  luaunit.assertNotNil(string.find(networkContents, "config globals 'globals"))
  luaunit.assertNotNil(string.find(networkContents, "config route 'route1"))
  luaunit.assertNotNil(string.find(networkContents, "config route 'route2"))
  -- ensure rest of config options are present
  luaunit.assertNotNil(string.find(networkContents, "config interface 'loopback'"))
  luaunit.assertNotNil(string.find(networkContents, "config interface 'lan'"))
  -- check wireless
  local wirelessFile = io.open(write_dir .. 'wireless')
  luaunit.assertNotNil(wirelessFile)
  local wirelessContents = wirelessFile:read('*all')
  luaunit.assertNotNil(string.find(wirelessContents, "config wifi-iface 'wifi_wlan0",
    nil, true))
  luaunit.assertNotNil(string.find(wirelessContents, "config wifi-iface 'wifi_wlan1",
    nil, true))
  -- check system
  local systemFile = io.open(write_dir .. 'system')
  luaunit.assertNotNil(systemFile)
  local systemContents = systemFile:read('*all')
  luaunit.assertNotNil(string.find(systemContents, "config system 'system'"))
  luaunit.assertNotNil(string.find(systemContents, "config led 'led_test1'"))
  -- ensure rest of config options are present
  luaunit.assertNotNil(string.find(systemContents, "config timeserver 'ntp'"))
  luaunit.assertNotNil(string.find(systemContents, "config led 'led_usb1'"))
  -- check firewall
  local firewallFile = io.open(write_dir .. 'firewall')
  luaunit.assertNotNil(firewallFile)
  local firewallContents = firewallFile:read('*all')
  luaunit.assertNotNil(string.find(firewallContents, "config defaults 'defaults'"))
end

os.exit(luaunit.LuaUnit.run())
