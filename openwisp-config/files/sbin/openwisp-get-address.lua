#!/usr/bin/env lua
-- gets the first useful address of the specified interface
-- usage:
--   * openwisp-get-address <ifname>
--   * openwisp-get-address <network-name>
require('os')
require('nixio')
require('uci')

name = arg[1]

uci_cursor = uci.cursor()
families = {
  inet = true,
  inet6 = true
}

function get_address(name)
    -- get ifname from network configuration or
    -- default to supplied name if none is found
    ifname = uci_cursor:get('network', name, 'ifname') or name
    interfaces = nixio.getifaddrs()
    for i, interface in pairs(interfaces) do
        if interface.name == ifname and families[interface.family] then
            return interface.addr
        end
    end
    return nil
end

address = get_address(name)

if address then
  print(address)
else
  os.exit(1)
end
