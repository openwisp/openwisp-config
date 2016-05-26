-- openwisp uci utils

function starts_with_dot(str)
    if string.sub(str, 1, 1) == '.' then
        return true
    end
    return false
end

-- writes uci section, eg:
--
-- write_uci_section(cursor, 'network', {
--     [".name"] = "wan",
--     [".type"] = "interface",
--     [".anonymous"] = false,
--     proto = "none",
--     ifname = "eth0.2",
-- }
--
-- will write to "network" the following:
--
--     config interface 'wan'
--         option proto 'none'
--         option ifname 'eth0.2'
--
function write_uci_section(cursor, config, section)
    local name
    -- add named section
    if not section['.anonymous'] then
        name = section['.name']
        cursor:set(config, name, section['.type'])
    -- add anonymous section
    else
        name = cursor:add(config, section['.type'])
    end
    -- write options for section
    for key, value in pairs(section) do
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

-- returns true if uci section is empty
function is_uci_empty(table)
    for key, value in pairs(table) do
        if not starts_with_dot(key) then return false end
    end
    return true
end

-- removes uci options
-- and removes section if empty
-- this is the inverse operation of `write_uci_section`
function remove_uci_options(cursor, config, section)
    local name = section['.name']
    -- loop over keys in section and
    -- remove each one from cursor
    for key, value in pairs(section) do
        if not starts_with_dot(key) then
            cursor:delete(config, name, key)
        end
    end
    -- remove entire section if empty
    if is_uci_empty(cursor:get_all(config, name)) then
        cursor:delete(config, name)
    end
end
