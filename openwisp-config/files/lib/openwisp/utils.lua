-- openwisp uci utils
local io = require('io')
local lfs = require('lfs')

local utils = {}

function utils.starts_with_dot(str) return str:sub(1, 1) == '.' end

function utils.split(input, sep)
  if input == '' or input == nil then return {} end
  if sep == nil then sep = '%s' end
  local t = {};
  local i = 1
  for str in string.gmatch(input, '([^' .. sep .. ']+)') do
    t[i] = str
    i = i + 1
  end
  return t
end

function utils.basename(path)
  local parts = utils.split(path, '/')
  return parts[table.getn(parts)]
end

function utils.dirname(path)
  local parts = utils.split(path, '/')
  local returnPath = '/'
  local length = table.getn(parts)
  for i, part in ipairs(parts) do
    if i < length then returnPath = returnPath .. part .. '/' end
  end
  return returnPath
end

function utils.add_values_to_set(set, values)
  for _, el in pairs(values) do set[el] = true end
  return set
end

-- writes uci section, eg:
--
-- utils.write_uci_section(cursor, 'network', {
--     [".name"] = "wan",
--     [".type"] = "interface",
--     [".anonymous"] = false,
--     proto = "none",
--     ifname = "eth0.2",
-- })
--
-- will write to "network" the following:
--
--     config interface 'wan'
--         option proto 'none'
--         option ifname 'eth0.2'
--
function utils.write_uci_section(cursor, config, section, merge_list)
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
  for key, value in utils.sorted_pairs(section) do
    utils.write_uci_option(cursor, config, name, key, value, merge_list)
  end
end

-- abstraction for "uci set" which handles corner cases
function utils.write_uci_option(cursor, config, name, key, value, merge_list)
  -- ignore properties starting with .
  if utils.starts_with_dot(key) then return end
  -- avoid duplicate list settings
  if type(value) == 'table' and merge_list then
    -- create set with unique values
    local set = {}
    -- read existing value
    local current = cursor:get(config, name, key)
    if type(current) == 'table' then set = utils.add_values_to_set(set, current) end
    set = utils.add_values_to_set(set, value)
    -- reset value var with set contents
    value = {}
    for item_value, present in pairs(set) do table.insert(value, item_value) end
  end
  cursor:set(config, name, key, value)
end

-- returns true if uci section is empty
function utils.is_uci_empty(table)
  for key, value in pairs(table) do
    if not utils.starts_with_dot(key) then return false end
  end
  return true
end

-- removes uci options
-- and removes section if empty
-- this is the inverse operation of `write_uci_section`
function utils.remove_uci_options(cursor, config, section)
  local name = section['.name']
  -- loop over keys in section and
  -- remove each one from cursor
  for key, value in pairs(section) do
    if not utils.starts_with_dot(key) then cursor:delete(config, name, key) end
  end
  -- remove entire section if empty
  local uci = cursor:get_all(config, name)
  if uci and utils.is_uci_empty(uci) then cursor:delete(config, name) end
end

-- returns true if a table is empty
function utils.is_table_empty(t)
  if next(t) == nil then
    return true
  else
    return false
  end
end

-- Code by David Kastrup
-- http://lua-users.org/wiki/DirTreeIterator
function utils.dirtree(dir_param)
  assert(dir_param and dir_param ~= '', 'directory parameter is missing or empty')
  if string.sub(dir_param, -1) == '/' then dir_param = string.sub(dir_param, 1, -2) end
  local function yieldtree(dir)
    for entry in lfs.dir(dir) do
      if entry ~= '.' and entry ~= '..' then
        entry = dir .. '/' .. entry
        local attr = lfs.attributes(entry)
        coroutine.yield(entry, attr)
        if attr.mode == 'directory' then yieldtree(entry) end
      end
    end
  end
  return coroutine.wrap(function() yieldtree(dir_param) end)
end

function utils.file_exists(path)
  local f = io.open(path, 'r')
  if f ~= nil then
    io.close(f)
    return true
  end
  return false
end

function utils.file_to_set(path)
  local f = io.open(path, 'r')
  local set = {}
  for line in f:lines() do set[line] = true end
  return set
end

function utils.set_to_file(set, path)
  local f = io.open(path, 'w')
  for file, bool in pairs(set) do f:write(file, '\n') end
  io.close(f)
  return true
end

function utils.starts_with(str, start) return str:sub(1, #start) == start end

-- iterates over a table in alphabeticaly order
function utils.sorted_pairs(t)
  -- collect keys
  local keys = {}
  for key in pairs(t) do keys[#keys + 1] = key end

  table.sort(keys)

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then return keys[i], t[keys[i]] end
  end
end

return utils
