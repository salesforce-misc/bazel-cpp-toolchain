# ===========================================================================
# Clang Linux Toolchain
# ===========================================================================

#inspired by https://github.com/grailbio/bazel-toolchain

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "tool_path",
)
load("//toolchain:clang/clang_hyper_features.bzl", "create_hyper_features")
load(
    "//toolchain:clang/clang_posix_toolchain_config_base.bzl",
    "create_compile_flags_for_include_paths",
    "create_posix_action_configs",
    "create_posix_default_features",
    "create_toolchain_cxx_builtin_include_directories",
)
load("//toolchain/helper:context_helpers.bzl", "file_attribute_to_toolpath")
load("//toolchain/helper:file_helpers.bzl", "get_common_root_dir")
load("//toolchain/helper:platform_helpers.bzl", "PLATFORM_LINUX")

# ---------------------------------------------------------------------------
# Toolchain implementation
# ---------------------------------------------------------------------------

include_paths = [
    "external/clang_linux/include/x86_64-unknown-linux-gnu/c++/v1",
    "external/clang_linux/include/c++/v1",
]

# clang resource directory, containing non-gnu headers and clang-specific libraries (part of the clang package)
clang_resource_directory = "external/clang_linux/lib/clang/17"
clang_builtin_includes = clang_resource_directory + "/include"

platform_specific_link_flags = [
    # Make build-id non-random
    "-Wl,--build-id=md5",

    # When generating an executable or shared library, mark it to tell the dynamic linker to resolve all symbols when
    # the program is started, or when the shared library is linked to using dlopen, instead of deferring function call
    # resolution to the point when the function is first called.
    "-Wl,-z,relro",
    "-Wl,-z,now",

    # Use `-Wl,--as-needed` to ensure that the DT_NEEDED tags in the .dynamic section reflect _exactly_ the dynamic
    # libraries that are actually needed.
    "-Wl,--as-needed",

    # C++ Standard Library: Use the static version of `libc++` (actual linkind happening through `static_runtime_lib` toolchain config)
    # To avoid surprises, we want to be very explicit here and override Clang's complex built-in behavior.
    # Note: The `--exclude-libs` linker arguments prevent global symbols in the specified archive libraries from being
    #    automatically exported by the linked binaries. We generally don't want our binaries to re-export
    #    C++ standard library symbols.
    "-Wl,--exclude-libs,libc++.a",
    "-Wl,--exclude-libs,libc++abi.a",

    # Unwind Library: Use the LLVM `libunwind.a` from our Clang package instead of GCC's `libgcc_eh.a` (actual linkind happening through `static_runtime_lib` toolchain config)
    # Note: The `--unwindlib=none` prevents Clang from automatically linking to `libunwind.so` or `libgcc_s.so`.
    # Note: --unwindlib is relevant only on Linux. On macOS, adding --unwindlib would cause -Wunused-command-line-argument to produce a warning.
    "--unwindlib=none",
    "-Wl,--exclude-libs,libunwind.a",
]

linux_debug_prefix_map_compile_flags = [
    # This maps absolute source paths (e.g. to map debugging symbols or in asserts) to the current execution root
    "-ffile-prefix-map=/proc/self/cwd=.",
]

