#!/usr/bin/env lua

-- openwisp-config configuration updater
local os = require('os')
local lfs = require('lfs')
local uci = require('uci')
local utils = require('openwisp.utils')
local arg = {...}

-- parse arguments
local MERGE = true
local TEST = false
local conf = nil

for _, value in pairs(arg) do
  if utils.starts_with(value, '--conf=') then conf = string.sub(value, 8) end
  if value == '--merge=0' then MERGE = false; end
  -- test argument
  if value == '--test=1' then TEST = true; end
end

local working_dir = lfs.currentdir()
local tmp_dir = not TEST and '/tmp/openwisp' or working_dir
local check_dir = tmp_dir .. '/check'
local check_config_dir = check_dir .. '/etc/config'
local downloaded_conf = conf or (tmp_dir .. '/configuration.tar.gz')
local openwisp_dir = not TEST and '/etc/openwisp' or working_dir .. '/openwisp'
local standard_config_dir = not TEST and '/etc/config' or working_dir ..
                              '/update-test/etc/config'
local test_root_dir = working_dir .. '/update-test'
local remote_dir = openwisp_dir .. '/remote'
local remote_config_dir = remote_dir .. '/etc/config'
local stored_dir = openwisp_dir .. '/stored'
local stored_config_dir = stored_dir .. '/etc/config'
local added_file = openwisp_dir .. '/added.list'
local modified_file = openwisp_dir .. '/modified.list'
local get_standard = function() return uci.cursor(standard_config_dir) end
local get_remote = function()
  return uci.cursor(remote_config_dir, '/tmp/openwisp/.uci')
end
local get_check =
  function() return uci.cursor(check_config_dir, '/tmp/openwisp/.uci') end
local get_stored = function()
  return uci.cursor(stored_config_dir, '/tmp/openwisp/.uci')
end

-- uci cursors
local standard = get_standard()
local remote = get_remote()

-- check downloaded UCI files before proceeding
os.execute('mkdir -p ' .. check_dir)
os.execute('tar -zxf ' .. downloaded_conf .. ' -C ' .. check_dir)
local check = get_check()

if lfs.attributes(check_config_dir, 'mode') == 'directory' then
  for file in lfs.dir(check_config_dir) do
    local path = check_config_dir .. '/' .. file
    if lfs.attributes(path, 'mode') == 'file' then
      if check:get_all(file) == nil then
        print('ERROR: invalid UCI configuration file: ' .. file)
        os.execute('rm -rf ' .. check_dir)
        if TEST then
          return
        else
          os.exit(2)
        end
      end
    end
  end
end

-- update UCI configuration
-- (overwrite or merge)

local stored = get_stored()
-- remove config items added via openwisp-config
if lfs.attributes(remote_config_dir, 'mode') == 'directory' then
  for file in lfs.dir(remote_config_dir) do
    local standard_path = standard_config_dir .. '/' .. file
    if lfs.attributes(standard_path, 'mode') == 'file' then
      for _, section in pairs(remote:get_all(file)) do
        -- if section has been removed in the new configuration
        if check:get(file, section['.name']) == nil then
          -- search section in the backup configuration
          local section_stored = stored:get_all(file, section['.name'])
          -- section is not in the backup configuration -> remove
          if section_stored == nil then
            utils.remove_uci_options(standard, file, section)
            -- section is in the backup configuration -> restore
          else
            -- delete all options first
            for option, value in pairs(section) do
              if not utils.starts_with_dot(option) then
                standard:delete(file, section['.name'], option)
              end
            end
            utils.write_uci_section(standard, file, section_stored)
          end
          -- if section still exists in the new configuration
        else
          -- compare each option in current with new configuration
          for option, value in pairs(section) do
            if not utils.starts_with_dot(option) then
              -- if option has been removed in the new configuration
              if check:get(file, section['.name'], option) == nil then
                -- search option in the backup configuration
                local value_stored = stored:get(file, section['.name'], option)
                if value_stored == nil then
                  -- option is not in the backup configuration -> remove
                  standard:delete(file, section['.name'], option)
                else
                  -- option is in the backup configuration -> restore
                  standard:set(file, section['.name'], option, value_stored)
                end
              end
            end
          end
          -- remove entire section if empty
          local result = standard:get_all(file, section['.name'])
          if result and utils.is_uci_empty(result) then
            standard:delete(file, section['.name'])
          end
        end
      end
      standard:commit(file)
      -- remove uci file if empty
      local uci_file = standard:get_all(file)
      if uci_file and utils.is_table_empty(uci_file) then
        os.remove(standard_path)
      end
    end
  end
end
os.execute('rm -rf ' .. check_dir)

-- persist remote config in /etc/openwisp/remote
os.execute('rm -rf ' .. remote_dir)
os.execute('mkdir -p ' .. remote_dir)
os.execute('tar -zxf ' .. downloaded_conf .. ' -C ' .. remote_dir)
os.execute('mkdir -p ' .. stored_config_dir)
-- reload uci cursors
standard = get_standard()
remote = get_remote()

