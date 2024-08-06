Developer Documentation
=======================

.. include:: ../partials/developer-docs.rst

.. contents:: **Table of Contents**:
    :depth: 2
    :local:

.. _compiling_openwisp_config:

Compiling openwisp-config
-------------------------

The following procedure illustrates how to compile *openwisp-config* and
its dependencies:

.. code-block:: shell

    git clone https://github.com/openwrt/openwrt.git openwrt
    cd openwrt
    git checkout <openwrt-branch>

    # configure feeds
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" > feeds.conf
    cat feeds.conf.default >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    # any arch/target is fine because the package is architecture indipendent
    arch="ar71xx"
    echo "CONFIG_TARGET_$arch=y" > .config;
    echo "CONFIG_PACKAGE_openwisp-config=y" >> .config
    make defconfig
    make tools/install
    make toolchain/install
    make package/openwisp-config/compile

Alternatively, you can configure your build interactively with ``make
menuconfig``, in this case you will need to select *openwisp-config* by
going to ``Administration > openwisp``:

.. code-block:: shell

    git clone https://github.com/openwrt/openwrt.git openwrt
    cd openwrt
    git checkout <openwrt-branch>

    # configure feeds
    echo "src-git openwisp https://github.com/openwisp/openwisp-config.git" > feeds.conf
    cat feeds.conf.default >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    make menuconfig
    # go to Administration > openwisp and select the variant you need interactively
    make -j1 V=s

Quality Assurance Checks
------------------------

We use `LuaFormatter <https://luarocks.org/modules/tammela/luaformatter>`_
and `shfmt <https://github.com/mvdan/sh#shfmt>`_ to format lua files and
shell scripts respectively.

First of all, you will need install the lua packages mentioned above, then
you can format all files with:

.. code-block::

    ./qa-format

To run quality assurance checks you can use the ``run-qa-checks`` script:

.. code-block::

    # install openwisp-utils QA tools first
    pip install openwisp-utils[qa]

    # run QA checks before committing code
    ./run-qa-checks

Run tests
---------

To run the unit tests, you must install the required dependencies first;
to do this, you can take a look at the `install-dev.sh
<https://github.com/openwisp/openwisp-config/blob/master/install-dev.sh>`_
script.

You can run all the unit tests by launching the dedicated script:

.. code-block:: shell

    ./runtests

Alternatively, you can run specific tests, e.g.:

.. code-block:: shell

    cd openwisp-config/tests/
    lua test_utils.lua -v
