#!/usr/bin/env lua
-- removes OpenWrt/LEDE default wifi-iface settings, if present

require('uci')

-- parse arguments
local arg={...}
for key, value in pairs(arg) do
    -- test argument
    if value == '--test=1' then test = true; end
end

local standard_prefix = test and '../tests/' or '/etc/'
local standard_path = standard_prefix .. 'config/'
-- standard standard
local standard = uci.cursor(standard_path)
local changed = false

standard:foreach('wireless', 'wifi-iface', function(section)
    if section['.anonymous'] and
       section.encryption == 'none' and
       section.mode == 'ap' and
       (section.ssid == 'LEDE' or section.ssid == 'OpenWrt')
    then
        standard:delete('wireless', section['.name'])
        changed = true
    end
end)
if changed then standard:commit('wireless') end
