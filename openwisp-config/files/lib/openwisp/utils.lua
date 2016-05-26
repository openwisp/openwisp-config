-- openwisp uci utils

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

-- returns true if uci block is empty
function is_uci_empty(table)
    for key, value in pairs(table) do
        if not starts_with_dot(key) then return false end
    end
    return true
end
