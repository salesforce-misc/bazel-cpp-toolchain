load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "artifact_name_pattern",
    "env_entry",
    "env_set",
    "feature",
    "flag_group",
    "flag_set",
    "tool",
    "variable_with_value",
    "with_feature_set",
)
load("//toolchain:clang/clang_hyper_features.bzl", "create_hyper_features")
load(
    "//toolchain:clang/clang_toolchain_actions.bzl",
    "all_compile_actions",
    "all_cpp_compile_actions",
    "all_link_actions",
    "codegen_compile_actions",
    "preprocessor_compile_actions",
)
load("//toolchain/helper:context_helpers.bzl", "file_attribute_to_toolpath")
load("//toolchain/helper:platform_helpers.bzl", "PLATFORM_WINDOWS")

_msvc_libraries_path = "external\\msvc\\lib\\x64\\"
_ucrt_libraries_path = "external\\windows_sdk\\Lib\\ucrt\\x64\\"

default_include_paths = [
    "external/msvc/include",
    "external/windows_sdk/Include/shared/",
    "external/windows_sdk/Include/ucrt/",
    "external/windows_sdk/Include/um/",
    "external/windows_sdk/Include/winrt/",
]

# clang resource directory, containing non-gnu headers and clang-specific libraries (part of the clang package)
clang_resource_directory = "external/clang_windows/lib/clang/17"
clang_c_includes = clang_resource_directory + "/include"

# ===========================================================================
# Bazel Windows Toolchain (inspired by bazels tools/cpp/windows_cc_toolchain_config.bzl)
#
# Bazel supports a list of abstract actions (ACTION_NAMES) that can be performed.
# A toolchain definition defines action_configs for these actions that describe
# which tool to use for which action and how.
# Features (like C++23) are entities that enable additional command-line flags
# on actions and can trigger other actions.
# ===========================================================================

