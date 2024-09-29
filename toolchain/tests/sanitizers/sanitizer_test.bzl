load("@rules_python//python:defs.bzl", "py_test")
load("//toolchain/helper:condition_helpers.bzl", "list_for")
load("//toolchain/rules:hyper_cc.bzl", "hyper_cc_binary")

def sanitizer_test(name, executable_cpp_sources, expected_errors, sanitizers, target_compatible_with = []):
    binary_name = name + "_executable"
    hyper_cc_binary(
        name = binary_name,
        srcs = executable_cpp_sources,
        features = list_for(["//toolchain/platforms:is_linux", "//toolchain/platforms:is_macos"], sanitizers),
        target_compatible_with = target_compatible_with,
    )

    test_arguments = ["--executable_path", "$(rootpath " + binary_name + ")"]
    for error in expected_errors:
        test_arguments += ["--expected_stack_line_regex", error]

    py_test(
        name = name,
        srcs = ["//toolchain/tests/sanitizers:sanitizer_test.py"],
        main = "//toolchain/tests/sanitizers:sanitizer_test.py",
        # ASAN is linked dynamically on macOS, thus we need to add the dynamic ASAN library to the sandbox
        data = [":" + binary_name] + select({
            "//toolchain/platforms:is_macos": ["@clang_darwin//:libsan"],
            "//conditions:default": [],
        }),
        args = test_arguments,
        target_compatible_with = target_compatible_with,
    )
