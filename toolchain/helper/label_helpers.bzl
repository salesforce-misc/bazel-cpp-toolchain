load("//toolchain/helper:list_helpers.bzl", "unique_list")

LabelInfo = provider(
    doc = " The LabelInfo provider is a structured way to present the information contained in a Bazel label. For details on the exact semantic of labels please have a look at: https://docs.bazel.build/versions/master/build-ref.html#labels",
    fields = {
        "repository_name": "The repository name of a label is everything including the @ before the '//'. If it is not specified in a labels string (e.g. package relative label, or labels starting with //), it is set to the repository name of the current BUILD.bazel file.",
        "package_name": "The package name of a label is everything starting right after the '//' and ending before the first colon ':'. In the case of package relative label string (e.g. :my_label) the package name is equivalent to the package of the current BUILD.bazel file.",
        "package_relative_target": "Ther package relative target of a label. If it is not specified in a label string the directory name of the current package is used. For instance for the label //my/special/sub/pa_ck_ag_e, the package relative target is 'pa_ck_ag_e'",
    },
)

def get_label_info(label):
    """
    Given a valid label this function converts the label to its fully qualified name consisting of its absolute
    package name and the package relative label name.

    If a package relative label (e.g. :my_label or my_other_label) is provided it will be resolved to the package of the currently
    evaluated BUILD.bazel
    If a label is a short form label (e.g. //my_package/the_sub_package) the name of the target will be inferred from
    the last package component (e.g. package: //my_package/the_sub_package, target: the_sub_package)
    In all other cases the fully qualified label string will be split at the position of the last / to determine the
    label's package and the package relative target.

    :param label: The label to canonicalize
    :return package,target: returns a pair consisting of the label's fully qualified package name and its target name
    """

    # Validate that a label only contains a single "//", which separates the repository from the package path
    if label.count("//") > 1:
        fail("Occurence of // is only allowed once inside a label")

    index_of_repository_separator = label.find("//")
    repository_name = label[0:index_of_repository_separator] if index_of_repository_separator > 0 else native.repository_name()

    # Validate repository name
    if not repository_name.startswith("@"):
        fail("Invalid repository name: {repository_name} in label: {label}".format(repository_name = repository_name, label = label))

    # No package path and no repository name
    if index_of_repository_separator == -1:
        package_name = native.package_name()
        package_relative_target = label[label.find(":") + 1:]
        # Regular package

    else:
        repository_relative_label = label[index_of_repository_separator + 2:]

        # validate potential package name
        if repository_relative_label.startswith("/"):
            fail("Label: {label} is invalid, because package names are not allowed to start with a single slash.".format(label = label))

        index_of_label_separator = repository_relative_label.find(":")
        if index_of_label_separator == -1:
            package_name = repository_relative_label
            package_relative_target = repository_relative_label[repository_relative_label.rfind("/") + 1:]
        else:
            package_name = repository_relative_label[0:index_of_label_separator]
            package_relative_target = repository_relative_label[index_of_label_separator + 1:]

    return LabelInfo(
        repository_name = repository_name,
        package_name = package_name,
        package_relative_target = package_relative_target,
    )

def unique_labels(list_of_labels):
    """
    Given a list of labels this function returns a unique lists of fully qualified labels.
    To do so the method does the follow:
      1. Convert the provided labels into fully qualified labels
      2. Removes duplicated entries

    Whenever the input is not None a new list is returned
    If the input is None, None will be returned.

    Args:
        list_of_labels: A list of label strings
    Returns:
        A unique list of fully qualified label strings.
    """

    # Early abort if list_of_labels is None
    # We do not early abort on empty lists to ensure that
    # always a new list is returned
    if list_of_labels == None:
        return list_of_labels

    return unique_list([convert_to_fully_qualified_label(label) for label in list_of_labels])

def convert_to_fully_qualified_label(label):
    """
    Given a label this function returns the fully qualified counterpart of the label.
    For instance, if a inside package //bar/baz in the main repository a relative
    label :foo is provided this function converts it into the fully qualified representation @//bar/baz:foo.

    Args:
        label: The label to convert into its fully qualified counterpart
    Returns:
        The fully qualified label
    """

    label_info = get_label_info(label)
    return "{repository_name}//{package_name}:{package_relative_target}".format(
        repository_name = label_info.repository_name,
        package_name = label_info.package_name,
        package_relative_target = label_info.package_relative_target,
    )

def extract_runfiles_relative_path(label):
    """
    Given a label this function converts it into a relative path and takes care to remove a leading `@` if present
    """
    label_info = get_label_info(label)

    repository_name_without_leading_at = label_info.repository_name[1:]

    if (label_info.package_name):
        return "{repository_name}/{package_name}/{package_relative_target}".format(
            repository_name = repository_name_without_leading_at,
            package_name = label_info.package_name,
            package_relative_target = label_info.package_relative_target,
        )
    else:
        return "{repository_name}/{package_relative_target}".format(
            repository_name = repository_name_without_leading_at,
            package_relative_target = label_info.package_relative_target,
        )
