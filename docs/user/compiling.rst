Compiling openwisp-config
=========================

The following procedure illustrates how to compile *openwisp-config* and
its dependencies:

.. code-block:: shell

    git clone https://github.com/openwrt/openwrt.git openwrt
    cd openwrt
    git checkout <openwrt-branch>

    # configure feeds
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" > feeds.conf
    cat feeds.conf.default >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    # any arch/target is fine because the package is architecture indipendent
    arch="ar71xx"
    echo "CONFIG_TARGET_$arch=y" > .config;
    echo "CONFIG_PACKAGE_openwisp-config=y" >> .config
    make defconfig
    make tools/install
    make toolchain/install
    make package/openwisp-config/compile

Alternatively, you can configure your build interactively with ``make
menuconfig``, in this case you will need to select *openwisp-config* by
going to ``Administration > openwisp``:

.. code-block:: shell

    git clone https://github.com/openwrt/openwrt.git openwrt
    cd openwrt
    git checkout <openwrt-branch>

    # configure feeds
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" > feeds.conf
    cat feeds.conf.default >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    make menuconfig
    # go to Administration > openwisp and select the variant you need interactively
    make -j1 V=s

.. _compiling_custom_openwrt_image:

Compiling a custom OpenWRT image
================================

If you are managing many devices and customizing your ``openwisp-config``
configuration by hand on each new device, you should switch to using a
custom OpenWRT firmware image that includes ``openwisp-config`` and its
precompiled configuration file, this strategy has a few important
benefits:

- you can save yourself the effort of installing and configuring
  ``openwisp-config`` on each device
- you can enable :doc:`automatic-registration` by setting
  ``shared_secret``, hence saving extra time and effort to register each
  device on the controller app
- if you happen to reset the firmware to initial settings, these
  precompiled settings will be restored as well

The following procedure illustrates how to compile a custom `OpenWRT
<https://openwrt.org/>`_ image with a precompiled minimal
``/etc/config/openwisp`` configuration file:

.. code-block:: shell

    git clone https://github.com/openwrt/openwrt.git openwrt
    cd openwrt
    git checkout <openwrt-branch>

    # include precompiled file
    mkdir -p files/etc/config
    cat <<EOF > files/etc/config/openwisp
    config controller 'http'
        # change the values of the following 2 options
        option url 'https://demo.openwisp.io'
        option shared_secret 'nzXTd7qpXKPNdrWZDsYoMxbGpOrEVjeD'
    EOF

    # configure feeds
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" > feeds.conf
    cat feeds.conf.default >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    # replace with your desired arch target
    arch="ar71xx"
    echo "CONFIG_TARGET_$arch=y" > .config
    echo "CONFIG_PACKAGE_openwisp-config=y" >> .config
    make defconfig
    # compile with verbose output
    make -j1 V=s

Automate compilation for different organizations
================================================

If you are working with OpenWISP, there are chances you may be compiling
several images for different organizations (clients or non-profit
communities) and use cases (full featured, mesh, 4G, etc).

Doing this by hand without tracking your changes can lead you into a very
disorganized and messy situation.

To alleviate this pain you can use `ansible-openwisp2-imagegenerator
<https://github.com/openwisp/ansible-openwisp2-imagegenerator>`_.
