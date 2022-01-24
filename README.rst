===============
openwisp-config
===============

.. image:: https://github.com/openwisp/openwisp-config/workflows/OpenWISP%20Config%20CI%20Build/badge.svg?branch=master
    :target: https://github.com/openwisp/openwisp-config/actions?query=workflow%3A%22OpenWISP+Config+CI+Build%22
    :alt: ci build

.. image:: http://img.shields.io/github/release/openwisp/openwisp-config.svg
   :target: https://github.com/openwisp/openwisp-config/releases

.. image:: https://img.shields.io/gitter/room/nwjs/nw.js.svg?style=flat-square
   :target: https://gitter.im/openwisp/general
   :alt: support chat

------------

`OpenWRT <https://openwrt.org/>`_ configuration agent for the new
`OpenWISP Controller <https://github.com/openwisp/ansible-openwisp2>`_.

**Want to help OpenWISP?** `Find out how to help us grow here
<http://openwisp.io/docs/general/help-us.html>`_.

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

Then install one of the `latest builds <http://downloads.openwisp.io/openwisp-config/>`_:

.. code-block:: shell

    opkg install <URL>

Where ``<URL>`` is the URL of the precompiled openwisp-config package.

For a list of the latest built images, take a look at `downloads.openwisp.io/openwisp-config/
<http://downloads.openwisp.io/openwisp-config/>`_.

**If you need to compile the package yourself**, see `Compiling openwisp-config`_
and `Compiling a custom OpenWRT image`_.

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
- ``management_interval``: time in seconds between the management ip discovery attempts, defaults to ``$interval/12``
- ``registration_interval``: time in seconds between the registration attempts, defaults to ``$interval/4``
- ``verify_ssl``: whether SSL verification must be performed or not, defaults to ``1``
- ``shared_secret``: shared secret, needed for `Automatic registration`_
- ``consistent_key``: whether `Consistent key generation`_ is enabled or not, defaults to ``1``
- ``merge_config``: whether `Merge configuration`_ is enabled or not, defaults to ``1``
- ``tags``: template tags to use during registration, multiple tags separated by space can be used,
  for more information see `Template Tags <https://openwisp.io/docs/user/templates.html#template-tags>`_
- ``test_config``: whether a new configuration must be tested before being considered applied, defaults to ``1``
- ``test_retries``: maximum number of retries when doing the default configuration test, defaults to ``3``
- ``test_script``: custom test script, read more about this feature in `Configuration test`_
- ``uuid``: unique identifier of the router configuration in the controller application
- ``key``: key required to download the configuration
- ``hardware_id_script``: custom script to read out a hardware id (e.g. a serial number), read more about this feature in `Hardware ID`_
- ``hardware_id_key``: whether to use the hardware id for key generation or not, defaults to ``1``
- ``bootup_delay``: maximum value in seconds of a random delay after bootup, defaults to ``0``, see `Bootup Delay`_
- ``unmanaged``: list of config sections which won't be overwritten, see `Unmanaged Configurations`_
- ``capath``: value passed to curl ``--capath`` argument, by default is empty; see also `curl capath argument <https://curl.haxx.se/docs/manpage.html#--capath>`_
- ``cacert``: value passed to curl ``--cacert`` argument, by default is empty; see also `curl cacert argument <https://curl.haxx.se/docs/manpage.html#--cacert>`_
- ``connect_timeout``: value passed to curl ``--connect-timeout`` argument, defaults to ``15``; see `curl connect-timeout argument <https://curl.haxx.se/docs/manpage.html#--connect-timeout>`__
- ``max_time``: value passed to curl ``--max-time`` argument, defaults to ``30``; see `curl max-time argument <https://curl.haxx.se/docs/manpage.html#-m>`__
- ``mac_interface``: the interface from which the MAC address is taken when performing automatic registration, defaults to ``eth0``
- ``management_interface``: management interface name (both openwrt UCI names and
  linux interface names are supported), it's used to collect the management interface ip address
- ``default_hostname``: if your firmware has a custom default hostname, you can use this configuration
  option so the agent can recognize it during registration and replicate the standard behavior
  (new device will be named after its mac address, to avoid having many new devices with the same name)
- ``pre_reload_hook``: path to custom executable script, see `pre-reload-hook`_
- ``post_reload_hook``: path to custom executable script, see `post-reload-hook`_
- ``post_reload_delay``: delay in seconds to wait before the post-reload-hook and any configuration test, defaults to ``5``
- ``post_registration_hook``: path to custom executable script, see `post-registration-hook`_
- ``respawn_threshold``: time in seconds used as procd respawn threshold, defaults to ``3600``
- ``respawn_timeout``: time in seconds used as procd respawn timeout, defaults to ``5``
- ``respawn_retry``: number of procd respawn retries (use ``0`` for infinity), defaults to ``5``

Automatic registration
----------------------

When the agent starts, if both ``uuid`` and ``key`` are not defined, it will consider
the router to be unregistered and it will attempt to perform an automatic registration.

The automatic registration is performed only if ``shared_secret`` is correctly set.

The device will choose as name one of its mac addresses, unless its hostname is not ``OpenWrt``,
in the latter case it will simply register itself with the current hostname.

