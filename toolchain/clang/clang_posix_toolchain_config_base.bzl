# ===========================================================================
# Clang Toolchain (code shared between Linux and Darwin toolchain config)
#
# Bazel supports a list of abstract actions (ACTION_NAMES) that can be performed.
# A toolchain definition defines action_configs for these actions that describe
# which tool to use for which action and how.
# A features (like C++23) is a shared set of command line flags for multiple
# action configs and can be either enabled/disabled explicitily or specified
# as a requirement of action configs and therefore get enabled automatically,
# whenever the action config gets enabled.
# ===========================================================================

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "feature",
    "flag_group",
    "flag_set",
    "tool",
    "variable_with_value",
    "with_feature_set",
)
load(
    "//toolchain:clang/clang_toolchain_actions.bzl",
    "all_compile_actions",
    "all_cpp_compile_actions",
    "all_link_actions",
    "compile_actions_without_assemble",
    "lto_index_actions",
    "preprocessor_compile_actions",
)

# ---------------------------------------------------------------------------
# Action classes (used to easier assign features to actions)
# ---------------------------------------------------------------------------

# CLIF is a google tool for creating C++ wrappers, but not all language
# generators are publicly available. The action clif_match extracts the language
# agnostic model for a given C++ header. We don't need this, so all occurencies
# of ACTIONS_NAMES.clif_match in this file have been removed.
#
# The cpp module actions (cpp_header_parsing, cpp_module_compile, cpp_module_codegen)
# are not implemented yet, as only needed for C++20 modules.
#
# Toolchain doesn't contain objective C support, objc* actions have been removed.
#
# List of compiler flags that are used both in compile and link actions
# Conservative approach: Better give too much flags to either of both calls and let the
# compiler frontend ignore it, instead of missing flags.
shared_compile_and_link_flags = [
    # Security
    "-fstack-protector-strong",

    # `-fvisibility-inlines-hidden` causes inline functions to have hidden visibility by default.
    # `-fvisibility=hidden` sets the general visibility to hidden by default.
    # This reduces export symbol table size and binary size and enables certain link-time optimizations.
    # It also helps us avoid complex linking issues around `extern inline` functions; see `Visibility of Inline Functions` under
    #    https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/CppRuntimeEnv/Articles/SymbolVisibility.html
    # Note it may be necessary to override visibility where address identity is important (e.g., for inlines containing local static data).
    "-fvisibility-inlines-hidden",
    "-fvisibility=hidden",
]

# ---------------------------------------------------------------------------
# Toolchain config helper methods
# ---------------------------------------------------------------------------

def create_compile_flags_for_include_paths(include_paths):
    return [v for path in include_paths for v in ("-isystem", path)]

def create_toolchain_cxx_builtin_include_directories(include_paths):
    """ Unfortunately, Bazel is inconsistent in what the variables for substitution look like.
    Therefore, this function has to replace the flags-style sysroot variable with the
    cxx_builtin_include_directories-style variable.
    """
    return [path.replace("%{sysroot}", "%sysroot%") for path in include_paths]

# ---------------------------------------------------------------------------
# Helper methods for creating actions configs
# ---------------------------------------------------------------------------

