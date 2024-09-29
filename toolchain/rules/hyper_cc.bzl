# Wrappers around the Bazel cc-rules that set specific properties for code we own.
# All targets with code we own should use these macros instead of the native cc-rules.

load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library", "cc_test")
load("//toolchain/helper:condition_helpers.bzl", "list_for")
load("//toolchain/helper:label_helpers.bzl", "get_label_info", "unique_labels")
load("//toolchain/rules:dsym.bzl", "dsym")
load("//toolchain/rules:exported_symbols.bzl", "linux_lds_script", "linux_version_script", "mac_exported_symbols", "windows_def_file")

# Shared features across hyper cc targets
HYPER_TOOLCHAIN_FEATURES = ["hyper_warning_flags", "hyper_cxx20_compat", "hyper_platform_defines", "-ignore_some_warnings_per_default"]

def add_target_visibility(current, target):
    if "//visibility:public" in current:
        # Already visible to target
        return current
    if "//visibility:private" in current:
        # Instead of private we just change it to our target
        return [target]
    else:
        return current + [target]

def hyper_cc_library(
        name,
        deps = [],
        implementation_deps = None,
        srcs = [],
        data = [],
        hdrs = [],
        alwayslink = False,
        compatible_with = [],
        copts = [],
        defines = [],
        deprecation = None,
        exec_compatible_with = [],
        features = [],
        includes = [],
        include_prefix = None,
        licenses = [],
        linkopts = [],
        linkstatic = True,
        local_defines = [],
        nocopts = None,
        restricted_to = None,
        strip_include_prefix = None,
        tags = [],
        target_compatible_with = None,
        testonly = False,
        textual_hdrs = [],
        toolchains = [],
        visibility = []):
    label_info = get_label_info(name)
    full_package_name = "//" + label_info.package_name + ":" + label_info.package_relative_target

    # Ensure that every default visbility binary can be included in the compilation_database.json
    visibility = add_target_visibility(visibility, "//:__pkg__")

    cc_library(
        name = name,
        deps = deps,
        implementation_deps = implementation_deps,
        srcs = srcs,
        data = data,
        hdrs = hdrs,
        alwayslink = alwayslink,
        compatible_with = compatible_with,
        copts = copts,
        defines = defines,
        deprecation = deprecation,
        exec_compatible_with = exec_compatible_with,
        features = HYPER_TOOLCHAIN_FEATURES + features,
        include_prefix = include_prefix,
        includes = includes,
        licenses = licenses,
        linkopts = linkopts,
        linkstatic = linkstatic,
        local_defines = local_defines,
        nocopts = nocopts,
        restricted_to = restricted_to,
        strip_include_prefix = strip_include_prefix,
        tags = tags + ["check-clang-tidy"],
        target_compatible_with = target_compatible_with,
        testonly = testonly,
        textual_hdrs = textual_hdrs,
        toolchains = toolchains,
        visibility = visibility,
    )

