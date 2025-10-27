Change log
==========

1.2.0 [2025-10-27]
------------------

Features
~~~~~~~~

- Added hotplug script for ``management_interface`` to automatically
  update the management IP when the interface comes up `#208
  <https://github.com/openwisp/openwisp-config/issues/208>`_.

Changes
~~~~~~~

Other changes
+++++++++++++

- Added random wait time between 5 and 20 seconds before retrying default
  tests after failure to reduce simultaneous retries and improve
  reliability.
- Increased default ``test_retries`` to 10 for improved connection
  stability.

Bugfixes
~~~~~~~~

- Added IPv6 support to ``openwisp-get-address`` `#224
  <https://github.com/openwisp/openwisp-config/issues/224>`_.

1.1.0 [2024-09-25]
------------------

Features
~~~~~~~~

- Added the ``default_hostname`` option to force devices to register using
  their MAC address instead of their hostname.
- Added support for `hotplug events
  <https://openwisp.io/docs/stable/openwrt-config-agent/user/hotplug-events.html>`_.
- Added error reporting functionality, which sends error logs to the
  controller if the agent fails to apply a configuration update.
- Implemented a retry mechanism with random backoff for essential
  operations, including retrieving checksums and downloading
  configurations from the controller, as well as reporting error statuses.

Changes
~~~~~~~

Backward incompatible changes
+++++++++++++++++++++++++++++

- Renamed ``/etc/init.d/openwisp_config`` to
  ``/etc/init.d/openwisp_config``.

Deprecations
++++++++++++

- Deprecated ``/usr/sbin/openwisp_config`` in favor of
  ``/usr/sbin/openwisp-config`` to maintain consistency with other files
  in the package. The path ``/usr/sbin/openwisp_config`` is now a symbolic
  link to ``/usr/sbin/openwisp-config``.
- Deprecated `hooks
  <https://openwisp.io/docs/stable/openwrt-config-agent/user/settings.html#hooks>`_
  in favor of `hotplug events
  <https://openwisp.io/docs/stable/openwrt-config-agent/user/hotplug-events.html>`_.

Other changes
+++++++++++++

- Updated logging to capture errors from ``openwisp-update-config`` in
  ``logd``.
- Changed the default ``bootup_delay`` to ``10`` seconds.
- Changed the auto-naming of ``network.device`` objects to make it
  consistent with OpenWISP.

Bugfixes
~~~~~~~~

- Ensured full backup of default UCI files to prevent the loss of
  configuration.
- Preserved persistent data directories across system upgrades.
- Fixed a registration bug where the agent failed to automatically fall
  back to the first non-loopback interface when the configured
  ``mac_interface`` was not present.
- Fixed backup process to include all modified files in the backup to
  ensure no changes are omitted.
- Resolved issues in post-installation and removal scripts in the
  ``Makefile``, ensuring proper execution during image building.

1.0.1 [2022-06-21]
------------------

- Fixed addition of new UCI files which were not previously already
  present on the file system

1.0.0 [2022-05-10]
------------------

Features
~~~~~~~~

- The SIGUSR1 signal can be now used to interrupt the interval sleep and
  check for configuration changes again
- Made the procd respawn parameters configurable
- The agent now stores the any UCI configuration which is overwritten by
  OpenWISP with the goal of restoring it if the piece of configuration
  overwritten by OpenWISP is removed
- Added ``management_interval`` and ``registration_interval`` options

Changes
~~~~~~~

Backward incompatible changes
+++++++++++++++++++++++++++++

- Remove unneeded SSL package implementation definitions

Other changes
+++++++++++++

- Made configuration checksum persistent to fix 2 problems:

  1. If the openwisp-config daemon is restarted (e.g. by the openwisp-
     controller via ssh) after it already downloaded the latest checksum
     but before it has applied the configuration, all further calls of
     configuration_changed() (until CONFIGURATION_CHECKSUM is deleted,
     e.g. by a reboot) will imply that everything is already up-to-date,
     although the configuration was never applied
  2. prevents the configuration from being downloaded and written again
     after a reboot

- Do not wait for management interface during registration: If
  openwisp-config is not registered yet, do not wait for the management
  interface to be ready because we can assume the management interface
  configuration is not present yet
- Increased report status retries: in some cases the report status
  operation may fail because the network reload could take a few minutes
  to complete (e.g.: in mesh networks scenarios) and therefore the agent
  must be a bit more patient before giving up
- Refactored init script to make it more consistent with the best
  practices used in the OpenWrt community
- If the agent receives 404 response from the server when downloading the
  configuration checksum, after the number of attempts specified in
  ``checksum_max_retries`` fail, the agent assumes the device has been
  deleted from OpenWISP and exits

Bugfixes
~~~~~~~~

- Use configured curl timeout values in default configuration test;
  Without this fix, it's possible that the configuration test fails while
  the regular checksum fetch succeeds