def _impl(ctx):
    clang_cl = tool(path = file_attribute_to_toolpath(ctx, ctx.file.clang_cl))
    lld_link = tool(path = file_attribute_to_toolpath(ctx, ctx.file.lld_link))
    llvm_lib = tool(path = file_attribute_to_toolpath(ctx, ctx.file.llvm_lib))

    return cc_common.create_cc_toolchain_config_info(
        artifact_name_patterns = [
            artifact_name_pattern(
                category_name = "object_file",
                prefix = "",
                extension = ".obj",
            ),
            artifact_name_pattern(
                category_name = "static_library",
                prefix = "",
                extension = ".lib",
            ),
            artifact_name_pattern(
                category_name = "alwayslink_static_library",
                prefix = "",
                extension = ".lo.lib",
            ),
            artifact_name_pattern(
                category_name = "executable",
                prefix = "",
                extension = ".exe",
            ),
            artifact_name_pattern(
                category_name = "dynamic_library",
                prefix = "",
                extension = ".dll",
            ),
            artifact_name_pattern(
                category_name = "interface_library",
                prefix = "",
                extension = ".if.lib",
            ),
        ],
        action_configs = [
            action_config(
                # Assemble without preprocessing. Typically for .s files.
                action_name = ACTION_NAMES.assemble,
                tools = [clang_cl],
                implies = [
                    "nologo",
                    "user_compile_flags",
                    "unfiltered_compile_flags",
                    "compiler_input_flags",
                    "compiler_output_flags",
                    "default_compile_flags",
                    "user_compile_flags",
                    "msvc_runtime_compile_flags",
                ],
            ),
            action_config(
                # Assemble with preprocessing. Typically for .S files.
                action_name = ACTION_NAMES.preprocess_assemble,
                tools = [clang_cl],
                implies = [
                    "nologo",
                    "user_compile_flags",
                    "unfiltered_compile_flags",
                    "compiler_input_flags",
                    "compiler_output_flags",
                    "default_compile_flags",
                    "user_compile_flags",
                    "msvc_runtime_compile_flags",
                ],
            ),
            action_config(
                action_name = ACTION_NAMES.c_compile,
                tools = [clang_cl],
                implies = [
                    "nologo",
                    "user_compile_flags",
                    "unfiltered_compile_flags",
                    "compiler_input_flags",
                    "compiler_output_flags",
                    "default_compile_flags",
                    "user_compile_flags",
                    "msvc_runtime_compile_flags",
                ],
            ),
            action_config(
                action_name = ACTION_NAMES.cpp_compile,
                tools = [clang_cl],
                implies = [
                    "nologo",
                    "user_compile_flags",
                    "unfiltered_compile_flags",
                    "compiler_input_flags",
                    "compiler_output_flags",
                    "default_compile_flags",
                    "user_compile_flags",
                    "msvc_runtime_compile_flags",
                ],
            ),
            action_config(
                action_name = ACTION_NAMES.cpp_link_executable,
                # In contrast to Posix we call the linker on Windows directly.
                # We choose this approach, firstly to have the Windows toolchain
                # aligned with our CMake toolchain and secondly, such that the usage
                # of the msvc-compatible clang-cl.exe compiler and the lld-link.exe
                # is aligned with how the msvc equivalent tools cl.exe and link.exe
                # are used in general.
                tools = [lld_link],
                implies = [
                    "nologo",
                    "link_input_params",
                    "libraries_to_link",
                    "linkstamps",
                    "output_execpath_flags",
                    "target_platform",
                    "user_link_flags",
                    "linker_param_file",
                    "archive_param_file",
                    "no_stripping",
                    "msvc_runtime_link_flags",
                    "def_file",
                ],
            ),
            action_config(
                action_name = ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                # In contrast to Posix we call the linker on Windows directly.
                # We choose this approach, firstly to have the Windows toolchain
                # aligned with our CMake toolchain and secondly, such that the usage
                # of the msvc-compatible clang-cl.exe compiler and the lld-link.exe
                # is aligned with how the msvc equivalent tools cl.exe and link.exe
                # are used in general.
                tools = [lld_link],
                implies = [
                    "nologo",
                    "link_input_params",
                    "libraries_to_link",
                    "shared_flag",
                    "linkstamps",
                    "output_execpath_flags",
                    "target_platform",
                    "user_link_flags",
                    "linker_param_file",
                    "archive_param_file",
                    "no_stripping",
                    "msvc_runtime_link_flags",
                    "def_file",
                ],
            ),
            action_config(
                action_name = ACTION_NAMES.cpp_link_dynamic_library,
                # In contrast to Posix we call the linker on Windows directly.
                # We choose this approach, firstly to have the Windows toolchain
                # aligned with our CMake toolchain and secondly, such that the usage
                # of the msvc-compatible clang-cl.exe compiler and the lld-link.exe
                # is aligned with how the msvc equivalent tools cl.exe and link.exe
                # are used in general.
                tools = [lld_link],
                implies = [
                    "nologo",
                    "shared_flag",
                    "link_input_params",
                    "libraries_to_link",
                    "linkstamps",
                    "output_execpath_flags",
                    "target_platform",
                    "user_link_flags",
                    "linker_param_file",
                    "archive_param_file",
                    "no_stripping",
                    "msvc_runtime_link_flags",
                    "def_file",
                ],
            ),
            action_config(
                action_name = ACTION_NAMES.cpp_link_static_library,
                tools = [llvm_lib],
                implies = [
                    "nologo",
                    "output_execpath_flags",
                    "target_platform",
                    "link_input_params",
                    "libraries_to_link",
                    "linker_param_file",
                    "archive_param_file",
                    "msvc_runtime_link_flags",
                ],
            ),
        ],
        features = [
            # Disabled all legacy features first
            feature("no_legacy_features", enabled = True),

            # Disable stripping feature
            # if no_stripping feature is set on the toolchain, the stripped binary will simply
            # be a symlink (or a copy on Windows) of the original binary.
            feature("no_stripping", enabled = True),
            # This feature has to be exactly named "generate_pdb_file" as this name is hardcoded in
            # the CcBinary.java rule and triggers pdb file handling on windows.
            feature("generate_pdb_file", enabled = True),

            # indicates that tool_path in action_config points to a real tool, not a dummy placeholder
            feature("has_configured_linker_path", enabled = True),

            # Tagging feature for C++ rules indicating that the toolchain can produce shared libraries
            feature(name = "supports_dynamic_linker", enabled = True),
            # Tagging feature for explicitly linking the C++ runtime
            # In static linking mode, the static runtime library is used
            # In dynamic linking mode, the dynamic runtime library is used
            feature(name = "static_link_cpp_runtimes", enabled = True),
            # Tagging feature for C++ rules indicating that the toolchain uses position independent objects for shared libraries
            # In combination with "--force-pic" pic is also used for executable to create position independent executables
            feature(name = "supports_pic", enabled = True),
            # Tagging feature indicating that objects should be linked directly instead of using intermediate static libraries
            feature(name = "supports_start_end_lib", enabled = False),

            # The following two lines are required for the toolchain to support static and dynamic linking
            feature(name = "static_linking_mode"),
            feature(name = "dynamic_linking_mode"),

            # Tagging features for windows. It is currently hardcoded in bazel source code

            # It has two side effects
            # * It enables the copy_dynamic_libraries_to_binary features
            # * It results in linking all transitive dependencies when creating shared libraries
            feature(
                name = "targets_windows",
                enabled = True,
                implies = ["copy_dynamic_libraries_to_binary"],
            ),

            # Windows specific tagged feature that allows to switch between static and dynamic runtime libraries (/MT and /MD)
            # Currently the name of all msvcrt related targets are hardcoded in bazel's CcCommon.java
            # We got rid of most of them. At least this feature must be provided, otherwise we cannot switch between the /MT and /MD mode
            # at compile time
            # enables static msvcrt linkage, switch to static runtime feature
            feature(name = "static_link_msvcrt", enabled = True),

            # Tagged feature for windows to indicate that the toolchain supports the generation of interface shared libraries
            feature(name = "supports_interface_shared_libraries", enabled = True),

            # Tagged feature for windows that results in all shared libraries to get copied next to the binary.
            feature(name = "copy_dynamic_libraries_to_binary"),

            # CAUTION: The order of the following features is important!
            # https://docs.bazel.build/versions/master/cc-toolchain-config-reference.html#well-known-features

            # Custom features that indicates that c++ code should be build with C++23
            feature(name = "c++23"),
            # Custom features that indicates that c++ code should be build with C++14
            feature(name = "c++14"),
            # Custom features that indicates that c++ code should be build with C++11
            feature(name = "c++11"),

            # Create features for instruction set extensions like SSE
        ] + create_instruction_set_extension_features(ctx.attr.supported_instruction_set_extensions, ctx.attr.default_instruction_set_extensions) + [

            # Create feature for target architecture flags
            create_target_architecture_feature(ctx.attr.target_architecture_triple, ctx.attr.target_base_cpu),

            # Windows specific feature to suppress startup banner for microsoftish compilers and tools
            create_no_logo_feature(ctx),

            # environment for msvc set to non existing paths to ensure that we have hermetic builds
            create_msvc_env_feature(ctx),

            ###### Compilation modes #####
        ] + create_compilation_mode_features() + [

            ###### Compile flags #####
            create_compiler_input_flags(ctx),
            create_compiler_output_flags(ctx),
            # This feature uses the internal clang dependency-file generation option
            # this allows us to get rid of the msvc special case parse_showincludes
            create_dependency_file_feature(ctx),
            create_preprocessor_defines_feature(ctx),
            create_includes_feature(ctx),
            create_include_paths_feature(ctx),
            create_default_compile_flags_feature(ctx),
            create_unfiltered_compile_flags_feature(ctx),

            # Msvc runtime specific compile flags feature.
            # This sets the flags /MT /MTd, /MD or /MDd according to the build type and if static/dynamic linking mode
            # should be used
            create_msvc_runtime_compile_flags_feature(ctx),

            ###### Link flags #####

            # Flag defining to build a .dll
            create_shared_flag_feature(ctx),
            # Defines the output file name
            create_output_execpath_flags_feature(ctx),
            # Provides the interface libraries and library options
            create_link_input_param_flags(ctx),
            # Sets the target platform in our case x64
            create_target_platform_feature(ctx),
            # Adds all dependent libraries to link command line
            create_libraries_to_link_feature(ctx),
            create_default_link_flags_feature(ctx),
            # Provides response files to the linker in case the command line is too long
            create_linker_param_file_feature(ctx),
            # A feature to control whether to use param files for archiving commands
            create_archive_param_file_feature(ctx),

            # Adds flags for linkstamping
            create_linkstamps_feature(ctx),

            # This feature passes a provided def file to the link action (for shared libraries only!).
            # It thereby defines what symbols should be exported from a shared library
            create_def_file_feature(ctx),

            # Defines what runtime libraries the final artifact will be linked agains.
            # The exact library files that have to be used, are kept in sync wir the compile flags /MT, /MD, ... as
            # defined by create_msvc_runtime_compile_flags_feature
            create_msvc_runtime_link_flags_feature(ctx),
            create_color_diagnostics_feature(),

            # We ignore some warnings in our toolchain per default so they don't pop up in third-party builds
            ignore_some_warnings_per_default(),
            # Enable Werror flag for compiling actions
            create_treat_warnings_as_errors_compiling_feature(),
            # Enable Werror flag for linking
            create_treat_warnings_as_errors_linking_feature(),

            # The user compile and link flags *must* be the last features in the list!
            # Example: locally disable a compiler warning with -Wno-cast-qual that is previously set in a feature
        ] + create_hyper_features(PLATFORM_WINDOWS) + [

            # To allow users to override linker and compile flags these flags must be provided last
            create_user_compile_flags_feature(ctx),
            create_user_link_flags_feature(ctx),

            # Enable pretty-printing
            create_pretty_printer_feature(ctx),
        ],
        ctx = ctx,
        toolchain_identifier = "clang-windows",
        host_system_name = "x86_64",
        target_system_name = "x86_64-windows",
        target_cpu = "x64_windows",
        target_libc = "msvcrt",
        compiler = "msvc-cl",
        abi_version = "local",
        abi_libc_version = "local",
        cxx_builtin_include_directories = default_include_paths + [clang_c_includes],
    )

