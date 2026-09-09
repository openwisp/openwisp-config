Quick Start Guide
=================

Install the Config Agent on your OpenWrt system with:

.. code-block:: shell

    # OpenWrt >= 25.12
    apk update
    apk add openwisp-config

    # OpenWrt <= 24.10
    opkg update
    opkg install openwisp-config

Development Builds
------------------

If you need an unreleased feature or bug fix, try the development version
from `downloads.openwisp.io <https://downloads.openwisp.io/>`_. It
provides APK packages built by our continuous integration. Before
installing one, add the OpenWISP public key to the APK keyring:

.. code-block:: shell

    cat > /etc/apk/keys/openwisp-config.pem <<'EOF'
    -----BEGIN PUBLIC KEY-----
    MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEYhhsie+759Mk34fJso4cDHVeLNeE
    277qiiRySdHKYQNx8KV1RGd1ynm+5m+Z3RUl1BMYAAqi8Tip1+6q+DgEiQ==
    -----END PUBLIC KEY-----
    EOF

Then download the ``openwisp-config`` APK from `the latest build
<https://downloads.openwisp.io/?prefix=openwisp-config/latest/>`_ and
install it. ``apk`` verifies its signature with the installed public key.

.. code-block:: shell

    apk add /tmp/openwisp-config_*.apk

Once the config agent is installed, you need to configure it. Edit the
config file located at ``/etc/config/openwisp``.

You will see the default config file, as shown below.

.. code-block:: text

    # For more information about the config options please see the README
    # or https://openwisp.io/docs/stable/openwrt-config-agent/user/settings.html

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
