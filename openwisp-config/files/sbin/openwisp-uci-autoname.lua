#!/usr/bin/env lua
-- ensures anonymous configurations are named

require('io')
require('uci')
require('lfs')
require('openwisp.utils')
local arg={...}

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
        local config = standard:get_all(file)
        if config then
            for key, section in pairs(config) do
                if section['.anonymous'] then
                    output:delete(file, section['.name'])
                    if file == 'system' and section['.type'] == 'system' then
                        section['.name'] = 'system'
                    end
                    section['.anonymous'] = false
                    write_uci_section(output, file, section)
                    output:reorder(file, 'system', 0)
                    changed = true
                    -- append new named section to stdout var
                    stdout = stdout .. file .. '.' .. section['.name'] .. ', '
                end
            end
            if changed then
                output:commit(file)
            end
        end
    end
end

if stdout ~= '' then
    -- print changed UCI elements to standard output
    print(string.sub(stdout, 0, -3))  -- remove trailing comma
end
