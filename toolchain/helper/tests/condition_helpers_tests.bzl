load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":condition_helpers.bzl", "list_for")

def condition_helpers_test_suite():
    condition_helpers__list_for__dict_only__test(
        name = "condition_helpers__list_for__dict_only__test",
    )
    condition_helpers__list_for__use_select__test(
        name = "condition_helpers__list_for__use_select__test",
    )

    native.test_suite(
        name = "condition_helpers_tests",
        tests = [
            ":condition_helpers__list_for__dict_only__test",
            ":condition_helpers__list_for__use_select__test",
        ],
    )

def _condition_helpers__list_for__use_select__test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, repr(select({
        "//toolchain/platforms:is_windows": ["a", "b", "c"],
        "//conditions:default": [],
    })), repr(list_for(["//toolchain/platforms:is_windows"], ["a", "b", "c"])))

    return unittest.end(env)

def _condition_helpers__list_for__dict_only__test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, {
        "//toolchain/platforms:is_windows": ["a", "b", "c"],
        "//conditions:default": [],
    }, list_for(["//toolchain/platforms:is_windows"], ["a", "b", "c"], dict_only = True))

    return unittest.end(env)

condition_helpers__list_for__dict_only__test = unittest.make(_condition_helpers__list_for__dict_only__test_impl)
condition_helpers__list_for__use_select__test = unittest.make(_condition_helpers__list_for__use_select__test_impl)
