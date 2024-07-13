Compiling a Custom OpenWrt Image
================================

If you are managing many devices and customizing your ``openwisp-config``
configuration by hand on each new device, you should switch to using a
custom OpenWrt firmware image that includes ``openwisp-config`` and its
precompiled configuration file, this strategy has a few important
benefits:

- you can save yourself the effort of installing and configuring
  ``openwisp-config`` on each device
- you can enable :doc:`automatic-registration` by setting
  ``shared_secret``, hence saving extra time and effort to register each
  device on the controller app
- if you happen to reset the firmware to initial settings, these
  precompiled settings will be restored as well

The following procedure illustrates how to compile a custom `OpenWrt
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

Automate Compilation for Different Organizations
------------------------------------------------

If you are working with OpenWISP, there are chances you may be compiling
several images for different organizations (clients or non-profit
communities) and use cases (full featured, mesh, 4G, etc).

Doing this by hand without tracking your changes can lead you into a very
disorganized and messy situation.

To alleviate this pain you can use `ansible-openwisp2-imagegenerator
<https://github.com/openwisp/ansible-openwisp2-imagegenerator>`_.