- Ensured config download error is detected: adding the ``--fail`` flag to
  curl makes it exit with a non zero exit code in case the server respond
  with an HTTP status code which is not 200 OK, without this fix, a bad
  response is interpreted as a valid configuration and the agent removes
  the old configuration, then installs the new configuration, which fails
  and the router remains with an empty configuration, effectively causing
  a disruption of service
- Fixed post-registration-hook logging line which was mistakenly
  mentioning ``post-reload-hook`` instead of ``post-registration-hook``
- Fixed service reload handling for unnamed uci sections: the openwisp
  agent modifies the configuration on first contact by rewriting all
  anonymous UCI sections into named UCI sections. This causes almost all
  services to be restarted even though the configuration has not really
  changed. To prevent this from happening, the md5sums are rewritten after
  calling ``openwisp-uci-autoname``; this will reload only those services
  whose configuration has actually been changed
- Remove ``applying_conf`` control file after status report: without this
  fix, the agent may be reloaded before the status is reported to OpenWISP
  Controller, leaving the device in "modified" config status even though
  the configuration has been already applied
- Fixed HTTP response codes on newer cURL versions
- Handled agent crashes when registration is not successful
- Verify downloaded tarball against the configuration checksum
- Fixed a bug in the ``bootup_delay`` feature which caused it to not work
  unless an extra dependency was being used; the need on the extra
  undocumented dependency has been eliminated
- Fixed unhandled naming conflicts when anonymous configuration are
  renamed via the ``openwisp-uci-autoname`` script

0.5.0 [2020-12-20]
------------------

Features
~~~~~~~~

- Added support for `Template Tags
  <https://openwisp.io/docs/user/templates.html#template-tags>`_
- Send hardware and software information (hardware model, operating
  system, soc) during registration and boot (too keep it up to date)
- Added `post-reload-hook
  <https://github.com/openwisp/openwisp-config/#post-reload-hook>`_ and
  `post-registration-hook
  <https://github.com/openwisp/openwisp-config/#post-registration-hook>`_
- Added ``management_interface`` `config option
  <https://github.com/openwisp/openwisp-config/#configuration-options>`_,
  which allows sending the IP of the management interface to OpenWISP, a
  pre-requisite for enabling features of OpenWISP as `push updates
  <https://openwisp.io/docs/user/configure-push-updates.html>`_, `firmware
  upgrades
  <https://github.com/openwisp/openwisp-firmware-upgrader#openwisp-firmware-upgrader>`_
  and `fping <https://github.com/openwisp/openwisp-monitoring/#ping>`_
  health checks
- Added support for `hardware ID / serial number
  <https://github.com/openwisp/openwisp-config/#hardware-id>`_
- Added random `bootup delay
  <https://github.com/openwisp/openwisp-config/#bootup-delay>`_
- Added ``default_hostname`` `config option
  <https://github.com/openwisp/openwisp-config/#configuration-options>`_
- Improved automatic recovery of previous backups when configuration
  updates fail
- Added ``post_reload_delay`` and ``test_retries`` `config options
  <https://github.com/openwisp/openwisp-config/#configuration-options>`_

Changes
~~~~~~~

- **Backward incompatible change**: list options are now overwritten to
  prevent duplication
- Improved log message in case of registration failure
- Allow ``$MAC_ADDRESS`` to be bridge
- Removed polarssl
- Check sanity of downloaded UCI files before applying them
- Give up with registration only when 403 is returned by the server
- Show entire registration error message in logs
- Updated examples and precompiled packages to use OpenWrt 19.07
- Made check of OpenWISP Controller header case insensitve

Bugfixes
~~~~~~~~

- Ensured order of UCI sections is preserved during config write
  operations, handle special section types
- Ensure anonymous UCI config sections are handled well
- Ensure removal of files only includes items which are not in the new
  downloaded configuration
- Fixed duplication of list options
- Fixed a bug that caused ``/etc/config/openwisp`` to be overwritten

0.4.5 [2017-03-03]
------------------

- `ade89b2 <https://github.com/openwisp/openwisp-config/commit/ade89b2>`_:
  made default hostname check case insensitive
- `#26 <https://github.com/openwisp/openwisp-config/issues/26>`_: added
  pre-reload-hook

0.4.4 [2017-03-02]
------------------

- `57e431f <https://github.com/openwisp/openwisp-config/commit/57e431f>`_:
  [makefile] added ``PKGARCH:=all`` in order to compile an architecture
  indipendent package
- `35067c8 <https://github.com/openwisp/openwisp-config/commit/35067c8>`_:
  [docs] default compile instructions to to `LEDE
  <https://lede-project.org/>`_ 17.01

0.4.3 [2017-03-01]
------------------