def hyper_cc_binary(
        name,
        deps = [],
        srcs = [],
        data = [],
        additional_linker_inputs = [],
        args = [],
        compatible_with = [],
        copts = [],
        defines = [],
        deprecation = None,
        exec_compatible_with = [],
        features = [],
        licenses = [],
        linkopts = [],
        linkshared = False,
        linkstatic = True,
        local_defines = [],
        malloc = None,
        nocopts = None,
        output_licenses = None,
        restricted_to = None,
        stamp = -1,
        tags = [],
        target_compatible_with = None,
        testonly = False,
        toolchains = [],
        visibility = [],
        sym_file = None):
    label_info = get_label_info(name)
    full_package_name = "//" + label_info.package_name + ":" + label_info.package_relative_target
    if sym_file:
        win_def_file = name + ".def"
        linux_linker_version_script = name + ".ver"
        darwin_exported_symbols_file = name + ".exp"
        linux_linker_script = name + ".lds"

        windows_def_file(
            name = win_def_file,
            sym_file = sym_file,
            target_compatible_with = ["@platforms//os:windows"],
        )

        if linkshared:
            linux_version_script(
                name = linux_linker_version_script,
                sym_file = sym_file,
                target_compatible_with = ["@platforms//os:linux"],
            )
        else:
            linux_lds_script(
                name = linux_linker_script,
                sym_file = sym_file,
                target_compatible_with = ["@platforms//os:linux"],
            )

        mac_exported_symbols(
            name = darwin_exported_symbols_file,
            sym_file = sym_file,
            target_compatible_with = ["@platforms//os:osx"],
        )

    deps = deps + (select({
        "//toolchain/platforms:is_linux": [linux_linker_version_script if linkshared else linux_linker_script],
        "//toolchain/platforms:is_macos": [darwin_exported_symbols_file],
        "//toolchain/platforms:is_windows": [win_def_file] if not linkshared else [],
    }) if sym_file else []) + list_for(["//toolchain/platforms:is_windows"], ["//toolchain/toolchain/clang/windows:windows_enable_long_path_support"])

    data = data + ["//thirdparty/clang:sanitizer_support"]

    # Ensure that non globally enforced binaries can be included in the compilation_database.json
    visibility = add_target_visibility(visibility, "//:__pkg__")

    win_def_file = select({
        "//toolchain/platforms:is_linux": None,
        "//toolchain/platforms:is_macos": None,
        "//toolchain/platforms:is_windows": win_def_file,
    }) if linkshared and sym_file else None

    cc_binary(
        name = name,
        deps = deps,
        srcs = srcs,
        data = data,
        args = args,
        compatible_with = compatible_with,
        copts = copts,
        defines = defines,
        deprecation = deprecation,
        exec_compatible_with = exec_compatible_with,
        features = HYPER_TOOLCHAIN_FEATURES + features,
        includes = [],  # We explicitly disallow the usage of the `includes` attribute
        licenses = licenses,
        linkshared = linkshared,
        linkstatic = linkstatic,
        local_defines = local_defines,
        malloc = malloc,
        nocopts = nocopts,
        output_licenses = output_licenses,
        restricted_to = restricted_to,
        stamp = stamp,
        target_compatible_with = target_compatible_with,
        tags = tags + ["check-clang-tidy"],
        testonly = testonly,
        toolchains = toolchains,
        visibility = visibility,
        additional_linker_inputs = additional_linker_inputs,
        linkopts = linkopts,
        win_def_file = win_def_file,
    )

    # An additional target to generate the .dSYM files containing the binaries debug symbols on mac OS
    dsym(
        name = name + ".dSYM",
        binary = name,
        # We also need to set the testonly attribute here so it properly
        # works in conjuction with testonly binaries
        testonly = testonly,
        target_compatible_with = (target_compatible_with or []) + [
            "@platforms//os:macos",
        ],
        # Also inherit the tags from the binary.
        # This is important to have the same sandboxing and also
        # to propagate tags like manual that disables building of the
        # dSYM along with the corresponding binary.
        tags = tags + ["manual"],
        visibility = visibility,
    )

def split_positive_negative_gtest_filters(pattern):
    """ gtest_filter has positive and negative patterns.
        These need to be always grouped, first all positive, then after a single '-' all negative patterns
        This function splits the pattern in positive and negative ones. """
    if pattern.startswith("-"):
        return ("", pattern[1:])

    index = pattern.find(":-")
    if index == -1:
        return (pattern, "")

    return (pattern[:index], pattern[index + 2:])

def filter_empty(list):
    return [x for x in list if x]

def merge_gtest_filters(args, pattern):
    """ Add `pattern` as gtest filter to `args`.
        In case there are already gtest filter present, add `pattern` to any gtest filter argument in `args`.
        In case none are present, add a new argument with the filter.
        Positive patterns are prepended to existing filters, negative filters appended."""
    merged_args = args
    if pattern:
        merged_args = []
        pattern_merged = False
        for arg in args:
            if arg.startswith("--gtest_filter="):
                pattern_merged = True
                arg_positive, arg_negative = split_positive_negative_gtest_filters(arg[len("--gtest_filter="):])
                pattern_positive, pattern_negative = split_positive_negative_gtest_filters(pattern)

                positive_args = ":".join(filter_empty([arg_positive, pattern_positive]))
                negative_args = ":".join(filter_empty([arg_negative, pattern_negative]))
                if negative_args:
                    negative_args = "-" + negative_args
                merged_args.append("--gtest_filter=" + ":".join(filter_empty([positive_args, negative_args])))
            else:
                merged_args.append(arg)
        if not pattern_merged:
            merged_args.append("--gtest_filter=" + pattern)
    return merged_args

