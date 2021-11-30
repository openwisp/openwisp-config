#!/usr/bin/env lua

-- restores unmanaged configurations
local uci = require('uci')
local lfs = require('lfs')
local utils = require('openwisp.utils')

-- parse arguments
local test = false
local arg = {...}
for key, value in pairs(arg) do
  -- test argument
  if value == '--test=1' then test = true; end
end

local standard_prefix = test and '../tests/' or '/etc/'
local unmanaged_prefix = test and '../tests/' or '/tmp/openwisp/'
local standard_path = standard_prefix .. 'config/'
local unmanaged_path = unmanaged_prefix .. 'unmanaged/'
local uci_tmp_path = '/tmp/openwisp/.uci'
-- standard cursor
local standard = uci.cursor(standard_path)
-- unmanaged cursor
local unmanaged = uci.cursor(unmanaged_path, uci_tmp_path)

for file in lfs.dir(unmanaged_path) do
  if file ~= '.' and file ~= '..' then
    for key, section in pairs(unmanaged:get_all(file)) do
      standard:delete(file, key)
      utils.write_uci_section(standard, file, section, true)
    end
    standard:commit(file)
  end
end