if lfs.attributes(remote_config_dir, 'mode') == 'directory' then
  -- loop over each file in new remote uci config
  for file in lfs.dir(remote_config_dir) do
    local standard_path = standard_config_dir .. '/' .. file
    local remote_path = remote_config_dir .. '/' .. file
    local stored_path = stored_config_dir .. '/' .. file
    -- ensure we are acting on a file
    if lfs.attributes(remote_path, 'mode') == 'file' then
      -- if there's no backup of the file yet, create one
      if not utils.file_exists(stored_path) then
        os.execute('cp ' .. standard_path .. ' ' .. stored_path)
        local uci_sections = stored:get_all(file) or {}
        for key, section in pairs(uci_sections) do
          -- check if section is in remote configuration
          local section_check = check:get(file, section['.name'])
          if section_check then
            -- check if options is in remote configuration
            for option, value in pairs(section) do
              if not utils.starts_with_dot(option) then
                local option_check = check:get(file, section['.name'], option)
                if option_check then
                  -- if option is in remote configuration, remove it
                  stored:delete(file, section['.name'], option)
                end
              end
            end
            -- remove entire section if empty
            local result = stored:get_all(file, section['.name'])
            if result and utils.is_uci_empty(result) then
              stored:delete(file, section['.name'])
            end
          end
        end
        stored:commit(file)
        -- remove uci file if empty
        local uci_file = stored:get_all(file)
        if uci_file and utils.is_table_empty(uci_file) then
          os.remove(stored_path)
        end
      end
      -- MERGE mode
      if MERGE then
        -- avoid "file does not exist" error
        os.execute('touch ' .. standard_path)
        for _, section in pairs(remote:get_all(file)) do
          utils.write_uci_section(standard, file, section)
        end
        standard:commit(file)
        -- OVERWRITE mode
      else
        os.execute('cp ' .. remote_config_dir .. '/* ' .. standard_config_dir)
      end
    end
  end
end

-- ensure list files exist
os.execute('touch ' .. added_file)
os.execute('touch ' .. modified_file)
-- convert lists to lua sets
local added = utils.file_to_set(added_file)
local modified = utils.file_to_set(modified_file)
local added_changed = false
local modified_changed = false

-- loop each file except directories and standard UCI config files
local ignored_path = remote_config_dir .. '/'
local function is_ignored(path) return utils.starts_with(path, ignored_path) end

for path, attr in utils.dirtree(remote_dir) do
  if attr.mode == 'file' and not is_ignored(path) then
    -- calculates destination dir
    local dest_path = path:sub(#(remote_dir .. '/'))
    local dest_dir = utils.dirname(dest_path)
    -- like dest_path but used during automated tests
    local check_path = not TEST and dest_path or test_root_dir .. dest_path
    local is_added = added[dest_path] == true
    local is_modified = modified[dest_path] == true
    -- if file is neither in added.list nor modified.list
    if is_added == false and is_modified == false then
      -- if file exists
      if utils.file_exists(check_path) then
        -- add file path to modified set
        modified[dest_path] = true
        modified_changed = true
        -- store original in /etc/openwisp/stored/<path>
        os.execute('mkdir -p ' .. stored_dir .. dest_dir)
        os.execute('cp ' .. check_path .. ' ' .. stored_dir .. dest_path)
      else
        -- add file path added set
        added[dest_path] = true
        added_changed = true
      end
    end
    if TEST then
      dest_path = test_root_dir .. dest_path
      dest_dir = test_root_dir .. dest_dir
    end
    -- add file to filesystem
    os.execute('mkdir -p ' .. dest_dir)
    os.execute('cp ' .. path .. ' ' .. dest_path)
  end
end

-- remove files that have been added via openwisp
-- which are not present anymore
for file, bool in pairs(added) do
  local remote_path = remote_dir .. file
  local dest_path = not TEST and file or test_root_dir .. file
  -- if file is not in /etc/openwisp/remote anymore
  if not utils.file_exists(remote_path) then
    -- remove file
    os.remove(dest_path)
    -- remove entry from added set
    added[file] = nil
    added_changed = true
  end
end

-- restore pre-existing files that were changed via openwisp
-- which are not present anymore
for file, bool in pairs(modified) do
  local remote_path = remote_dir .. file
  local stored_path = stored_dir .. file
  local dest_path = not TEST and file or test_root_dir .. file
  -- if file is not in /etc/openwisp/remote anymore
  if not utils.file_exists(remote_path) then
    -- restore original file
    os.execute('mv ' .. stored_path .. ' ' .. dest_path)
    -- remove stored dir if empty
    lfs.rmdir(utils.dirname(stored_path))
    -- remove entry from modified set
    modified[file] = nil
    modified_changed = true
  end
end

-- persist changes to file lists
if added_changed then utils.set_to_file(added, added_file) end
if modified_changed then utils.set_to_file(modified, modified_file) end
