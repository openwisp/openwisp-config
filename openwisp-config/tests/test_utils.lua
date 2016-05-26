-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
require('os')
require('io')
require('uci')
require('openwisp.utils')
luaunit = require('luaunit')
uci_write_dir = './tmp'

TestUtils = {
    setUp = function()
        os.execute('mkdir '..uci_write_dir)
        os.execute('touch '..uci_write_dir..'/network')
    end,
    tearDown = function()
        os.execute('rm -rf '..uci_write_dir)
    end
}

function TestUtils.test_write_uci_block_named()
    u = uci.cursor('./tmp')
    write_uci_block(u, 'network', {
        [".name"] = "globals",
        [".type"] = "globals",
        [".anonymous"] = false,
        ula_prefix = "fd8e:f40a:fede::/48"
    })
    u:commit('network')
    local file = io.open(uci_write_dir .. '/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config globals 'globals'"))
    luaunit.assertNotNil(string.find(contents, "option ula_prefix 'fd8e:f40a:fede::/48'"))
end

function TestUtils.test_write_uci_block_anon()
    u = uci.cursor('./tmp')
    write_uci_block(u, 'network', {
        [".anonymous"] = true,
        [".name"] = "cfg0c1ec7",
        [".type"] = "switch_vlan",
        [".index"] = 8,
        ports = "0t 1",
        device = "switch0",
        vlan = "2"
    })
    u:commit('network')
    local file = io.open(uci_write_dir .. '/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config switch_vlan"))
    luaunit.assertNotNil(string.find(contents, "option device 'switch0'"))
    luaunit.assertNotNil(string.find(contents, "option vlan '2'"))
    luaunit.assertNotNil(string.find(contents, "option ports '0t 1'"))
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

os.exit(luaunit.LuaUnit.run())
