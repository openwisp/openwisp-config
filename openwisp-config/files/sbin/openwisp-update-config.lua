#!/usr/bin/env lua
-- openwisp-config configuration updater

require('os')
require('lfs')
require('uci')
require('openwisp.utils')

-- parse arguments
MERGE = true -- default value
for key, value in pairs(arg) do
    -- test argument
    if value == '--merge=0' then MERGE = false; end
end

downloaded_conf = '/tmp/openwisp/configuration.tar.gz'
openwisp_dir = '/etc/openwisp'
standard_config_dir = '/etc/config'
remote_dir = openwisp_dir .. '/remote'
remote_config_dir = remote_dir .. standard_config_dir
stored_dir = openwisp_dir .. '/stored'
added_file = openwisp_dir .. '/added.list'
modified_file = openwisp_dir .. '/modified.list'
get_standard = function() return uci.cursor(standard_config_dir) end
get_remote = function() return uci.cursor(remote_config_dir, '/tmp/openwisp/.uci') end

-- uci cursors
standard = get_standard()
remote = get_remote()

-- update UCI configuration
-- (overwrite or merge)

-- remove config items added via openwisp-config
if lfs.attributes(remote_config_dir, 'mode') == 'directory' then
    for file in lfs.dir(remote_config_dir) do
        local standard_path = standard_config_dir .. '/' .. file
        if lfs.attributes(standard_path, 'mode') == 'file' then
            for key, section in pairs(remote:get_all(file)) do
                remove_uci_options(standard, file, section)
            end
            standard:commit(file)
            -- remove uci file if empty
            local uci = standard:get_all(file)
            if uci and is_table_empty(uci) then
                os.remove(standard_path)
            end
        end
    end
end

-- persist remote config in /etc/openwisp/remote
os.execute('rm -rf '..remote_dir)
os.execute('mkdir -p '..remote_dir)
os.execute('tar -zxf '..downloaded_conf..' -C '..remote_dir)
-- reload uci cursors
standard = get_standard()
remote = get_remote()

if lfs.attributes(remote_config_dir, 'mode') == 'directory' then
    -- loop over each file in new remote uci config
    for file in lfs.dir(remote_config_dir) do
        local standard_path = standard_config_dir .. '/' .. file
        local remote_path = remote_config_dir .. '/' .. file
        -- ensure we are acting on a file
        if lfs.attributes(remote_path, 'mode') == 'file' then
            -- MERGE mode
            if MERGE then
                -- avoid "file does not exist" error
                os.execute('touch ' .. standard_path)
                for key, section in pairs(remote:get_all(file)) do
                    write_uci_section(standard, file, section)
                end
                standard:commit(file)
            -- OVERWRITE mode
            else
                os.execute('cp '..remote_config_dir..'/* '..standard_config_dir)
            end
        end
    end
end

-- ensure list files exist
os.execute('touch ' .. added_file)
os.execute('touch ' .. modified_file)
-- convert lists to lua sets
added = file_to_set(added_file)
modified = file_to_set(modified_file)
added_changed = false
modified_changed = false

-- loop each file except directories and standard UCI config files
ignored_path = remote_config_dir .. '/'

for path, attr in dirtree(remote_dir) do
    if attr.mode == 'file' and string.sub(path, 1, 32) ~= ignored_path then
        -- calculates destination dir
        local dest_path = string.sub(path, 21)
        local dest_dir = dirname(dest_path)
        local is_added = added[dest_path] == true
        local is_modified = modified[dest_path] == true
        -- if file is neither in added.list nor modified.list
        if is_added == false and is_modified == false then
            -- if file exists
            if file_exists(dest_path) then
                -- add file path to modified set
                modified[dest_path] = true
                modified_changed = true
                -- store original in /etc/openwisp/stored/<path>
                os.execute('mkdir -p '..stored_dir..dest_dir)
                os.execute('cp '..dest_path..' '..stored_dir..dest_path)
            else
                -- add file path added set
                added[dest_path] = true
                added_changed = true
            end
        end
        -- add file to filesystem
        os.execute('mkdir -p '..dest_dir)
        os.execute('cp '..path..' '..dest_path)
    end
end

-- remove files that have been added via openwisp
-- which are not present anymore
for file, bool in pairs(added) do
    local remote_path = remote_dir .. file
    -- if file is not in /etc/openwisp/remote anymore
    if not file_exists(remote_path) then
        -- remove file
        os.remove(file)
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
    -- if file is not in /etc/openwisp/remote anymore
    if not file_exists(remote_path) then
        -- restore original file
        os.execute('mv '..stored_path..' '..file)
        -- remove stored dir if empty
        lfs.rmdir(dirname(stored_path))
        -- remove entry from modified set
        modified[file] = nil
        modified_changed = true
    end
end

-- persist changes to file lists
if added_changed then set_to_file(added, added_file) end
if modified_changed then set_to_file(modified, modified_file) end
