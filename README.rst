===============
openwisp-config
===============

.. image:: https://ci.publicwifi.it/buildStatus/icon?job=openwisp-config

.. image:: http://img.shields.io/github/release/openwisp/openwisp-config.svg

OpenWRT configuration agent for the new OpenWISP Controller (currently under development, will
be based on `django-netjsonconfig <https://github.com/openwisp/django-netjsonconfig>`_).

Install latest release
----------------------

For `ar71xx <https://wiki.openwrt.org/doc/hardware/soc/soc.qualcomm.ar71xx>`_:

.. code-block:: shell

    opkg install http://downloads.openwisp.org/openwisp-config/0.2/ar71xx/openwisp-config_0.2-1_ar71xx.ipk

For `rampis <https://wiki.openwrt.org/doc/hardware/soc/soc.mediatek>`_:

.. code-block:: shell

    opkg install http://downloads.openwisp.org/openwisp-config/latest/ramips/openwisp-config_0.2-1_ramips_24kec.ipk

For a list of the latest builds, take a look at `downloads.openwisp.org
<http://downloads.openwisp.org/openwisp-config/>`_.

If you need a package for other SoCs you will need to compile the package, see
`Compiling openwisp-config`_.

Configuration options
---------------------

UCI configuration options must go in ``/etc/config/openwisp``.

- ``url``: url of controller, eg: ``https://controller.openwisp.org``
- ``interval``: time in seconds between checks for changes to the configuration, defaults to ``120``
- ``verify_ssl``: whether SSL verification must be performed or not, defaults to ``1``
- ``uuid``: unique identifier of the router configuration in the controller application
- ``key``: key required to download the configuration
- ``shared_secret``: shared secret, needed for `Automatic registration`_
- ``test_config``: whether a new configuration must be tested before being considered applied, defaults to ``1``
- ``test_script``: custom test script, read more about this feature in `Configuration test`_

Automatic registration
----------------------

When the agent starts, if both ``uuid`` and ``key`` are not defined, it will consider
the router to be unregistered and it will attempt to perform an automatic registration.

The automatic registration is performed only if ``shared_secret`` is correctly set.

When the registration is completed, the agent will automatically set ``uuid`` and ``key``
in ``/etc/config/openwisp``.

In the controller you will find a new (empty) configuration named as the mac address of the router.

Configuration test
------------------

When a new configuration is downloaded, the agent will first backup the current running
configuration, then it will try to apply the new one and perform a basic test, which consists
in trying to contact the controller again;

If the test succeeds, the configuration is considered applied and the backup is deleted.

If the test fails, the backup is restored and the agent will log the failure via syslog.

Disable testing
^^^^^^^^^^^^^^^

To disable this feature, set the ``test_config`` option to ``0``, then reload/restart *openwisp_config*.

Define custom tests
^^^^^^^^^^^^^^^^^^^

If the default test does not satisfy your needs, you can define your own tests in an
**executable** script and indicate the path to this script in the ``test_script`` config option.

If the exit code of the executable script is higher than ``0`` the test will be considered failed.

Compiling openwisp-config
-------------------------

The following procedure illustrates how to compile *openwisp-config* and its dependencies:

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

Changelog
---------

See `CHANGELOG <https://github.com/openwisp/openwisp-config/blob/master/CHANGELOG.rst>`_.

License
-------

See `LICENSE <https://github.com/openwisp/openwisp-config/blob/master/LICENSE>`_.
