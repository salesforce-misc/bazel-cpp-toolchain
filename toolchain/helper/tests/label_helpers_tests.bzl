load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":label_helpers.bzl", "convert_to_fully_qualified_label", "extract_runfiles_relative_path", "get_label_info", "unique_labels")

def label_helpers_test_suite():
    native.test_suite(
        name = "label_helpers_tests",
        tests = [
            get_label_info_test(
                name = "get_label_info__local_target_1_test",
                label = ":local_target_1",
                expected_repository_name = "@",
                expected_package_name = "bazel/libraries",
                expected_package_relative_target = "local_target_1",
            ),
            get_label_info_test(
                name = "get_label_info__local_target_2_test",
                label = ":local_target_2",
                expected_repository_name = "@",
                expected_package_name = "bazel/libraries",
                expected_package_relative_target = "local_target_2",
            ),
            get_label_info_test(
                name = "get_label_info__repository_relative_target_test",
                label = "@repo//:repository_relative_target",
                expected_repository_name = "@repo",
                expected_package_name = "",
                expected_package_relative_target = "repository_relative_target",
            ),
            get_label_info_test(
                name = "get_label_info__short_form_target_test",
                label = "//my_package/my_subpackage",
                expected_repository_name = "@",
                expected_package_name = "my_package/my_subpackage",
                expected_package_relative_target = "my_subpackage",
            ),
            get_label_info_test(
                name = "get_label_info__short_form_target__with_main_repository_test",
                label = "@//my_package/my_subpackage",
                expected_repository_name = "@",
                expected_package_name = "my_package/my_subpackage",
                expected_package_relative_target = "my_subpackage",
            ),
            get_label_info_test(
                name = "get_label_info__short_form_target__with_a_repository_test",
                label = "@test//other_package/other_subpackage",
                expected_repository_name = "@test",
                expected_package_name = "other_package/other_subpackage",
                expected_package_relative_target = "other_subpackage",
            ),
            get_label_info_test(
                name = "get_label_info__fully_qualified_target_test",
                label = "//my_package/my_subpackage:my_target",
                expected_repository_name = "@",
                expected_package_name = "my_package/my_subpackage",
                expected_package_relative_target = "my_target",
            ),
            get_label_info_test(
                name = "get_label_info__fully_qualified_target_with_main_repository_test",
                label = "@//my_package/my_subpackage:my_target",
                expected_repository_name = "@",
                expected_package_name = "my_package/my_subpackage",
                expected_package_relative_target = "my_target",
            ),
            get_label_info_test(
                name = "get_label_info__fully_qualified_target_with_repository_test",
                label = "@my_repository//my_package/my_subpackage:my_target",
                expected_repository_name = "@my_repository",
                expected_package_name = "my_package/my_subpackage",
                expected_package_relative_target = "my_target",
            ),
            extract_runfiles_relative_path_test(
                name = "extract_runfiles_relative_path_test",
                input_label = "@my_repo//package/sub_package:target",
                expected_runfiles_relative_path = "my_repo/package/sub_package/target",
            ),
            extract_runfiles_relative_path_test(
                name = "extract_runfiles_relative_path_test_no_subpackage",
                input_label = "@my_repo//:target",
                expected_runfiles_relative_path = "my_repo/target",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__local_package_relative_label_with_leading_colon__test",
                input_label = ":relative_label",
                expected_fully_qualified_label = "@//toolchain/helper:relative_label",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__local_package_relative_label_without_leading_colon__test",
                input_label = "relative_label",
                expected_fully_qualified_label = "@//toolchain/helper:relative_label",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__repository_relative_label_with_implicit_main_repository__test",
                input_label = "//:relative_label",
                expected_fully_qualified_label = "@//:relative_label",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__repository_relative_label_with_explicit_main_repository__test",
                input_label = "@//:relative_label",
                expected_fully_qualified_label = "@//:relative_label",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__repository_relative_label_with_other_repository__test",
                input_label = "@other//:relative_label",
                expected_fully_qualified_label = "@other//:relative_label",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__package_path_without_target_and_implicit_main_repository__test",
                input_label = "//package/sub",
                expected_fully_qualified_label = "@//package/sub:sub",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__package_path_without_target_and_explicit_main_repository__test",
                input_label = "@//pack/sub-package",
                expected_fully_qualified_label = "@//pack/sub-package:sub-package",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__package_path_without_target_and_explicit_other_repository__test",
                input_label = "@repo//pack/sub-package2",
                expected_fully_qualified_label = "@repo//pack/sub-package2:sub-package2",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__fully_qualified_target_with_implict_main_repository__test",
                input_label = "//foo/bar:baz",
                expected_fully_qualified_label = "@//foo/bar:baz",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__fully_qualified_target_with_explicit_main_repository__test",
                input_label = "@//john:doe",
                expected_fully_qualified_label = "@//john:doe",
            ),
            convert_to_fully_qualified_label_test(
                name = "convert_to_fully_qualified_label__fully_qualified_target_with_other_repository__test",
                input_label = "@location//the/package/path:and_target",
                expected_fully_qualified_label = "@location//the/package/path:and_target",
            ),
            unique_labels__none_input_test(
                name = "unique_labels__none_input_test",
            ),
            unique_labels__not_none_input_test(
                name = "unique_labels__empty_list_test",
                input_list = [],
                expected_unique_list = [],
            ),
            unique_labels__not_none_input_test(
                name = "unique_labels__conversion_to_fully_qualitied_paths_test",
                input_list = ["//e/f", ":a", "//c:d", "@external//package/subpackage:target"],
                expected_unique_list = [
                    "@//toolchain/helper:a",
                    "@//c:d",
                    "@//e/f:f",
                    "@external//package/subpackage:target",
                ],
            ),
            unique_labels__not_none_input_test(
                name = "unique_labels__duplicate_same_form_test",
                input_list = ["//e/f:g", "@external//b/c", ":a", "@external//b/c", ":a"],
                expected_unique_list = ["@//toolchain/helper:a", "@//e/f:g", "@external//b/c:c"],
            ),
            unique_labels__not_none_input_test(
                name = "unique_labels__duplicate_multiple_form_test",
                input_list = ["@//e/f:g", "//e/f:g", "//toolchain/helper", "@external//b/c", "@//toolchain/helper:libraries", "@external//b/c:c", ":libraries"],
                expected_unique_list = ["@//toolchain/helper:libraries", "@//e/f:g", "@external//b/c:c"],
            ),
        ],
    )

