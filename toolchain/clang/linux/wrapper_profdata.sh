#!/bin/bash
set -euo pipefail

# The wrapper file is the recommended way to configure the tools when they are not supported by action_config yet: https://github.com/bazelbuild/bazel/issues/8438#issuecomment-594443436
./external/clang_linux/bin/llvm-profdata "$@"
