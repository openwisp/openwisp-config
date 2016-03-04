# --- installs development dependencies ---
# --- designed for debian linux systems ---
set -e
export CFLAGS="-Wno-error"
apt-get update
# install cmake and git
apt-get install -y cmake git-core
# install json-c and lua
apt-get install -y libjson0 libjson0-dev lua5.1 liblua5.1-0-dev
# install openwrt libubox and uci
git clone https://git.openwrt.org/project/libubox.git --depth=1 && cd libubox
cmake . && sudo make install && cd ..
git clone https://git.openwrt.org/project/uci.git --depth=1 && cd uci
cmake . && sudo make install && cd ..
# update links to shared libraries
sudo ldconfig -v
# install luaunit
git clone https://github.com/bluebird75/luaunit.git --depth=1
mkdir -p /usr/share/lua/5.1/
cd luaunit && sudo cp luaunit.lua /usr/share/lua/5.1/ && cd ..
test -f /usr/share/lua/5.1/luaunit.lua
# clean
rm -rf libubox uci luaunit
