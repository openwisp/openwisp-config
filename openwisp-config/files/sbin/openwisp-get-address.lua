#!/usr/bin/env lua

-- gets the first useful address of the specified interface
-- usage:
--   * openwisp-get-address <ifname> ["inet"|"inet6"] [ula 1|0]
--   * openwisp-get-address <network-name> ["inet"|"inet6"] [ula 1|0]
local os = require('os')
local net = require('openwisp.net')
local name = arg[1]
local family = arg[2]
local ula = arg[3]
local interface = net.get_interface(name, family, ula)
if not interface and family ~= 'inet6' then
  interface = net.get_interface(name, 'inet6')
end

if interface then
  print(interface.addr)
else
  os.exit(1)
end