# ---------------------------------------------------------------------------
# Toolchain rule declaration
# ---------------------------------------------------------------------------

windows_clang_toolchain_config = rule(
    implementation = _impl,
    provides = [CcToolchainConfigInfo],
    attrs = {
        "_default_defines": attr.label(
            allow_single_file = True,
            default = "//toolchain:clang/hermetic_default_defines.h",
        ),
        "_natvis": attr.label(
            allow_single_file = True,
            default = "//toolchain/clang/windows:windows_enable_pretty_printing",
        ),
        "clang_cl": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "lld_link": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "llvm_lib": attr.label(
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
            doc = "List of default instructions set extensions",
            mandatory = True,
        ),
    },
)

def create_no_logo_feature(ctx):
    return feature(
        name = "nologo",
        flag_sets = [
            flag_set(
                actions = all_compile_actions + all_link_actions + [
                    ACTION_NAMES.cpp_link_static_library,
                ],
                flag_groups = [flag_group(flags = ["/nologo"])],
            ),
        ],
    )

# set to non existing paths
def create_msvc_env_feature(ctx):
    # This is a path that is not expected to exist.
    # We use this path to ensure that the corresponding paths are actually empty during compile and link actions
    not_existing = "c:\\not\\existing\\for\\sure"
    return feature(
        name = "msvc_env",
        enabled = True,
        env_sets = [
            env_set(
                actions = all_compile_actions + all_link_actions + [ACTION_NAMES.cpp_link_static_library],
                env_entries = [
                    env_entry(key = "PATH", value = not_existing),
                    env_entry(key = "TMP", value = not_existing),
                    env_entry(key = "TEMP", value = not_existing),
                ],
            ),
        ],
    )

