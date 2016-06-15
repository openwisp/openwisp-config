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

function TestUtils.test_remove_uci_options_twice()
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

function TestUtils.test_is_table_empty_true()
    luaunit.assertEquals(is_table_empty({}), true)
end

function TestUtils.test_is_table_empty_false()
    luaunit.assertEquals(is_table_empty({
        el = "value"
    }), false)
end

function TestUtils.test_merge_uci_option()
    u = uci.cursor(write_dir)
    -- prepare config
    write_uci_section(u, 'network', {
        [".name"] = "wlan1",
        [".type"] = "interface",
        [".anonymous"] = false,
        [".index"] = 5,
        ipaddr = "172.27.254.252/16",
        proto = "static",
        ifname = "wlan1"
    })
    u:commit('network')
    -- add one option
    write_uci_section(u, 'network', {
        [".name"] = "wlan1",
        [".type"] = "interface",
        [".anonymous"] = false,
        [".index"] = 5,
        added = "merged"
    })
    u:commit('network')
    local file = io.open(write_dir..'/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "config interface 'wlan1'"))
    luaunit.assertNotNil(string.find(contents, "option ifname 'wlan1'"))
    luaunit.assertNotNil(string.find(contents, "option proto 'static'"))
    luaunit.assertNotNil(string.find(contents, "option ipaddr '172.27.254.252/16'"))
    luaunit.assertNotNil(string.find(contents, "option added 'merged'"))
end

function TestUtils.test_merge_uci_list()
    u = uci.cursor(write_dir)
    -- prepare config
    write_uci_section(u, 'network', {
        [".name"] = "wlan1",
        [".type"] = "interface",
        [".anonymous"] = false,
        [".index"] = 5,
        ipaddr = {"172.27.254.252/16"},
        proto = "static",
        ifname = "wlan1"
    })
    u:commit('network')
    -- add one option
    write_uci_section(u, 'network', {
        [".name"] = "wlan1",
        [".type"] = "interface",
        [".anonymous"] = false,
        [".index"] = 5,
        ipaddr = {"172.27.254.253/16"},
    })
    u:commit('network')
    local file = io.open(write_dir..'/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "list ipaddr '172.27.254.252/16'"))
    luaunit.assertNotNil(string.find(contents, "list ipaddr '172.27.254.253/16'"))
end

function TestUtils.test_merge_uci_list_duplicate()
    u = uci.cursor(write_dir)
    -- prepare config
    write_uci_section(u, 'network', {
        [".name"] = "wlan1",
        [".type"] = "interface",
        [".anonymous"] = false,
        [".index"] = 5,
        ipaddr = {"172.27.254.252/16"},
        proto = "static",
        ifname = "wlan1"
    })
    u:commit('network')
    -- add one option
    write_uci_section(u, 'network', {
        [".name"] = "wlan1",
        [".type"] = "interface",
        [".anonymous"] = false,
        [".index"] = 5,
        ipaddr = {"172.27.254.252/16"},
    })
    u:commit('network')
    local file = io.open(write_dir..'/network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    local _, count = string.gsub(contents, "list ipaddr '172.27.254.252/16'", "")
    luaunit.assertEquals(count, 1)
end

function TestUtils.test_dirtree()
    os.execute('rm '..write_dir..'/*')
    os.execute('touch '..write_dir..'/f1')
    os.execute('touch '..write_dir..'/f2')
    os.execute('mkdir '..write_dir..'/inner')
    os.execute('touch '..write_dir..'/f3')
    count = 0
    for filename, attr in dirtree(write_dir) do
        count = count + 1
    end
    luaunit.assertEquals(count, 4)
end

function TestUtils.test_file_exists()
    luaunit.assertEquals(file_exists('./test_utils.lua'), true)
    luaunit.assertEquals(file_exists('./WRONG'), false)
end

function TestUtils.test_file_to_set()
    os.execute('echo "line1" > '..write_dir..'/read.list')
    os.execute('echo "line2" >> '..write_dir..'/read.list')
    os.execute('echo "line3" >> '..write_dir..'/read.list')
    set = file_to_set(write_dir..'/read.list')
    luaunit.assertEquals(set.line1, true)
    luaunit.assertEquals(set.line2, true)
    luaunit.assertEquals(set.line3, true)
    luaunit.assertEquals(set.line4, nil)
end

function TestUtils.test_set_to_file()
    write = {line1=true, line2=true}
    result = set_to_file(write, write_dir..'/write.list')
    luaunit.assertEquals(result, true)
    read = file_to_set(write_dir..'/write.list')
    luaunit.assertEquals(read.line1, true)
    luaunit.assertEquals(read.line2, true)
    luaunit.assertEquals(read.line3, nil)
end

function TestUtils.test_split()
    t = {'a', 'b', 'c'}
    luaunit.assertEquals(split('a b c'), t)
    luaunit.assertEquals(split('a,b,c', ','), t)
    luaunit.assertEquals(split('a/b/c', '/'), t)
end

function TestUtils.test_basename()
    luaunit.assertEquals(basename('/etc/config/network'), 'network')
    luaunit.assertEquals(basename('./profile'), 'profile')
end

function TestUtils.test_dirname()
    luaunit.assertEquals(dirname('/etc/config/network'), '/etc/config/')
end

os.exit(luaunit.LuaUnit.run())
