load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":file_helpers.bzl", "get_common_directory_prefix", "get_common_root_dir", "stem")

def file_helpers_test_suite():
    stem_test(
        name = "stem_test",
    )

    get_common_directory_prefix_test(
        name = "get_common_directory_prefix_test",
    )

    get_common_root_dir_test(
        name = "get_common_root_dir_test",
    )

    native.test_suite(
        name = "file_helpers_tests",
        tests = [
            ":stem_test",
            ":get_common_directory_prefix_test",
            ":get_common_root_dir_test",
        ],
    )

def _stem_test_impl(ctx):
    env = unittest.begin(ctx)
    dummy_file = struct(
        extension = "ext",
        basename = "myname.ext",
    )

    asserts.equals(env, "myname", stem(dummy_file))
    return unittest.end(env)

stem_test = unittest.make(_stem_test_impl)

def _get_common_directory_prefix_test_impl(ctx):
    env = unittest.begin(ctx)

    # Case: trivial "" or "/" paths; empty common prefix
    asserts.equals(env, "", get_common_directory_prefix("", ""))
    asserts.equals(env, "", get_common_directory_prefix("", "/"))
    asserts.equals(env, "", get_common_directory_prefix("/", ""))

    # Case: paths without a root `/` separator
    asserts.equals(env, "a", get_common_directory_prefix("a/bc", "a/b"))
    asserts.equals(env, "a", get_common_directory_prefix("a/b", "a/bc"))

    # Case: one path is the prefix of another path
    asserts.equals(env, "a/b", get_common_directory_prefix("a/b/c", "a/b"))
    asserts.equals(env, "a/b", get_common_directory_prefix("a/b", "a/b/c"))

    # Case: one path with a trailing separator; empty common prefix
    asserts.equals(env, "", get_common_directory_prefix("/abc", "/ab/"))
    asserts.equals(env, "", get_common_directory_prefix("/ab/", "/abc"))

    # Case: one path with a trailing separator; non-empty common prefix
    asserts.equals(env, "/a", get_common_directory_prefix("/a/bc", "/a/b/"))
    asserts.equals(env, "/a", get_common_directory_prefix("/a/b/", "/a/bc"))

    # Case: both with trailing separator; non-empty common prefix
    asserts.equals(env, "/r", get_common_directory_prefix("/r/abc/", "/r/ab/"))
    asserts.equals(env, "/r", get_common_directory_prefix("/r/ab/", "/r/abc/"))

    return unittest.end(env)

get_common_directory_prefix_test = unittest.make(_get_common_directory_prefix_test_impl)

def _get_common_root_dir_test_impl(ctx):
    env = unittest.begin(ctx)

    files = [
        struct(path = "my/common/directory/suffixb/a.txt"),
        struct(path = "my/common/directory/suffixb/suffixc/c.txt"),
        struct(path = "my/common/directory/suffixa/d.txt"),
    ]

    asserts.equals(env, "my/common/directory", get_common_root_dir(files))

    return unittest.end(env)

get_common_root_dir_test = unittest.make(_get_common_root_dir_test_impl)
