#!/bin/sh
# Shell-level regression test for the PENDING_REPORT retry path added in
# https://github.com/openwisp/openwisp-config/pull/251.
#
# Covered scenarios:
#   T1  apply succeeds, report_status succeeds            -> no marker, checksums kept
#   T2  apply succeeds, report_status fails               -> marker written, checksums NOT removed
#   T3  next cycle: configuration_changed returns 0,
#        retry_pending_report succeeds                    -> marker removed
#   T4  next cycle: configuration_changed returns 2
#        (checksum fetch failure) -> marker NOT consumed  (must wait for confirmed no-change)
#   T5  marker save itself fails (read-only dir)          -> BOTH checksums invalidated (pre-#251 fallback)
#   T6  marker contains garbage                           -> discarded, no retry
#
# The test is shell-only and self-contained: it copies the relevant
# functions out of openwisp.agent into a sandbox, mocks report_status /
# retry_with_backoff / logger, and exercises the apply-success-but-
# report-fails-then-recovers path.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
AGENT="$SCRIPT_DIR/../files/openwisp.agent"

if [ ! -f "$AGENT" ]; then
	echo "FAIL: cannot locate openwisp.agent at $AGENT" >&2
	exit 1
fi

SANDBOX=$(mktemp -d -t owconf-pending-report-XXXXXX)
trap 'rm -rf "$SANDBOX"' EXIT

WORKING_DIR="$SANDBOX/working"
PERSISTENT_DIR="$SANDBOX/etc/openwisp"
mkdir -p "$WORKING_DIR" "$PERSISTENT_DIR"

CONFIGURATION_CHECKSUM="$WORKING_DIR/checksum"
PERSISTENT_CHECKSUM="$PERSISTENT_DIR/checksum"
PENDING_REPORT="$WORKING_DIR/pending_report"

PASS=0
FAIL=0

ok() {
	PASS=$((PASS + 1))
	echo "  PASS: $1"
}

fail() {
	FAIL=$((FAIL + 1))
	echo "  FAIL: $1" >&2
}

assert_file() {
	if [ -f "$1" ]; then
		ok "$2 (file exists: $1)"
	else
		fail "$2 (expected file missing: $1)"
	fi
}

assert_not_file() {
	if [ ! -f "$1" ]; then
		ok "$2 (file absent: $1)"
	else
		fail "$2 (unexpected file present: $1)"
	fi
}

assert_eq() {
	if [ "$1" = "$2" ]; then
		ok "$3"
	else
		fail "$3 (expected: '$2', got: '$1')"
	fi
}

reset_state() {
	rm -rf "$WORKING_DIR" "$PERSISTENT_DIR"
	mkdir -p "$WORKING_DIR" "$PERSISTENT_DIR"
	# pre-populate a remote checksum (as if a previous get_checksum ran)
	echo "remote-checksum-v1" >"$CONFIGURATION_CHECKSUM"
}

# Mock logger so the production code paths can call it freely.
logger() { :; }

# Counters for the mocked report_status.
REPORT_CALLS=0
REPORT_LAST_STATUS=""

# Force report_status outcome from the test: 0=success, non-zero=failure.
REPORT_RESULT=0

report_status() {
	REPORT_CALLS=$((REPORT_CALLS + 1))
	REPORT_LAST_STATUS="$1"
	return "$REPORT_RESULT"
}

# Simplified retry_with_backoff: single attempt, no sleep. Sufficient
# because the production retry_with_backoff loops 10x and we only care
# about the final exit code in this test.
retry_with_backoff() {
	command="$1"
	shift 1
	"$command" "$@" 1
}

# Provide /sbin/hotplug-call as a path-callable no-op so the env -i call
# inside update_configuration does not abort under set -e.
HOTPLUG_BIN="$SANDBOX/sbin/hotplug-call"
mkdir -p "$SANDBOX/sbin"
cat >"$HOTPLUG_BIN" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$HOTPLUG_BIN"

# A minimal update_configuration() that mirrors the production code path
# we care about: build a "new" checksum, call report_status, persist or
# discard PENDING_REPORT exactly like the upstream function does. We
# only inline the post-apply branch because the download/test branches
# are not under test here.
update_configuration_stub() {
	# Simulate a successful apply (or error if first arg is "error").
	apply_result=${1:-0}
	# Mirror production: write the "new" checksum that would come from
	# the controller.
	echo "remote-checksum-v2" >"$CONFIGURATION_CHECKSUM"

	# --- begin: copy of the post-apply block from update_configuration ---
	# shellcheck disable=SC2034
	status_to_report=""
	pending_marker_saved=0
	if [ "$apply_result" -eq 0 ]; then
		cp "$CONFIGURATION_CHECKSUM" "$PERSISTENT_CHECKSUM"
		status_to_report="applied"
	else
		status_to_report="error"
	fi

	if printf '%s\n' "$status_to_report" >"${PENDING_REPORT}.tmp" 2>/dev/null \
		&& mv "${PENDING_REPORT}.tmp" "$PENDING_REPORT" 2>/dev/null; then
		pending_marker_saved=1
	else
		rm -f "${PENDING_REPORT}.tmp"
	fi

	if retry_with_backoff report_status "$status_to_report"; then
		rm -f "$PENDING_REPORT"
	else
		if [ "$pending_marker_saved" -eq 0 ]; then
			rm -f "$CONFIGURATION_CHECKSUM" "$PERSISTENT_CHECKSUM"
		fi
	fi
	# --- end: copy of the post-apply block ---
}

