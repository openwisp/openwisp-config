#!/usr/bin/env lua

-- removes OpenWrt/LEDE default wifi-iface settings, if present
local uci = require('uci')

-- parse arguments
local test
local arg = {...}
for _, value in pairs(arg) do
  -- test argument
  if value == '--test=1' then test = true; end
end

local standard_prefix = test and '../tests/' or '/etc/'
local standard_path = standard_prefix .. 'config/'
-- standard standard
local standard = uci.cursor(standard_path)
local changed = false

local function is_default_wifi(section)
  if section.encryption == 'none' and section.mode == 'ap' and section.network ==
    'lan' and (section.ssid == 'LEDE' or section.ssid == 'OpenWrt') then return true end
  return false
end

standard:foreach('wireless', 'wifi-iface', function(section)
  if is_default_wifi(section) then
    standard:delete('wireless', section['.name'])
    changed = true
  end
end)
if changed then standard:commit('wireless') end
