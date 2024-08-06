Hotplug Events
==============

The agent sends the following `Hotplug events
<https://openwrt.org/docs/guide-user/base-system/hotplug>`_:

- After the registration is successfully completed: ``post-registration``
- After the registration failed: ``registration-failed``
- When the agent first starts after the booting process: ``bootup``
- After any subsequent restart: ``restart``
- After the configuration has been successfully applied:
  ``config-applied``
- After the previous configuration has been restored: ``config-restored``
- Before services are reloaded: ``pre-reload``
- After services have been reloaded: ``post-reload``
- After the agent has finished its check cycle, before going to sleep:
  ``end-of-cycle``

If a hotplug event is sent by *openwisp-config* then all scripts existing
in ``/etc/hotplug.d/openwisp/`` will be executed. In scripts the type of
event is visible in the variable ``$ACTION``. For example, a script to log
the hotplug events, ``/etc/hotplug.d/openwisp/01_log_events``, could look
like this:

.. code-block:: shell

    #!/bin/sh

    logger "openwisp-config sent a hotplug event. Action: $ACTION"

It will create log entries like this:

.. code-block:: text

    Wed Jun 22 06:15:17 2022 user.notice root: openwisp-config sent a hotplug event. Action: registration-failed

For more information on using these events refer to the `Hotplug Events
OpenWrt Documentation
<https://openwrt.org/docs/guide-user/base-system/hotplug>`_.