def create_compilation_mode_features():
    # We share this flagset between fastbuild and debug as the previous fastbuild options
    # were slower than this.
    dbg_flagset = [
        flag_set(
            actions = all_compile_actions,
            flag_groups = [
                flag_group(flags = [
                    "/Od",  # Disable optimization
                    "/Zi",  # Enable debug symbols
                    "/Oy-",  # Ensures that frame pointers are generated
                    # Disable checked iterators and iterator debugging in the Visual C++ runtime library.
                    "/D_ITERATOR_DEBUG_LEVEL=0",
                ]),
            ],
        ),
    ]
    return [
        feature(
            name = "opt",
            flag_sets = [
                flag_set(
                    actions = all_compile_actions,
                    flag_groups = [
                        flag_group(flags = [
                            # Set the optimization level to `/O2` to optimize for maximum speed.
                            #
                            # Note: In the POSIX toolchain we use `-O3`, but this is available only in POSIX-style frontends.
                            #    In MSVC-style frontends there is only `/O1` and `/O2`.
                            #    In Clang-cl, `/O2` is a shorthand for /Og /Oi /Ot /Oy /Ob2 /GF /Gy.
                            #    References:
                            #       https://docs.microsoft.com/en-us/cpp/build/reference/o-options-optimize-code
                            #       https://clang.llvm.org/docs/UsersManual.html#clang-cl
                            "/O2",  # Set optimization level
                            "/Zi",  # Enable debug symbols
                            "/Oy-",  # Ensures that frame pointers are generated
                            # Disable checked iterators and iterator debugging in the Visual C++ runtime library.
                            "/D_ITERATOR_DEBUG_LEVEL=0",
                            "/DNDEBUG",  # Disable debug code paths
                        ]),
                    ],
                ),
            ],
        ),
        feature(
            name = "fastbuild",
            flag_sets = dbg_flagset,
        ),
        feature(
            name = "dbg",
            flag_sets = dbg_flagset,
        ),
    ]

def create_compiler_input_flags(ctx):
    return feature(
        name = "compiler_input_flags",
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        #only difference is -c vs. /c
                        flags = ["/c", "%{source_file}"],
                        expand_if_available = "source_file",
                    ),
                ],
            ),
        ],
    )

def create_compiler_output_flags(ctx):
    return feature(
        name = "compiler_output_flags",
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.assemble],
                flag_groups = [
                    flag_group(
                        flag_groups = [
                            flag_group(
                                # FO defines the output
                                # Zi creates a separate pdb file
                                flags = ["/Fo%{output_file}", "/Zi"],
                                expand_if_available = "output_file",
                                expand_if_not_available = "output_assembly_file",
                            ),
                        ],
                        expand_if_not_available = "output_preprocess_file",
                    ),
                ],
            ),
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                ],
                flag_groups = [
                    flag_group(
                        flag_groups = [
                            flag_group(
                                flags = ["/Fo%{output_file}"],
                                expand_if_not_available = "output_preprocess_file",
                            ),
                        ],
                        expand_if_available = "output_file",
                        expand_if_not_available = "output_assembly_file",
                    ),
                    flag_group(
                        flag_groups = [
                            # The output assembler file
                            flag_group(
                                flags = ["/Fa%{output_file}"],
                                expand_if_available = "output_assembly_file",
                            ),
                        ],
                        expand_if_available = "output_file",
                    ),
                    flag_group(
                        flag_groups = [
                            flag_group(
                                # Output file for preprocessed ouput
                                flags = ["/P", "/Fi%{output_file}"],
                                expand_if_available = "output_preprocess_file",
                            ),
                        ],
                        expand_if_available = "output_file",
                    ),
                ],
            ),
        ],
    )

