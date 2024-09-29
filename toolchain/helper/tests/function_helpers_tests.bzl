load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":function_helpers.bzl", "function_info")

# Macro for testing function_info
def f():
    fail(msg = "This macro should never be executed")

def function_helpers_test_suite():
    # function_info tests
    function_helpers__function_info__function_input__test(
        name = "function_helpers__function_info__function_input__test",
    )
    native.test_suite(
        name = "function_helpers_tests",
        tests = [
            ":function_helpers__function_info__function_input__test",
        ],
    )

def _function_helpers__function_info__function_input__test_impl(ctx):
    env = unittest.begin(ctx)
    test_data = [
        ("//toolchain/helper:tests/function_helpers_tests.bzl", f, "f"),
        ("//toolchain/helper:function_helpers.bzl", function_info, "function_info"),
    ]
    for module, function, function_string in test_data:
        asserts.equals(env, repr(function_string), repr(function_info(function).function_name))
        asserts.equals(env, repr(module), repr(function_info(function).starlark_file_declaring_function))
    return unittest.end(env)

function_helpers__function_info__function_input__test = unittest.make(_function_helpers__function_info__function_input__test_impl)
