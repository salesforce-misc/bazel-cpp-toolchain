package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_files",
    srcs = glob(["**/*"])
)

filegroup(
    name = "clang",
    srcs = ["bin/clang"],
)

filegroup(
    name = "ld",
    srcs = ["bin/lld"],
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
    name = "dsymutil",
    srcs = ["bin/dsymutil"],
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
        "bin/llvm-readelf",
        "bin/llvm-ranlib",
        "bin/llvm-strip",
    ],
    data = [
       ":clang",
       ":ld",
       ":readelf",
       ":ranlib",
       ":strip",
    ],
)


filegroup(
    name = "includes",
    srcs = glob([
        "include/c++/v1/**",
        "include/x86_64-unknown-linux-gnu/c++/v1/**",
        "lib/clang/*/include/**",
    ]),
)

filegroup(
    name = "lib",
    srcs = glob(
        [
            # Various `libclang_rt` libraries
            "lib/clang/*/lib/**/*.a",
            "lib/clang/*/lib/**/*.so",
            # libc++, libunwind, ...
            "lib/x86_64-unknown-linux-gnu/lib*.a",
            "lib/x86_64-unknown-linux-gnu/lib*.so",
            "lib/x86_64-unknown-linux-gnu/lib*.so.1",
            "lib/x86_64-unknown-linux-gnu/lib*.so.1.0",
        ],
    ),
)

filegroup(
    name = "cpp_static_runtime_libraries",
    srcs = [
        # The symbol export of these three libraries is manually excluded in the Linux linker call.
        # bazel/toolchain/clang/linux/clang_linux_toolchain_config.bzl
        # Plase adapt accordingly if any changes are made here.
        "lib/x86_64-unknown-linux-gnu/libc++.a",
        "lib/x86_64-unknown-linux-gnu/libc++experimental.a",
        "lib/x86_64-unknown-linux-gnu/libc++abi.a",
        "lib/x86_64-unknown-linux-gnu/libunwind.a"
    ],
)

filegroup(
    name = "cpp_dynamic_runtime_libraries",
    srcs = [
        # libs and their symlinks/aliases
        "lib/x86_64-unknown-linux-gnu/libc++.so.1",
        "lib/x86_64-unknown-linux-gnu/libc++.so.1.0",
        "lib/x86_64-unknown-linux-gnu/libc++abi.so.1",
        "lib/x86_64-unknown-linux-gnu/libc++abi.so.1.0",
        "lib/x86_64-unknown-linux-gnu/libunwind.so.1",
        "lib/x86_64-unknown-linux-gnu/libunwind.so.1.0"
    ],
)

filegroup(
    name = "compiler_components",
    srcs = [
        ":clang",
        ":includes",
        # needed by clang binary for execution
        ":cpp_dynamic_runtime_libraries",
        ":bin_aliases",
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
    name = "dwp",
    srcs = ["bin/llvm-dwp"],
)

filegroup(
    name = "ranlib",
    srcs = ["bin/llvm-ar"],
)

filegroup(
    name = "readelf",
    srcs = ["bin/llvm-readelf"],
    data = [":lib", ":readobj"],
)

filegroup(
    name = "readobj",
    srcs = ["bin/llvm-readobj"],
)

filegroup(
    name = "strip",
    srcs = [ "bin/llvm-strip" ],
)

filegroup(
    name = "binutils_components",
    srcs = glob(["bin/*"]),
)

filegroup(
    name = "linker_components",
    srcs = [
        ":ar",
        ":clang",
        ":ld",
        ":lib",
        ":bin_aliases"
    ],
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
    name = "sanitizer_support",
    srcs = [
        "bin/llvm-symbolizer",
        # Make runtime libraries available in sandbox
        ":cpp_dynamic_runtime_libraries",
    ] + glob(["lib/clang/*/share/*_ignorelist.txt"]),
)

filegroup(
    name = "llvm_cvtres",
    srcs = [
        "bin/llvm-cvtres",
    ],
)

filegroup(
    name = "llvm_rc",
    srcs = [
        "bin/llvm-rc",
    ],
)
