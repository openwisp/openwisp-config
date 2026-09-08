#!/bin/sh
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
git clone --depth 1 --branch json-c-0.15-20200726 https://github.com/json-c/json-c.git
{ cd json-c && cmake . && make install && cd ..; } || { echo 'Installing json-c failed!' && exit 1; }
# install openwrt libubox and uci
git clone https://git.openwrt.org/project/libubox.git --depth=1
{ cd libubox && cmake . && make install && cd ..; } || { echo 'Installing libubox failed!' && exit 1; }
git clone https://git.openwrt.org/project/uci.git --depth=1
{ cd uci && cmake . && make install && cd ..; } || { echo 'Installing uci failed!' && exit 1; }
# update links to shared libraries
ldconfig -v
# install luafilesystem
luarocks install luafilesystem
# install luaunit
luarocks install luaunit
# install luacheck
luarocks install luacheck
# install luaformatter
# Pin LuaFormatter and its submodules to immutable commits before building.
LUA_FORMATTER_COMMIT=417d4570a4265109ebbab6610023e91c4668f631
git clone --no-checkout https://github.com/Koihik/LuaFormatter.git LuaFormatter && (
	cd LuaFormatter \
		&& git checkout --detach "$LUA_FORMATTER_COMMIT" \
		&& git submodule update --init --recursive \
		&& cmake -DBUILD_TESTS=OFF . \
		&& make install
) || { rm -rf LuaFormatter && echo 'Installing LuaFormatter failed' && exit 1; }
# clean
rm -rf json-c libubox uci LuaFormatter
