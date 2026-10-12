#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Some preview Command Line Tools ship Swift Testing but do not discover its
# framework or macro plugin. Full Xcode and Linux toolchains need no workaround.
if [[ "$(uname -s)" == Darwin ]] && [[ "$(xcode-select -p)" == /Library/Developer/CommandLineTools ]]; then
  developer_dir="$(xcode-select -p)"
  framework_dir="$developer_dir/Library/Developer/Frameworks"
  plugin_path="$developer_dir/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
  if [[ -f "$plugin_path" ]]; then
    exec swift test --build-system native --disable-xctest \
      -Xswiftc -F -Xswiftc "$framework_dir" \
      -Xswiftc -load-plugin-library -Xswiftc "$plugin_path" \
      -Xlinker -rpath -Xlinker "$framework_dir" "$@"
  fi
fi
exec swift test --disable-xctest "$@"