def create_posix_action_configs(ar_path, clang_path, strip_path):
    """ Creates a list that defines all action configs with clang or the required tool.
    Documentation of all available actions: https://docs.bazel.build/versions/master/cc-toolchain-config-reference.html#actions
    """
    tool_ar = tool(path = ar_path)

    # We call `clang` for all actions and not `clang++` like CMake does.
    # Therefore `-lm` has to be passed explicitly if libmath is needed.
    tool_clang = tool(path = clang_path)
    tool_strip = tool(path = strip_path)

    return [
        action_config(
            # Assemble without preprocessing. Typically for .s files.
            action_name = ACTION_NAMES.assemble,
            tools = [tool_clang],
            implies = [
                "user_compile_flags",
                "sysroot",
                "unfiltered_compile_flags",
                "compiler_input_flags",
                "compiler_output_flags",
            ],
        ),
        action_config(
            # Assemble with preprocessing. Typically for .S files.
            action_name = ACTION_NAMES.preprocess_assemble,
            tools = [tool_clang],
            implies = [
                "user_compile_flags",
                "sysroot",
                "unfiltered_compile_flags",
                "compiler_input_flags",
                "compiler_output_flags",
                "hermetic_compile_and_link_flags",
            ],
        ),
        action_config(
            action_name = ACTION_NAMES.linkstamp_compile,
            tools = [tool_clang],
            implies = [
                "user_compile_flags",
                "sysroot",
                "unfiltered_compile_flags",
                "compiler_input_flags",
                "compiler_output_flags",
            ],
        ),
        action_config(
            # ThinLTO action compiling bitcodes into native objects.
            action_name = ACTION_NAMES.lto_backend,
            tools = [tool_clang],
            implies = [
                "user_compile_flags",
                "sysroot",
                "unfiltered_compile_flags",
                "compiler_input_flags",
                "compiler_output_flags",
            ],
        ),
        action_config(
            # Compile as C
            action_name = ACTION_NAMES.c_compile,
            tools = [tool_clang],
            implies = [
                "user_compile_flags",
                "sysroot",
                "unfiltered_compile_flags",
                "compiler_input_flags",
                "compiler_output_flags",
                "hermetic_compile_and_link_flags",
            ],
        ),
        action_config(
            # Compile as C++
            action_name = ACTION_NAMES.cpp_compile,
            tools = [tool_clang],
            implies = [
                "user_compile_flags",
                "sysroot",
                "unfiltered_compile_flags",
                "compiler_input_flags",
                "compiler_output_flags",
                "hermetic_compile_and_link_flags",
            ],
        ),
        action_config(
            # Link a final ready-to-run library
            action_name = ACTION_NAMES.cpp_link_executable,
            tools = [tool_clang],
            implies = [
                "symbol_counts",
                "strip_debug_symbols",
                "linkstamps",
                "output_execpath_flags",
                "runtime_library_search_directories",
                "library_search_directories",
                "libraries_to_link",
                "force_pic_flags",
                "user_link_flags",
                "linker_param_file",
                "sysroot",
            ],
        ),
        action_config(
            # ThinLTO action generating global index
            action_name = ACTION_NAMES.lto_index_for_executable,
            tools = [tool_clang],
            implies = [
                "symbol_counts",
                "strip_debug_symbols",
                "linkstamps",
                "output_execpath_flags",
                "runtime_library_search_directories",
                "library_search_directories",
                "libraries_to_link",
                "force_pic_flags",
                "user_link_flags",
                "linker_param_file",
                "sysroot",
            ],
        ),
        action_config(
            # Link a shared library only containing cc_library sources
            action_name = ACTION_NAMES.cpp_link_nodeps_dynamic_library,
            tools = [tool_clang],
            implies = [
                "symbol_counts",
                "strip_debug_symbols",
                "shared_flag",
                "linkstamps",
                "output_execpath_flags",
                "runtime_library_search_directories",
                "library_search_directories",
                "libraries_to_link",
                "user_link_flags",
                "linker_param_file",
                "sysroot",
            ],
        ),
        action_config(
            # ThinLTO action generating global index
            action_name = ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
            tools = [tool_clang],
            implies = [
                "symbol_counts",
                "strip_debug_symbols",
                "shared_flag",
                "linkstamps",
                "output_execpath_flags",
                "runtime_library_search_directories",
                "library_search_directories",
                "libraries_to_link",
                "user_link_flags",
                "linker_param_file",
                "fission_support",
                "sysroot",
            ],
        ),
        action_config(
            # Link a shared library containing all of its dependencies
            action_name = ACTION_NAMES.cpp_link_dynamic_library,
            tools = [tool_clang],
            implies = [
                "symbol_counts",
                "strip_debug_symbols",
                "shared_flag",
                "linkstamps",
                "output_execpath_flags",
                "runtime_library_search_directories",
                "library_search_directories",
                "libraries_to_link",
                "user_link_flags",
                "linker_param_file",
                "sysroot",
            ],
        ),
        action_config(
            # ThinLTO action generating global index
            action_name = ACTION_NAMES.lto_index_for_dynamic_library,
            tools = [tool_clang],
            implies = [
                "symbol_counts",
                "strip_debug_symbols",
                "shared_flag",
                "linkstamps",
                "output_execpath_flags",
                "runtime_library_search_directories",
                "library_search_directories",
                "libraries_to_link",
                "user_link_flags",
                "linker_param_file",
                "sysroot",
            ],
        ),
        action_config(
            # Create a static library (archive)
            action_name = ACTION_NAMES.cpp_link_static_library,
            tools = [tool_ar],
            implies = [
                "archiver_flags",
                "linker_param_file",
            ],
        ),
        action_config(
            # Strip binary and remove symbols
            action_name = ACTION_NAMES.strip,
            tools = [tool_strip],
            flag_sets = [
                flag_set(
                    flag_groups = [
                        flag_group(
                            flags = ["-S", "-o", "%{output_file}"],
                        ),
                        flag_group(
                            iterate_over = "stripopts",
                            flags = ["%{stripopts}"],
                        ),
                        flag_group(
                            flags = ["%{input_file}"],
                        ),
                    ],
                ),
            ],
        ),
    ]

