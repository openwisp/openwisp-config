-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
require('os')
require('io')
require('uci')
require('openwisp.utils')
luaunit = require('luaunit')
write_dir = './utils'

TestUtils = {
    setUp = function()
        os.execute('mkdir '..write_dir)
        os.execute('touch '..write_dir..'/network')
    end,
    tearDown = function()
        os.execute('rm -rf '..write_dir)
    end
}

function TestUtils.test_starts_with_dot()
    luaunit.assertEquals(starts_with_dot('.name'), true)
    luaunit.assertEquals(starts_with_dot('.type'), true)
    luaunit.assertEquals(starts_with_dot('ifname'), false)
end

function TestUtils.test_write_uci_section_named()
    u = uci.cursor(write_dir)
    write_uci_section(u, 'network', {
        [".name"] = "globals",
        [".type"] = "globals",
        [".anonymous"] = false,
        ula_prefix = "fd8e:f40a:fede::/48"
    })
    u:commit('network')
    local file = io.open(write_dir .. '/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config globals 'globals'"))
    luaunit.assertNotNil(string.find(contents, "option ula_prefix 'fd8e:f40a:fede::/48'"))
end

function TestUtils.test_write_uci_section_anon()
    u = uci.cursor(write_dir)
    write_uci_section(u, 'network', {
        [".anonymous"] = true,
        [".name"] = "cfg0c1ec7",
        [".type"] = "switch_vlan",
        [".index"] = 8,
        ports = "0t 1",
        device = "switch0",
        vlan = "2"
    })
    u:commit('network')
    local file = io.open(write_dir .. '/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config switch_vlan"))
    luaunit.assertNotNil(string.find(contents, "option device 'switch0'"))
    luaunit.assertNotNil(string.find(contents, "option vlan '2'"))
    luaunit.assertNotNil(string.find(contents, "option ports '0t 1'"))
end

function TestUtils.test_write_uci_section_duplicate_list()
    u = uci.cursor(write_dir)
    write_uci_section(u, 'network', {
        [".name"] = "lan",
        [".type"] = "interface",
        [".anonymous"] = false,
        ifname = "eth0",
        proto = "static",
        ipaddr = {"10.0.0.1/24", "10.0.0.1/24"}
    })
    u:commit('network')
    local file = io.open(write_dir .. '/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "list ipaddr '10.0.0.1/24'"))
    -- count occurrences of list setting and ensure is not repeated
    local _, count = string.gsub(contents, "list ipaddr '10.0.0.1/24", "")
    luaunit.assertEquals(count, 1)
end

function TestUtils.test_is_uci_empty_false()
    luaunit.assertEquals(is_uci_empty({
        [".name"] = "lan",
        [".type"] = "interface",
        [".anonymous"] = false,
        proto = "dhcp",
        ip6assign = "60",
        type = "bridge",
        force_link = "0",
        ifname = "eth0.1"
    }), false)
    luaunit.assertEquals(is_uci_empty({
        [".name"] = "globals",
        [".type"] = "globals",
        [".anonymous"] = false,
        ula_prefix = "fd8e:f40a:6701::/48"
    }), false)
end

function TestUtils.test_is_uci_empty_true()
    luaunit.assertEquals(is_uci_empty({
        [".name"] = "lan",
        [".type"] = "interface",
        [".anonymous"] = false,
        [".index"] = 2
    }), true)
end

function TestUtils.test_remove_uci_options()
    os.execute('cp ./config/network '..write_dir..'/network')
    u = uci.cursor(write_dir)
    remove_uci_options(u, 'network', {
        [".name"] = "wlan1",
        [".type"] = "interface",
        [".anonymous"] = false,
        [".index"] = 5,
        ipaddr = "172.27.254.252/16",
        proto = "static",
        ifname = "wlan1"
    })
    u:commit('network')
    local file = io.open(write_dir .. '/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNil(string.find(contents, "config interface 'wlan1'"))
    luaunit.assertNil(string.find(contents, "option ifname 'wlan1'"))
    luaunit.assertNil(string.find(contents, "option ipaddr '172.27.254.252/16'"))
end

os.exit(luaunit.LuaUnit.run())
