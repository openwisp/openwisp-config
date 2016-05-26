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

local input_prefix = test and '../tests/' or '/etc/'
local input_path = input_prefix .. 'config'
local input = uci.cursor(input_path) -- read operations
local output = input  -- write operations
local stdout = ''  -- result

-- if test mode
if test then
    -- use different write cursor in test mode
    local uci_tmp_path = '/tmp/openwisp/.uci'
    os.execute('mkdir -p ' .. uci_tmp_path)
    output = uci.cursor('../tests/anonymous/', uci_tmp_path)
end

for file in lfs.dir(input_path) do
    if lfs.attributes(file, 'mode') ~= 'directory' then
        local changed = false
        input:foreach(file, nil, function(block)
            if block['.anonymous'] then
                output:delete(file, block['.name'])
                if file == 'system' and block['.type'] == 'system' then
                    block['.name'] = 'system'
                end
                block['.anonymous'] = false
                write_uci_section(output, file, block)
                changed = true
                -- append new named block to stdout var
                stdout = stdout .. file .. '.' .. block['.name'] .. ', '
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
