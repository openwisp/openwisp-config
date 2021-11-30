-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'
require('os')
require('io')
local luaunit = require('luaunit')
local update_config = assert(loadfile("../files/sbin/openwisp-update-config.lua"))
local write_dir = './update-test/'
local config_dir = write_dir .. 'etc/config/'
local openwisp_dir = './openwisp/'
local stored_dir = openwisp_dir .. '/stored/'
local remote_config_dir = openwisp_dir .. 'remote/etc/config'

local function string_count(base, pattern)
  return select(2, string.gsub(base, pattern, ""))
end

TestUpdateConfig = {
    setUp = function()
        os.execute('mkdir -p ' .. config_dir)
        os.execute('mkdir -p ' .. remote_config_dir)
        -- prepare config tar gz
        os.execute('cp good-config.tar.gz configuration.tar.gz')
        -- this file is pre-existing on the device
        os.execute('cp ./update/system '..config_dir..'system')
        os.execute('cp ./update/network '..config_dir..'network')
        os.execute('cp ./update/wireless '..config_dir..'wireless')
        -- we expect these UCI files to be removed
        os.execute('cp ./config/wireless-autoname '..remote_config_dir..'/wireless-autoname')
        os.execute('cp ./wifi/wireless '..remote_config_dir..'/wireless')
        -- this file will be overwrited by stored configuration and new configuration
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
        -- this file is stored in the backup
        os.execute('mkdir -p ' .. stored_dir ..'etc/config/')
        os.execute("cp ./update/stored_wireless " ..stored_dir.. '/etc/config/wireless')
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
    -- ensure interface added is present
    luaunit.assertNotNil(string.find(networkContents, "config interface 'added'"))
    luaunit.assertNotNil(string.find(networkContents, "option ifname 'added0'"))
    -- ensure wg1 added via remote previously is present
    luaunit.assertNotNil(string.find(networkContents, "config interface 'wg1'"))
    luaunit.assertNotNil(string.find(networkContents, "option proto 'static'"))
    -- ensure network file is stored for backup
    local storedNetworkFile = io.open(stored_dir .. '/etc/config/network')
    luaunit.assertNotNil(storedNetworkFile)
    local storedNetworkContents = storedNetworkFile:read('*all')
    -- ensure wg1 is not added that is downloaded from remote
    luaunit.assertNil(string.find(storedNetworkContents, "config interface 'wg1'"))
    -- ensure wan and wg0 are present
    luaunit.assertNotNil(string.find(storedNetworkContents, "config interface 'wan'"))
    luaunit.assertNotNil(string.find(storedNetworkContents, "config interface 'wg0'"))
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
    -- ensure system file is stored for backup
    local storedSystemFile = io.open(stored_dir .. '/etc/config/network')
    luaunit.assertNotNil(storedSystemFile)
    local storedSystemContents = storedSystemFile:read('*all')
    -- ensure hostname is not added that is updated from remote
    luaunit.assertNil(string.find(storedSystemContents, "option hostname"))
    -- ensure custom is not added that is downloaded from remote
    luaunit.assertNil(string.find(storedSystemContents, "option custom 'custom'"))
    -- ensure new is not added that is downloaded from remote
    luaunit.assertNil(string.find(storedSystemContents, "config new 'new'"))
    -- ensure test file is present
    local testFile = io.open(write_dir .. 'etc/test')
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
    luaunit.assertNil(io.open(config_dir..'/wireless-autoname'))
    luaunit.assertNil(io.open(remote_config_dir..'/wireless-autoname'))
    -- ensure file is not removed
    luaunit.assertNotNil(io.open(remote_config_dir..'/wireless'))
    -- ensure configuration is restored
    local wirelessFile = io.open(config_dir..'/wireless')
    luaunit.assertNotNil(wirelessFile)
    local wirelessContents = wirelessFile:read('*all')
    -- ensure device radio0 is stored from backup
    luaunit.assertNotNil(string.find(wirelessContents, "config wifi-device 'radio0'", 1, true))
    luaunit.assertNotNil(string.find(wirelessContents, "option path 'platform/ar934x_wmac'"))
    luaunit.assertNotNil(string.find(wirelessContents, "option channel '9'"))
    -- ensure device radio1 is removed as it is neither in backup nor in new configuration
    luaunit.assertNil(string.find(wirelessContents, "config wifi-device 'radio1'"))
    -- ensure device radio3 options are updated
    luaunit.assertNotNil(string.find(wirelessContents, "config wifi-device 'radio3'", 1, true))
    -- ensure channel is stored from backup
    luaunit.assertNotNil(string.find(wirelessContents, "option channel '14'"))
    -- ensure country value is used from new configuration
    luaunit.assertNotNil(string.find(wirelessContents, "option country 'IT'"))
    -- ensure hwmode is not stored as not available in remote config
    luaunit.assertNil(string.find(wirelessContents, "option hwmode '11h'"))
    -- ensure path has been removed
    luaunit.assertNil(string.find(wirelessContents, "option path 'pci0000:00/0000:00:1c.2/0000:05:00.0'"))
    -- ensure existing original file has been stored
    local modifiedListFile = io.open(openwisp_dir .. '/modified.list')
    luaunit.assertNotNil(modifiedListFile)
    luaunit.assertEquals(modifiedListFile:read('*all'), '/etc/existing\n')
    local storedExisitngFile = io.open(stored_dir .. '/etc/existing')
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
    luaunit.assertNil(io.open(stored_dir .. '/etc/restore-me'))
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

function TestUpdateConfig.test_duplicate_list_options()
    update_config('--test=1', '--conf=./test-duplicate-list.tar.gz')
    -- check network
    local networkFile = io.open(config_dir .. 'network')
    luaunit.assertNotNil(networkFile)
    local networkContents = networkFile:read('*all')
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.1/24'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.2/24'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.3/24'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.2'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.3'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.4'"), 2)
    luaunit.assertNotNil(string.find(networkContents, "option test_restore '2'"))
    -- repeating the operation has the same result
    update_config('--test=1', '--conf=./test-duplicate-list.tar.gz')
    networkFile = io.open(config_dir .. 'network')
    luaunit.assertNotNil(networkFile)
    networkContents = networkFile:read('*all')
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.1/24'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.2/24'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.3/24'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.2'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.3'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.4'"), 2)
    luaunit.assertNotNil(string.find(networkContents, "option test_restore '2'"))
end

function TestUpdateConfig.test_removal_list_options()
    update_config('--test=1', '--conf=./test-list-removal.tar.gz')
    -- -- check network
    local networkFile = io.open(config_dir .. 'network')
    luaunit.assertNotNil(networkFile)
    local networkContents = networkFile:read('*all')
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.1/24'"), 0)
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.2/24'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list ipaddr '192.168.10.3/24'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.2'"), 0)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.3'"), 1)
    luaunit.assertEquals(string_count(networkContents, "list addresses '10.0.0.4'"), 2)
    luaunit.assertNotNil(string.find(networkContents, "option test_restore '2'"))
end

os.exit(luaunit.LuaUnit.run())
