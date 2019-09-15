################################################################################
#
# duperemove
#
################################################################################

DUPEREMOVE_VERSION = v0.11.1
DUPEREMOVE_SITE = git://github.com/markfasheh/duperemove.git
DUPEREMOVE_LICENSE = GPL-2.0
DUPEREMOVE_DEPENDENCIES = host-pkgconf

define DUPEREMOVE_BUILD_CMDS
	$(MAKE) -C $(@D) $(TARGET_CONFIGURE_OPTS)
endef

define DUPEREMOVE_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) PREFIX=/usr DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))
