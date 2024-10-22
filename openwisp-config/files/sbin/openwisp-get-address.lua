#!/usr/bin/env lua

-- gets the first useful address of the specified interface
-- usage:
--   * openwisp-get-address <ifname>
--   * openwisp-get-address <network-name>
local os = require('os')
local net = require('openwisp.net')
local name = arg[1]
local interface = net.get_interface(name, 'inet')
if not interface then
  interface = net.get_interface(name, 'inet6')
end

if interface then
  print(interface.addr)
else
  os.exit(1)
end
