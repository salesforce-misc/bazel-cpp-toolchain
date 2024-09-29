def file_attribute_to_toolpath(ctx, file_attribute):
    """ Generate a relative path pointing to the file from the given context.
    The returned path is not normalized! (There is no way to normalize paths in Starlark)
    """
    path_to_root = ""

    for _ in ctx.label.package.split("/"):
        path_to_root = path_to_root + "../"

    return path_to_root + file_attribute.path