def _get_label_info__internal_test_impl(ctx):
    env = unittest.begin(ctx)

    # checks repository
    asserts.equals(
        env,
        actual = ctx.attr.actual_repository_name,
        expected = ctx.attr.expected_repository_name,
        msg = "Asserts that the repository_name of label \"" + ctx.attr.label + "\" is \"" + ctx.attr.expected_repository_name + "\"",
    )

    # checks repository
    asserts.equals(
        env,
        actual = ctx.attr.actual_package_name,
        expected = ctx.attr.expected_package_name,
        msg = "Asserts that the package_name of label \"" + ctx.attr.label + "\" is \"" + ctx.attr.expected_package_name + "\"",
    )

    # checks repository
    asserts.equals(
        env,
        actual = ctx.attr.actual_package_relative_target,
        expected = ctx.attr.expected_package_relative_target,
        msg = "Asserts that the package_relative_target of label \"" + ctx.attr.label + "\" is \"" + ctx.attr.expected_package_relative_target + "\"",
    )

    return unittest.end(env)

_get_label_info__internal_test = unittest.make(_get_label_info__internal_test_impl, {
    "label": attr.string(mandatory = True),
    "actual_repository_name": attr.string(mandatory = True),
    "actual_package_name": attr.string(mandatory = True),
    "actual_package_relative_target": attr.string(mandatory = True),
    "expected_repository_name": attr.string(mandatory = True),
    "expected_package_name": attr.string(mandatory = True),
    "expected_package_relative_target": attr.string(mandatory = True),
})

def get_label_info_test(name, label, expected_repository_name, expected_package_name, expected_package_relative_target):
    actual_label_info = get_label_info(label)
    _get_label_info__internal_test(
        name = name,
        label = label,
        actual_repository_name = actual_label_info.repository_name,
        actual_package_name = actual_label_info.package_name,
        actual_package_relative_target = actual_label_info.package_relative_target,
        expected_repository_name = expected_repository_name,
        expected_package_name = expected_package_name,
        expected_package_relative_target = expected_package_relative_target,
    )
    return name

def _unique_labels__none_input_internal_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.true(env, unique_labels(None) == None, "unique_labels has to return None for None input.")

    return unittest.end(env)

_unique_labels__none_input_internal_test = unittest.make(_unique_labels__none_input_internal_test_impl, {})

def unique_labels__none_input_test(name):
    _unique_labels__none_input_internal_test(
        name = name,
    )
    return name

