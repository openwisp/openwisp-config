Quick Start Guide
=================

To install the Config Agent on your OpenWrt system, follow these steps:

Download and install the latest build from `downloads.openwisp.io
<http://downloads.openwisp.io/?prefix=openwisp-config/>`_. Copy the URL of
the IPK file you want to download, then run the following commands on your
OpenWrt device:

.. code-block:: bash

    cd /tmp  # /tmp runs in memory
    wget <URL-just-copied>
    opkg update
    opkg install ./<file-just-downloaded>

Replace ``<URL-just-copied>`` with the URL of the package from
`downloads.openwisp.io
<http://downloads.openwisp.io/?prefix=openwisp-config/>`_.

You can also install from the official OpenWrt packages:

.. code-block:: bash

    opkg update
    opkg install openwisp-config

.. important::

    **We recommend installing from our latest builds** because the OpenWrt
    packages are not always up to date.

Once the config agent is installed, you need to configure it. Edit the
config file located at ``/etc/config/openwisp``.

You will see the default config file, as shown below.

.. code-block:: text

    # For more information about the config options please see the README
    # or https://openwisp.io/docs/dev/openwrt-config-agent/user/settings.html

    config controller 'http'
        #option url 'https://openwisp2.mynetwork.com'
        #option interval '120'
        #option verify_ssl '1'
        #option shared_secret ''
        #option consistent_key '1'
        #option mac_interface 'eth0'
        #option management_interface 'tun0'
        #option merge_config '1'
        #option test_config '1'
        #option test_script '/usr/sbin/mytest'
        #option hardware_id_script '/usr/sbin/read_hw_id'
        #option hardware_id_key '1'
        option uuid ''
        option key ''
        # curl options
        #option connect_timeout '15'
        #option max_time '30'
        #option capath '/etc/ssl/certs'
        #option cacert '/etc/ssl/certs/ca-certificates.crt'
        # hooks
        #option pre_reload_hook '/usr/sbin/my_pre_reload_hook'
        #option post_reload_hook '/usr/sbin/my_post_reload_hook'

Uncomment and change the following fields:

- ``url``: the hostname of your OpenWISP controller. For example, if you
  are hosting your OpenWISP server locally and set the IP Address to
  "192.168.56.2", the URL would be ``https://192.168.56.2``.
- ``verify_ssl``: set to ``'0'`` if your controller's SSL certificate is
  self-signed; in production, you need a valid SSL certificate to keep
  your instance secure.
- ``shared_secret``: you can retrieve this from the OpenWISP admin panel,
  in the Organization settings. The list of organizations is available at
  ``/admin/openwisp_users/organization/``.
- ``management_interface``: this is the interface which OpenWISP uses to
  reach the device. Please refer to :doc:`/user/vpn` for more information.

.. note::

    When testing or developing using the Django development server
    directly from your computer, make sure the server listens on all
    interfaces (``./manage.py runserver 0.0.0.0:8000``) and then just
    point OpenWISP Config to use your local IP address (e.g.,
    ``http://192.168.1.34:8000``).

Save the file and start openwisp-config:

.. code-block:: bash

    /etc/init.d/openwisp-config restart

Your OpenWrt device should register itself to your OpenWISP controller.
Check the devices page in the OpenWISP admin dashboard to make sure your
device has registered successfully.

.. seealso::

    - For troubleshooting and debugging, refer to :doc:`debugging`.
    - To learn more about the configuration options of the config agent,
      refer to :doc:`settings`.
    - For instructions on how to compile the package, refer to
      :doc:`compiling`.
    - Read about the complementary :doc:`Monitoring Agent
      </openwrt-monitoring-agent/index>`.
