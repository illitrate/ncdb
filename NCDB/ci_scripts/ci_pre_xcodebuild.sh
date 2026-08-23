#!/bin/sh

#
#  ci_pre_xcodebuild.sh
#  NCDB
#
#  Stamps the Xcode Cloud build number into the project before archiving.
#
#  With GENERATE_INFOPLIST_FILE = YES, CFBundleVersion is derived from
#  CURRENT_PROJECT_VERSION, so that is what we rewrite. agvtool isn't used
#  because this project doesn't set VERSIONING_SYSTEM = apple-generic, and
#  turning that on would change how versions work for local builds too.
#
#  Only the CI checkout is modified — it's ephemeral and never committed, so
#  the number in the repository stays as it is. That's deliberate: TestFlight
#  is the only place builds are distributed, so it's the only place the number
#  needs to be authoritative.
#

set -e

echo "── NCDB: stamping build number ──"

# CI_BUILD_NUMBER is provided by Xcode Cloud and increments per run.
if [ -z "$CI_BUILD_NUMBER" ]; then
    echo "warning: CI_BUILD_NUMBER is not set — leaving the build number alone."
    echo "         (This is expected if the script is run outside Xcode Cloud.)"
    exit 0
fi

# Locate the project. CI_PRIMARY_REPOSITORY_PATH is the repository checkout root;
# fall back to a path relative to this script so it also works if run by hand.
if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
    PROJECT_FILE="$CI_PRIMARY_REPOSITORY_PATH/NCDB/NCDB.xcodeproj/project.pbxproj"
else
    SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
    PROJECT_FILE="$SCRIPT_DIR/../NCDB.xcodeproj/project.pbxproj"
fi

if [ ! -f "$PROJECT_FILE" ]; then
    echo "error: couldn't find project.pbxproj at $PROJECT_FILE"
    exit 1
fi

BEFORE=$(grep -c "CURRENT_PROJECT_VERSION = " "$PROJECT_FILE" || true)

if [ "$BEFORE" -eq 0 ]; then
    echo "error: no CURRENT_PROJECT_VERSION entries found — the project layout has changed."
    exit 1
fi

# Rewrite every target's build number so the app and its extension stay in step.
# A mismatch here is rejected at upload.
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = ${CI_BUILD_NUMBER};/g" "$PROJECT_FILE"

AFTER=$(grep -c "CURRENT_PROJECT_VERSION = ${CI_BUILD_NUMBER};" "$PROJECT_FILE" || true)

if [ "$AFTER" -ne "$BEFORE" ]; then
    echo "error: expected to set $BEFORE entries, set $AFTER."
    exit 1
fi

echo "Set CURRENT_PROJECT_VERSION to ${CI_BUILD_NUMBER} across ${AFTER} configuration(s)."

if [ -n "$CI_COMMIT" ]; then
    echo "Commit: ${CI_COMMIT}"
fi
