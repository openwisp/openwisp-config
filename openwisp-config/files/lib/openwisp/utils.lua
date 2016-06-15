-- openwisp uci utils
require('io')
require('lfs')

function starts_with_dot(str)
    if string.sub(str, 1, 1) == '.' then
        return true
    end
    return false
end

function split(input, sep)
    if input == '' or input == nil then
        return {}
    end
    if sep == nil then
        sep = '%s'
    end
    local t={}; i=1
    for str in string.gmatch(input, '([^' .. sep .. ']+)') do
        t[i] = str
        i = i + 1
    end
    return t
end

function basename(path)
    local parts = split(path, '/')
    return parts[table.getn(parts)]
end

function dirname(path)
    local parts = split(path, '/')
    local path = '/'
    local length = table.getn(parts)
    for i, part in ipairs(parts) do
        if i < length then
            path = path..part..'/'
        end
    end
    return path
end

function add_values_to_set(set, values)
    for i, el in pairs(values) do
        set[el] = true
    end
    return set
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
        -- read existing value
        current = cursor:get(config, name, key)
        if type(current) == 'table' then
            set = add_values_to_set(set, current)
        end
        set = add_values_to_set(set, value)
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
    local uci = cursor:get_all(config, name)
    if uci and is_uci_empty(uci) then
        cursor:delete(config, name)
    end
end

-- returns true if a table is empty
function is_table_empty(t)
    for k, v in pairs(t) do
        return false
    end
    return true
end

-- Code by David Kastrup
-- http://lua-users.org/wiki/DirTreeIterator
function dirtree(dir)
    assert(dir and dir ~= '', 'directory parameter is missing or empty')
    if string.sub(dir, -1) == '/' then
        local dir = string.sub(dir, 1, -2)
    end
    local function yieldtree(dir)
        for entry in lfs.dir(dir) do
            if entry ~= '.' and entry ~= '..' then
                entry = dir .. '/' ..entry
                local attr = lfs.attributes(entry)
                coroutine.yield(entry,attr)
                if attr.mode == 'directory' then
                    yieldtree(entry)
                end
            end
        end
    end
    return coroutine.wrap(function() yieldtree(dir) end)
end

function file_exists(path)
    local f = io.open(path, 'r')
    if f ~= nil then io.close(f) return true end
    return false
end

function file_to_set(path)
    local f = io.open(path, 'r')
    local set = {}
    for line in f:lines() do
        set[line] = true
    end
    return set
end

function set_to_file(set, path)
    local f = io.open(path, 'w')
    for file, bool in pairs(set) do
        f:write(file, '\n')
    end
    io.close(f)
    return true
end
