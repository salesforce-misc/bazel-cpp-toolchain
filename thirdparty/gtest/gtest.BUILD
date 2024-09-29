load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "gtest",
    srcs = [
        "src/gtest-all.cc",
        "src/gtest-internal-inl.h",
    ],
    hdrs = glob(["include/gtest/**/*.h"]),
    copts = [
        "-Wno-zero-as-null-pointer-constant",
        "-Wno-missing-declarations",
        "-Wno-undef",
        "-Wno-unused-member-function",
        "-Wno-suggest-override",
        "-Wno-shift-sign-overflow",
    ],
    includes = ["include"],
    # disables building gtest as a shared library
    # in case you want to build it as a shared library you have to additionally set the following define: GTEST_CREATE_SHARED_LIBRARY
    linkstatic = True,
    textual_hdrs = [
        "src/gtest-assertion-result.cc",
        "src/gtest-death-test.cc",
        "src/gtest-filepath.cc",
        "src/gtest-matchers.cc",
        "src/gtest-port.cc",
        "src/gtest-printers.cc",
        "src/gtest-test-part.cc",
        "src/gtest-typed-test.cc",
        "src/gtest.cc",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@//thirdparty/posix_system_library:math_library",
    ],
)

cc_library(
    name = "gtest_main",
    srcs = [
        "src/gtest_main.cc",
    ],
    visibility = ["//visibility:public"],
    deps = ["gtest"],
)