def create_dependency_file_feature(ctx):
    # For more details on using clangs internal dependency file generation option please see,
    # the firefox issue https://bugzilla.mozilla.org/show_bug.cgi?id=1340588 and
    # the clang issue: https://bugs.llvm.org/show_bug.cgi?id=36701
    # Missing flag -sys-header-deps found in this writeup: https://gist.github.com/masuidrive/5231110
    return feature(
        name = "dependency_file",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = codegen_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-Xclang", "-sys-header-deps", "-Xclang", "-dependency-file", "-Xclang", "%{dependency_file}", "-Xclang", "-MT", "-Xclang", "%{output_file}"],
                        expand_if_available = "dependency_file",
                    ),
                ],
            ),
        ],
    )

def create_preprocessor_defines_feature(ctx):
    return feature(
        name = "preprocessor_defines",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = preprocessor_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["/D%{preprocessor_defines}"],
                        iterate_over = "preprocessor_defines",
                    ),
                ],
            ),
        ],
    )

# Adds header files listed in the compile variable includes, before all other header files in the source to compile.
# E.g. bazel's link stamping mechanism uses this feature to provide the keys of the workspace status to c++ files
def create_includes_feature(ctx):
    return feature(
        name = "includes",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = preprocessor_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["/FI", "%{includes}"],
                        iterate_over = "includes",
                        expand_if_available = "includes",
                    ),
                ],
            ),
        ],
    )

def create_include_paths_feature(ctx):
    return feature(
        name = "include_paths",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-Xclang", "-iquote", "-Xclang", "%{quote_include_paths}"],
                        iterate_over = "quote_include_paths",
                    ),
                    flag_group(
                        flags = ["/I", "%{include_paths}"],
                        iterate_over = "include_paths",
                    ),
                    flag_group(
                        flags = ["/imsvc", "%{system_include_paths}"],
                        iterate_over = "system_include_paths",
                    ),
                ],
            ),
        ],
    )

