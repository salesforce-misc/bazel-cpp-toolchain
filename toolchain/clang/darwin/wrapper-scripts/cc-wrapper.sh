#!/bin/bash
#
# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Ship the environment to the C++ action
#

set -eu

# Set-up the environment
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# Call the C++ compiler.
if [[ "${PATH}:" == *"external/clang_darwin/bin:"* ]]; then
  # GoCompile sets the PATH to the directory containing the linker, and changes CWD.
  clang "$@"
else
  # Call the C++ compiler
  export RELATIVE_PATH=external/clang_darwin/bin/clang

  if test -f ${RELATIVE_PATH}; then
    # Replace occurrences of %pwd% in the provided arguments with the path to the current working directory.
    # Example use cases are the -Wl,-oso_prefix or the -fdebug-prefix-map that need to resolve absolute paths
    # to paths relative to the current sandbox.
    # Keep in mind that %%pwd%% has to be used inside the toolchain configuration as the % charachter has to be
    # escaped by using %%.
    #
    # Without relativizing, the absolute paths would point to files in the current sandbox.
    # These absolute paths would be invalid immediately after the current invocation.
    ${RELATIVE_PATH} "${@//%pwd%/$(pwd)}"
  else
    # if it cannot be found (e.g. in case of the external cmake rule try to resolve the binary from the current location of the script
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    EXECROOT=$(cd $DIR/../../../../../ && pwd)
    CLANG_TOOlCHAIN_DIR=$(cd $DIR/../../ && pwd)
    ${EXECROOT}/${RELATIVE_PATH} -I${CLANG_TOOlCHAIN_DIR} "$@"
  fi
fi
