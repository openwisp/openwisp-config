-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
require('os')
require('io')
luaunit = require('luaunit')
store_unmanaged = assert(loadfile("../files/sbin/openwisp-store-unmanaged.lua"))
default_blocks = "system.ntp " ..
                 "system.@led " ..
                 "network.loopback " ..
                 "network.globals " ..
                 "network.lan " ..
                 "network.wan " ..
                 "network.@switch " ..
                 "network.@switch_vlan"
write_dir = './unmanaged/'
assertNotNil = luaunit.assertNotNil
assertNil = luaunit.assertNil
assertEquals = luaunit.assertEquals

local function _clean()
    os.remove(write_dir .. 'network')
    os.remove(write_dir .. 'system')
    os.remove(write_dir)
end

TestStoreUnmanaged = {
    setUp = _clean,
    tearDown = _clean
}

function TestStoreUnmanaged.test_empty()
    store_unmanaged('--test=1')
    assertNil(io.open(write_dir .. 'network'))
    assertNil(io.open(write_dir .. 'system'))
end

function TestStoreUnmanaged.test_default()
    store_unmanaged('--test=1', '-o=' .. default_blocks)
    -- ensure network config file has been created correctly
    local file = io.open(write_dir .. 'network')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNotNil(string.find(contents, "config interface 'loopback'"))
    assertNotNil(string.find(contents, "option ipaddr '127.0.0.1'"))
    assertNotNil(string.find(contents, "option ula_prefix 'fd8e:f40a:6701::/48'"))
    assertNotNil(string.find(contents, "config interface 'wan'"))
    assertNotNil(string.find(contents, "config switch"))
    assertNotNil(string.find(contents, "option vlan '2'"))
    assertNotNil(string.find(contents, "option vlan '1'"))
    assertNil(string.find(contents, "config interface 'wlan0'"))
    assertNil(string.find(contents, "config interface 'wlan1'"))
    -- ensure system config file exists
    local file = io.open(write_dir .. 'system')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNotNil(string.find(contents, "list server '1.openwrt.pool.ntp.org'"))
    assertNotNil(string.find(contents, "config led 'led_usb1'"))
    assertNotNil(string.find(contents, "config led 'led_usb2'"))
    assertNotNil(string.find(contents, "config led 'led_wlan2g'"))
    assertNil(string.find(contents, "option hostname 'OpenWrt'"))
end

function TestStoreUnmanaged.test_specific_name()
    store_unmanaged('--test=1', '-o="system.ntp"')
    local file = io.open(write_dir .. 'system')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNotNil(file)
    assertNil(string.find(contents, "config led 'led_usb1'"))
    assertNil(string.find(contents, "option hostname 'OpenWrt'"))
    assertNotNil(string.find(contents, "list server '1.openwrt.pool.ntp.org'"))
end

function TestStoreUnmanaged.test_specific_type()
    store_unmanaged('--test=1', '-o="system.@led"')
    local file = io.open(write_dir .. 'system')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNotNil(file)
    assertNotNil(string.find(contents, "config led 'led_usb1'"))
    assertNotNil(string.find(contents, "config led 'led_usb2'"))
    assertNotNil(string.find(contents, "config led 'led_wlan2g'"))
    assertNil(string.find(contents, "option hostname 'OpenWrt'"))
    assertNil(string.find(contents, "list server '1.openwrt.pool.ntp.org'"))
end

function TestStoreUnmanaged.test_unrecognized_config_option()
    store_unmanaged('--test=1', '-o="network.vpn"')
    local file = io.open(write_dir .. 'network')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNil(string.find(contents, "vpn"))
end

function TestStoreUnmanaged.test_unrecognized_config_type()
    store_unmanaged('--test=1', '-o="network.@vpn"')
    local file = io.open(write_dir .. 'network')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNil(string.find(contents, "vpn"))
end

function TestStoreUnmanaged.test_unrecognized_config()
    store_unmanaged('--test=1', '-o="totally.@wrong"')
    assertNil(io.open(write_dir .. 'totally'))
end

function TestStoreUnmanaged.test_duplicate_list()
    store_unmanaged('--test=1', '-o=network.wlan0')
    local file = io.open(write_dir .. 'network')
    assertNotNil(file)
    local contents = file:read('*all')
    assertNotNil(string.find(contents, "list ipaddr '172.27.254.251/16'"))
    -- count occurrences of list setting and ensure is not repeated
    local _, count = string.gsub(contents, "list ipaddr '172.27.254.251/16'", "")
    assertEquals(count, 1)
end

os.exit(luaunit.LuaUnit.run())