def create_default_compile_flags_feature(ctx):
    include_paths = []

    for path in default_include_paths:
        include_paths.extend(["/imsvc", path])

    # Don't explicitly set /TC or /TP for C or C++ files as all our files are named
    # .c or .cpp/.cxx correctly anyway.

    flag_sets = [
        flag_set(
            actions = [
                ACTION_NAMES.assemble,
                ACTION_NAMES.preprocess_assemble,
                ACTION_NAMES.linkstamp_compile,
                ACTION_NAMES.c_compile,
                ACTION_NAMES.cpp_compile,
                ACTION_NAMES.cpp_header_parsing,
                ACTION_NAMES.cpp_module_compile,
                ACTION_NAMES.cpp_module_codegen,
                ACTION_NAMES.clif_match,
            ],
            flag_groups = [
                flag_group(
                    flags = [
                        # suppress warnings due to windows case insensitive header file handling
                        "-Wno-nonportable-include-path",
                        # Enable full Microsoft Visual C++ compatibility
                        "-fms-compatibility",
                        # enables compatibility with microsoft language extensions like __declspec
                        "-fms-extensions",
                        # Set `-fms-compatibility-version` to what `cl.exe` in the MSVC package reports.
                        # This ensures that _MSC_VER is reported as at least 1910 in C/C++ code.
                        "-fms-compatibility-version=19.39.33519",
                        # Set the targeted Windows version to at least "Windows Server 2008 R2".
                        # The canonical documentation is https://docs.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt?view=vs-2019, it lists
                        # "Windows Server 2008" (listed with 0x0600) but not R2. https://en.wikipedia.org/wiki/Windows_NT shows "Windows 2008 R2" as belonging to the
                        # 6.1 NT family unlike "Windows Server 2008" which belongs to 6.0. This is also confirmed based in
                        # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-emfspool/b8892ec2-e30c-4c53-ad90-9814c904c6aa page which explicitely
                        # mentions `_WIN32_WINNT_WIN7 (0x601):  Windows 7 operating system and Windows Server 2008 R2 operating system`.
                        # Thus using 0x0x601 is the correct value to still remain compatible with "Windows Server 2008 R2"
                        "/D_WIN32_WINNT=0x0601",
                        # Enable extended alignment which makes the windows c++ standard library more standard conforming.
                        "/D_ENABLE_EXTENDED_ALIGNED_STORAGE",
                        # Use builtin offsetof. Required for compile-time static `offsetof` definition as of libc++17 with msvc toolchain.
                        "/D_CRT_USE_BUILTIN_OFFSETOF",
                        # Enable `/bigobj` to avoid issues with large source files.
                        # It increases the number of addressable sections in .obj files from 2^16 to 2^32.
                        "/bigobj",
                        # Extends the compilers internal heap limit
                        # Prevents problems with complicated templates
                        # see https://stackoverflow.com/questions/25885625/globally-set-compiler-flags-zm-memory-limit
                        "/Zm500",
                        # sane exception handling
                        "/EHsc",
                        # Disables warnings of the following kind: '<call>' is deprecated: The POSIX name for this item is deprecated. Instead, use the ISO C and C++ conformant name: _<call> (e.g. for call close)
                        # These types of warnings also occur in standard libraries and is therefore disabled
                        "/wd4996",
                        # With Clang-cl, use Clang-style diagnostics as on our other platforms, rather than MSVC-style diagnostics.
                        # We found that this works better in cross-platform tools and IDEs such as CLion.
                        "/clang:-fdiagnostics-format=clang",
                        # `/Zc:dllexportInlines-` is Clang-cl's equivalent of `-fvisibility-inlines-hidden`.
                        # Details: http://blog.llvm.org/2018/11/30-faster-windows-builds-with-clang-cl_14.html
                        "/Zc:dllexportInlines-",
                    ],
                ),
                flag_group(
                    flags = [
                        "/X",  # do not use default imports
                        # Ensure that a relative explicit resource directory is used instead of the builtin absolute path
                        "-resource-dir",
                        clang_resource_directory,
                    ] + include_paths,
                ),
            ],
        ),
        # There is on purpose no flag_set for the feature "c++11":
        # C++11 is the current standard in clang-cl and it will throw `argument unused during compilation` if `/std:c++11` is supplied.
        # And Starlark doesn't allow empty flag_groups, so we can't even put a stub here.
        flag_set(
            actions = all_cpp_compile_actions,
            flag_groups = [flag_group(flags = ["/std:c++14"])],
            with_features = [with_feature_set(features = ["c++14"])],
        ),
        # Use C++23 as default
        flag_set(
            actions = all_cpp_compile_actions,
            flag_groups = [flag_group(flags = ["-Xclang", "-std=c++23"])],
            with_features = [with_feature_set(not_features = ["c++11", "c++14"])],
        ),
        flag_set(
            actions = all_compile_actions,
            flag_groups = [
                flag_group(
                    flags = [
                        "/D_FORTIFY_SOURCE=1",  # Enable run-time buffer overflow detection.
                    ],
                ),
            ],
            with_features = [with_feature_set(
                # Note: _FORTIFY_SOURCE requires compiling with optimization (-O) -> fastbuild, opt
                features = ["fastbuild", "opt"],
                # Note: _FORTIFY_SOURCE doesn't currently work with sanitizers; see https://github.com/google/sanitizers/issues/247.
                not_features = ["address_sanitizer", "undefined_behavior_sanitizer", "memory_sanitizer", "thread_sanitizer"],
            )],
        ),
    ]

    return feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = flag_sets,
    )

def create_instruction_set_extension_features(supported_instruction_set_extensions, default_instruction_set_extensions):
    # Create one feature for every instruction set extension
    features = [
        feature(
            name = name,
            flag_sets = [
                flag_set(
                    actions = all_cpp_compile_actions,
                    flag_groups = [flag_group(flags = ["-m" + name])],
                ),
            ],
        )
        for name in supported_instruction_set_extensions
    ]

    # Create one default features that will enable all default extensions and is enabled by default
    # If one target wants to specify its extensions from scratch, it can simply disable the default feature
    features.append(feature(
        name = "default_instruction_set_extensions",
        implies = default_instruction_set_extensions,
        enabled = True,
    ))

    return features

def create_target_architecture_feature(target_architecture_triple, target_base_cpu):
    target_base_cpu_flag = [
        flag_set(
            actions = all_compile_actions,
            flag_groups = [flag_group(flags = ["-march={target_base_cpu}".format(target_base_cpu = target_base_cpu)])],
        ),
    ] if target_base_cpu else []

    return feature(
        name = "target_architecture",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = ["--target={target_architecture_triple}".format(target_architecture_triple = target_architecture_triple)])],
            ),
        ] + target_base_cpu_flag,
    )

def create_user_compile_flags_feature(ctx):
    return feature(
        name = "user_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_compile_flags}"],
                        iterate_over = "user_compile_flags",
                        expand_if_available = "user_compile_flags",
                    ),
                ],
            ),
        ],
    )

def create_unfiltered_compile_flags_feature(ctx):
    return feature(
        name = "unfiltered_compile_flags",
        flag_sets = [
            flag_set(
                actions = preprocessor_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{unfiltered_compile_flags}"],
                        iterate_over = "unfiltered_compile_flags",
                        expand_if_available = "unfiltered_compile_flags",
                    ),
                ],
            ),
        ],
    )

