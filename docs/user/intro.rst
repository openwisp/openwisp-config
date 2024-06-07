OpenWISP Config: Features
=========================

OpenWISP Config agent provides the following features:

- Fetches the latest configuration from the OpenWISP Controller, ensuring
  devices stay up-to-date.
- :ref:`Combines centrally managed settings with local configurations
  <config_merge_configuration>`, preserving local overrides.
- Performs :ref:`rollback of previous configuration
  <config_configuration_test>` when the new configuration fails to apply.
- Simplifies onboarding by :doc:`automatically registering devices
  <automatic-registration>` with the controller using a shared secret.
- Supports :doc:`OpenWrt hotplugs <hotplugs>`.
