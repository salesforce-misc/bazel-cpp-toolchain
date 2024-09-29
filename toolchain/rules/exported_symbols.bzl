load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _generate_platform_specific_symfile(ctx, mnemonic, output_type):
    """ Generates a platform-specific symfile """
    filename = ctx.attr.name
    output_file = ctx.actions.declare_file(filename)

    ctx.actions.run(
        inputs = [ctx.file.sym_file],
        outputs = [output_file],
        executable = ctx.executable._conversion_script,
        mnemonic = mnemonic,
        progress_message = "Generating {output_type} \"{filename}\" from symfile \"{input_file_name}\"".format(
            output_type = output_type,
            filename = output_file.path,
            input_file_name = ctx.file.sym_file.path,
        ),
        arguments = [ctx.file.sym_file.path, output_file.path],
    )
    return output_file

def _generate_platform_specific_linker_parameter(ctx, additional_inputs, user_link_flags):
    """ Generates a platform-specific CcInfo with linking context """
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features + ctx.attr.features,
        unsupported_features = ctx.disabled_features,
    )
    linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        additional_inputs = depset(additional_inputs),
        user_link_flags = depset(user_link_flags),
    )
    return CcInfo(linking_context = cc_common.create_linking_context(linker_inputs = depset(direct = [linker_input])))

def _platform_specific_symfile_rule(implementation, doc):
    """ Generates a rule to create platform specific symfiles """
    return rule(
        implementation = implementation,
        doc = doc,
        attrs = {
            "sym_file": attr.label(
                allow_single_file = True,
                doc = ".sym file containing a list of symbols used to generate platform-specific exported symbols file",
            ),
            "_conversion_script": attr.label(
                default = Label("//toolchain/rules:generatesymbolfile"),
                executable = True,
                cfg = "exec",
            ),
            "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
        },
        toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
        fragments = ["cpp"],
    )

def _linux_lds_script(ctx):
    """ Implementation of linux_lds_script """
    lds_script = _generate_platform_specific_symfile(ctx, "LdsGenerate", "Linux Linker Script")

    return [
        _generate_platform_specific_linker_parameter(ctx, [lds_script], [lds_script.path]),
        DefaultInfo(files = depset([lds_script])),
    ]

def _linux_version_script(ctx):
    """ Implementation of linux_version_script """
    linker_version_script = _generate_platform_specific_symfile(ctx, "VerGenerate", "Linux version")

    return [
        _generate_platform_specific_linker_parameter(ctx, [linker_version_script], ["-Wl,--version-script,\"{linker_version_script}\"".format(linker_version_script = linker_version_script.path)]),
        DefaultInfo(files = depset([linker_version_script])),
    ]

def _mac_exported_symbols_list(ctx):
    """ Implementation of mac_exported_symbols_list """
    exported_symbols_list = _generate_platform_specific_symfile(ctx, "ExpGenerate", "Exported Symbols")

    return [
        _generate_platform_specific_linker_parameter(ctx, [exported_symbols_list], ["-exported_symbols_list", exported_symbols_list.path]),
        DefaultInfo(files = depset([exported_symbols_list])),
    ]

def _windows_def_file(ctx):
    """ Implementation of windows_def_file """
    def_file = _generate_platform_specific_symfile(ctx, "DefGenerate", "Windows Module Definition File")

    return [
        _generate_platform_specific_linker_parameter(ctx, [def_file], ["/DEF:{win_def_file}".format(win_def_file = def_file.path)]),
        DefaultInfo(files = depset([def_file])),
    ]

linux_lds_script = _platform_specific_symfile_rule(implementation = _linux_lds_script, doc = "Rule to create a ld linker script file for Linux build (extension: .lds). The main purpose of the linker script is to describe how the sections in the input files should be mapped into the output file, and to control the memory layout of the output file.")
linux_version_script = _platform_specific_symfile_rule(implementation = _linux_version_script, doc = "Rule to create a version script for Linux build (extension: .ver). Version scripts are only meaningful when creating shared libraries.")
mac_exported_symbols = _platform_specific_symfile_rule(implementation = _mac_exported_symbols_list, doc = "Rule to create a symbols export file for MacOS build (extension: .exp). Stores symbol table data.")
windows_def_file = _platform_specific_symfile_rule(implementation = _windows_def_file, doc = "Rule to create a Module-Definition file for Windows build (extension: .def). The file lists the exports and attributes of a program to be linked by an application linker.")