- `6bbbc75 <https://github.com/openwisp/openwisp-config/commit/6bbbc75>`_:
  Adapted ``openwisp-remove-default-wifi`` script to work on LEDE 17.01

0.4.2 [2017-02-14]
------------------

- `3e89fd6 <https://github.com/openwisp/openwisp-config/commit/3e89fd6>`_:
  [openwisp-reload-config] Removed ``local`` declarations
- `13bc735 <https://github.com/openwisp/openwisp-config/commit/13bc735>`_:
  [agent] Improved log messages
- `6955d5b <https://github.com/openwisp/openwisp-config/commit/6955d5b>`_:
  [reload-config] Reintroduced ``init.d`` check
- `7c4cb8b <https://github.com/openwisp/openwisp-config/commit/7c4cb8b>`_:
  [agent] Improved 2 more connection failure messages
- `#25 <https://github.com/openwisp/openwisp-config/issues/25>`_:
  [Makefile] Added openwisp-config-mbedtls
- [docs]: several documentation improvements regarding compilation and
  relation with other openwisp2 modules

0.4.1 [2016-09-22]
------------------

- `5cdb8fa <https://github.com/openwisp/openwisp-config/commit/5cdb8fa>`_:
  [autoname] avoid failure if UCI files are empty
- `#24 <https://github.com/openwisp/openwisp-config/pull/24>`_: added
  ``mac_interface`` option, defaults to ``eth0`` (thanks to `@agabellini
  <https://github.com/agabellini>`_)
- `b09a497 <https://github.com/openwisp/openwisp-config/commit/b09a497>`_:
  [registration] send ``mac_address`` parameter to openwisp2 controller
- `e8f0b35 <https://github.com/openwisp/openwisp-config/commit/e8f0b35>`_:
  [reload-config] log which services have been reloaded

0.4.0 [2016-06-23]
------------------

- `#16 <https://github.com/openwisp/openwisp-config/issues/16>`_: added
  "Unmanaged Configurations" feature (replaced ``merge_default``)
- `#19 <https://github.com/openwisp/openwisp-config/issues/19>`_: added
  smarter configuration merge mechanism
- `#20 <https://github.com/openwisp/openwisp-config/issues/20>`_: improved
  default test
- `#21 <https://github.com/openwisp/openwisp-config/issues/21>`_:
  introduced automatic naming of anonymous uci sections
- `daff21f <https://github.com/openwisp/openwisp-config/commit/daff21f>`_:
  added "Consistent key generation" feature
- `d6294ce <https://github.com/openwisp/openwisp-config/commit/d6294ce>`_:
  added ``capath`` argument and configuration option
- `93639af <https://github.com/openwisp/openwisp-config/commit/93639af>`_:
  added ``connect_timeout`` and ``max_time`` options for curl
- `9ef6f93 <https://github.com/openwisp/openwisp-config/commit/9ef6f93>`_:
  added support for LEDE
- `e122e40 <https://github.com/openwisp/openwisp-config/commit/e122e40>`_:
  fixed bug in autoregistration when hostname is empty
- `bd8ad3b <https://github.com/openwisp/openwisp-config/commit/bd8ad3b>`_:
  improved build options (ssl, category, maintainer)

0.3.1 [2016-03-02]
------------------

- `bd64be8 <https://github.com/openwisp/openwisp-config/commit/bd64be8>`_:
  fixed infinite registration bug introduced in `#14
  <https://github.com/openwisp/openwisp-config/issues/14>`_
- `e8ae900 <https://github.com/openwisp/openwisp-config/commit/e8ae900>`_:
  use current hostname in registration unless hostname is ``OpenWrt``

0.3 [2016-02-26]
----------------

- `09c672c <https://github.com/openwisp/openwisp-config/commit/09c672c>`_:
  strip trailing slash in URL parameter to avoid unexpected 404
- `#11 <https://github.com/openwisp/openwisp-config/issues/11>`_: added
  ``merge_default`` feature
- `#12 <https://github.com/openwisp/openwisp-config/issues/12>`_: improved
  syslog facility and level (e.g.: daemon.info)
- `#14 <https://github.com/openwisp/openwisp-config/issues/14>`_:
  resilient register failure
- `#13 <https://github.com/openwisp/openwisp-config/issues/13>`_: smarter
  reload
- `8879a4d <https://github.com/openwisp/openwisp-config/commit/8879a4d>`_:
  retry ``report_status`` several times before giving up

0.2 [2016-01-25]
----------------

- `#9 <https://github.com/openwisp/openwisp-config/issues/9>`_: preserve
  configuration file when reinstalling/upgrading
- `#10 <https://github.com/openwisp/openwisp-config/issues/10>`_: added
  "test configuration" feature with automatic rollback

0.1 [2016-01-15]
----------------

- configuration daemon
- ``apply_config`` script based on OpenWrt ``/sbin/reload_config``
- automatic registration in controller
