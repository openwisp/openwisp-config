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
local standard_path = standard_prefix .. 'config'
local standard = uci.cursor(standard_path) -- read operations
local output = standard  -- write operations
local stdout = ''  -- result

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
                end
                if file == 'network' and section['.type'] == 'globals' then
                    section['.name'] = 'globals'
                end
                if file == 'system' and section['.type'] == 'system' then
                    section['.name'] = 'system'
                end
                if file == 'system' and section['.type'] == 'led' then
                    section['.name'] = 'led_' .. string.lower(section['name'])
                end
                if file == 'wireless' and section['.type'] == 'wifi-iface' then
                    if section['ifname'] == nil then
                        section['.name'] = 'wifi_' .. string.gsub(standard:get('network', section['network'], 'ifname'),'%.','_')
                    else
                        section['.name'] = 'wifi_' .. section['ifname']
                    end
                end
                section['.anonymous'] = false
                utils.write_uci_section(output, file, section)
                output:reorder(file, section['.name'], index)
                changed = true
                -- append new named section to stdout var
                stdout = stdout .. file .. '.' .. section['.name'] .. ', '
            end
        end)
        if changed then
            output:commit(file)
        end
    end
end

if stdout ~= '' then
    -- print changed UCI elements to standard output
    print(string.sub(stdout, 0, -3))  -- remove trailing comma
end
