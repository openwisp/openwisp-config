# --- installs development dependencies ---
# --- designed for debian linux systems ---
set -e
export CFLAGS="-Wno-error"
apt-get update
# install cmake and git
apt-get install -y cmake git-core
# install lua
apt-get install -y lua5.1 liblua5.1-0-dev luarocks
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
# install luafilesystem
luarocks install luafilesystem
# install luaunit
luarocks install luaunit
# install luacheck
luarocks install luacheck
# clean
rm -rf json-c libubox uci
