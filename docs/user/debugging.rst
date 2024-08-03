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
