load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# -------------------------------------
# rules_cc

http_archive(
    name = "rules_cc",
    sha256 = "2037875b9a4456dce4a79d112a8ae885bbc4aad968e6587dca6e64f3a0900cdf",
    strip_prefix = "rules_cc-0.0.9",
    urls = ["https://github.com/bazelbuild/rules_cc/releases/download/0.0.9/rules_cc-0.0.9.tar.gz"],
)

# -------------------------------------
# rules_python

http_archive(
    name = "rules_python",
    sha256 = "be04b635c7be4604be1ef20542e9870af3c49778ce841ee2d92fcb42f9d9516a",
    strip_prefix = "rules_python-0.35.0",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.35.0/rules_python-0.35.0.tar.gz",
)

load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()

# -------------------------------------
# rules_pkg

http_archive(
    name = "rules_pkg",
    sha256 = "d20c951960ed77cb7b341c2a59488534e494d5ad1d30c4818c736d57772a9fef",
    urls = [
        "https://github.com/bazelbuild/rules_pkg/releases/download/1.0.1/rules_pkg-1.0.1.tar.gz",
    ],
)

load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")

rules_pkg_dependencies()

# -------------------------------------
# Linux Sysroot

# The centos_sysroot depends on the python interpreter and the rpmfile pip package
# and must therefore occur after the setup of python and the initialization of the pip modules
load("//toolchain/rules/sysroot:centos_sysroot.bzl", "centos_sysroot")

centos_sysroot(
    name = "sysroot_linux",
    python_interpreter = None,  # if you have a hermetic python toolchain you can plug it in here
    rpm_packages = {
        "https://archive.kernel.org/centos-vault/7.9.2009/os/x86_64/Packages/gcc-4.8.5-44.el7.x86_64.rpm": "186d9bdbb568d08c4d8b2f9a2c0fce952c2ac80ef5989806116df61c7cbc5a22",
        "https://archive.kernel.org/centos-vault/7.9.2009/os/x86_64/Packages/glibc-2.17-317.el7.x86_64.rpm": "49eb081de1ddd13f5440abdbb3b42cdd01d11b74d624793ae1b80a1cf432551b",
        "https://archive.kernel.org/centos-vault/7.9.2009/os/x86_64/Packages/glibc-devel-2.17-317.el7.x86_64.rpm": "57e04523b12c9aa5a0632cbfa2ff13e33f1ecec5e6bd0b609a77d9c24cebf8c4",
        "https://archive.kernel.org/centos-vault/7.9.2009/os/x86_64/Packages/glibc-headers-2.17-317.el7.x86_64.rpm": "b7e4e19b362cbd73e09e6ee5eff3d70dbeb7cc2c702a927b8f646f324d4ec4a3",
        "https://archive.kernel.org/centos-vault/7.9.2009/os/x86_64/Packages/kernel-headers-3.10.0-1160.el7.x86_64.rpm": "81b4e4f401d2402736ceba4627eaafd5b615c2cc45aa4d4f941ea79562045139",
    },
)

# -------------------------------------
# macOS SDK

# TODO: Extract "macOS 13.3 SDK" from XCode or download it from https://github.com/alexey-lysiuk/macos-sdk and extract it to
# thirdparty/macos_sdk.
# Note: You have to manually delete the System/Library/Frameworks/Ruby.framework/Versions/2.6/Headers/ruby/ruby
# folder from the package, since it contains a cyclic symlink and which annoys Bazel.
local_repository(
    name = "macos_sdk",
    path = "thirdparty/macos_sdk",
)

# TODO: Download "Command Line Tools for Xcode 15.3" from the Apple website (https://developer.apple.com/xcode/resources/)
# and extract them to thirdparty/macos_cmdtools.
local_repository(
    name = "macos_cmdtools",
    path = "thirdparty/macos_cmdtools",
)

# -------------------------------------
# Windows SDK

# Microsoft Visual C++ toolchain
# TODO: Download "MSVC 14.39.33519" from https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-microsoft-visual-c-redistributable-version
# and extract it into thirdparty/msvc
local_repository(
    name = "msvc",
    path = "thirdparty/msvc",
)

# Microsoft Windows SDK
# TODO: Download "Windows SDK 10.0.22621" from https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
# and extract it into thirdparty/windows_sdk
local_repository(
    name = "windows_sdk",
    path = "thirdparty/windows_sdk",
)

# -------------------------------------
# Clang

# Custom statically clang 17.0.6 including libc++
http_archive(
    name = "clang_linux",
    build_file = "@//thirdparty:clang/clang_linux.BUILD",
    sha256 = "54ec30358afcc9fb8aa74307db3046f5187f9fb89fb37064cdde906e062ebf36",
    strip_prefix = "clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04",
    urls = ["https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz"],
)

# Custom statically clang 17.0.6 including libc++ for both x64 and arm
http_archive(
    name = "clang_darwin",
    build_file = "@//thirdparty:clang/clang_darwin.BUILD",
    sha256 = "4573b7f25f46d2a9c8882993f091c52f416c83271db6f5b213c93f0bd0346a10",
    strip_prefix = "clang+llvm-18.1.8-arm64-apple-macos11",
    urls = ["https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-arm64-apple-macos11.tar.xz"],
)

# Custom statically clang 17.0.6 including libc++
http_archive(
    name = "clang_windows",
    build_file = "@//thirdparty:clang/clang_windows.BUILD",
    sha256 = "78ef87e8e0abb34e8463faf612f0d4100818d5181f7e1b1a23b64f677ba74de4",
    urls = ["https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-pc-windows-msvc.tar.xz"],
)

# -------------------------------------
# Google test

# Common variables to define googltest and googlemock dependencies
GTEST_VERSION = "1.15.2"

GTEST_SHA256 = "7b42b4d6ed48810c5362c265a17faebe90dc2373c885e5216439d37927f02926"

GTEST_URL = "https://github.com/google/googletest/archive/refs/tags/v" + GTEST_VERSION + ".tar.gz"

http_archive(
    name = "googletest",
    build_file = "@//thirdparty:gtest/gtest.BUILD",
    sha256 = GTEST_SHA256,
    strip_prefix = "googletest-" + GTEST_VERSION + "/googletest",
    url = GTEST_URL,
)

# -------------------------------------
# Register toolchains

register_toolchains(
    "//toolchain:cc-toolchain-clang-windows-x64-x64",
    "//toolchain:cc-toolchain-clang-linux-x64-x64",
    "//toolchain:cc-toolchain-clang-macos-any-x64",
    "//toolchain:cc-toolchain-clang-macos-any-arm",
)
