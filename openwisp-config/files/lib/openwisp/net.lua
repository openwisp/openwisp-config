local nixio = require('nixio')
local uci = require('uci')
local net = {}

function net.get_interface(name, family)
  local uci_cursor = uci.cursor()
  local ip_family = family or 'inet'
  -- if UCI network name is a bridge, the ifname won't be the name of the bridge
  local is_bridge = uci_cursor:get('network', name, 'type') == 'bridge'
  local ifname
  if is_bridge then
    ifname = 'br-' .. name
  else
    -- get ifname from network configuration or
    -- default to supplied name if none is found
    ifname = uci_cursor:get('network', name, 'ifname') or name
  end
  -- get list of interfaces and loop until found
  local interfaces = nixio.getifaddrs()
  for _, interface in pairs(interfaces) do
    if interface.name == ifname and interface.family == ip_family then
      return interface
    end
  end
  -- return nil if nothing is found
  return nil
end

return net
