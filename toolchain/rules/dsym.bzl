load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

StaticLibrariesLinkerInputs = provider(
    fields = {
        "files": "the static libraries that have been used as an input on the link command line of a binary",
    },
)

def _link_inputs_aspect_impl(target, ctx):
    # Retrieve the C++ toolchain and determine the features that were used to build the provided binary
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features + ctx.rule.attr.features,
        unsupported_features = ctx.disabled_features,
    )

    # Determines if the pic or non pic static libraries were used to link the final binary
    needs_pic = cc_toolchain.needs_pic_for_dynamic_libraries(feature_configuration = feature_configuration)

    # Merges the cc_infos of the binaries transitive dependencies
    cc_info = cc_common.merge_cc_infos(cc_infos = [dep[CcInfo] for dep in ctx.rule.attr.deps])
    #return for linker_input in cc_info.linking_context.linker_inputs

    dependent_static_libraries = []
    for linker_input in cc_info.linking_context.linker_inputs.to_list():
        for library_to_link in linker_input.libraries:
            if ctx.rule.attr.linkstatic or not library_to_link.dynamic_library:
                # Only add pic libraries if pic is enabled and they are actually available.
                # If pic is enabled but not static library with pic is available fall back to the non pic variant.
                if needs_pic and library_to_link.pic_static_library:
                    dependent_static_libraries.append(library_to_link.pic_static_library)
                elif library_to_link.static_library:
                    dependent_static_libraries.append(library_to_link.static_library)

    # Also add the toolchain's static runtime library if it was used for linking
    need_to_consider_runtime_library = ctx.rule.attr.linkstatic and cc_common.is_enabled(feature_configuration = feature_configuration, feature_name = "static_link_cpp_runtimes")
    runtime_libraries = [cc_toolchain.static_runtime_lib(feature_configuration = feature_configuration)] if need_to_consider_runtime_library else []

    return StaticLibrariesLinkerInputs(
        files = depset(
            direct = dependent_static_libraries,
            transitive = runtime_libraries,
        ),
    )

_link_inputs_aspect = aspect(
    doc = """
        This aspect allows to retrieve all static libraries that are used to link the binary the aspect is applied on.
    """,
    implementation = _link_inputs_aspect_impl,
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    fragments = ["cpp"],
)

def _dsym_impl(ctx):
    # The label is used as the name of the resulting .dSYM package
    dSYM_package_name = ctx.label.name

    # The file inside the .dSYM package that contains the actual dwarf debug symbols
    dsym_internal_path_to_dwarf_symbols = "Contents/Resources/DWARF/{binary_name}".format(binary_name = ctx.attr.binary.label.name)
    path_to_dwarf_symbols = "{dSYM_package_name}/{dsym_internal_path_to_dwarf_symbols}".format(dSYM_package_name = dSYM_package_name, dsym_internal_path_to_dwarf_symbols = dsym_internal_path_to_dwarf_symbols)

    dwarf_symbols_file = ctx.actions.declare_file(path_to_dwarf_symbols, sibling = ctx.executable.binary)

    # The +1 accounts for the slash separating the .dSYM directory name from the package's internal path to the symbol file
    path_to_dSYM_root_directory = dwarf_symbols_file.path[0:-(len(dsym_internal_path_to_dwarf_symbols) + 1)]

    # The plist file inside the .dSYM package
    plist_file = ctx.actions.declare_file("{dSYM_package_name}/Contents/Info.plist".format(dSYM_package_name = dSYM_package_name), sibling = ctx.executable.binary)

    # The static libraries that were used to link the provided binary and are referenced by the OSO stabs
    static_libraries_used_to_link_the_binary = ctx.attr.binary[StaticLibrariesLinkerInputs].files

    # The object files that were provided on the link command line of the provided binary and are referenced by the OSO stabs
    object_files_used_to_link_the_binary = ctx.attr.binary[OutputGroupInfo].compilation_outputs

    ctx.actions.run(
        executable = ctx.executable._dsymutil,
        arguments = [ctx.actions.args().add(ctx.executable.binary).add("-o").add(path_to_dSYM_root_directory)],
        outputs = [dwarf_symbols_file, plist_file],
        inputs = depset(direct = [ctx.executable.binary], transitive = [static_libraries_used_to_link_the_binary, object_files_used_to_link_the_binary]),
    )
    return [DefaultInfo(files = depset(direct = [dwarf_symbols_file, plist_file]))]

dsym = rule(
    implementation = _dsym_impl,
    doc = """
        This rule is used to generate a .dSYM package containing the debug symbols for a mac os binary.
        Currently this is a missing feature in Bazel (please see Bazel issue 2537 https://github.com/bazelbuild/bazel/issues/2537)
        The name of resulting targets are identical to the name of the resulting package.
        Therefore, please follow the convention to name targets generated by this rule "<binary>.dSYM"
    """,
    attrs = {
        "binary": attr.label(
            doc = "The binary to generate debug symbols for.",
            cfg = "target",
            executable = True,
            providers = [CcInfo],
            aspects = [_link_inputs_aspect],
        ),
        "_dsymutil": attr.label(
            doc = "Internal attribute that holds the reference to the macos sdk's dsymutil.",
            cfg = "target",
            executable = True,
            default = "//toolchain/rules:platformspecific_dsym_utils",
        ),
        #"_dsymutil_libraries": attr.label(
        #    doc = "Internal attribute that holds the reference to the required library for macos sdk's dsymutil.",
        #    cfg = "target",
        #    default = "//toolchain/rules:platformspecific_dsym_utils_additional_libraries",
        #),
    },
)
