#!/bin/bash
# Install the host and Python dependencies used by CI and AI review.
set -e

if [ "${CI_SYSTEM_DEPS_READY:-0}" != 1 ]; then
	sudo ./install-dev.sh
fi
if [ "${CI_SYSTEM_DEPS_ONLY:-0}" = 1 ]; then
	exit 0
fi
python -m pip install --upgrade -r requirements-test.txt