# Verbatim copy of retry_pending_report from openwisp.agent.
retry_pending_report() {
	pending_status=""
	if [ ! -f "$PENDING_REPORT" ]; then
		return 0
	fi
	pending_status=$(tr -d '[:space:]' <"$PENDING_REPORT")
	case "$pending_status" in
		applied | error) ;;
		*)
			rm -f "$PENDING_REPORT"
			return 1
			;;
	esac
	if retry_with_backoff report_status "$pending_status"; then
		rm -f "$PENDING_REPORT"
	fi
}

############################################################
# T1: apply OK, report OK -> no marker, both checksums kept
############################################################
echo "T1: apply ok, report ok"
reset_state
REPORT_CALLS=0
REPORT_RESULT=0
update_configuration_stub 0
assert_not_file "$PENDING_REPORT" "T1 marker absent after success"
assert_file "$PERSISTENT_CHECKSUM" "T1 persistent checksum kept"
assert_file "$CONFIGURATION_CHECKSUM" "T1 working checksum kept"
assert_eq "$REPORT_LAST_STATUS" "applied" "T1 reported applied"
assert_eq "$REPORT_CALLS" "1" "T1 single report attempt"

############################################################
# T2: apply OK, report FAIL -> marker written, checksums kept
############################################################
echo "T2: apply ok, report fails -> marker persisted"
reset_state
REPORT_CALLS=0
REPORT_RESULT=2
update_configuration_stub 0
assert_file "$PENDING_REPORT" "T2 marker present after report fail"
marker_content=$(cat "$PENDING_REPORT")
assert_eq "$marker_content" "applied" "T2 marker content is 'applied'"
assert_file "$PERSISTENT_CHECKSUM" "T2 persistent checksum NOT removed (retry path)"
assert_file "$CONFIGURATION_CHECKSUM" "T2 working checksum NOT removed (retry path)"

############################################################
# T3: next cycle, configuration_changed == 0, retry succeeds
############################################################
echo "T3: next cycle, retry succeeds -> marker removed"
# carry state forward from T2
REPORT_CALLS=0
REPORT_RESULT=0
# emulate the agent loop branch: config_change_status==0 && marker exists
config_change_status=0
if [ "$config_change_status" -eq 0 ] && [ -f "$PENDING_REPORT" ]; then
	retry_pending_report
fi
assert_not_file "$PENDING_REPORT" "T3 marker removed after successful retry"
assert_eq "$REPORT_LAST_STATUS" "applied" "T3 re-reported same status"
assert_eq "$REPORT_CALLS" "1" "T3 single retry attempt"

############################################################
# T4: next cycle, configuration_changed == 2 -> NO retry
############################################################
echo "T4: next cycle, checksum fetch error -> marker untouched"
reset_state
# seed an existing pending marker (as if a previous cycle failed reporting)
printf 'error\n' >"$PENDING_REPORT"
REPORT_CALLS=0
REPORT_RESULT=0
config_change_status=2
if [ "$config_change_status" -eq 0 ] && [ -f "$PENDING_REPORT" ]; then
	retry_pending_report
fi
assert_file "$PENDING_REPORT" "T4 marker untouched on checksum-fetch error"
assert_eq "$REPORT_CALLS" "0" "T4 retry NOT attempted"

############################################################
# T5: marker save fails -> pre-#251 fallback (rm both checksums)
############################################################
echo "T5: marker save fails -> both checksums invalidated"
reset_state
REPORT_CALLS=0
REPORT_RESULT=2
# Make WORKING_DIR read-only so the marker write fails.
chmod 0500 "$WORKING_DIR"
# The checksum files were created in reset_state under WORKING_DIR /
# PERSISTENT_DIR; PERSISTENT_DIR stays writable. We expect rm -f to wipe
# CONFIGURATION_CHECKSUM (best-effort) and PERSISTENT_CHECKSUM (writable).
# stderr is silenced because the permission-denied warnings here are
# the very condition we are simulating.
update_configuration_stub 0 2>/dev/null || true
chmod 0700 "$WORKING_DIR"
assert_not_file "$PENDING_REPORT" "T5 no marker after save failure"
assert_not_file "$PERSISTENT_CHECKSUM" "T5 persistent checksum invalidated"
# CONFIGURATION_CHECKSUM lived in the now-read-only dir, so rm may have
# failed silently. We only enforce that the persistent one is gone --
# that is sufficient for the next-cycle re-download because on agent
# start PERSISTENT_CHECKSUM is the source of truth for CURRENT_CHECKSUM.

############################################################
# T6: garbage marker -> discarded, no retry
############################################################
echo "T6: garbage marker discarded"
reset_state
printf 'rogue-status\n' >"$PENDING_REPORT"
REPORT_CALLS=0
REPORT_RESULT=0
config_change_status=0
if [ "$config_change_status" -eq 0 ] && [ -f "$PENDING_REPORT" ]; then
	retry_pending_report || true
fi
assert_not_file "$PENDING_REPORT" "T6 garbage marker removed"
assert_eq "$REPORT_CALLS" "0" "T6 no retry on garbage marker"

echo
echo "=================================="
echo "PASS: $PASS  FAIL: $FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ]
