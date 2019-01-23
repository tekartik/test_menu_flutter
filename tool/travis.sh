#!/usr/bin/env bash

# Fast fail the script on failures.
# and print line as they are read
set -ev

flutter --version

#
# test_menu_flutter
#
pushd test_menu_flutter

flutter packages get

flutter analyze
flutter analyze --no-current-package lib test

flutter test

popd

#
# test_menu_example
#
pushd test_menu_flutter_example

flutter packages get

flutter analyze
flutter analyze --no-current-package lib
# flutter analyze --no-current-package --preview-dart-2 lib

# flutter test