def hyper_cc_test(
        name,
        deps = [],
        srcs = [],
        data = [],
        additional_linker_inputs = [],
        args = [],
        env = {},
        compatible_with = [],
        copts = [],
        defines = [],
        deprecation = None,
        exec_compatible_with = [],
        exec_properties = {},
        features = [],
        flaky = False,
        licenses = [],
        linkopts = [],
        linkstatic = True,
        local = False,
        local_defines = [],
        malloc = None,
        nocopts = None,
        restricted_to = None,
        shard_count = None,
        size = "small",
        stamp = -1,
        tags = [],
        target_compatible_with = None,
        testonly = True,
        # Do not set a default timeout.
        # Otherwise this might lead to unexpectedly short timeouts when
        # specifiying larger size classes.
        # E.g. having short as a default timeout would also limit the timeout
        # in the case that someone specifies a test size of medium or larger.
        # This would be counter intuitive as it would be different
        # from Bazel's default behavior: https://docs.bazel.build/versions/main/test-encyclopedia.html#role-of-the-test-runner
        timeout = None,
        toolchains = [],
        visibility = [],
        split_fvt = False,  # Create a separate target for FVT tests?
        fvt_timeout = None,  # Apply a different timeout for FVT tests
        split_perf = False,  # Create a separate target for Perf tests?
        perf_data = []):  # Provide data dependency that is only required for perf target
    label_info = get_label_info(name)
    full_package_name = "//" + label_info.package_name + ":" + label_info.package_relative_target

    # Ensure that every default visbility binary can be included in the compilation_database.json
    visibility = add_target_visibility(visibility, "//:__pkg__")

    if len(perf_data) > 0 and not split_perf:
        fail("Split perf target was not requested, but perf only data dependency provided anyway")

    # Gtests that include `_FVT` in the name must only run in the fvt (functional verification test)
    # test group. When `split_fvt` is enabled, this generates an extra target with suffix `.fvt` and
    # adds a `--gtest_filter` that runs only fvt tests with the target. Additionally, `_FVT` tests are
    # excluded from the regular test runs.
    base_filter = ""
    if split_fvt and split_perf:
        base_filter = "-*_FVT*:*_Perf*"
    elif split_fvt:
        base_filter = "-*_FVT*"
    elif split_perf:
        base_filter = "-*_Perf*"

    test_groups = [([], "", base_filter, [], timeout)]
    if split_fvt:
        # If no explicit fvt_timeout was given, use the default timeout
        test_groups.append((["fvt"], "_FVT", "*_FVT*", [], fvt_timeout or timeout))
    if split_perf:
        test_groups.append((["perf"], "_Perf", "*_Perf*", perf_data, timeout))

    for (group_tags, suffix, pattern, specific_data_dependencies, timeout) in test_groups:
        merged_args = merge_gtest_filters(args, pattern)

        cc_test_args = dict(
            name = name + suffix,
            deps = deps,
            srcs = srcs,
            data = data + specific_data_dependencies + ["//thirdparty/clang:sanitizer_support"],
            args = merged_args,
            env = env,
            compatible_with = compatible_with,
            copts = copts,
            defines = defines,
            deprecation = deprecation,
            exec_compatible_with = exec_compatible_with,
            exec_properties = exec_properties,
            features = HYPER_TOOLCHAIN_FEATURES + features,
            flaky = flaky,
            includes = [],  # We explicitly disallow the usage of the `includes` attribute
            licenses = licenses,
            linkstatic = linkstatic,
            linkopts = linkopts,
            local = local,
            local_defines = local_defines,
            malloc = malloc,
            nocopts = nocopts,
            restricted_to = restricted_to,
            size = size,
            stamp = stamp,
            # Only add the clang tidy tag once to avoid running clang tidy multiple times on the same files
            tags = tags + (["check-clang-tidy"] if suffix == "" else []) + group_tags,
            target_compatible_with = target_compatible_with,
            testonly = testonly,
            timeout = timeout,
            toolchains = toolchains,
            visibility = visibility,
        )

        # Only set shard_count when we actually need it to allow bazel to determine a reasonable shard count automatically
        # This is done for gtests with the TEST_SHARD_STATUS_FILE automatically. https://docs.bazel.build/versions/master/test-encyclopedia.html#role-of-the-test-runner
        if shard_count != None:
            cc_test_args["shard_count"] = shard_count
        cc_test(**cc_test_args)

        # An additional target to generate the .dSYM files containing the binaries debug symbols on mac OS
        dsym(
            name = name + suffix + ".dSYM",
            binary = name,
            # We also need to set the testonly attribute here so it properly
            # works in conjuction with testonly binaries
            testonly = testonly,
            target_compatible_with = (target_compatible_with or []) + [
                "@platforms//os:macos",
            ],
            # Also inherit the tags from the binary.
            # This is important to have the same sandboxing and also
            # to propagate tags like manual that disables building of the
            # dSYM along with the corresponding binary.
            tags = tags + ["manual"],
        )