def create_msvc_runtime_compile_flags_feature(ctx):
    return feature(
        enabled = True,
        name = "msvc_runtime_compile_flags",
        flag_sets = [
            _msvc_runtime_compile_flag_set(use_static_runtime = True, compile_flag = "/MT"),
            _msvc_runtime_compile_flag_set(use_static_runtime = False, compile_flag = "/MD"),
        ],
    )

################################################ Link flags ############################################################

def create_shared_flag_feature(ctx):
    return feature(
        name = "shared_flag",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = [flag_group(flags = ["/DLL"])],
            ),
        ],
    )

def create_output_execpath_flags_feature(ctx):
    return feature(
        name = "output_execpath_flags",
        flag_sets = [
            flag_set(
                actions = all_link_actions + [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        flags = ["/OUT:%{output_execpath}"],
                        expand_if_available = "output_execpath",
                    ),
                ],
            ),
        ],
    )

def create_link_input_param_flags(ctx):
    return feature(
        name = "link_input_params",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["/IMPLIB:%{interface_library_output_path}"],
                        expand_if_available = "interface_library_output_path",
                    ),
                ],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{libopts}"],
                        iterate_over = "libopts",
                        expand_if_available = "libopts",
                    ),
                ],
            ),
        ],
    )

def create_target_platform_feature(ctx):
    return feature(
        name = "target_platform",
        flag_sets = [
            flag_set(
                actions = all_link_actions + [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        flags = ["/MACHINE:X64"],
                    ),
                ],
            ),
        ],
    )

def create_libraries_to_link_feature(ctx):
    return feature(
        name = "libraries_to_link",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions + [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        iterate_over = "libraries_to_link",
                        flag_groups = [
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file",
                                ),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "interface_library",
                                ),
                            ),
                            flag_group(
                                flag_groups = [
                                    flag_group(
                                        flags = ["%{libraries_to_link.name}"],
                                        expand_if_false = "libraries_to_link.is_whole_archive",
                                    ),
                                    flag_group(
                                        flags = ["/WHOLEARCHIVE:%{libraries_to_link.name}"],
                                        expand_if_true = "libraries_to_link.is_whole_archive",
                                    ),
                                ],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "static_library",
                                ),
                            ),
                            flag_group(
                                flag_groups = [
                                    flag_group(
                                        flags = ["-start-lib"],
                                        expand_if_false = "libraries_to_link.is_whole_archive",
                                    ),
                                    flag_group(
                                        flag_groups = [flag_group(flags = ["%{libraries_to_link.object_files}"])],
                                        iterate_over = "libraries_to_link.object_files",
                                    ),
                                    flag_group(
                                        flags = ["-end-lib"],
                                        expand_if_false = "libraries_to_link.is_whole_archive",
                                    ),
                                ],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file_group",
                                ),
                            ),
                        ],
                        expand_if_available = "libraries_to_link",
                    ),
                ],
            ),
        ],
    )

def create_default_link_flags_feature(ctx):
    return feature(
        name = "default_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "/NODEFAULTLIB",
                            _msvc_libraries_path + "oldnames.lib",
                            "external\\windows_sdk\\Lib\\um\\x64\\kernel32.lib",
                        ],
                    ),
                ],
            ),
            # Activates pdb generation
            # For more details on optimization and pdb generation please
            # have a look at: https://www.wintellect.com/correctly-creating-native-c-release-build-pdbs/
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    # Control the PDB generation by replacing the "/DEBUG" flag with an explicit mode.
                    # Use /DEBUG:FULL by default in both Debug and Release builds.
                    # For local Debug builds, /DEBUG:GHASH is a faster option, but works only with the LLDB debugger.
                    flag_group(flags = ["/DEBUG:FULL"]),
                    # Disables incremental linking which is implicitly enabled by /DEBUG
                    # Incremental linking isn't possible with Bazel anyway, and incremental
                    # linking may produce non-deterministic binaries.
                    flag_group(flags = ["/INCREMENTAL:NO"]),
                ],
            ),
            # Ensures that the optimization flags are set correctly in the case of "opt" compile mode
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    # DEBUG ensure generation of debug symbols
                    # /OPT:NOREF,NOICF, which is sensible for a real debug build but not
                    # for a release build with debug info.  The lack of /DEBUG implies
                    # /OPT:REF,ICF, which is much more sensible, but leads to issues with
                    # assumptions in our code that two different proxy methods would have
                    # two different function pointers.  For release builds, we should be
                    # sure to explicitly set our optimization flags, and until we can
                    # reduce our assumptions we should set those flags to /OPT:REF,NOICF.
                    #
                    # Reenables /OPT:REF which is implicitly disabled by /DEBUG
                    # OPT:REF only includes referenced symbols
                    flag_group(flags = ["/OPT:REF"]),
                    # Although /OPT:ICF is implicitly disabled by /DEBUG we set /OPT:NOICF explicitly
                    flag_group(flags = ["/OPT:NOICF"]),
                ],
                with_features = [with_feature_set(features = ["opt"])],
            ),
            flag_set(
                actions = [ACTION_NAMES.cpp_link_executable],
                flag_groups = [
                    # Extend the stack size, as some queries can end up using a lot of stack
                    # We only need to do this on Windows since only on Windows the default stack size is 1MB while it is 8MB on MacOS and Linux.
                    flag_group(flags = ["/STACK:{stack_size}".format(stack_size = 8 * 1024 * 1024)]),  #8 MB Stack Size
                    # Disable the generation of side by side manifests (.manifest file next to the binary) during linktime
                    flag_group(flags = ["/MANIFEST:NO"]),
                ],
            ),
        ],
    )

