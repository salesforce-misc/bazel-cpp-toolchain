package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_files",
    srcs = glob(["**/*"])
)

filegroup(
    name = "clang_cl",
    srcs = [
        "bin/clang-cl.exe",
    ],
)

filegroup(
    name = "clang",
    srcs = [
        "bin/clang.exe",
    ],
)

filegroup(
    name = "lld_link",
    srcs = [
        "bin/lld-link.exe",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "clang_tidy",
    srcs = ["bin/clang-tidy.exe"],
)

filegroup(
    name = "clang_format",
    srcs = ["bin/clang-format.exe"],
)

filegroup(
    name = "clang_apply_replacements",
    srcs = ["bin/clang-apply-replacements.exe"],
)


filegroup(
    name = "llvm_lib",
    srcs = [
        "bin/llvm-lib.exe",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "llvm_rc",
    srcs = [
        "bin/llvm-rc.exe",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "strip",
    srcs = [
        "bin/llvm-strip.exe",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "sanitizer_support",
    srcs = [],
)

filegroup(
    name = "llvm_cvtres",
    srcs = [
        "bin/llvm-cvtres.exe",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "compiler_specific_headers",
    srcs = glob(
        ["lib/clang/*/include/**/*.h"],
    ),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "all_toolchain_components",
    srcs = [
        ":clang_cl",
        ":lld_link",
        ":llvm_lib",
    ],
)

filegroup(
    name = "dsymutil",
    srcs = ["bin/dsymutil.exe"],
    visibility = ["//visibility:public"],
)
