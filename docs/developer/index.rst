Install precompiled package
===========================

First run:

.. code-block:: shell

    opkg update

Then install one of the `latest builds
<https://downloads.openwisp.io/?prefix=openwisp-config/latest/>`_:

.. code-block:: shell

    opkg install <URL>

Where ``<URL>`` is the URL of the precompiled openwisp-config package.

For a list of the latest built images, take a look at
`downloads.openwisp.io/?prefix=openwisp-config/
<https://downloads.openwisp.io/?prefix=openwisp-config/>`_.

**If you need to compile the package yourself**, see
doc:`Compiling openwisp-config`_ and `Compiling a custom OpenWRT image`_.

Once installed *openwisp-config* needs to be configured (see
`Configuration options`_) and then started with:

.. code-block::

    /etc/init.d/openwisp-config start

To ensure the agent is working correctly find out how to perform debugging
in the Debugging_ section.
