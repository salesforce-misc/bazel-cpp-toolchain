package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
)

filegroup(
    name = "clang",
    srcs = ["bin/clang"],
)

filegroup(
    name = "ld",
    srcs = ["bin/lld"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "dsymutil",
    srcs = ["bin/dsymutil"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "bin_aliases",
    srcs = [
        "bin/clang",
        "bin/clang++",
        "bin/clang-cpp",
        "bin/ld.lld",
        "bin/ld64.lld",
        "bin/lld-link",
        "bin/llvm-ranlib",
        "bin/llvm-readelf",
        "bin/llvm-strip",
    ],
    data = [
        ":clang",
        ":ld",
        ":ranlib",
        ":readelf",
    ],
)

filegroup(
    name = "includes",
    srcs = glob([
        "include/c++/v1/**",
        "lib/clang/*/include/**",
        "lib/clang/*/share/*_ignorelist.txt",
    ]),
)

filegroup(
    name = "libsan",
    srcs = glob(
        [
            "lib/clang/*/lib/**/*san*_osx_dynamic.dylib",
        ],
    ),
)

filegroup(
    name = "lib",
    srcs = glob(
        [
            "lib/lib*.a",
            "lib/lib*.dylib",
            "lib/clang/*/lib/**/*.a",
            "lib/clang/*/lib/**/*.dylib",
        ],
        exclude = [
            "lib/libLLVM*.a",
            "lib/libclang*.a",
            "lib/liblld*.a",
            "lib/libLLVM*.dylib",
            "lib/libclang*.dylib",
            "lib/liblld*.dylib",
        ],
    ),
)

filegroup(
    name = "cpp_static_runtime_libraries",
    srcs = [
        "lib/libc++.a",
        "lib/libc++abi.a",
        "lib/libc++experimental.a",
    ],
)

filegroup(
    name = "cpp_dynamic_runtime_libraries",
    srcs = [
        # libs and their symlinks/aliases
        "lib/libc++.1.0.dylib",
        "lib/libc++.1.dylib",
        "lib/libc++.dylib",
        "lib/libc++abi.1.0.dylib",
        "lib/libc++abi.1.dylib",
        "lib/libc++abi.dylib",
    ],
)

filegroup(
    name = "compiler_components",
    srcs = [
        ":bin_aliases",
        ":clang",
        ":includes",
        ":sanitizer_support",
    ],
)

filegroup(
    name = "ar",
    srcs = ["bin/llvm-ar"],
)

filegroup(
    name = "as",
    srcs = ["bin/llvm-as"],
)

filegroup(
    name = "nm",
    srcs = ["bin/llvm-nm"],
)

filegroup(
    name = "objcopy",
    srcs = ["bin/llvm-objcopy"],
)

filegroup(
    name = "objdump",
    srcs = ["bin/llvm-objdump"],
)

filegroup(
    name = "clang_tidy",
    srcs = ["bin/clang-tidy"],
)

filegroup(
    name = "clang_format",
    srcs = ["bin/clang-format"],
)

filegroup(
    name = "clang_apply_replacements",
    srcs = ["bin/clang-apply-replacements"],
)

filegroup(
    name = "dwp",
    srcs = ["bin/llvm-dwp"],
)

filegroup(
    name = "ranlib",
    srcs = ["bin/llvm-ar"],
)

filegroup(
    name = "readelf",
    srcs = ["bin/llvm-readobj"],
)

filegroup(
    name = "binutils_components",
    srcs = glob(["bin/*"]),
)

filegroup(
    name = "linker_components",
    srcs = [
        ":ar",
        ":bin_aliases",
        ":clang",
        ":ld",
        ":lib",
    ],
)

filegroup(
    name = "sanitizer_support",
    srcs = [
        "bin/llvm-symbolizer",
        # ASAN is linked dynamically on macOS, thus we need to add the dynamic ASAN library to the sandbox.
        "@clang_darwin//:libsan",
    ] + glob(["lib/clang/*/share/*_ignorelist.txt"]),
)

filegroup(
    name = "all_components",
    srcs = [
        ":binutils_components",
        ":compiler_components",
        ":linker_components",
    ],
)

filegroup(
    name = "llvm_cvtres",
    srcs = [
        "bin/llvm-cvtres",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "llvm_rc",
    srcs = [
        "bin/llvm-rc",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "llvm-lipo",
    srcs = [
        "bin/llvm-lipo",
    ],
    visibility = ["//visibility:public"],
)
