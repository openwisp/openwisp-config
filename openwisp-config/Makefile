# openwisp.org
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=openwisp-controller-http
PKG_VERSION:=$(shell git describe --always --tags 2> /dev/null || echo 0.1)

include $(INCLUDE_DIR)/package.mk


define Package/openwisp-controller-http
	SECTION:=openwisp
	CATEGORY:=OpenWisp
	TITLE:=OpenWISP Configuration Updater (HTTP)
	MAINTAINER:=info@openwisp.org
	#this is a meta package suitable for any archs...
	PKG_ARCH:=all
	DEPENDS:=+libpolarssl libustream-polarssl libuclient uclient-fetch
endef

define Package/openwisp-controller-http/description
	OpenWISP controller agent, updates configuration via HTTP
endef

define Package/openwisp-fw/config
  source "$(SOURCE)/Config.in"
endef

define Build/Compile
endef

define Package/openwisp-controller-http/install
	$(INSTALL_DIR) $(1)/
	$(CP) -r ./files/* $(1)/

	#unpack external configuration
	if [ -z "$(OPENWISP_CONF)" ]; then exit 2; fi      # system unconfigured
	if [ -d $(OPENWISP_CONF) ]; then \
		cp -fr $(OPENWISP_CONF) $(1)/; \
	fi
	if [ -f $(OPENWISP_CONF) ]; then \
		tar xvzf $(OPENWISP_CONF) -C $(1)/; \
	fi
	if [ `echo $(OPENWISP_CONF) | grep '^http' -` ]; then \
		wget $(OPENWISP_CONF) -qO - | tar xvz -C $(1)/; \
	fi

	git describe --tags --always || echo 'no-git-version' > $(1)/etc/openwisp_version
endef


$(eval $(call BuildPackage,openwisp-fw-base))
$(eval $(call BuildPackage,openwisp-fw))
