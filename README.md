# bazel-cpp-toolchain

*Example repository for the [Utilizing Bazel for Cross-Platform and Cross-Architecture Compilation and Testing](https://sched.co/1h6SU) talk at [BazelCon 24](https://events.linuxfoundation.org/bazelcon/) by Axel Uhlig & Marcel Kost at Salesforce.*

This repository shows the setup of a fully hermetic [Bazel C++ Toolchain](https://bazel.build/docs/cc-toolchain-config-reference) and how it can be used to achieve cool things like multi-OS support, cross-compiling and creating macOS universal binaries just with native Bazel features. The code in this repository is not maintained.

The toolchain in this repository is used to build the [Hyper database](https://tableau.github.io/hyper-db/) that powers the backend of [Tableau](https://tableau.com/) as well as [Salesforce Data Cloud](https://salesforce.com/data). The name `hyper` therefore is used in many places in the code.

## About the Toolchain

Main features:
* Cross-OS support (Windows, Linux, macOS)
* Cross-architecture support (x86-64 by default, aarch64 on macOS)
* Fully hermetic:
  * Uses explicit sysroot/SDK on all platforms
  * Disables non-hermetic compiler behaviour like default includes and link search paths

Additional features:
* C++23 support
* libstdc++ support
* Compiler flags for security hardening
* Automatic centos7 sysroot creation from rpm packages
* Toolchain tests: Set of small hello-world projects to test different toolchain features
* Sanitizer Support
* Fuzzer support (LLVM libFuzzer)
* Rules to create [Universal Binaries](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary) on macOS
* Debug symbol handling

## Setup

For legal reason this repository unfortunately doesn't include pre-built clang packages and OS-specific SDKs on macOS and Windows. To build the targets in all configurations, these have to be provided manually.

This section explains the steps necessary to provide all missing parts:

### Compiler

This C++ toolchain uses [clang](https://clang.llvm.org/) for all operating systems. It expects clang to be linked statically (to run independent from the host system version) and the package to contain libstdc++ for all desired target architectures. We highly recommend to go the extra mile and build such a clang package yourself.

To make it easier to test this toolchain code, **by default the [pre-build packages from LLVM](https://github.com/llvm/llvm-project/releases) are used**, but these are not statically linked and only contain libstdc++ for the host platform. Therefore the universal binary example doesn't work unless different clang packages are provided.

### OS-dependent sysroot/SDKs

#### Linux
On Linux the C++ toolchain creates a centos7 sysroot on the fly by downloading and extracting rpm packages. However, this example repository doesn't ship a hermetic python toolchain and thus requires Python 3 and a few libaries to be available on the host system. If you have a hermetic python toolchain, you can plug it into the `centos_sysroot()` instance in the `MODULE.bazel` file.

**Requirements on the host system**
- `python3`
- The pip packages `rpmfile` and `zstandard`

#### macOS
The C++ toolchain for macOS requires the macOS SDK and the macOS Command Line Tools. Unfortunately both are available for download only with an Apple login and therefore can't be pulled automatically. For the C++ toolchain to work on macOS, you need to manually download and extract those two packages.
For your own setup we suggest to mirror the two packages internally and let Bazel consume them via `http_archive` like the other packages.

**macOS 13.3 SDK**
* Run `thirdparty/macos_sdk/download_and_extract.sh` to download and extract the package automatically (This downloads the SDK from https://github.com/alexey-lysiuk/macos-sdk)
*  __or__ Extract it manually from XCode and copy the files to `thirdparty/macos_sdk`.
Note: You have to manually delete the `System/Library/Frameworks/Ruby.framework/Versions/2.6/Headers/ruby/ruby` folder from the package, since it contains a cyclic symlink and which annoys Bazel.

**Command Line Tools for Xcode 15.3**
* Download "Command Line Tools for Xcode 15.3" from the Apple website (https://developer.apple.com/xcode/resources/), mount it and copy the `.pkg` file to `thirdparty/macos_cmdtools`.
* Run `thirdparty/macos_cmdtools/extract.sh` to extract the package.

#### Windows
On Windows the C++ toolchain requires the Windows SDK, which also needs to be downloaded and extracted manually.

**Windows SDK 10.0.22621**
* Download from the [Windows website](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/)
* Install on a host system
* Copy folders to `thirdparty/windows_sdk`

**Microsoft Visual C++ Redistributable Version 14.39.33519**
* Download from the [MSVC Website](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-microsoft-visual-c-redistributable-version)
* Install on a host system
* Copy folders to `thirdparty/msvc`

## How to contribute

### Required tools

1. [bazelisk](https://github.com/bazelbuild/bazelisk)
1. [buildifier](https://github.com/bazelbuild/buildtools/tree/main/buildifier)

### How to verify your changes

1. Formatting: `buildifier -r .`
1. Test: `bazelisk test //...`

## Questions

If you have questions, feel free to reach out to the authors of the talk in the [Bazel Slack Workspace](https://slack.bazel.build/).
