load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":runfiles_helpers.bzl", "collect_runfiles")

def _dummy(ctx):
    """
    A dummy target containing a single file and a transitive file
    """
    file_path = ctx.actions.declare_file("file_" + ctx.attr.index)
    ctx.actions.write(file_path, "")
    transitive_file_path = ctx.actions.declare_file("transitive_file_" + ctx.attr.index)
    ctx.actions.write(transitive_file_path, "")
    return DefaultInfo(
        files = depset([transitive_file_path]),
        runfiles = ctx.runfiles(files = [file_path]),
    )

dummy = rule(_dummy, attrs = {"index": attr.string()})

def runfiles_helpers_test_suite():
    dummy(name = "local_target_1", index = "1")
    dummy(name = "local_target_2", index = "2")

    runfiles_helpers__data_runfiles__test(
        name = "runfiles_helpers__data_runfiles__test",
        data = [":local_target_1", ":local_target_2"],
    )

def _runfiles_helpers__data_runfiles__test(ctx):
    env = unittest.begin(ctx)
    runfiles = collect_runfiles(ctx, ctx.attr.data)

    # We check the repr of runfiles. This may fail in the future if bazel changes
    # the output. A test based on to_list might be more stable.
    asserts.equals(
        env,
        ("depset([<generated file bazel/libraries/file_1>, " +
         "<generated file bazel/libraries/transitive_file_1>, " +
         "<generated file bazel/libraries/file_2>, " +
         "<generated file bazel/libraries/transitive_file_2>], order = \"postorder\")"),
        repr(runfiles.files),
    )
    return unittest.end(env)

runfiles_helpers__data_runfiles__test = unittest.make(
    _runfiles_helpers__data_runfiles__test,
    {"data": attr.label_list(mandatory = True)},
)
