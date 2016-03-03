Change log
^^^^^^^^^^

0.4.0 [unreleased]
==================

WIP

0.3.1 [2016-03-02]
==================

- `bd64be8 <https://github.com/openwisp/openwisp-config/commit/bd64be8>`_:
  fixed infinite registration bug introduced in
  `#14 <https://github.com/openwisp/openwisp-config/issues/14>`_
- `e8ae900 <https://github.com/openwisp/openwisp-config/commit/e8ae900>`_:
  use current hostname in registration unless hostname is ``OpenWrt``

0.3 [2016-02-26]
================

- `09c672c <https://github.com/openwisp/openwisp-config/commit/09c672c>`_:
  strip trailing slash in URL parameter to avoid unexpected 404
- `#11 <https://github.com/openwisp/openwisp-config/issues/11>`_:
  added ``merge_default`` feature
- `#12 <https://github.com/openwisp/openwisp-config/issues/12>`_:
  improved syslog facility and level (eg: daemon.info)
- `#14 <https://github.com/openwisp/openwisp-config/issues/14>`_:
  resilient register failure
- `#13 <https://github.com/openwisp/openwisp-config/issues/13>`_:
  smarter reload
- `8879a4d <https://github.com/openwisp/openwisp-config/commit/8879a4d>`_:
  retry ``report_status`` several times before giving up

0.2 [2016-01-25]
================

- `#9 <https://github.com/openwisp/openwisp-config/issues/9>`_:
  preserve configuration file when reinstalling/upgrading
- `#10 <https://github.com/openwisp/openwisp-config/issues/10>`_:
  added "test configuration" feature with automatic rollback

0.1 [2016-01-15]
================

- configuration daemon
- ``apply_config`` script based on OpenWRT ``/sbin/reload_config``
- automatic registration in controller