When the registration is completed, the agent will automatically set ``uuid`` and ``key``
in ``/etc/config/openwisp``.

To enable this feature by default on your firmware images, follow the procedure described in
`Compiling a custom OpenWRT image`_.

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

* less boilerplate configuration stored in the remote controller
* local users can change local configurations without fear of losing their changes

It is possible to turn this feature off by setting ``merge_config`` to ``0`` in ``/etc/config/openwisp``.

**Details about the merging behavior**:

* if a configuration option or list is present both in the remote configuration
  and in the local configuration, the remote configurations will overwrite the local ones
* configuration options that are present in the local configuration but are not present
  in the remote configuration will be retained
* configuration files that were present in the local configuration and are replaced
  by the remote configuration are backed up and eventually restored if the modifications
  are removed from the controller

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

Hardware ID
-----------

It is possible to use a unique hardware id for device identification, for example a serial number.

If ``hardware_id_script`` contains the path to an executable script, it will be used to read out the hardware
id from the device. The hardware id will then be sent to the controller when the device is registered.

If the above configuration option is set then the hardware id will also be used for generating the device key,
instead of the mac address. If you use a hardware id script but prefer to use the mac address for key
generation then set ``hardware_id_key`` to ``0``.

See also the `related hardware ID settings in OpenWISP Controller
<https://github.com/openwisp/openwisp-controller/#openwisp-controller-hardware-id-enabled>`_.

Bootup Delay
------------

The option ``bootup_delay`` can be used to make the agent wait for a random amount of seconds after the bootup of
the device. Allowed random values range from 0 up to the value of ``bootup_delay``. The delay is applied only after the
device has been registered.

The random bootup delay reduces the load on the OpenWISP controller when a large amount of devices boot up at the
same time after a power failure, all trying to connect to the controller.

Unmanaged Configurations
------------------------

In some cases it could be necessary to ensure that some configuration sections won't be
overwritten by the controller.

These settings are called "unmanaged", in the sense that they are not managed remotely.
In the default configuration of *openwisp_config* there are no unmanaged settings.

Example unmanaged settings::

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

Hooks
-----

Below are described the available hooks in *openwisp-config*.

pre-reload-hook
^^^^^^^^^^^^^^^

Defaults to ``/etc/openwisp/pre-reload-hook``; the hook is not called if the
path does not point to an executable script file.

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

post-reload-hook
^^^^^^^^^^^^^^^^

Defaults to ``/etc/openwisp/post-reload-hook``; the hook is not called if the
path does not point to an executable script file.

Same as `pre_reload_hook` but with the difference that this hook is called
after the configuration services have been reloaded.

post-registration-hook
^^^^^^^^^^^^^^^^^^^^^^

Defaults to ``/etc/openwisp/post-registration-hook``;

Path to an executable script that will be called after the registration is completed.

Compiling openwisp-config
-------------------------

The following procedure illustrates how to compile *openwisp-config* and its dependencies:

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

Alternatively, you can configure your build interactively with ``make menuconfig``, in this case
you will need to select *openwisp-config* by going to ``Administration > openwisp``:

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

Compiling a custom OpenWRT image
--------------------------------

If you are managing many devices and customizing your ``openwisp-config`` configuration by hand on
each new device, you should switch to using a custom OpenWRT firmware image that includes
``openwisp-config`` and its precompiled configuration file, this strategy has a few important benefits:

* you can save yourself the effort of installing and configuring ``openwisp-config`` on each device
* you can enable `Automatic registration`_ by setting ``shared_secret``,
  hence saving extra time and effort to register each device on the controller app
* if you happen to reset the firmware to initial settings, these precompiled settings will be restored as well

The following procedure illustrates how to compile a custom `OpenWRT <https://openwrt.org/>`_
image with a precompiled minimal ``/etc/config/openwisp`` configuration file:

.. code-block:: shell

    git clone https://github.com/openwrt/openwrt.git openwrt
    cd openwrt
    git checkout <openwrt-branch>

    # include precompiled file
    mkdir -p files/etc/config
    cat <<EOF > files/etc/config/openwisp
    config controller 'http'
        # change the values of the following 2 options
        option url 'https://openwisp2.mydomain.com'
        option shared_secret 'mysharedsecret'
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

Quality Assurance Checks
------------------------

We use `LuaFormatter <https://luarocks.org/modules/tammela/luaformatter>`_ and
`shfmt <https://github.com/mvdan/sh#shfmt>`_ to format lua files and shell scripts respectively.

First of all, you will need install the lua packages mentioned above, then you can format all files with::

    ./qa-format

To run quality assurance checks you can use the ``run-qa-checks`` script::

    # install openwisp-utils QA tools first
    pip install openwisp-utils[qa]

    # run QA checks before committing code
    ./run-qa-checks

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

Contributing
------------

Please read the `OpenWISP contributing guidelines
<http://openwisp.io/docs/developer/contributing.html>`_.

Changelog
---------

See `CHANGELOG <https://github.com/openwisp/openwisp-config/blob/master/CHANGELOG.rst>`_.

License
-------

See `LICENSE <https://github.com/openwisp/openwisp-config/blob/master/LICENSE>`_.

Support
-------

See `OpenWISP Support Channels <http://openwisp.org/support.html>`_.