# ---------------------------------------------------------------------------
# Helper methods for creating features
# ---------------------------------------------------------------------------

def create_posix_default_features(
        default_defines,
        ld,
        sysroot_enabled,
        shared_flag,
        supports_start_end_lib,
        dynamic_lookup_for_undefined_symbols,
        runtime_library_search_directories_base,
        whole_archive_linker_flag,
        no_whole_archive_linker_flag,
        solib_name_flag,
        clang_resource_directory,
        target_architecture_triple,
        target_base_cpu,
        supported_instruction_set_extensions,
        default_instruction_set_extensions,
        platform_specific_compile_flags = [],
        platform_specific_link_flags = [],
        platform_specifc_link_flags_for_position_independent_executables = [],
        link_libs = [],
        additional_features = []):
    """ Create list of explicitly defined standard features for the toolchain.
    """
    return [
        # Disabled all legacy features first
        feature("no_legacy_features", enabled = True),

        # Then add all needed features manually
        # CAUTION: The order of the features is important!
        # https://docs.bazel.build/versions/master/cc-toolchain-config-reference.html#well-known-features
    ] + create_compilation_mode_features() + [

        # Well-known features
        feature(name = "supports_start_end_lib", enabled = supports_start_end_lib),
        feature(name = "supports_dynamic_linker", enabled = True),
        feature(name = "static_link_cpp_runtimes", enabled = True),
        feature(name = "supports_pic", enabled = True),

        # Custom features (don't exist in Bazel by default)
        feature(name = "c++23"),
        feature(name = "c++14"),
        feature(name = "c++11"),

        # Create features for instruction set extensions like SSE
    ] + create_instruction_set_extension_features(supported_instruction_set_extensions, default_instruction_set_extensions) + [
        create_target_architecture_feature(target_architecture_triple, target_base_cpu),
        create_sanitizer_feature("address"),
        create_sanitizer_feature("undefined_behavior"),
        create_sanitizer_feature("thread"),
        create_sanitizer_feature("memory"),
        create_sanitizer_feature("fuzzer"),
        create_sanitizer_feature("fuzzer-no-link"),
        create_objcopy_embed_flags_feature(),

        # Legacy-known features
        create_default_compile_flags_feature(),
        create_verbose_flags_feature(),
        create_platform_specific_compile_flags_feature(platform_specific_compile_flags),

        # Legacy features
        create_dependency_file_feature(),
        create_pic(),
        create_per_object_debug_info_feature(),
        create_preprocessor_defines_feature(),
        create_includes_feature(),
        create_include_paths_feature(),
        create_symbol_counts_feature(),
        create_shared_flag_feature(shared_flag, dynamic_lookup_for_undefined_symbols),
        create_linkstamps_feature(),
        create_output_execpath_flags_feature(),
        create_runtime_library_search_directories_feature(runtime_library_search_directories_base),
        create_library_search_directories_feature(),
        create_archiver_flags_feature(),
        create_libraries_to_link_feature(whole_archive_linker_flag, no_whole_archive_linker_flag),

        # Forces PIC compilation not only for shared libraries, but for all compile units
        # Is triggered by commandline switch --force_pic
        create_pie_flags(platform_specifc_link_flags_for_position_independent_executables),
        create_debug_fission_support_feature(),
        create_strip_debug_symbols_feature(),
        create_fully_static_link(),

        # Only enable sysroot feature if a sysroot is provided to the toolchain
        create_sysroot_feature(enabled = sysroot_enabled),
        create_unfiltered_compile_flags_feature(),
        create_hermetic_compile_and_link_flags_feature(default_defines, clang_resource_directory),
        create_linker_param_file_feature(),
        create_compiler_input_flags(),
        create_compiler_output_flags(),
        create_default_link_flags_feature(ld),
        create_platform_specific_link_flags_feature(platform_specific_link_flags),
        create_solib_name_feature(solib_name_flag),

        # Forces PIC compilation, even if the PIC features is disabled
        # Should be manually specified on certain libraries
        create_force_pic(),

        # We ignore some warnings in our toolchain per default so they don't pop up in third-party builds
        ignore_some_warnings_per_default(),
        # Enable Werror flag for compiling actions
        create_treat_warnings_as_errors_compiling_feature(),
        # Enable Werror flag for linking
        create_treat_warnings_as_errors_linking_feature(),

        # The user compile and link flags *must* be the last features in the list!
        # Example: locally disable a compiler warning with -Wno-cast-qual that is previously set in a feature
    ] + additional_features + [

        # To allow users to override linker and compile flags these flags must be provided last
        create_user_compile_flags_feature(),
        create_user_link_flags_feature(link_libs),
        create_color_diagnostics_feature(),
    ]

