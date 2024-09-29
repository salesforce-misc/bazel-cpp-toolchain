load(":platform_helpers.bzl", "is_windows")

def get_common_directory_prefix(dirname1, dirname2):
    len1 = len(dirname1)
    len2 = len(dirname2)

    # Loop over the two strings until the first mismatching character is found (or until one string ends but the
    # other doesn't), maintaining `s` as the index of the last-seen common `/` separator.
    s = 0
    for i in range(0, min(len1, len2) + 1):
        # If the end of either string is reached, interpret the end as a trailing `/`. This way, it won't be treated as
        # a mismatch if one path ends with a trailing `/` but the other, otherwise identical path does not.
        c1 = dirname1[i] if (i < len1) else "/"
        c2 = dirname2[i] if (i < len2) else "/"
        if c1 != c2:
            break
        if c1 == "/":
            s = i

    # Shorten the path (does not matter which) to just before the last-common `/` separator.
    return dirname1[0:s]

def get_common_root_path(paths):
    """
    Returns the lowest common ancestor ("root path") of the given paths.

    Args:
        paths: The list of `path` objects or strings to analyze.

    Returns:
        string: The root path.
    """

    # The root path is the result of "folding" all given paths with `get_common_directory_prefix()`.
    root = None
    for path in paths:
        root = path if not root else get_common_directory_prefix(path, root)
    return root

# Note: See `detect_root.bzl` in `rules_foreign_cc` for a similar helper function. (Not worth importing, though.)
def get_common_root_dir(files, path_property = "path"):
    """
    Returns the path to the lowest common parent directory ("root dir") that contains the given files.

    Args:
        files: The list of `File` objects to analyze.

    Returns:
        string: The root dir. The path is always relative to the execution directory.
    """

    return get_common_root_path([getattr(file, path_property) for file in files])

def stem(file):
    """
    Given a file object, it returns its base filename with the suffix stripped.

    :param file: the file object to retrieve its stem from
    :return the stem of the file basename. This is the basename without its extension.
    """
    return file.basename[0:-len("." + file.extension)]

def to_windows_file_path(path):
    """
    Replaces all slashses with backslashes
    """
    return path.replace("/", "\\")

def to_host_specific_path(ctx, platform_agnostic_path):
    """
    Given a platform agnostic path that uses slashes as folder separators this function returns a path that uses the folder separator of the current host platform.

    Args:
        ctx: the current rule context
        platform_agnostic_path: the platform agnostic path that uses slashes as separator
    Returns:
        a path that uses the folder separator of the rule context's host platform
    """
    return to_windows_file_path(platform_agnostic_path) if is_windows(ctx) else platform_agnostic_path

def substitute_path_prefixes(path, substitutions):
    """
    Substitute path prefixes. Perform at most one substitution.

    Args:
        path: Original path
        substitutions: List of tuples (`old`, `new`) so that if `parts` starts with `old`, this occurence of `old` will be replaced with `new`.
    Returns:
        Path with substitutions applied
    """
    for old, new in substitutions:
        if (path.startswith(old)):
            return new + path[len(old):]
    return path
