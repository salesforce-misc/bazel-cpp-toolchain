def collect_runfiles(ctx, data):
    """
    Extract the runfiles from the data attribute.
    Useful as a replacement for collect_data.
    """
    runfiles = ctx.runfiles()
    for data_dependency in data:
        runfiles = runfiles.merge(data_dependency[DefaultInfo].default_runfiles)
        runfiles = runfiles.merge(ctx.runfiles(transitive_files = data_dependency[DefaultInfo].files))
    return runfiles