def create_default_compile_flags_feature():
    flag_sets = [
        flag_set(
            actions = compile_actions_without_assemble,
            flag_groups = [
                flag_group(
                    flags = shared_compile_and_link_flags,
                ),
            ],
        ),
        flag_set(
            actions = [ACTION_NAMES.c_compile],
            # Workaround for char16_t compatibility
            flag_groups = [flag_group(flags = ["-Dchar16_t=uint16_t"])],
        ),
        flag_set(
            actions = all_cpp_compile_actions,
            flag_groups = [flag_group(flags = ["-std=c++11"])],
            with_features = [with_feature_set(features = ["c++11"])],
        ),
        flag_set(
            actions = all_cpp_compile_actions,
            flag_groups = [flag_group(flags = ["-std=c++14"])],
            with_features = [with_feature_set(features = ["c++14"])],
        ),
        # Use C++23 by default
        flag_set(
            actions = all_cpp_compile_actions,
            flag_groups = [flag_group(flags = ["-std=c++23"])],
            with_features = [with_feature_set(not_features = ["c++11", "c++14"])],
        ),
        # Enable experimental features in libc++
        flag_set(
            actions = all_cpp_compile_actions,
            flag_groups = [flag_group(flags = ["-fexperimental-library"])],
        ),
        flag_set(
            actions = all_compile_actions,
            flag_groups = [
                flag_group(
                    flags = [
                        "-D_FORTIFY_SOURCE=1",  # Enable run-time buffer overflow detection.
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

def create_verbose_flags_feature():
    return feature(
        name = "verbose",
        enabled = False,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = ["-v"])],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = ["-Wl,-v"])],
            ),
        ],
    )

def create_target_architecture_feature(target_architecture_triple, target_base_cpu):
    target_base_cpu_flag = [
        flag_set(
            actions = all_compile_actions + all_link_actions,
            flag_groups = [flag_group(flags = ["-march={target_base_cpu}".format(target_base_cpu = target_base_cpu)])],
        ),
    ] if target_base_cpu else []

    return feature(
        name = "target_architecture",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions + all_link_actions,
                flag_groups = [flag_group(flags = ["--target={target_architecture_triple}".format(target_architecture_triple = target_architecture_triple)])],
            ),
        ] + target_base_cpu_flag,
    )

def create_compilation_mode_features():
    # We share this flagset between fastbuild and debug as the previous fastbuild options
    # were slower than this.
    dbg_flagsets = [
        flag_set(
            actions = all_compile_actions,
            flag_groups = [
                flag_group(flags = [
                    "-O0",  # Disable optimization
                    "-g",  # Enable debug symbols
                    "-fstandalone-debug",  # Disable debug optimizations
                    "-D_LIBCPP_ENABLE_ASSERTIONS=1",  # Enable debug assertions in libc++
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
                            "-O3",  # Set optimization level
                            "-g",  # Enable debug symbols
                            "-DNDEBUG",  # Disable debug code paths
                        ]),
                    ],
                ),
            ],
        ),
        feature(
            name = "fastbuild",
            flag_sets = dbg_flagsets,
        ),
        feature(
            name = "dbg",
            flag_sets = dbg_flagsets,
        ),
    ]

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

