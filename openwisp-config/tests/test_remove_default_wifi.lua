require('os')
require('io')
luaunit = require('luaunit')
remove_default_wifi = assert(loadfile("../files/sbin/openwisp-remove-default-wifi.lua"))

TestRemoveDefaultWifi = {
    setUp = function()
        os.execute('cp ./wifi/wireless ./config')
    end,
    tearDown = function()
        os.execute('rm ./config/wireless')
    end
}

function TestRemoveDefaultWifi.test_default()
    remove_default_wifi('--test=1')
    local file = io.open('./config/wireless')
    luaunit.assertNotNil(file)
    local contents = file:read('*all')
    luaunit.assertNil(string.find(contents, "option ssid 'LEDE'"))
    luaunit.assertNil(string.find(contents, "option ssid 'OpenWrt'"))
end

os.exit(luaunit.LuaUnit.run())
