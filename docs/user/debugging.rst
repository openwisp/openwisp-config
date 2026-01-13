Debugging
=========

Debugging *openwisp-config* can be easily done by using the ``logread``
command:

.. code-block:: shell

    logread

Use grep to filter out any other log message:

.. code-block:: shell

    logread | grep openwisp

If you are in doubt openwisp-config is running at all, you can check with:

.. code-block:: shell

    ps | grep openwisp

You should see something like:

.. code-block:: text

    3800 root      1200 S    {openwisp-config} /bin/sh /usr/sbin/openwisp-config --url https://demo.openwisp.io --verify-ssl 1 --consistent-key 1 ...

You can inspect the version of openwisp-config currently installed with:

.. code-block:: shell

    openwisp-config --version

Forcing Configuration Update
----------------------------

You can force openwisp-config to immediately download and apply the latest
configuration from the controller using the ``--force-update`` option:

.. code-block:: shell

    openwisp-config --force-update

This command checks if the openwisp-config agent is running and sends a
SIGUSR2 signal to trigger an immediate configuration update. If the agent
is not running, the command will exit with an error.

Alternatively, you can manually send the SIGUSR2 signal to the agent
process:

.. code-block:: shell

    kill -USR2 "$(pgrep -P 1 -f openwisp-config)"

This is useful when you need to:

- Force the device to fetch the latest configuration without waiting for
  the next polling interval
- Apply configuration changes immediately after making updates in OpenWISP
  Controller
- Troubleshoot configuration synchronization issues