def create_sanitizer_feature(sanitizer_name):
    compiler_flags = []
    linker_flags = []
    if sanitizer_name == "undefined_behavior":
        # Set up the compile flags for UndefinedBehaviorSanitizer.
        #
        # Instead of a `-fsanitize=undefined` we enable only a subset of checks here.
        # We use `-fno-sanitize-recover` to exit the program immediately rather than `-fsanitize`, which would continue execution.
        #
        # Note: The following checks are intentionally _not_ enabled:
        #    alignment: Use of a misaligned pointer or creation of a misaligned reference.
        #       Currently, many alignment issues that are non-issues on x86 CPUs are reported.
        #    vptr: Use of an object whose vptr indicates that it is of the wrong dynamic type, or that its lifetime has not begun or has ended.
        #       This check requires all libraries to be compiled with RTTI.
        #
        # Note: Futher checks to try:
        #    builtin
        #    function
        #    implicit-conversion [implicit-unsigned-integer-truncation, implicit-signed-integer-truncation, implicit-integer-sign-change]
        #    nullability [nullability-arg, nullability-assign, nullability-return]
        #    pointer-overflow
        #    unsigned-integer-overflow
        ubsan_flags = [
            "-fno-sanitize-recover=bool",
            "-fno-sanitize-recover=bounds",
            "-fno-sanitize-recover=enum",
            "-fno-sanitize-recover=float-cast-overflow",
            "-fno-sanitize-recover=float-divide-by-zero",
            "-fno-sanitize-recover=integer-divide-by-zero",
            "-fno-sanitize-recover=nonnull-attribute",
            "-fno-sanitize-recover=null",
            "-fno-sanitize-recover=object-size",
            "-fno-sanitize-recover=return",
            "-fno-sanitize-recover=returns-nonnull-attribute",
            "-fno-sanitize-recover=shift",
            "-fno-sanitize-recover=signed-integer-overflow",
            "-fno-sanitize-recover=unreachable",
            "-fno-sanitize-recover=vla-bound",
        ]
        compiler_flags += ubsan_flags
        linker_flags += ubsan_flags
    else:
        sanitizer_flag = "-fsanitize=" + sanitizer_name
        compiler_flags.append(sanitizer_flag)
        linker_flags.append(sanitizer_flag)
    if sanitizer_name == "fuzzer":
        feature_name = "fuzzer"
    elif sanitizer_name == "fuzzer-no-link":
        feature_name = "fuzzer-no-link"

        # Add the "Fuzzer-friendly build mode" flag as suggested on the libfuzzer documentation: https://llvm.org/docs/LibFuzzer.html#fuzzer-friendly-build-mode
        # This mode should only be used for code that we are sure we want to ignore during fuzzing (i.e. CRC checks on files), we specifically only add it
        # to the "fuzzer-no-link" because that is when the fuzzer instrumentation is built into the build, the "fuzzer" sanitizer is where the fuzzer main
        # is linked into the binary
        compiler_flags.append("-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION")
    else:
        feature_name = sanitizer_name + "_sanitizer"
    compiler_flags.append("-fno-omit-frame-pointer")
    return feature(
        name = feature_name,
        flag_sets = [
            flag_set(
                actions = all_cpp_compile_actions,
                flag_groups = [flag_group(flags = compiler_flags)],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = linker_flags)],
            ),
        ],
    )

def create_platform_specific_compile_flags_feature(platform_specific_compile_flags):
    return feature(
        name = "platform_specific_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = platform_specific_compile_flags,
                    ),
                ],
            ),
            flag_set(
                actions = compile_actions_without_assemble,
                flag_groups = [
                    flag_group(
                        flags = [
                            # Set `-faligned-allocation` to tell Clang explicitly that aligned (de-)allocation is supported.
                            # Define _LIBCPP_DISABLE_AVAILABILITY so that libc++/libc++abi ignore visibility annotations such as `((availability(macosx,strict,introduced=...))`.
                            # Note: If we do not do this, Clang/libc++/libc++abi will hide C++ functionality according to the specified `-mmacos-version-min compile` option,
                            #       based on the assumption that the libc++/libc++abi of the targeted macOS will be linked dynamically.
                            #       This assumption does not hold for us, as we link libc++/libc++abi statically.
                            # Background: https://reviews.llvm.org/D34556
                            "-faligned-allocation",
                            "-D_LIBCPP_DISABLE_AVAILABILITY",
                        ],
                    ),
                ],
                with_features = [with_feature_set(features = ["static_link_cpp_runtimes"])],
            ),
        ],
    )

def create_objcopy_embed_flags_feature():
    return feature(
        name = "objcopy_embed_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = ["objcopy_embed_data"],
                flag_groups = [flag_group(flags = ["-I", "binary"])],
            ),
        ],
    )

def create_unfiltered_compile_flags_feature():
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

def create_hermetic_compile_and_link_flags_feature(default_defines, clang_resource_directory):
    return feature(
        name = "hermetic_compile_and_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wno-ambiguous-reversed-operator",
                            "-I" + default_defines.dirname,
                            "-include" + default_defines.basename,
                            # Disable default c++ include paths, all c++ include paths will be set given explicitly
                            "-nostdinc++",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = all_compile_actions + all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            # Do not resolve our symlinked resource prefixes to real paths.
                            "-no-canonical-prefixes",
                            # Explicitly set clang resource directory to avoid problems if default contains full path
                            "-resource-dir",
                            clang_resource_directory,
                        ],
                    ),
                ],
            ),
        ],
    )

