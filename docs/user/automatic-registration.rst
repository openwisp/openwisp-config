Automatic registration
======================

When the agent starts, if both ``uuid`` and ``key`` are not defined, it
will consider the router to be unregistered and it will attempt to perform
an automatic registration.

The automatic registration is performed only if ``shared_secret`` is
correctly set.

The device will choose as name one of its mac addresses, unless its
hostname is not ``OpenWrt``, in the latter case it will simply register
itself with the current hostname.

When the registration is completed, the agent will automatically set
``uuid`` and ``key`` in ``/etc/config/openwisp``.

To enable this feature by default on your firmware images, follow the
procedure described in `Compiling a custom OpenWRT image`_.

Consistent key generation
=========================

When using `Automatic registration`_, this feature allows devices to keep
the same configuration even if reset or reflashed.

The ``key`` is generated consistently with an operation like
``md5sum(mac_address + shared_secret)``; this allows the controller
application to recognize that an existing device is registering itself
again.

The ``mac_interface`` configuration key specifies which interface is used
to calculate the mac address, this setting defaults to ``eth0``. If no
``eth0`` interface exists, the first non-loopback, non-bridge and non-tap
interface is used. You won't need to change this setting often, but if you
do, ensure you choose a physical interface which has constant mac address.

The "Consistent key generation" feature is enabled by default, but must be
enabled also in the controller application in order to work.
