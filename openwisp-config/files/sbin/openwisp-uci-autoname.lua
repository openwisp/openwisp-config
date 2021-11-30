#!/usr/bin/env lua

-- ensures anonymous configurations are named
local uci = require('uci')
local lfs = require('lfs')
local utils = require('openwisp.utils')
local arg = {...}
local test = false

-- parse arguments
for key, value in pairs(arg) do
  -- test argument
  if value == '--test=1' then test = true; end
end

local standard_prefix = test and '../tests/' or '/etc/'
local standard_path = standard_prefix .. (test and 'anonymous' or 'config')
local standard = uci.cursor(standard_path) -- read operations
local output = standard -- write operations
local stdout = '' -- result
local count = {}

local function getCount(type) return count[type] end

local function incCount(type)
  if count[type] == nil then
    count[type] = 1
  else
    count[type] = count[type] + 1
  end
end

local function getUCIName(name)
  return string.gsub(string.gsub(name, '%.', '_'), '-', '_')
end

-- if test mode
if test then
  -- use different write cursor in test mode
  local uci_tmp_path = '/tmp/openwisp/.uci'
  os.execute('mkdir -p ' .. uci_tmp_path)
  output = uci.cursor('../tests/anonymous/', uci_tmp_path)
end

for file in lfs.dir(standard_path) do
  if file ~= '.' and file ~= '..' then
    local changed = false
    standard:foreach(file, nil, function(section)
      local index = section['.index']
      if section['.anonymous'] then
        output:delete(file, section['.name'])
        if file == 'firewall' and section['.type'] == 'defaults' then
          section['.name'] = 'defaults'
        elseif file == 'network' and section['.type'] == 'globals' then
          section['.name'] = 'globals'
        elseif file == 'network' and
          (section['.type'] == 'route' or section['.type'] == 'route6') then
          incCount('route')
          section['.name'] = 'route' .. getCount('route')
        elseif file == 'network' and section['.type'] == 'switch' then
          section['.name'] = section['name']
        elseif file == 'network' and section['.type'] == 'switch_vlan' then
          section['.name'] = section['device'] .. '_vlan' .. section['vlan']
        elseif file == 'network' and section['.type'] == 'switch_port' then
          section['.name'] = section['device'] .. '_port' .. section['port']
        elseif file == 'system' and section['.type'] == 'system' then
          section['.name'] = 'system'
        elseif file == 'system' and section['.type'] == 'led' then
          section['.name'] = 'led_' .. string.lower(section['name'])
        elseif file == 'wireless' and section['.type'] == 'wifi-iface' then
          if section['ifname'] == nil then
            section['.name'] = 'wifi_' ..
                                 getUCIName(
                standard:get('network', section['network'], 'ifname'))
          else
            section['.name'] = 'wifi_' .. getUCIName(section['ifname'])
          end
        else
          incCount(section['.type'])
          section['.name'] = getUCIName(section['.type']) ..
                               getCount(section['.type'])
        end
        section['.anonymous'] = false
        utils.write_uci_section(output, file, section)
        output:reorder(file, section['.name'], index)
        changed = true
        -- append new named section to stdout var
        stdout = stdout .. file .. '.' .. section['.name'] .. ', '
      end
    end)
    if changed then output:commit(file) end
  end
end

if stdout ~= '' then
  -- print changed UCI elements to standard output
  print(string.sub(stdout, 0, -3)) -- remove trailing comma
end