def create_archiver_flags_feature():
    return feature(
        name = "archiver_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        flags = ["rcsD"],
                    ),
                    flag_group(
                        expand_if_available = "output_execpath",
                        flags = ["%{output_execpath}"],
                    ),
                    flag_group(
                        expand_if_available = "libraries_to_link",
                        iterate_over = "libraries_to_link",
                        flag_groups = [
                            flag_group(
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file",
                                ),
                                flags = ["%{libraries_to_link.name}"],
                            ),
                            flag_group(
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file_group",
                                ),
                                iterate_over = "libraries_to_link.object_files",
                                flags = ["%{libraries_to_link.object_files}"],
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

def create_default_link_flags_feature(ld):
    return feature(
        name = "default_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            # Make clang use the provided linker (-B sets the clang tool search path)
                            "-B" + ld.dirname,
                            "-fuse-ld=" + ld.basename,
                            # Compiler runtime features.
                            "--rtlib=compiler-rt",
                        ] + shared_compile_and_link_flags,
                    ),
                ],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            # "Projects that want to statically link their own C++ standard library
                            # need to pass -nostdlib or -nodefaultlibs, which also disables linking of the builtins library"
                            # (https://reviews.llvm.org/D35780)
                            "-nostdlib++",
                        ],
                    ),
                ],
                with_features = [with_feature_set(features = ["static_link_cpp_runtimes"])],
            ),
        ],
    )

def create_platform_specific_link_flags_feature(linker_flags):
    """ Create a feature with additional platform specific linker flags for all linker actions.

    If conditional linker flags are required, refactor the function to take a whole flag_group
    """
    return feature(
        name = "platform_specific_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = linker_flags,
                    ),
                ],
            ),
        ],
    )

# Bazel default for runtime_library_search_directories is more complex
# It has a special casing where EXEC_ORIGIN is used
# https://source.bazel.build/bazel/+/master:src/main/java/com/google/devtools/build/lib/rules/cpp/CppActionConfigs.java?q=cppactionconfigs&ss=bazel
def create_runtime_library_search_directories_feature(runtime_library_search_directories_base):
    # If $ORIGIN is used as the base, also add `-Wl,-z,origin` to the flags.
    # `-Wl,-z,origin` instructs the linker to mark the target binary with the ORIGIN flag.
    # The ORIGIN flag in turn indicates to the loader that the RPATHs may contain a $ORIGIN variable to be processed.
    if (runtime_library_search_directories_base == "$ORIGIN"):
        origin_flag_if_needed = ["-Wl,-z,origin"]
    else:
        origin_flag_if_needed = []

    return feature(
        name = "runtime_library_search_directories",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        iterate_over = "runtime_library_search_directories",
                        flags = origin_flag_if_needed + ["-Wl,-rpath," + runtime_library_search_directories_base + "/%{runtime_library_search_directories}"],
                    ),
                ],
            ),
        ],
    )

def create_library_search_directories_feature():
    return feature(
        name = "library_search_directories",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-L%{library_search_directories}"],
                        iterate_over = "library_search_directories",
                        expand_if_available = "library_search_directories",
                    ),
                ],
            ),
        ],
    )

def create_solib_name_feature(soname_flag):
    """
    This feature is required to embed the proper solib_name/install_name in shared libraries
    This embedded name is later on required when linking the final binary
    """
    return feature(
        name = "solib_name",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            soname_flag + "%{runtime_solib_name}",
                        ],
                        expand_if_available = "runtime_solib_name",
                    ),
                ],
            ),
        ],
    )

def create_pic():
    return feature(
        name = "pic",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        expand_if_available = "pic",
                        flags = ["-fPIC"],
                    ),
                ],
            ),
        ],
    )

def create_force_pic():
    return feature(
        name = "force_pic",
        enabled = False,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        expand_if_not_available = "pic",
                        flags = ["-fPIC"],
                    ),
                ],
            ),
        ],
    )

def create_pie_flags(platform_specifc_link_flags_for_position_independent_executables):
    return feature(
        name = "force_pic_flags",
        enabled = False,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_executable,
                    ACTION_NAMES.lto_index_for_executable,
                ],
                flag_groups = [
                    flag_group(
                        # Note: To avoid getting warnings while compiling, we need to set "pie" for linux and "-Wl,-pie" for MacOS
                        flags = platform_specifc_link_flags_for_position_independent_executables,
                        expand_if_available = "force_pic",
                    ),
                ],
            ),
        ],
    )

def create_dependency_file_feature():
    return feature(
        name = "dependency_file",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_header_parsing,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-MD", "-MF", "%{dependency_file}"],
                        expand_if_available = "dependency_file",
                    ),
                ],
            ),
        ],
    )

