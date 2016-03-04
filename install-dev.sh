# --- installs development dependencies ---
# --- designed for debian linux systems ---
set -e
export CFLAGS="-Wno-error"
apt-get update
# install cmake and git
apt-get install -y cmake git-core
# install lua
apt-get install -y lua5.1 liblua5.1-0-dev
# install json-c
apt-get install -y dh-autoreconf
git clone https://github.com/json-c/json-c.git --depth=1 && cd json-c
sh autogen.sh && ./configure && make && make install && cd ..
# install openwrt libubox and uci
git clone https://git.openwrt.org/project/libubox.git --depth=1 && cd libubox
cmake . && make install && cd ..
git clone https://git.openwrt.org/project/uci.git --depth=1 && cd uci
cmake . && make install && cd ..
# update links to shared libraries
ldconfig -v
# install luaunit
git clone https://github.com/bluebird75/luaunit.git --depth=1
mkdir -p /usr/share/lua/5.1/
cd luaunit && cp luaunit.lua /usr/share/lua/5.1/ && cd ..
test -f /usr/share/lua/5.1/luaunit.lua
# clean
rm -rf json-c libubox uci luaunit
