===============
openwisp-config
===============

.. image:: https://ci.publicwifi.it/buildStatus/icon?job=openwisp-config

.. image:: http://img.shields.io/github/release/openwisp/openwisp-config.svg

OpenWRT configuration agent for the new OpenWISP Controller (currently under development, will
be based on `django-netjsonconfig <https://github.com/openwisp/django-netjsonconfig>`_).

Install latest release
----------------------

.. code-block:: shell

    cd /tmp
    wget http://downloads.openwisp.org/openwisp-config/0.1/ar71xx/openwisp-config_0.1-1_ar71xx.ipk
    opkg update
    opkg install ./openwisp-config_0.1-1_ar71xx.ipk

Configuration options
---------------------

UCI configuration options must go in ``/etc/config/openwisp``.

- ``url``: url of controller, eg: ``https://controller.openwisp.org``
- ``interval``: time in seconds between checks for changes to the configuration, defaults to ``120``
- ``verify_ssl``: whether SSL verification must be performed or not, defaults to ``1``
- ``uuid``: unique identifier of the router configuration in the controller application
- ``key``: key required to download the configuration
- ``shared_secret``: shared secret, needed for `Automatic registration`_

Automatic registration
----------------------

When the agent starts, if both ``uuid`` and ``key`` are not defined, it will consider
the router to be unregistered and it will attempt to perform an automatic registration.

The automatic registration is performed only if ``shared_secret`` is correctly set.

When the registration is completed, the agent will automatically set ``uuid`` and ``key``
in ``/etc/config/openwisp``.

In the controller you will find a new (empty) configuration named as the mac address of the router.

How to compile
--------------

Follow this procedure to compile *openwisp-config* and its dependencies.

.. code-block:: shell

    git clone git://git.openwrt.org/openwrt.git --depth 1
    cd openwrt

    # configure feeds
    cp feeds.conf.default feeds.conf
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    # replace with your desired arch target
    arch="ar71xx"
    echo "CONFIG_TARGET_$arch=y" > .config;
    echo "CONFIG_PACKAGE_openwisp-config=y" >> .config
    make defconfig
    make tools/install
    make toolchain/install
    make package/polarssl/compile
    make package/polarssl/install
    make package/curl/compile
    make package/curl/install
    make package/ca-certificates/compile
    make package/ca-certificates/install
    make package/openwisp-config/compile
    make package/openwisp-config/install
