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
	DEPENDS:=+libpolarssl +curl +ca-certificates +libuci-lua
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

	$(INSTALL_BIN) \
		files/openwisp.agent \
		$(1)/usr/sbin/openwisp_config

	$(INSTALL_BIN) \
		files/apply_config \
		$(1)/usr/sbin/apply_config

	$(INSTALL_BIN) \
		files/store_unmanaged.lua \
		$(1)/usr/sbin/store_unmanaged

	$(INSTALL_BIN) \
		files/openwisp.init \
		$(1)/etc/init.d/openwisp_config

	$(INSTALL_CONF) files/openwisp.config \
		$(1)/etc/config/openwisp
endef

$(eval $(call BuildPackage,openwisp-config))
