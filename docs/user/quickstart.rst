Install precompiled package
===========================

To install openwisp-config on your OpenWRT system follow the steps below:

Install one of the latest stable builds from
`downloads.openwisp.io <http://downloads.openwisp.io/?prefix=openwisp-config/>`_,
copy the URL of the IPK file you want to download onto your
clipboard, then run the following commands on your OpenWrt device:

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

**If you need to compile the package yourself**, see `Compiling
openwisp-config`_ and `Compiling a custom OpenWRT image`_.

Once installed *openwisp-config* needs to be configured (see
`Configuration options`_) and then started with:

.. code-block::

    /etc/init.d/openwisp-config start

To ensure the agent is working correctly find out how to perform debugging
in the Debugging_ section.
