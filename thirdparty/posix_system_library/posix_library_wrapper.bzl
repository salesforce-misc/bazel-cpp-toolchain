load("@rules_cc//cc:defs.bzl", "cc_library")
load("//toolchain/helper:condition_helpers.bzl", "list_not_for")

def posix_library_wrapper(name, link_flag):
    cc_library(
        name = name,
        linkopts = list_not_for(
            ["//toolchain/platforms:is_windows"],
            [link_flag],
        ),
        visibility = ["//visibility:public"],
    )
