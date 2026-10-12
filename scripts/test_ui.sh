#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! xcodebuild -version >/dev/null 2>&1; then
  echo 'Full Xcode is required for UI tests; select it with xcode-select.' >&2
  exit 1
fi
command -v xcodegen >/dev/null || { echo 'Install XcodeGen to generate the UI test project.' >&2; exit 1; }
xcodegen generate --spec UITests/project.yml --project UITests
xcodebuild test -project UITests/NovaPlayerUI.xcodeproj -scheme NovaPlayerUI \
  -destination 'platform=macOS' -derivedDataPath build/ui-tests \
  -resultBundlePath "build/UIResults-$(date +%s).xcresult" CODE_SIGNING_ALLOWED=NO
