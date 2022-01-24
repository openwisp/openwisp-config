#!/usr/bin/env lua

-- stores unmanaged configurations
local os = require('os')
local io = require('io')
local uci = require('uci')
local utils = require('openwisp.utils')
local sections
local arg = {...}

-- parse arguments
local test = false
for key, value in pairs(arg) do
  -- test argument
  if value == '--test=1' then test = true; end
  -- sections argument
  if string.sub(value, 1, 3) == '-o=' then
    sections = value:gsub('%-o=', '')
    sections = sections:gsub('%"', '')
  end
end

local standard_prefix = test and '../tests/' or '/etc/'
local unmanaged_prefix = test and '../tests/' or '/tmp/openwisp/'
local standard_path = standard_prefix .. 'config/'
local unmanaged_path = unmanaged_prefix .. 'unmanaged/'
local uci_tmp_path = '/tmp/openwisp/.uci'

local function empty_file(path)
  local file = io.open(path, 'w')
  file:write('')
  file:close()
end

-- convert list of sections in a table with a structure like:
-- {
--   network = {
--     {name = 'loopback'},
--     {name = 'globals'},
--     {type = 'switch'},
--     {type = 'switch_vlan'}
--   },
--   system = {
--     {name = 'ntp'},
--     {type = 'led'}
--   }
-- }
local unmanaged_map = {}
local section_list = utils.split(sections)
for _, section in pairs(section_list) do
  local parts = utils.split(section, '.')
  -- skip unrecognized strings
  if parts[1] and parts[2] then
    local config = parts[1]
    local section_type = nil
    local section_name = nil
    -- anonymous section
    if string.sub(parts[2], 1, 1) == '@' then
      section_type = string.sub(parts[2], 2, -1)
      -- named section
    else
      section_name = parts[2]
    end
    if config and (section_name or section_type) then
      if not unmanaged_map[config] then unmanaged_map[config] = {} end
      local el = {name = section_name, type = section_type}
      table.insert(unmanaged_map[config], el)
    end
  end
end

-- cleanup temporary files to avoid conflicts
os.execute('mkdir -p ' .. uci_tmp_path)
os.execute('rm -rf ' .. unmanaged_path)
os.execute('mkdir -p ' .. unmanaged_path)
-- standard cursor
local standard = uci.cursor(standard_path)
-- unmanaged cursor
local unmanaged = uci.cursor(unmanaged_path, uci_tmp_path)

-- loop over standard sections and store a copy in unmanaged
for config_name, config_values in pairs(unmanaged_map) do
  local uci_table = standard:get_all(config_name)
  if uci_table then
    -- create empty file
    empty_file(unmanaged_path .. config_name)
    for i, element in pairs(config_values) do
      if element.name then
        local section = uci_table[element.name]
        if section then
          utils.write_uci_section(unmanaged, config_name, section, true)
        end
      else
        standard:foreach(config_name, element.type, function(section)
          utils.write_uci_section(unmanaged, config_name, section, true)
        end)
      end
    end
  end
  unmanaged:commit(config_name)
end
