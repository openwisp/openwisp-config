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

local output = standard  -- write operations
local stdout = ''  -- result
local new_name = ''
local all_names = {}

local function getUCIName(name)
  return string.gsub(string.gsub(name, '%.', '_'), '-', '_')
end

local function nextAvailableName(type)
  -- first available name in the form of
  -- 'type .. increment' with increment starting from 1
  local i = 1
  local name = type .. i
  while all_names[name] do
    i = i + 1
    name = type .. i
  end
  return name
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
    -- avoid name collisions by storing all existing names
    standard:foreach(file, nil, function(section)
      if not section['.anonymous'] then
        all_names[section['.name']] = true
      end
    end)
    standard:foreach(file, nil, function(section)
      local index = section['.index']
      if section['.anonymous'] then
        output:delete(file, section['.name'])
        if file == 'firewall' and section['.type'] == 'defaults' then
          new_name = 'defaults'
        elseif file == 'network' and section['.type'] == 'globals' then
          new_name = 'globals'
        elseif file == 'network' and
          (section['.type'] == 'route' or section['.type'] == 'route6') then
          new_name = nextAvailableName('route')
        elseif file == 'network' and section['.type'] == 'switch' then
          new_name = section['name']
        elseif file == 'network' and section['.type'] == 'switch_vlan' then
          new_name = section['device'] .. '_vlan' .. section['vlan']
        elseif file == 'network' and section['.type'] == 'switch_port' then
          new_name = section['device'] .. '_port' .. section['port']
        elseif file == 'system' and section['.type'] == 'system' then
          new_name = 'system'
        elseif file == 'system' and section['.type'] == 'led' then
          new_name = 'led_' .. string.lower(section['name'])
        elseif file == 'wireless' and section['.type'] == 'wifi-iface' then
          if section['ifname'] == nil then
            new_name = 'wifi_' .. getUCIName(
              standard:get('network', section['network'], 'ifname')
            )
          else
            new_name = 'wifi_' .. getUCIName(section['ifname'])
          end
        else
          new_name = nextAvailableName(getUCIName(section['.type']))
        end
        -- make sure the new name is unique
        if all_names[new_name] then
            new_name = nextAvailableName(new_name .. '_')
        end
        all_names[new_name] = true
        section['.name'] = new_name
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