def create_per_object_debug_info_feature():
    return feature(
        name = "per_object_debug_info",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_codegen,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-gsplit-dwarf"],
                        # This is the compile-time part of fission.
                        # The "per_object_debug_info_file" variable is set by Bazel when fission is used
                        expand_if_available = "per_object_debug_info_file",
                    ),
                ],
            ),
        ],
    )

def create_preprocessor_defines_feature():
    return feature(
        name = "preprocessor_defines",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = preprocessor_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-D%{preprocessor_defines}"],
                        iterate_over = "preprocessor_defines",
                    ),
                ],
            ),
        ],
    )

def create_includes_feature():
    return feature(
        name = "includes",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = preprocessor_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-include", "%{includes}"],
                        iterate_over = "includes",
                        expand_if_available = "includes",
                    ),
                ],
            ),
        ],
    )

def create_include_paths_feature():
    return feature(
        name = "include_paths",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = preprocessor_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-iquote", "%{quote_include_paths}"],
                        iterate_over = "quote_include_paths",
                    ),
                    flag_group(
                        flags = ["-I", "%{include_paths}"],
                        iterate_over = "include_paths",
                    ),
                    flag_group(
                        flags = ["-isystem", "%{system_include_paths}"],
                        iterate_over = "system_include_paths",
                    ),
                ],
            ),
        ],
    )

def create_symbol_counts_feature():
    return feature(
        name = "symbol_counts",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wl,--print-symbol-counts=%{symbol_counts_output}",
                        ],
                        expand_if_available = "symbol_counts_output",
                    ),
                ],
            ),
        ],
    )

def create_shared_flag_feature(flag, dynamic_lookup_for_undefined_symbols):
    flag_sets = [
        flag_set(
            actions = [
                ACTION_NAMES.cpp_link_dynamic_library,
                ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ACTION_NAMES.lto_index_for_dynamic_library,
                ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
            ],
            flag_groups = [flag_group(flags = [flag])],
        ),
    ]

    if dynamic_lookup_for_undefined_symbols:
        flag_sets.append(flag_set(
            actions = [
                ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
            ],
            # Mark all undefined symbols as having to be looked up at runtime.
            # https://github.com/bazelbuild/bazel/issues/492
            flag_groups = [flag_group(flags = ["-undefined", "dynamic_lookup"])],
        ))

    return feature(
        name = "shared_flag",
        flag_sets = flag_sets,
    )

def create_linkstamps_feature():
    return feature(
        name = "linkstamps",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
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

def create_output_execpath_flags_feature():
    return feature(
        name = "output_execpath_flags",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-o", "%{output_execpath}"],
                        expand_if_available = "output_execpath",
                    ),
                ],
            ),
        ],
    )

def create_libraries_to_link_feature(whole_archive_linker_flag = None, no_whole_archive_linker_flag = None):
    libraries_to_link_flag_groups = []

    libraries_to_link_flag_groups.append(
        flag_group(
            flags = ["-Wl,--start-lib"],
            expand_if_equal = variable_with_value(
                name = "libraries_to_link.type",
                value = "object_file_group",
            ),
            expand_if_false = "libraries_to_link.is_whole_archive",
        ),
    )

    if (whole_archive_linker_flag):
        libraries_to_link_flag_groups.append(
            flag_group(
                flags = ["-Wl,{whole_archive_linker_flag}".format(
                    whole_archive_linker_flag = whole_archive_linker_flag,
                )],
                expand_if_true =
                    "libraries_to_link.is_whole_archive",
            ),
        )

    libraries_to_link_flag_groups.append(
        flag_group(
            flags = ["%{libraries_to_link.object_files}"],
            iterate_over = "libraries_to_link.object_files",
            expand_if_equal = variable_with_value(
                name = "libraries_to_link.type",
                value = "object_file_group",
            ),
        ),
    )

    libraries_to_link_flag_groups.append(
        flag_group(
            flags = ["%{libraries_to_link.name}"],
            expand_if_equal = variable_with_value(
                name = "libraries_to_link.type",
                value = "object_file",
            ),
        ),
    )

    libraries_to_link_flag_groups.append(
        flag_group(
            flags = ["%{libraries_to_link.name}"],
            expand_if_equal = variable_with_value(
                name = "libraries_to_link.type",
                value = "interface_library",
            ),
        ),
    )

    libraries_to_link_flag_groups.append(
        flag_group(
            flags = ["%{libraries_to_link.name}"],
            expand_if_equal = variable_with_value(
                name = "libraries_to_link.type",
                value = "static_library",
            ),
        ),
    )

    libraries_to_link_flag_groups.append(
        flag_group(
            flags = ["-l%{libraries_to_link.name}"],
            expand_if_equal = variable_with_value(
                name = "libraries_to_link.type",
                value = "dynamic_library",
            ),
        ),
    )

    libraries_to_link_flag_groups.append(
        flag_group(
            flags = ["-l:%{libraries_to_link.name}"],
            expand_if_equal = variable_with_value(
                name = "libraries_to_link.type",
                value = "versioned_dynamic_library",
            ),
        ),
    )

    if (no_whole_archive_linker_flag):
        libraries_to_link_flag_groups.append(
            flag_group(
                flags = ["-Wl,{no_whole_archive_linker_flag}".format(
                    no_whole_archive_linker_flag = no_whole_archive_linker_flag,
                )],
                expand_if_true = "libraries_to_link.is_whole_archive",
            ),
        )

    libraries_to_link_flag_groups.append(
        flag_group(
            flags = ["-Wl,--end-lib"],
            expand_if_equal = variable_with_value(
                name = "libraries_to_link.type",
                value = "object_file_group",
            ),
            expand_if_false = "libraries_to_link.is_whole_archive",
        ),
    )

    return feature(
        name = "libraries_to_link",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        iterate_over = "libraries_to_link",
                        flag_groups = libraries_to_link_flag_groups,
                        expand_if_available = "libraries_to_link",
                    ),
                    flag_group(
                        flags = ["-Wl,@%{thinlto_param_file}"],
                        expand_if_true = "thinlto_param_file",
                    ),
                ],
            ),
        ],
    )

