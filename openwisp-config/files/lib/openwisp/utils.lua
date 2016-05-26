-- openwisp uci utils

function starts_with_dot(str)
    if string.sub(str, 1, 1) == '.' then
        return true
    end
    return false
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
    if starts_with_dot(key) then
        return
    end
    -- avoid duplicate list settings
    if type(value) == 'table' then
        -- create set with unique values
        local set = {}
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

-- removes uci options in block (table) from a section
-- and removes section if empty
function remove_uci_options_from_block(cursor, config, block)
    local name = block['.name']
    -- loop over keys in block and remove each one
    for key, value in pairs(block) do
        if not starts_with_dot(key) then
            cursor:delete(config, name, key)
        end
    end
    -- remove entire section if empty
    if is_uci_empty(cursor:get_all(config, name)) then
        cursor:delete(config, name)
    end
end