def _impl(ctx):
    default_defines_include_path = ctx.file._default_defines.path[0:-len(ctx.file._default_defines.basename)]
    platform_specific_compile_flags = create_compile_flags_for_include_paths(include_paths + [default_defines_include_path]) + linux_debug_prefix_map_compile_flags
    sysroot_files = ctx.attr.sysroot.files.to_list()

    # We must list all tool_paths even if most of them are unused as the tools are specified in the corresponding actions
    tool_paths = [
        tool_path(name = "ar", path = "/bin/false"),
        tool_path(name = "compat-ld", path = "/bin/false"),
        tool_path(name = "cpp", path = "/bin/false"),
        tool_path(name = "dwp", path = ctx.attr.llvm_dwp),
        tool_path(name = "gcc", path = "/bin/false"),
        tool_path(name = "ld", path = "/bin/false"),
        tool_path(name = "nm", path = "/bin/false"),
        tool_path(name = "objcopy", path = "/bin/false"),
        tool_path(name = "objdump", path = "/bin/false"),
        tool_path(name = "strip", path = "/bin/false"),
    ]

    return cc_common.create_cc_toolchain_config_info(
        features = create_posix_default_features(
            default_defines = ctx.file._default_defines,
            ld = ctx.file.ld,
            sysroot_enabled = True,
            shared_flag = "-shared",
            supports_start_end_lib = True,
            dynamic_lookup_for_undefined_symbols = False,
            supported_instruction_set_extensions = ctx.attr.supported_instruction_set_extensions,
            default_instruction_set_extensions = ctx.attr.default_instruction_set_extensions,
            runtime_library_search_directories_base = "$ORIGIN",
            clang_resource_directory = clang_resource_directory,
            target_architecture_triple = ctx.attr.target_architecture_triple,
            target_base_cpu = ctx.attr.target_base_cpu,
            platform_specific_compile_flags = platform_specific_compile_flags,
            platform_specific_link_flags = platform_specific_link_flags,
            platform_specifc_link_flags_for_position_independent_executables = ["-pie"],
            whole_archive_linker_flag = "--whole-archive",
            no_whole_archive_linker_flag = "--no-whole-archive",
            solib_name_flag = "-Wl,-soname,",
            additional_features = create_hyper_features(PLATFORM_LINUX),
        ),
        action_configs = create_posix_action_configs(
            ar_path = file_attribute_to_toolpath(ctx, ctx.file.ar),
            clang_path = file_attribute_to_toolpath(ctx, ctx.file.clang),
            strip_path = file_attribute_to_toolpath(ctx, ctx.file.strip),
        ),
        ctx = ctx,
        toolchain_identifier = "clang-linux",
        host_system_name = "x86_64",
        target_system_name = "x86_64-unknown-linux-gnu",
        target_cpu = "k8",
        target_libc = "unknown",
        compiler = "clang",
        abi_version = "clang",
        abi_libc_version = "glibc_unknown",
        tool_paths = tool_paths,
        cxx_builtin_include_directories = create_toolchain_cxx_builtin_include_directories(include_paths) + [clang_builtin_includes, default_defines_include_path],
        builtin_sysroot = get_common_root_dir(sysroot_files) if sysroot_files else None,
    )

# ---------------------------------------------------------------------------
# Toolchain rule declaration
# ---------------------------------------------------------------------------

linux_toolchain_config = rule(
    implementation = _impl,
    provides = [CcToolchainConfigInfo],
    attrs = {
        "_default_defines": attr.label(
            allow_single_file = True,
            default = "//toolchain:clang/hermetic_default_defines.h",
        ),
        "link_libs": attr.string_list(),
        "ar": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "clang": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "ld": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "llvm_dwp": attr.string(
            mandatory = True,
        ),
        "strip": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "target_architecture_triple": attr.string(
            mandatory = True,
            doc = """Target architecture triple (set by `--target=<name>`), defining target architecture, vendor and OS""",
        ),
        "target_base_cpu": attr.string(
            # While on x86-64 this value can be derived from the target triple, that doesn't work on arm
            doc = """Target processor base architecture (set by `-march=<name>`), used to disable instruction set extensions""",
        ),
        "supported_instruction_set_extensions": attr.string_list(
            doc = "List of supported instructions set extensions (set by `-m<name>`)",
            mandatory = True,
        ),
        "default_instruction_set_extensions": attr.string_list(
            doc = "List of default instructions set extensions (set by `-m<name>`)",
            mandatory = True,
        ),
        "sysroot": attr.label(
            doc = "The label to the sysroot that should be used by this toolchain.",
        ),
    },
)
