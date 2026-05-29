-- manually add lib dir to lua package path
package.path = package.path .. ';../files/lib/?.lua'

local luaunit = require('luaunit')
local network_config = {}
local interfaces = {}

package.loaded['uci'] = {
  cursor = function()
    return {
      get = function(_, config, section, option)
        if config ~= 'network' or not network_config[section] then
          return nil
        end
        return network_config[section][option]
      end
    }
  end
}

package.loaded['nixio'] = {getifaddrs = function() return interfaces end}
local net = require('openwisp.net')
TestNet = {}

function TestNet.setUp()
  network_config = {}
  interfaces = {}
end

function TestNet.test_get_interface_uses_bridge_prefix()
  network_config.lan = {type = 'bridge'}
  interfaces = {{name = 'br-lan', family = 'inet', addr = '192.168.1.1'}}
  local interface = net.get_interface('lan')
  luaunit.assertNotNil(interface)
  luaunit.assertEquals(interface.name, 'br-lan')
  luaunit.assertEquals(interface.addr, '192.168.1.1')
end

function TestNet.test_get_interface_uses_pppoe_prefix()
  network_config.wan = {proto = 'pppoe'}
  interfaces = {{name = 'pppoe-wan', family = 'inet', addr = '192.0.2.1'}}
  local interface = net.get_interface('wan')
  luaunit.assertNotNil(interface)
  luaunit.assertEquals(interface.name, 'pppoe-wan')
  luaunit.assertEquals(interface.addr, '192.0.2.1')
end

os.exit(luaunit.LuaUnit.run())
