-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
require('os')
require('io')
local luaunit = require('luaunit')
local update_config = assert(loadfile("../files/sbin/openwisp-update-config.lua"))
local write_dir = './update-test/'
local config_dir = write_dir .. 'etc/config/'
local openwisp_dir = './openwisp/'
local remote_config_dir = openwisp_dir .. 'remote/etc/config'

TestUpdateConfig = {
    setUp = function()
        os.execute('mkdir -p ' .. config_dir)
        os.execute('mkdir -p ' .. remote_config_dir)
        -- prepare config tar gz
        os.execute('cp good-config.tar.gz configuration.tar.gz')
        -- this file is pre-existing on the device
        os.execute('cp ./update/system '..config_dir..'system')
        -- we expect these UCI files to be removed
        os.execute('cp ./wifi/wireless '..remote_config_dir..'/wireless')
        os.execute('cp ./wifi/wireless '..config_dir..'/wireless')
        -- we expect this file to be stored
        os.execute('echo original > '..write_dir..'/etc/existing')
        -- we expect this regular file to be removed
        os.execute('echo remove-me > '..write_dir..'/etc/remove-me')
        os.execute('echo /etc/remove-me > '..openwisp_dir..'/added.list')
        -- we expect this file to be restored
        os.execute('mkdir -p ' .. openwisp_dir .. 'stored/etc/')
        os.execute('echo restore-me > '..openwisp_dir..'/stored/etc/restore-me')
        os.execute('echo /etc/restore-me > '..openwisp_dir..'/modified.list')
    end,
    tearDown = function()
        os.execute('rm -rf ' .. write_dir)
        os.execute('rm -rf ' .. openwisp_dir)
        os.execute('rm configuration.tar.gz')
    end
}

function TestUpdateConfig.test_update()
    update_config('--test=1')
    -- check network
    local networkFile = io.open(config_dir .. 'network')
    luaunit.assertNotNil(networkFile)
    local networkContents = networkFile:read('*all')
    luaunit.assertNotNil(string.find(networkContents, "config interface 'added'"))
    luaunit.assertNotNil(string.find(networkContents, "option ifname 'added0'"))
    -- check system
    local systemFile = io.open(config_dir .. 'system')
    luaunit.assertNotNil(systemFile)
    local systemContents = systemFile:read('*all')
    luaunit.assertNotNil(string.find(systemContents, "config system 'system'"))
    luaunit.assertNotNil(string.find(systemContents, "option custom 'custom'"))
    luaunit.assertNotNil(string.find(systemContents, "option hostname 'update_config'"))
    luaunit.assertNotNil(string.find(systemContents, "config new 'new'"))
    luaunit.assertNotNil(string.find(systemContents, "option test 'test'"))
    -- ensure rest of config options are present
    luaunit.assertNotNil(string.find(systemContents, "config timeserver 'ntp'"))
    luaunit.assertNotNil(string.find(systemContents, "list server '3.openwrt.pool.ntp.org'"))
    -- ensure test file is present
    local testFile = io.open('./update-test/etc/test')
    luaunit.assertNotNil(testFile)
    local testContents = testFile:read('*all')
    luaunit.assertEquals(testContents, 'test\n')
    -- ensure added.list is what we expect
    local addedListFile = io.open(openwisp_dir .. '/added.list')
    luaunit.assertNotNil(addedListFile)
    -- ensure test file is present
    local addedListContents = addedListFile:read('*all')
    luaunit.assertEquals(addedListContents, '/etc/test\n')
    -- ensure files are removed
    luaunit.assertNil(io.open(config_dir..'/wireless'))
    luaunit.assertNil(io.open(remote_config_dir..'/wireless'))
    -- ensure existing original file has been stored
    local modifiedListFile = io.open(openwisp_dir .. '/modified.list')
    luaunit.assertNotNil(modifiedListFile)
    luaunit.assertEquals(modifiedListFile:read('*all'), '/etc/existing\n')
    local storedExisitngFile = io.open(openwisp_dir .. '/stored/etc/existing')
    luaunit.assertNotNil(storedExisitngFile)
    luaunit.assertEquals(storedExisitngFile:read('*all'), 'original\n')
    -- ensure it has been modified
    local existingFile = io.open(write_dir .. '/etc/existing')
    luaunit.assertNotNil(existingFile)
    luaunit.assertEquals(existingFile:read('*all'), 'modified\n')
    -- ensure file is removed
    luaunit.assertNil(io.open(write_dir .. '/etc/remove-me'))
    -- ensure file is restored
    local restoreFile = io.open(write_dir..'/etc/restore-me')
    luaunit.assertNotNil(restoreFile)
    luaunit.assertEquals(restoreFile:read('*all'), 'restore-me\n')
    luaunit.assertNil(io.open(openwisp_dir..'/stored/etc/restore-me'))
end

function TestUpdateConfig.test_update_conf_arg()
    update_config('--test=1', '--conf=./test-conf-arg.tar.gz')
    -- check network
    local networkFile = io.open(config_dir .. 'network')
    luaunit.assertNotNil(networkFile)
    local networkContents = networkFile:read('*all')
    luaunit.assertNotNil(string.find(networkContents, "config interface 'added'"))
    luaunit.assertNotNil(string.find(networkContents, "option ifname 'added1'"))
    -- check system
    local systemFile = io.open(config_dir .. 'system')
    luaunit.assertNotNil(systemFile)
    local systemContents = systemFile:read('*all')
    luaunit.assertNotNil(string.find(systemContents, "config system 'system'"))
    luaunit.assertNil(string.find(systemContents, "option custom 'custom'"))
    luaunit.assertNotNil(string.find(systemContents, "option hostname 'confarg'"))
    luaunit.assertNotNil(string.find(systemContents, "config new 'new'"))
    luaunit.assertNotNil(string.find(systemContents, "option test 'test'"))
end

os.exit(luaunit.LuaUnit.run())
