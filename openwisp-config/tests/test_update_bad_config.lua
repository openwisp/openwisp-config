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

TestBrokenConfig = {
  setUp = function()
    os.execute('mkdir -p ' .. config_dir)
    os.execute('mkdir -p ' .. remote_config_dir)
    -- prepare bad config tar gz
    os.execute('cp bad-config.tar.gz configuration.tar.gz')
    -- these files are pre-existing on the device
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

function TestBrokenConfig.test_update()
  update_config('--test=1')
  local local_system = io.open(config_dir .. '/system')
  luaunit.assertNotNil(local_system)
  local remote_system = io.open(remote_config_dir .. '/system')
  luaunit.assertNotNil(remote_system)
  local local_network = io.open(config_dir .. '/network')
  luaunit.assertNotNil(local_network)
  local remote_network = io.open(remote_config_dir .. '/network')
  luaunit.assertNotNil(local_system:read('*all'), remote_system:read('*all'))
  luaunit.assertNotNil(local_network:read('*all'), remote_network:read('*all'))
end

os.exit(luaunit.LuaUnit.run())
