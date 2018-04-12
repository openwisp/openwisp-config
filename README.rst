===============
openwisp-config
===============

.. image:: http://img.shields.io/github/release/openwisp/openwisp-config.svg
   :target: https://github.com/openwisp/openwisp-config/releases

------------

`LEDE <https://lede-project.org/>`_ / `OpenWRT <https://openwrt.org/>`_ configuration agent for the new
`OpenWISP 2 Controller <https://github.com/openwisp/ansible-openwisp2>`_.

.. image:: http://netjsonconfig.openwisp.org/en/latest/_images/openwisp.org.svg
  :target: http://openwisp.org

.. contents:: **Table of Contents**:
 :backlinks: none
 :depth: 3

------------

Install precompiled package
---------------------------

First run:

.. code-block:: shell

    opkg update

Then install one of the `latest builds <http://downloads.openwisp.org/openwisp-config/>`_:

.. code-block:: shell

    opkg install <URL>

Where ``<URL>`` is the URL of the image that is suitable for your case.

For a list of the latest built images, take a look at `downloads.openwisp.org
<http://downloads.openwisp.org/openwisp-config/>`_.

**If you need to compile the package yourself**, see `Compiling openwisp-config`_
and `Compiling a custom LEDE / OpenWRT image`_.

Once installed *openwisp-config* needs to be configured (see `Configuration options`_)
and then started with::

    /etc/init.d/openwisp_config start

To ensure the agent is working correctly find out how to perform debugging in
the `Debugging`_ section.

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
- ``capath``: value passed to curl ``--capath`` argument, by default is empty; see also `curl capath argument <https://curl.haxx.se/docs/manpage.html#--capath>`_
- ``cacert``: value passed to curl ``--cacert`` argument, by default is empty; see also `curl cacert argument <https://curl.haxx.se/docs/manpage.html#--cacert>`_
- ``connect_timeout``: value passed to curl ``--connect-timeout`` argument, defaults to ``15``; see `curl connect-timeout argument <https://curl.haxx.se/docs/manpage.html#--connect-timeout>`_
- ``max_time``: value passed to curl ``--max-time`` argument, defaults to ``30``; see `curl connect-timeout argument <https://curl.haxx.se/docs/manpage.html#-m>`_
- ``mac_interface``: the interface from which the MAC address is taken when performing automatic registration, defaults to ``eth0``
- ``pre_reload_hook``: path to custom executable script, see `pre-reload-hook`_

Automatic registration
----------------------

When the agent starts, if both ``uuid`` and ``key`` are not defined, it will consider
the router to be unregistered and it will attempt to perform an automatic registration.

The automatic registration is performed only if ``shared_secret`` is correctly set.

The device will choose as name one of its mac addresses, unless its hostname is not ``OpenWrt`` or ``LEDE``,
in the latter case it will simply register itself with the current hostname.

When the registration is completed, the agent will automatically set ``uuid`` and ``key``
in ``/etc/config/openwisp``.

To enable this feature by default on your firmware images, follow the procedure described in
`Compiling a custom LEDE / OpenWRT image`_.

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

Hooks
-----

Below are described the available hooks in *openwisp-config*.

pre-reload-hook
^^^^^^^^^^^^^^^

This hook is called each time *openwisp-config* applies a configuration, but **before services are reloaded**,
more precisely in these situations:

* after a new remote configuration is downloaded and applied
* after a configuration test failed (see `Configuration test`_) and a previous backup is restored

You can use this hook to perform custom actions before services are reloaded, eg: to perform
auto-configuration with `LibreMesh <http://libre-mesh.org/>`_.

Example configuration::

    config controller 'http'
            ...
            option pre_reload_hook '/usr/sbin/my-pre-reload-hook'
            ...

Complete example:

.. code-block:: shell

    # set hook in configuration
    uci set openwisp.http.pre_reload_hook='/usr/sbin/my-pre-reload-hook'
    uci commit openwisp
    # create hook script
    cat <<EOF > /usr/sbin/my-pre-reload-hook
    #!/bin/sh
    # put your custom operations here
    EOF
    # make script executable
    chmod +x /usr/sbin/my-pre-reload-hook
    # reload openwisp_config by using procd's convenient utility
    reload_config

Compiling openwisp-config
-------------------------

There are 4 variants of *openwisp-config*:

- **openwisp-config-openssl**: depends on *ca-certificates* and *libopenssl*
- **openwisp-config-mbedtls**: depends on *ca-certificates* and *libmbedtls*
- **openwisp-config-cyassl**: depends on *ca-certificates* and *libcyassl*
- **openwisp-config-polarssl**: depends on *ca-certificates* and *libpolarssl* (**note**: polarssl
  has been deprecated in favour of mbedtls on more recent OpenWRT and LEDE versions)
- **openwisp-config-nossl**: doesn't depend on any SSL library and doesn't install trusted CA certificates

The following procedure illustrates how to compile all the *openwisp-config* variants and their dependencies:

.. code-block:: shell

    git clone git://git.lede-project.org/source.git lede
    cd lede

    # configure feeds
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" > feeds.conf
    cat feeds.conf.default >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    # any arch/target is fine because the package is architecture indipendent
    arch="ar71xx"
    echo "CONFIG_TARGET_$arch=y" > .config;
    echo "CONFIG_PACKAGE_openwisp-config-openssl=y" >> .config
    echo "CONFIG_PACKAGE_openwisp-config-mbedtls=y" >> .config
    echo "CONFIG_PACKAGE_openwisp-config-cyassl=y" >> .config
    echo "CONFIG_PACKAGE_openwisp-config-polarssl=y" >> .config
    echo "CONFIG_PACKAGE_openwisp-config-nossl=y" >> .config
    make defconfig
    make tools/install
    make toolchain/install
    make package/openwisp-config/compile
    make package/openwisp-config/install

Alternatively, you can configure your build interactively with ``make menuconfig``, in this case
you will need to select the *openwisp-config* variant by going to ``Administration > openwisp``:

.. code-block:: shell

    git clone git://git.lede-project.org/source.git lede
    cd lede

    # configure feeds
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" > feeds.conf
    cat feeds.conf.default >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    make menuconfig
    # go to Administration > openwisp and select the variant you need interactively
    make -j1 V=s

Compiling a custom LEDE / OpenWRT image
---------------------------------------

If you are managing many devices and customizing your ``openwisp-config`` configuration by hand on
each new device, you should switch to using a custom LEDE / OpenWRT firmware image that includes
``openwisp-config`` and its precompiled configuration file, this strategy has a few important benefits:

* you can save yourself the effort of installing and configuring ``openwisp-config`` on each device
* you can enable `Automatic registration`_ by setting ``shared_secret``,
  hence saving extra time and effort to register each device on the controller app
* if you happen to reset the firmware to initial settings, these precompiled settings will be restored as well

The following procedure illustrates how to compile a custom `LEDE 17.01 <https://lede-project.org>`_
image with a precompiled minimal ``/etc/config/openwisp`` configuration file:

.. code-block:: shell

    git clone git://git.lede-project.org/source.git lede
    cd lede
    git checkout lede-17.01

    # include precompiled file
    mkdir -p files/etc/config
    cat <<EOF > files/etc/config/openwisp
    config controller 'http'
        # change the values of the following 2 options
        option url 'https://openwisp2.mydomain.com'
        option shared_secret 'mysharedsecret'
        list unmanaged 'system.@led'
        list unmanaged 'network.loopback'
        list unmanaged 'network.@switch'
        list unmanaged 'network.@switch_vlan'
    EOF

    # configure feeds
    cp feeds.conf.default feeds.conf
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    # replace with your desired arch target
    arch="ar71xx"
    echo "CONFIG_TARGET_$arch=y" > .config
    echo "CONFIG_PACKAGE_openwisp-config-openssl=y" >> .config
    echo "CONFIG_LIBCURL_OPENSSL=y" >> .config
    make defconfig
    # compile with verbose output
    make -j1 V=s

Automate compilation for different organizations
------------------------------------------------

If you are working with OpenWISP, there are chances you may be compiling several images for different
organizations (clients or non-profit communities) and use cases (full featured, mesh, 4G, etc).

Doing this by hand without tracking your changes can lead you into a very disorganized and messy situation.

To alleviate this pain you can use `ansible-openwisp2-imagegenerator
<https://github.com/openwisp/ansible-openwisp2-imagegenerator>`_.

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
    
Contributing guidelines
-----------------------

See `Contributing <https://github.com/openwisp/openwisp-config/blob/master/CONTRIBUTING.md>`_.

Changelog
---------

See `CHANGELOG <https://github.com/openwisp/openwisp-config/blob/master/CHANGELOG.rst>`_.

License
-------

See `LICENSE <https://github.com/openwisp/openwisp-config/blob/master/LICENSE>`_.

Support
-------

See `OpenWISP Support Channels <http://openwisp.org/support.html>`_.
