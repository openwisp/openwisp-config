Settings
========

.. contents:: **Table of Contents**:
    :depth: 2
    :local:

.. _openwrt_config_agent_configuration_options:

Configuration Options
---------------------

UCI configuration options must go in ``/etc/config/openwisp``.

- ``url``: url of controller, eg: ``https://demo.openwisp.io``
- ``interval``: time in seconds between checks for changes to the
  configuration, defaults to ``120``
- ``management_interval``: time in seconds between the management ip
  discovery attempts, defaults to ``$interval/12``
- ``registration_interval``: time in seconds between the registration
  attempts, defaults to ``$interval/4``
- ``verify_ssl``: whether SSL verification must be performed or not,
  defaults to ``1``
- ``shared_secret``: shared secret, needed for
  :doc:`automatic-registration`
- ``consistent_key``: whether :ref:`config_consistent_key_generation` is
  enabled or not, defaults to ``1``
- ``merge_config``: whether :ref:`config_merge_configuration` is enabled
  or not, defaults to ``1``
- ``tags``: template tags to use during registration, multiple tags
  separated by space can be used, for more information see :ref:`Template
  Tags <templates_tags>`
- ``test_config``: whether a new configuration must be tested before being
  considered applied, defaults to ``1``
- ``test_retries``: maximum number of retries when doing the default
  configuration test, defaults to ``3``
- ``test_script``: custom test script, read more about this feature in
  :ref:`config_configuration_test`
- ``uuid``: unique identifier of the router configuration in the
  controller application
- ``key``: key required to download the configuration
- ``hardware_id_script``: custom script to read out a hardware id (e.g. a
  serial number), read more about this feature in
  :ref:`config_hardware_id`
- ``hardware_id_key``: whether to use the hardware id for key generation
  or not, defaults to ``1``
- ``bootup_delay``: maximum value in seconds of a random delay after
  bootup, defaults to ``10``, see :ref:`config_bootup_delay`
- ``unmanaged``: list of config sections which won't be overwritten, see
  :ref:`config_unmanaged_configuration`
- ``capath``: value passed to curl ``--capath`` argument, by default is
  empty; see also `curl capath argument
  <https://curl.haxx.se/docs/manpage.html#--capath>`_
- ``cacert``: value passed to curl ``--cacert`` argument, by default is
  empty; see also `curl cacert argument
  <https://curl.haxx.se/docs/manpage.html#--cacert>`_
- ``connect_timeout``: value passed to curl ``--connect-timeout``
  argument, defaults to ``15``; see `curl connect-timeout argument
  <https://curl.haxx.se/docs/manpage.html#--connect-timeout>`__
- ``max_time``: value passed to curl ``--max-time`` argument, defaults to
  ``30``; see `curl max-time argument
  <https://curl.haxx.se/docs/manpage.html#-m>`__
- ``mac_interface``: the interface from which the MAC address is taken
  when performing automatic registration, defaults to ``eth0``
- ``management_interface``: management interface name (both openwrt UCI
  names and linux interface names are supported), it's used to collect the
  management interface ip address and send this information to the
  OpenWISP server, for more information please read :ref:`how to make sure
  OpenWISP can reach your devices <openwisp_reach_devices>`
- ``default_hostname``: if your firmware has a custom default hostname,
  you can use this configuration option so the agent can recognize it
  during registration and replicate the standard behavior (new device will
  be named after its mac address, to avoid having many new devices with
  the same name), the possible options are to either set this to the value
  of the default hostname used by your firmware, or set it to ``*`` to
  always force to register new devices using their mac address as their
  name (this last option is useful if you have a firmware which can work
  on different hardware models and each model has a different default
  hostname)
- ``pre_reload_hook``: path to custom executable script, see
  :ref:`config_pre_reload_hook`
- ``post_reload_hook``: path to custom executable script, see
  :ref:`config_post_reload_hook`
- ``post_reload_delay``: delay in seconds to wait before the
  post-reload-hook and any configuration test, defaults to ``5``
- ``post_registration_hook``: path to custom executable script, see
  :ref:`config_post_registration_hook`
- ``respawn_threshold``: time in seconds used as procd respawn threshold,
  defaults to ``3600``
- ``respawn_timeout``: time in seconds used as procd respawn timeout,
  defaults to ``5``
- ``respawn_retry``: number of procd respawn retries (use ``0`` for
  infinity), defaults to ``5``
- ``checksum_max_retries``: maximum number of retries for checksum
  requests which fail with 404, defaults to ``5``, after these failures
  the agent will assume the device has been deleted from OpenWISP
  Controller and will exit; please keep in mind that due to
  ``respawn_retry``, procd will try to respawn the agent after it exits,
  so the total number of attempts which will be tried has to be calculated
  as: ``checksum_max_retries * respawn_retry``
- ``checksum_retry_delay``: time in seconds between retries, defaults to
  ``6``

.. _config_merge_configuration:

Merge Configuration
-------------------

By default the remote configuration is merged with the local one. This has
several advantages:

- less boilerplate configuration stored in the remote controller
- local users can change local configurations without fear of losing their
  changes

It is possible to turn this feature off by setting ``merge_config`` to
``0`` in ``/etc/config/openwisp``.

**Details about the merging behavior**:

- if a configuration option or list is present both in the remote
  configuration and in the local configuration, the remote configurations
  will overwrite the local ones
- configuration options that are present in the local configuration but
  are not present in the remote configuration will be retained
- configuration files that were present in the local configuration and are
  replaced by the remote configuration are backed up and eventually
  restored if the modifications are removed from the controller

.. _config_configuration_test:

Configuration Test
------------------

When a new configuration is downloaded, the agent will first backup the
current running configuration, then it will try to apply the new one and
perform a basic test, which consists in trying to contact the controller
again;

If the test succeeds, the configuration is considered applied and the
backup is deleted.

If the test fails, the backup is restored and the agent will log the
failure via syslog (see :doc:`debugging` for more information on auditing
logs).

Disable Testing
~~~~~~~~~~~~~~~

To disable this feature, set the ``test_config`` option to ``0``, then
reload/restart *openwisp-config*.

Define Custom Tests
~~~~~~~~~~~~~~~~~~~

If the default test does not satisfy your needs, you can define your own
tests in an **executable** script and indicate the path to this script in
the ``test_script`` config option.

If the exit code of the executable script is higher than ``0`` the test
will be considered failed.

.. _config_hardware_id:

Hardware ID
-----------

It is possible to use a unique hardware id for device identification, for
example a serial number.

If ``hardware_id_script`` contains the path to an executable script, it
will be used to read out the hardware id from the device. The hardware id
will then be sent to the controller when the device is registered.

If the above configuration option is set then the hardware id will also be
used for generating the device key, instead of the mac address. If you use
a hardware id script but prefer to use the mac address for key generation
then set ``hardware_id_key`` to ``0``.

See also the :ref:`related hardware ID settings in OpenWISP Controller
<openwisp_controller_hardware_id_enabled>`.

.. _config_bootup_delay:

Bootup Delay
------------

The option ``bootup_delay`` is used to delay the initialization of the
agent for a random amount of seconds after the device boots.

The value specified in this option represents the maximum value of the
range of possible random values, the minimum value being ``0``.

The default value of this option is 10, meaning that the initialization of
the agent will be delayed for a random number of seconds, this random
number being comprised between ``0`` and ``10``.

This feature is used to spread the load on the OpenWISP server when a
large amount of devices boot up at the same time after a blackout.

Large OpenWISP installations may want to increase this value.

.. _config_hooks:

Hooks
-----

.. warning::

    Hooks are deprecated in favour of
    :doc:`Hotplug events <hotplug-events>`.

Below are described the available hooks in *openwisp-config*.

.. _config_pre_reload_hook:

``pre-reload-hook``
~~~~~~~~~~~~~~~~~~~

Defaults to ``/etc/openwisp/pre-reload-hook``; the hook is not called if
the path does not point to an executable script file.

This hook is called each time *openwisp-config* applies a configuration,
but **before services are reloaded**, more precisely in these situations:

- after a new remote configuration is downloaded and applied
- after a configuration test failed (see :ref:`config_configuration_test`)
  and a previous backup is restored

You can use this hook to perform custom actions before services are
reloaded, eg: to perform auto-configuration with `LibreMesh
<http://libre-mesh.org/>`_.

Example configuration:

.. code-block::

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
    # reload openwisp-config by using procd's convenient utility
    reload_config

.. _config_post_reload_hook:

``post-reload-hook``
~~~~~~~~~~~~~~~~~~~~

Defaults to ``/etc/openwisp/post-reload-hook``; the hook is not called if
the path does not point to an executable script file.

Same as `pre_reload_hook` but with the difference that this hook is called
after the configuration services have been reloaded.

.. _config_post_registration_hook:

``post-registration-hook``
~~~~~~~~~~~~~~~~~~~~~~~~~~

Defaults to ``/etc/openwisp/post-registration-hook``;

Path to an executable script that will be called after the registration is
completed.

.. _config_unmanaged_configuration:

Unmanaged Configurations
------------------------

In some cases it could be necessary to ensure that some configuration
sections won't be overwritten by the controller.

These settings are called "unmanaged", in the sense that they are not
managed remotely. In the default configuration of *openwisp-config* there
are no unmanaged settings.

Example unmanaged settings:

.. code-block::

    config controller 'http'
            ...
            list unmanaged 'system.@led'
            list unmanaged 'network.loopback'
            list unmanaged 'network.@switch'
            list unmanaged 'network.@switch_vlan'
            ...

Note the lines with the `@` sign; this syntax means any UCI section of the
specified type will be unmanaged.

In the previous example, the loopback interface, all ``led settings``, all
``switch`` and ``switch_vlan`` directives will never be overwritten by the
remote configuration and will only be editable via SSH or via the web
interface.