def _unique_labels__not_none_input_test_impl(ctx):
    env = unittest.begin(ctx)

    actual_unique_labels = sorted(ctx.attr.actual_unique_labels)

    expected_string_representation_of_unique_labels = repr(sorted(ctx.attr.expected_unique_list))
    actual_string_representation_of_unique_labels = repr(sorted(actual_unique_labels))

    # checks that the generated lists are equal
    asserts.equals(
        env,
        actual = actual_string_representation_of_unique_labels,
        expected = expected_string_representation_of_unique_labels,
        msg = "unique_labels({input_list}) should return {expected_unique_list} but instead returned {returned_list}".format(
            input_list = repr(ctx.attr.input_list),
            expected_unique_list = expected_string_representation_of_unique_labels,
            returned_list = actual_string_representation_of_unique_labels,
        ),
    )

    return unittest.end(env)

_unique_labels__not_none_input__internal__test = unittest.make(_unique_labels__not_none_input_test_impl, {
    "input_list": attr.string_list(mandatory = True),
    "actual_unique_labels": attr.string_list(mandatory = True),
    "expected_unique_list": attr.string_list(mandatory = True),
})

def unique_labels__not_none_input_test(name, input_list, expected_unique_list):
    # Has to be executed in the test macro because the current package is required for label canonicalization
    actual_unique_labels = unique_labels(input_list)

    _unique_labels__not_none_input__internal__test(
        name = name,
        input_list = input_list,
        expected_unique_list = expected_unique_list,
        actual_unique_labels = actual_unique_labels,
    )

    return name

def _convert_to_fully_qualified_label__internal_test_impl(ctx):
    env = unittest.begin(ctx)

    # checks that the generated fully qualified label is expected
    asserts.equals(
        env,
        actual = ctx.attr.actual_fully_qualified_label,
        expected = ctx.attr.expected_fully_qualified_label,
        msg = "convert_to_fully_qualified_label({input_label}) should return {expected_unique_list} but instead returned {actual_fully_qualified_label}".format(
            input_label = repr(ctx.attr.input_label),
            expected_unique_list = ctx.attr.expected_fully_qualified_label,
            actual_fully_qualified_label = ctx.attr.actual_fully_qualified_label,
        ),
    )

    return unittest.end(env)

_convert_to_fully_qualified_label__internal_test = unittest.make(_convert_to_fully_qualified_label__internal_test_impl, {
    "input_label": attr.string(mandatory = True),
    "actual_fully_qualified_label": attr.string(mandatory = True),
    "expected_fully_qualified_label": attr.string(mandatory = True),
})

def convert_to_fully_qualified_label_test(name, input_label, expected_fully_qualified_label):
    # Has to be executed in the test macro because the current package is required for label canonicalization
    actual_fully_qualified_label = convert_to_fully_qualified_label(input_label)

    _convert_to_fully_qualified_label__internal_test(
        name = name,
        input_label = input_label,
        actual_fully_qualified_label = actual_fully_qualified_label,
        expected_fully_qualified_label = expected_fully_qualified_label,
    )

    return name

def _extract_runfiles_relative_path__internal_test_impl(ctx):
    env = unittest.begin(ctx)

    # checks that the generated fully qualified label is expected
    asserts.equals(
        env,
        actual = ctx.attr.actual_runfiles_relative_path,
        expected = ctx.attr.expected_runfiles_relative_path,
        msg = "extract_runfiles_relative_path({input_label}) should return {expected_runfiles_relative_path} but instead returned {actual_runfiles_relative_path}".format(
            input_label = repr(ctx.attr.input_label),
            expected_runfiles_relative_path = ctx.attr.expected_runfiles_relative_path,
            actual_runfiles_relative_path = ctx.attr.actual_runfiles_relative_path,
        ),
    )

    return unittest.end(env)

_extract_runfiles_relative_path__internal_test = unittest.make(_extract_runfiles_relative_path__internal_test_impl, {
    "input_label": attr.string(mandatory = True),
    "actual_runfiles_relative_path": attr.string(mandatory = True),
    "expected_runfiles_relative_path": attr.string(mandatory = True),
})

def extract_runfiles_relative_path_test(name, input_label, expected_runfiles_relative_path):
    # Has to be executed in the test macro because the current package is required for label canonicalization
    actual_runfiles_relative_path = extract_runfiles_relative_path(input_label)

    _extract_runfiles_relative_path__internal_test(
        name = name,
        input_label = input_label,
        actual_runfiles_relative_path = actual_runfiles_relative_path,
        expected_runfiles_relative_path = expected_runfiles_relative_path,
    )

    return name
