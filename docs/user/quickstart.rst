Quickstart
==========

Install Precompiled Package
---------------------------

To install openwisp-config on your OpenWRT system follow the steps below:

Install one of the latest stable builds from `downloads.openwisp.io
<http://downloads.openwisp.io/?prefix=openwisp-config/>`_, copy the URL of
the IPK file you want to download onto your clipboard, then run the
following commands on your OpenWrt device:

.. code-block:: bash

    cd /tmp  # /tmp runs in memory
    wget <URL-you-just-copied>
    opkg update
    opkg install ./<file-just-downloaded>

If you're running at least OpenWRT 19.07, you can install openwisp-config
from the official OpenWRT packages:

.. code-block:: bash

    opkg update
    opkg install openwisp-config

**We recommend installing from our latest builds or compiling your own
firmware image** as the OpenWrt packages are not always up to date.

**If you need to compile the package yourself**, see
ref:`compiling_openwisp_config` and :doc:`compiling`.

Once installed, *openwisp-config* needs to be configured (see
:doc:`Configuration options <settings>`). Start the agent with the
following command:

.. code-block::

    /etc/init.d/openwisp-config start

For troubleshooting and debugging, refer to the :doc:`debugging` section.
