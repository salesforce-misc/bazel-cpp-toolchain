# ===========================================================================
# Clang Linux Toolchain
# ===========================================================================

#inspired by https://github.com/grailbio/bazel-toolchain

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
load("//toolchain/helper:platform_helpers.bzl", "PLATFORM_MACOS")

# ---------------------------------------------------------------------------
# Toolchain implementation
# ---------------------------------------------------------------------------

include_paths = [
    "external/clang_darwin/include/c++/v1",
    "external/clang_darwin/include",
    "%{sysroot}/System/Library/Frameworks",
]

# clang resource directory, containing non-gnu headers and clang-specific libraries (part of the clang package)
clang_resource_directory = "external/clang_darwin/lib/clang/17"

def create_platform_specific_link_flags(macosx_version_min, sdk_version):
    return [
        "-headerpad_max_install_names",
        # Set the macOS deployment target to meet the specified official minimum requirements.
        "-Wl,-platform_version,macos,{macosx_version_min},{sdk_version},".format(macosx_version_min = macosx_version_min, sdk_version = sdk_version),
        # Sets the oso_prefix to the current working directory.
        # By setting the oso_prefix all paths in the final binary's OSO stabs are relatizived according to the provided directory.
        # If we do not relativize these OSO stabs the point to archive and object files in the current sandbox that won't
        # exist after the current compiler invocation.
        # Relativizing these paths allows us to use the dsymutil tool in a new sandbox containing the same libraries
        # and object files used to initially link the binary to generate the actual .dSYM file containing
        # the debug symbols of the resulting binary.
        #
        # The "%%pwd%%" itself is resolved by the cc-wrapper.sh script
        # with the current working directory as "." is not recognized
        # by the mac os ld linker.
        # The %% is used
        "-Wl,-oso_prefix,%%pwd%%/",
    ]

def create_platform_specific_compile_flags(macosx_version_min):
    return [
        "-mmacosx-version-min=" + macosx_version_min,
        # %%pwd%% is expanded by the cc-wrapper.sh to the current working directory
        # This has two benefits. First, the path is locally reproducible (the command is the same on all machines).
        # Second the path is globally reproducible (the absolute path is stripped from the output).
        # Globally means that the same paths are embedded regardless of the machine and sandbox the build was executed on.
        # Locally means that no absolute paths are part of the command line. E.g. if we would directly use the absolute path
        # to the working directory the commandline would be different for each checkout directory and caching would be impossible
        "-ffile-prefix-map=%%pwd%%=.",
    ] + create_compile_flags_for_include_paths(include_paths)

def _impl(ctx):
    clang_wrapper_path = "clang/darwin/wrapper-scripts/cc-wrapper.sh"
    darwin_toolchain_files = ctx.attr.sysroot.files.to_list()

    return cc_common.create_cc_toolchain_config_info(
        features = create_posix_default_features(
            default_defines = ctx.file._default_defines,
            ld = ctx.file.ld,
            sysroot_enabled = True,
            shared_flag = "-dynamiclib",
            supports_start_end_lib = False,
            dynamic_lookup_for_undefined_symbols = True,
            supported_instruction_set_extensions = ctx.attr.supported_instruction_set_extensions,
            default_instruction_set_extensions = ctx.attr.default_instruction_set_extensions,
            runtime_library_search_directories_base = "@loader_path",
            clang_resource_directory = clang_resource_directory,
            target_architecture_triple = ctx.attr.target_architecture_triple,
            target_base_cpu = ctx.attr.target_base_cpu,
            platform_specific_compile_flags = create_platform_specific_compile_flags(ctx.attr.macosx_version_min),
            platform_specific_link_flags = create_platform_specific_link_flags(ctx.attr.macosx_version_min, ctx.attr.sdk_version),
            platform_specifc_link_flags_for_position_independent_executables = ["-Wl,-pie"],
            whole_archive_linker_flag = "-force_load",
            no_whole_archive_linker_flag = None,
            solib_name_flag = "-Wl,-install_name,@rpath/",
            additional_features = create_hyper_features(PLATFORM_MACOS),
        ),
        action_configs = create_posix_action_configs(
            ar_path = file_attribute_to_toolpath(ctx, ctx.file.ar),
            clang_path = clang_wrapper_path,
            strip_path = file_attribute_to_toolpath(ctx, ctx.file.strip),
        ),
        ctx = ctx,
        toolchain_identifier = "clang-darwin",
        host_system_name = "unused",
        target_system_name = ctx.attr.target_architecture_triple,
        target_cpu = "darwin",
        target_libc = "macosx",
        compiler = "clang",
        abi_version = "darwin_x86_64",
        abi_libc_version = "darwin_x86_64",
        cxx_builtin_include_directories = create_toolchain_cxx_builtin_include_directories(include_paths) +
                                          [clang_resource_directory + "/include"],
        builtin_sysroot = get_common_root_dir(darwin_toolchain_files) if darwin_toolchain_files else None,
    )

# ---------------------------------------------------------------------------
# Toolchain rule declaration
# ---------------------------------------------------------------------------

darwin_toolchain_config = rule(
    implementation = _impl,
    provides = [CcToolchainConfigInfo],
    attrs = {
        "_default_defines": attr.label(
            allow_single_file = True,
            default = "//toolchain:clang/hermetic_default_defines.h",
        ),
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
        "sysroot": attr.label(
            mandatory = True,
        ),
        "strip": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "macosx_version_min": attr.string(
            mandatory = True,
        ),
        "sdk_version": attr.string(
            mandatory = True,
            doc = """
                  Pass `-sdk_version` to the linker so that binaries will correctly indicate the SDK they were linked against.
                  Note: Binaries will contain `sdk <version>` in the LC_VERSION_MIN_MACOSX or LC_BUILD_VERSION load commands.
                  Note: Can't use `-platform_version <platform> <min_version> <sdk_version>` here due to conflicts with `-mmacosx-version-min`.
                  """,
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
            default = [],
        ),
        "default_instruction_set_extensions": attr.string_list(
            doc = "List of default instructions set extensions",
            default = [],
        ),
    },
)