def create_user_link_flags_feature(link_libs):
    return feature(
        name = "user_link_flags",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_link_flags}"],
                        iterate_over = "user_link_flags",
                        expand_if_available = "user_link_flags",
                    ),
                ] + ([flag_group(flags = link_libs)] if link_libs else []),
            ),
        ],
    )

def create_debug_fission_support_feature():
    return feature(
        name = "fission_support",
        enabled = True,  # Enabled by default, disabled explicitly for opt-release
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-Wl,--gdb-index"],
                        # This is the link-time part of fission.
                        # If fission is used, the feature "per_object_debug_info" is being activated automatically
                        expand_if_available = "is_using_fission",
                    ),
                ],
            ),
        ],
    )

def create_strip_debug_symbols_feature():
    return feature(
        name = "strip_debug_symbols",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-Wl,-S"],
                        expand_if_available = "strip_debug_symbols",
                    ),
                ],
            ),
        ],
    )

def create_fully_static_link():
    return feature(
        name = "fully_static_link",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [flag_group(flags = ["-static"])],
            ),
        ],
    )

def create_user_compile_flags_feature():
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

def create_sysroot_feature(enabled):
    return feature(
        name = "sysroot",
        enabled = enabled,
        flag_sets = [
            flag_set(
                actions = compile_actions_without_assemble + all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "--sysroot",
                            "%{sysroot}",
                            "-isysroot",
                            "%{sysroot}",
                            "-isystem",
                            "%{sysroot}/usr/include",
                        ],
                        expand_if_available = "sysroot",
                    ),
                ],
            ),
        ],
    )

def create_linker_param_file_feature():
    return feature(
        name = "linker_param_file",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["@%{linker_param_file}"],
                        expand_if_available = "linker_param_file",
                    ),
                ],
            ),
            flag_set(
                actions = [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        flags = ["@%{linker_param_file}"],
                        expand_if_available = "linker_param_file",
                    ),
                ],
            ),
        ],
    )

def create_compiler_input_flags():
    return feature(
        name = "compiler_input_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-c", "%{source_file}"],
                        expand_if_available = "source_file",
                    ),
                ],
            ),
        ],
    )

def create_compiler_output_flags():
    return feature(
        name = "compiler_output_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-S"],
                        expand_if_available = "output_assembly_file",
                    ),
                ],
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-E"],
                        expand_if_available = "output_preprocess_file",
                    ),
                ],
            ),
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-o", "%{output_file}"],
                        expand_if_available = "output_file",
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
                            # Necessary for `ATOMIC_VAR_INIT` used by protobuf
                            "-Wno-deprecated-pragma",
                            # Necessary for absl which we need for grpc
                            "-Wno-deprecated-builtins",
                            # Necessary for grpc
                            "-Wno-missing-constinit",
                            # Necessary for grpc
                            "-Wno-deprecated-declarations",
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
                        flags = ["-Werror"],
                    ),
                ],
            ),
        ],
    )

def create_color_diagnostics_feature():
    return feature(
        name = "color_diagnostics",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions + all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-fcolor-diagnostics"],
                    ),
                ],
            ),
        ],
    )
