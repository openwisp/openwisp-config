# openwisp.org
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=openwisp
PKG_VERSION:=$(shell cat ../VERSION)
PKG_RELEASE:=1
PKG_LICENSE:=GPL-3.0

include $(INCLUDE_DIR)/package.mk

define Package/openwisp-config
	SECTION:=openwisp
	CATEGORY:=OpenWISP
	TITLE:=OpenWISP Configuration Agent
	MAINTAINER:=OpenWISP Project info@openwisp.org
	PKG_ARCH:=all
	DEPENDS:=+libpolarssl +curl +ca-certificates \
	         +lua +libuci-lua +luafilesystem
endef

define Package/openwisp-config/description
	OpenWISP controller agent, updates configuration via HTTP
endef

define Package/openwisp-config/config
	source "$(SOURCE)/Config.in"
endef

define Build/Compile
endef

define Package/openwisp-config/conffiles
/etc/config/openwisp
endef

define Package/openwisp-config/install
	$(INSTALL_DIR) \
		$(1)/usr/sbin \
		$(1)/etc/init.d \
		$(1)/etc/config \
		$(1)/usr/lib/lua/openwisp

	$(INSTALL_BIN) \
		files/openwisp.agent \
		$(1)/usr/sbin/openwisp_config

	$(INSTALL_BIN) \
		files/openwisp.init \
		$(1)/etc/init.d/openwisp_config

	$(INSTALL_CONF) files/openwisp.config \
		$(1)/etc/config/openwisp

	$(INSTALL_BIN) \
		files/sbin/openwisp-reload-config \
		$(1)/usr/sbin/openwisp-reload-config

	$(INSTALL_BIN) \
		files/lib/openwisp/utils.lua \
		$(1)/usr/lib/lua/openwisp/utils.lua

	$(INSTALL_BIN) \
		files/sbin/openwisp-store-unmanaged.lua \
		$(1)/usr/sbin/openwisp-store-unmanaged

	$(INSTALL_BIN) \
		files/sbin/openwisp-restore-unmanaged.lua \
		$(1)/usr/sbin/openwisp-restore-unmanaged

	$(INSTALL_BIN) \
		files/sbin/openwisp-remove-default-wifi.lua \
		$(1)/usr/sbin/openwisp-remove-default-wifi

	$(INSTALL_BIN) \
		files/sbin/openwisp-uci-autoname.lua \
		$(1)/usr/sbin/openwisp-uci-autoname

	$(INSTALL_BIN) \
		files/sbin/openwisp-update-config.lua \
		$(1)/usr/sbin/openwisp-update-config
endef

$(eval $(call BuildPackage,openwisp-config))