def create_user_link_flags_feature(ctx):
    return feature(
        name = "user_link_flags",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_link_flags}"],
                        iterate_over = "user_link_flags",
                        expand_if_available = "user_link_flags",
                    ),
                ],
            ),
        ],
    )

def create_linker_param_file_feature(ctx):
    return feature(
        name = "linker_param_file",
        flag_sets = [
            flag_set(
                actions = all_link_actions + [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        flags = ["@%{linker_param_file}"],
                        expand_if_available = "linker_param_file",
                    ),
                ],
            ),
        ],
    )

def create_archive_param_file_feature(ctx):
    return feature(name = "archive_param_file")

def create_linkstamps_feature(ctx):
    return feature(
        name = "linkstamps",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{linkstamp_paths}"],
                        iterate_over = "linkstamp_paths",
                        expand_if_available = "linkstamp_paths",
                    ),
                ],
            ),
        ],
    )

def create_def_file_feature(ctx):
    return feature(
        name = "def_file",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["/DEF:%{def_file_path}"],
                        expand_if_available = "def_file_path",
                    ),
                ],
            ),
        ],
    )

def create_pretty_printer_feature(ctx):
    return feature(
        name = "pretty_printing",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["/NATVIS:" + ctx.file._natvis.path],
                    ),
                ],
            ),
        ],
    )

def create_msvc_runtime_link_flags_feature(ctx):
    return feature(
        name = "msvc_runtime_link_flags",
        flag_sets = [
            _runtime_libraries_link_flag_set(provided_libraries_are_statics = True, libraries = {
                _ucrt_libraries_path: ["libucrt"],
                _msvc_libraries_path: ["libcmt", "libcpmt", "libvcruntime", "libconcrt"],
            }),
            _runtime_libraries_link_flag_set(provided_libraries_are_statics = False, libraries = {
                _ucrt_libraries_path: ["ucrt"],
                _msvc_libraries_path: ["msvcrt", "msvcprt", "vcruntime", "concrt"],
            }),
        ],
    )

def create_color_diagnostics_feature():
    return feature(
        name = "color_diagnostics",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["--color-diagnostics"],
                    ),
                ],
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-fcolor-diagnostics", "-fansi-escape-codes"],
                    ),
                ],
            ),
        ],
    )

def ignore_some_warnings_per_default():
    return feature(
        name = "ignore_some_warnings_per_default",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            # Necessary for grpc. Try removing after upgrading.
                            "-Wno-unknown-argument",
                            # Necessary for xz. Try removing after upgrading.
                            "-Wno-incompatible-pointer-types",
                        ],
                    ),
                ],
            ),
        ],
    )

def create_treat_warnings_as_errors_compiling_feature():
    return feature(
        name = "treat_warnings_as_errors_compiling",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-Werror"],
                    ),
                ],
            ),
        ],
    )

def create_treat_warnings_as_errors_linking_feature():
    return feature(
        name = "treat_warnings_as_errors_linking",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["/WX"],
                    ),
                ],
            ),
        ],
    )

def _msvc_runtime_compile_flag_set(use_static_runtime, compile_flag):
    return flag_set(
        actions = [ACTION_NAMES.c_compile, ACTION_NAMES.cpp_compile],
        flag_groups = [flag_group(flags = [compile_flag])],
        with_features = _create_required_features(use_static_runtime = use_static_runtime),
    )

def _runtime_libraries_link_flag_set(provided_libraries_are_statics, libraries):
    return flag_set(
        actions = all_link_actions,
        flag_groups = [flag_group(flags = _libs(libraries))],
        with_features = _create_required_features(use_static_runtime = provided_libraries_are_statics),
    )

def _libs(libraries):
    all_libraries = []
    for path, library_base_names in libraries.items():
        all_libraries.extend([path + "%s.lib" % (library_name) for library_name in library_base_names])
    return all_libraries

def _create_required_features(use_static_runtime):
    return [with_feature_set(
        features = ["static_link_msvcrt"] if use_static_runtime else [],
        not_features = [] if use_static_runtime else ["static_link_msvcrt"],
    )]
