local nixio = require('nixio')
local uci = require('uci')
local net = {}

function net.get_interface(name, family, ula)
  local uci_cursor = uci.cursor()
  local ip_family
  if family == 'inet' then
    ip_family = 'inet'
  else
    ip_family = 'inet6'
  end
  local ip_ula
  if ula == '1' then
    ip_ula = true
  else
    ip_ula = false
  end
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
  -- get list of interfaces
  local interfaces = nixio.getifaddrs()
  -- sort list of interfaces by addr (2001:xx:xx:xx::1,fd52:xx:xx::1,fe80::xx:xx:xx:901a)
  table.sort(interfaces, function (left, right)
    return left['addr'] < right['addr']
  end)
  -- loop until found
  for _, interface in pairs(interfaces) do
    if interface.name == ifname and interface.family == ip_family then
      if ip_family == 'inet6' then
        -- check if limklocal fe80::xx:xx:xx:xx addr
        if string.find(interface.addr,'fe') ~= 1 then
          -- check if ula fd52:xx:xx::1 addr
          if not ip_ula and string.find(interface.addr,'fd') ~= 1 then
            return interface
          elseif ip_ula then
            return interface
          end
        end
      else
        return interface
      end
    end
  end
  -- return nil if nothing is found
  return nil
end

return net
