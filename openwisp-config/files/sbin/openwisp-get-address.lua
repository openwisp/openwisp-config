#!/usr/bin/env lua

-- gets the first useful address of the specified interface
-- fistly tries to get an IPv4 address, if not found, tries to get an IPv6 address
-- with the --prefer-ipv6 option, it will try to get an IPv6 address first
-- usage:
--   * openwisp-get-address <ifname> [--prefer-ipv6]
--   * openwisp-get-address <network-name> [--prefer-ipv6]
local os = require('os')
local net = require('openwisp.net')
local name = arg[1]
local prefer_ipv6 = arg[2] == "--prefer-ipv6"

local ip_version1, ip_version2

if prefer_ipv6 then
  ip_version1 = 'inet6'
  ip_version2 = 'inet'
else
  ip_version1 = 'inet'
  ip_version2 = 'inet6'
end


local interface = net.get_interface(name, ip_version1)
if not interface then
  interface = net.get_interface(name, ip_version2)
end


if interface then
  print(interface.addr)
else
  os.exit(1)
end
