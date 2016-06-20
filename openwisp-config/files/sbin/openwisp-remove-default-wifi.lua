#!/usr/bin/env lua

require('uci')

-- parse arguments
local arg={...}
for key, value in pairs(arg) do
    -- test argument
    if value == '--test=1' then test = true; end
end

local standard_prefix = test and '../tests/' or '/etc/'
local standard_path = standard_prefix .. 'config/'
-- standard cursor
local cursor = uci.cursor(standard_path)
local changed = false

cursor:foreach('wireless', 'wifi-iface', function(section)
    if section['.anonymous'] and
       section.encryption == 'none' and
       section.mode == 'ap' and
       (section.ssid == 'LEDE' or section.ssid == 'OpenWrt')
    then
        cursor:delete('wireless', section['.name'])
        changed = true
    end
end)
if changed then cursor:commit('wireless') end
