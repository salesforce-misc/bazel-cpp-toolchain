# Rules for building macOS universal binaries, including the transition to build the same target for two architectures"

def _output_name_from_ctx(ctx):
    """ Generates the output name of the binary from a context """
    output_name = ctx.attr.output_name
    if not output_name:
        output_name = ctx.split_attr.dep["x64"][DefaultInfo].files_to_run.executable.basename
    return ctx.attr.output_prefix + output_name

def _impl(
        settings,  # @unused
        attr):  # @unused
    return {
        "x64": {
            "//command_line_option:platforms": "//toolchain/platforms:macos_x64",
            "//command_line_option:cpu": "darwin",
        },
        "arm": {
            "//command_line_option:platforms": "//toolchain/platforms:macos_arm",
            "//command_line_option:cpu": "darwin_aarch64",
        },
    }

universal_binary_transition = transition(
    implementation = _impl,
    inputs = [],
    outputs = ["//command_line_option:platforms", "//command_line_option:cpu"],
)

def _rule_impl(ctx):
    target_file_name = _output_name_from_ctx(ctx)
    x64_binary = ctx.split_attr.dep["x64"][DefaultInfo].files_to_run.executable
    arm_binary = ctx.split_attr.dep["arm"][DefaultInfo].files_to_run.executable
    target_file = ctx.actions.declare_file(target_file_name)
    lipo_tool = ctx.executable._lipo_tool

    args = ctx.actions.args()
    args.add("-create")
    args.add("-output")
    args.add(target_file)
    args.add(x64_binary)
    args.add(arm_binary)

    ctx.actions.run(
        inputs = [x64_binary, arm_binary],
        outputs = [target_file],
        executable = lipo_tool,
        mnemonic = "GenerateUniversalBinary",
        progress_message = "Create Universal Binary \"{target_file_name}\"".format(
            target_file_name = target_file_name,
        ),
        arguments = [args],
    )

    return DefaultInfo(files = depset([target_file]), executable = target_file)

universal_binary = rule(
    implementation = _rule_impl,
    attrs = {
        "dep": attr.label(
            cfg = universal_binary_transition,
        ),
        "output_name": attr.string(
            default = "",
            doc = "The name/path of the binary to produce.",
        ),
        "output_prefix": attr.string(
            default = "",
            doc = "The prefix for the output path to use. Must end with a slash if you want to create the binary in a subdirectory.",
        ),
        "_lipo_tool": attr.label(
            executable = True,
            cfg = "exec",
            allow_files = True,
            default = Label("@clang_darwin//:llvm-lipo"),
        ),
        # This attribute is required to use transitions.
        # It allowlists usage of this rule. For more information, see
        # https://bazel.build/extending/config#user-defined-transitions
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
