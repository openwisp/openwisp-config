-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
require('os')
require('io')
luaunit = require('luaunit')
restore_unmanaged = assert(loadfile("../files/sbin/openwisp-restore-unmanaged.lua"))
write_dir = './unmanaged/'

TestRestoreUnmanaged = {
    setUp = function()
        os.execute('mkdir ' .. write_dir)
        os.execute('cp ./config/network ./restore/network-backup')
        os.execute('cp ./restore/network ' .. write_dir)
    end,
    tearDown = function()
        os.execute('mv ./restore/network-backup ./config/network')
        os.execute('rm -rf ' .. write_dir)
    end
}

function TestRestoreUnmanaged.test_empty()
    restore_unmanaged('--test=1')
    os.execute('rm -rf ' .. write_dir)
    local file = io.open(write_dir .. 'network')
    luaunit.assertNil(file)
end

function TestRestoreUnmanaged.test_default()
    restore_unmanaged('--test=1')
    local file = io.open(write_dir .. 'network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNotNil(string.find(contents, "option unmanaged_test '1'"))
    luaunit.assertNotNil(string.find(contents, "option ifname 'eth0'"))
    luaunit.assertNil(string.find(contents, "option test_restore '1'"))
end

function TestRestoreUnmanaged.test_duplicate()
    restore_unmanaged('--test=1')
    restore_unmanaged('--test=1')
    local file = io.open(write_dir .. 'network')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    local _, count = string.gsub(contents, "list ipaddr '10.0.0.1/24'", "")
    luaunit.assertEquals(count, 1)
end

os.exit(luaunit.LuaUnit.run())
