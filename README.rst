===============
openwisp-config
===============

.. image:: https://ci.publicwifi.it/buildStatus/icon?job=openwisp-config

.. image:: http://img.shields.io/github/release/openwisp/openwisp-config.svg

------------

OpenWRT/LEDE configuration agent for the new `OpenWISP <http://openwrt.org>`_ Controller
(currently under development, will be based on `django-netjsonconfig <https://github.com/openwisp/django-netjsonconfig>`_).

.. image:: http://netjsonconfig.openwisp.org/en/latest/_images/openwisp.org.svg
  :target: http://openwisp.org

.. contents:: **Table of Contents**:
 :backlinks: none
 :depth: 3

------------

Install latest release
----------------------

First run:

.. code-block:: shell

    opkg update

Then install one of the `latest builds <http://downloads.openwisp.org/openwisp-config/>`_:

.. code-block:: shell

    opkg install <URL>

Where ``<URL>`` is the URL of the image that is suitable for your case.

For a list of the latest built images, take a look at `downloads.openwisp.org
<http://downloads.openwisp.org/openwisp-config/>`_.

If the SoC or OpenWRT version you are using is not available, you have to compile the package,
(see `Compiling openwisp-config`_).

Once installed *openwisp-config* needs to be configured (see `Configuration options <#configuration-options>`_)
and then started with::

    /etc/init.d/openwisp_config start

To ensure the agent is working correctly find out how to perform debugging in
the `Debugging <#debugging>`_ section.

Configuration options
---------------------

UCI configuration options must go in ``/etc/config/openwisp``.

- ``url``: url of controller, eg: ``https://controller.openwisp.org``
- ``interval``: time in seconds between checks for changes to the configuration, defaults to ``120``
- ``verify_ssl``: whether SSL verification must be performed or not, defaults to ``1``
- ``shared_secret``: shared secret, needed for `Automatic registration`_
- ``consistent_key``: whether `Consistent key generation`_ is enabled or not, defaults to ``1``
- ``merge_config``: whether `Merge configuration`_ is enabled or not, defaults to ``1``
- ``test_config``: whether a new configuration must be tested before being considered applied, defaults to ``1``
- ``test_script``: custom test script, read more about this feature in `Configuration test`_
- ``uuid``: unique identifier of the router configuration in the controller application
- ``key``: key required to download the configuration
- ``unmanaged``: list of config sections which won't be overwritten, see `Unmanaged Configurations`_
- ``capath``: value passed to curl ``--capath`` argument, defaults to ``/etc/ssl/certs``; see also `curl capath argument <https://curl.haxx.se/docs/manpage.html#--capath>`_
- ``connect_timeout``: value passed to curl ``--connect-timeout`` argument, defaults to ``15``; see `curl connect-timeout argument <https://curl.haxx.se/docs/manpage.html#--connect-timeout>`_
- ``max_time``: value passed to curl ``--max-time`` argument, defaults to ``30``; see `curl connect-timeout argument <https://curl.haxx.se/docs/manpage.html#-m>`_
- ``mac_interface``: the interface from which the MAC address is taken when performing automatic registration, defaults to ``eth0``;

Automatic registration
----------------------

When the agent starts, if both ``uuid`` and ``key`` are not defined, it will consider
the router to be unregistered and it will attempt to perform an automatic registration.

The automatic registration is performed only if ``shared_secret`` is correctly set.

The device will choose as name one of its mac addresses, unless its hostname is not "OpenWrt",
in the latter case it will simply register itself with the current hostname.

When the registration is completed, the agent will automatically set ``uuid`` and ``key``
in ``/etc/config/openwisp``.

Consistent key generation
-------------------------

When using `Automatic registration`_, this feature allows devices to keep the same configuration
even if reset or reflashed.

The ``key`` is generated consistently with an operation like ``md5sum(mac_address + shared_secret)``;
this allows the controller application to recognize that an existing device is registering itself again.

The ``mac_interface`` configuration key specifies which interface is used to calculate the mac address,
this setting defaults to ``eth0``. If no ``eth0`` interface exists, the first non-loopback, non-bridge and non-tap
interface is used. You won't need to change this setting often, but if you do, ensure you choose a physical
interface which has constant mac address.

The "Consistent key generation" feature is enabled by default, but must be enabled also in the
controller application in order to work.

