#!/usr/bin/env lua

require('os')
require('io')
require('uci')
local blocks
local arg={...}

-- parse arguments
for key, value in pairs(arg) do
    -- test argument
    if value == '--test=1' then test = true; end
    -- blocks argument
    if string.sub(value, 1, 3) == '-o=' then
        blocks = value:gsub('%-o=', '')
        blocks = blocks:gsub('%"', '')
    end
end

local standard_prefix = test and "../tests/" or "/etc/"
local unmanaged_prefix = test and "../tests/" or "/tmp/openwisp/"
local standard_path = standard_prefix .. "config/"
local unmanaged_path = unmanaged_prefix .. "unmanaged/"
local uci_tmp_path = "/tmp/openwisp/.uci"

function split(input, sep)
    if input == "" or input == nil then
        return {}
    end
    if sep == nil then
        sep = "%s"
    end
    local t={}; i=1
    for str in string.gmatch(input, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function empty_file(path)
    local file = io.open(path, 'w')
    file:write('')
    file:close()
end

-- writes uci block, eg:
--
--     config interface 'wan'
--         option proto 'none'
--         option ifname 'eth0.2'
--
function write_uci_block(cursor, config, block)
    local name
    -- add named block
    if not block['.anonymous'] then
        name = block['.name']
        cursor:set(config, name, block['.type'])
    -- add anonymous block
    else
        name = cursor:add(config, block['.type'])
    end
    -- write options for block
    for key, value in pairs(block) do
        write_uci_option(cursor, config, name, key, value)
    end
end

-- abstraction for "uci set" which handles corner cases
function write_uci_option(cursor, config, name, key, value)
    -- ignore properties starting with .
    if string.sub(key, 1, 1) == '.' then
        return
    end
    -- avoid duplicate list settings
    if type(value) == 'table' then
        -- create set with unique values
        set = {}
        for i, el in pairs(value) do
            set[el] = true
        end
        -- reset value var with set contents
        value = {}
        for item_value, present in pairs(set) do
            table.insert(value, item_value)
        end
    end
    cursor:set(config, name, key, value)
end

-- convert list of blocks in a table with a structure like:
-- {
--   network = {
--     {name = "loopback"},
--     {name = "globals"},
--     {type = "switch"},
--     {type = "switch_vlan"}
--   },
--   system = {
--     {name = "ntp"},
--     {type = "led"}
--   }
-- }
local unmanaged_map = {}
local block_list = split(blocks)
for i, block in pairs(block_list) do
    local parts = split(block, '.')
    -- skip unrecognized strings
    if parts[1] and parts[2] then
        local config = parts[1]
        local block_type = nil
        local block_name = nil
        -- anonymous block
        if string.sub(parts[2], 1, 1) == '@' then
            block_type = string.sub(parts[2], 2, -1)
        -- named block
        else
            block_name = parts[2]
        end
        if config and (block_name or block_type) then
            if not unmanaged_map[config] then
                unmanaged_map[config] = {}
            end
            el = {name=block_name, type=block_type}
            table.insert(unmanaged_map[config], el)
        end
    end
end

os.execute("mkdir -p " .. uci_tmp_path)
os.execute("mkdir -p " .. unmanaged_path)
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
                local block = uci_table[element.name]
                if block then
                    write_uci_block(unmanaged, config_name, block)
                end
            else
                standard:foreach(config_name, element.type, function(block)
                    write_uci_block(unmanaged, config_name, block)
                end)
            end
        end
    end
    unmanaged:commit(config_name)
end
