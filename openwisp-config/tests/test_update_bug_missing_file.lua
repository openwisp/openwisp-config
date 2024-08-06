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

TestConfigMissingFile = {
  setUp = function()
    os.execute('mkdir -p ' .. config_dir)
    os.execute('mkdir -p ' .. remote_config_dir)
    -- prepare bad config tar gz
    os.execute('cp good-config-missing-file-bug.tar.gz configuration.tar.gz')
    -- these files are preexisting on the device
    os.execute('cp ./update/system ' .. remote_config_dir .. '/system')
    os.execute('cp ./update/system ' .. config_dir .. '/system')
    os.execute('cp ./restore/network ' .. remote_config_dir .. '/network')
    os.execute('cp ./restore/network ' .. config_dir .. '/network')
  end,
  tearDown = function()
    os.execute('rm -rf ' .. write_dir)
    os.execute('rm -rf ' .. openwisp_dir)
    os.execute('rm configuration.tar.gz')
  end
}

function TestConfigMissingFile.test_update_missing_file()
  update_config('--test=1')
  local remote_firewall = io.open(remote_config_dir .. '/firewall')
  luaunit.assertNotNil(remote_firewall:read('*all'))
end

os.exit(luaunit.LuaUnit.run())