Merge configuration
-------------------

By default the remote configuration is merged with the local one. This has several advantages:

* less bolierplate configuration stored in the remote controller
* local users can change local configurations without fear of losing their changes

It is possible to turn this feature off by setting ``merge_config`` to ``0`` in ``/etc/config/openwisp``.

Configuration test
------------------

When a new configuration is downloaded, the agent will first backup the current running
configuration, then it will try to apply the new one and perform a basic test, which consists
in trying to contact the controller again;

If the test succeeds, the configuration is considered applied and the backup is deleted.

If the test fails, the backup is restored and the agent will log the failure via syslog
(see `Debugging`_ for more information on auditing logs).

Disable testing
^^^^^^^^^^^^^^^

To disable this feature, set the ``test_config`` option to ``0``, then reload/restart *openwisp_config*.

Define custom tests
^^^^^^^^^^^^^^^^^^^

If the default test does not satisfy your needs, you can define your own tests in an
**executable** script and indicate the path to this script in the ``test_script`` config option.

If the exit code of the executable script is higher than ``0`` the test will be considered failed.

Unmanaged Configurations
------------------------

In some cases it is necessary to ensure that some configuration sections won't be
overwritten by the controller.

These settings are called "unmanaged", in the sense that are not managed remotely.

The default unmanaged settings are the following ones::

    config controller 'http'
            ...
            list unmanaged 'system.@led'
            list unmanaged 'network.loopback'
            list unmanaged 'network.@switch'
            list unmanaged 'network.@switch_vlan'
            ...

Note the lines with the `@` sign; this syntax means any UCI section of the specified type will be unmanaged.

In the previous example, the loopback interface, all ``led settings``, all ``switch`` and ``switch_vlan``
directives will never be overwritten by the remote configuration and will only be editable via SSH
or via the web interface.

Disable Unmanaged Configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To disable unmanaged configurations simply remove all the ``unmanaged`` options.

Compiling openwisp-config
-------------------------

There are 4 variants of *openwisp-config*:

- **openwisp-config-openssl**: depends on *ca-certificates* and *libopenssl*
- **openwisp-config-polarssl**: depends on *ca-certificates* and *libpolarssl*
- **openwisp-config-cyassl**: depends on *ca-certificates* and *libcyassl*
- **openwisp-config-nossl**: doesn't depend on any SSL library and doesn't install trusted CA certificates

The following procedure illustrates how to compile *openwisp-config-polarssl* and its dependencies:

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
    echo "CONFIG_PACKAGE_openwisp-config-polarssl=y" >> .config
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

Alternatively, you can configure your build interactively with ``make menuconfig``, in this case
you will need to select the *openwisp-config* variant by going to ``Administration > openwisp``:

.. code-block:: shell

    git clone git://git.openwrt.org/openwrt.git --depth 1
    cd openwrt

    # configure feeds
    cp feeds.conf.default feeds.conf
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    make menuconfig
    # go to Administration > openwisp and select the variant you need interactively

Debugging
---------

Debugging *openwisp-config* can be easily done by using the ``logread`` command:

.. code-block:: shell

    logread

Use grep to filter out any other log message:

.. code-block:: shell

    logread | grep openwisp

If you are in doubt openwisp-config is running at all, you can check with::

    ps | grep openwisp

You should see something like::

    3800 root      1200 S    {openwisp_config} /bin/sh /usr/sbin/openwisp_config --url https://openwisp2.mydomain.com --verify-ssl 1 --consistent-key 1 ...

You can inspect the version of openwisp-config currently installed with::

    openwisp_config --version

Run tests
---------

To run the unit tests, you must install the required dependencies first; to do this, you can take
a look at the `install-dev.sh <https://github.com/openwisp/openwisp-config/blob/master/install-dev.sh>`_
script.

You can run all the unit tests by launching the dedicated script::

    ./runtests

Alternatively, you can run specifc tests, eg::

    cd openwisp-config/tests/
    lua test_utils.lua -v

Changelog
---------

See `CHANGELOG <https://github.com/openwisp/openwisp-config/blob/master/CHANGELOG.rst>`_.

License
-------

See `LICENSE <https://github.com/openwisp/openwisp-config/blob/master/LICENSE>`_.

Support
-------

Send questions to the `OpenWISP Mailing List <https://groups.google.com/d/forum/openwisp>`_.
