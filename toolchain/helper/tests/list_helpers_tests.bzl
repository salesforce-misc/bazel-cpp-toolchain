load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":list_helpers.bzl", "is_unique_list", "unique_list")

def list_helpers_test_suite():
    # unique_list tests
    list_helpers__unique_list__empty_list__test(
        name = "list_helpers__unique_list__empty_list__test",
    )
    list_helpers__unique_list__none_list__test(
        name = "list_helpers__unique_list__none_list__test",
    )
    list_helpers__unique_list__single_item_list__test(
        name = "list_helpers__unique_list__single_item_list__test",
    )
    list_helpers__unique_list__multi_item_list__test(
        name = "list_helpers__unique_list__multi_item_list__test",
    )

    # is_unique_list tests
    list_helpers__is_unique_list__empty_list__test(
        name = "list_helpers__is_unique_list__empty_list__test",
    )
    list_helpers__is_unique_list__none_list__test(
        name = "list_helpers__is_unique_list__none_list__test",
    )
    list_helpers__is_unique_list__single_item_list__test(
        name = "list_helpers__is_unique_list__single_item_list__test",
    )
    list_helpers__is_unique_list__multi_item_list__test(
        name = "list_helpers__is_unique_list__multi_item_list__test",
    )

    native.test_suite(
        name = "list_helpers_tests",
        tests = [
            ":list_helpers__unique_list__empty_list__test",
            ":list_helpers__unique_list__none_list__test",
            ":list_helpers__unique_list__single_item_list__test",
            ":list_helpers__unique_list__multi_item_list__test",
            ":list_helpers__is_unique_list__empty_list__test",
            ":list_helpers__is_unique_list__none_list__test",
            ":list_helpers__is_unique_list__single_item_list__test",
            ":list_helpers__is_unique_list__multi_item_list__test",
        ],
    )

def _list_helpers__unique_list__empty_list__test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, repr([]), repr(unique_list([])))
    return unittest.end(env)

def _list_helpers__unique_list__none_list__test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, repr(None), repr(unique_list(None)))
    return unittest.end(env)

def _list_helpers__unique_list__single_item_list__test_impl(ctx):
    env = unittest.begin(ctx)
    for item in [None, "i", "j", "xyz", "42", -1, 0, 1]:
        asserts.equals(env, repr([item]), repr(unique_list([item])))
    return unittest.end(env)

def _list_helpers__unique_list__multi_item_list__test_impl(ctx):
    env = unittest.begin(ctx)
    items = [None, "i", "j", "xyz", "42", -1, 0, 1]
    [asserts.equals(
        env,
        repr([item_i] + ([item_j] if item_i != item_j else []) + ([item_k] if item_k != item_j and item_k != item_i else [])),
        repr(unique_list([item_i] * i + [item_j] * j + [item_k] * k)),
    ) for i in range(1, 5) for j in range(1, 5) for k in range(1, 5) for item_i in items for item_j in items for item_k in items]
    return unittest.end(env)

def _list_helpers__is_unique_list__empty_list__test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, repr(True), repr(is_unique_list([])))
    return unittest.end(env)

def _list_helpers__is_unique_list__none_list__test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, repr(None), repr(is_unique_list(None)))
    return unittest.end(env)

def _list_helpers__is_unique_list__single_item_list__test_impl(ctx):
    env = unittest.begin(ctx)
    for item in ["i", "j", "xyz", "42", -1, 0, 1]:
        asserts.equals(env, repr(True), repr(is_unique_list([item])))
    return unittest.end(env)

def _list_helpers__is_unique_list__multi_item_list__test_impl(ctx):
    env = unittest.begin(ctx)
    items = ["i", "j", "xyz", "42", -1, 0, 1]
    for until_index in range(len(items)):
        asserts.equals(env, repr(True), repr(is_unique_list(items[:until_index])))
    return unittest.end(env)

list_helpers__unique_list__empty_list__test = unittest.make(_list_helpers__unique_list__empty_list__test_impl)
list_helpers__unique_list__none_list__test = unittest.make(_list_helpers__unique_list__none_list__test_impl)
list_helpers__unique_list__single_item_list__test = unittest.make(_list_helpers__unique_list__single_item_list__test_impl)
list_helpers__unique_list__multi_item_list__test = unittest.make(_list_helpers__unique_list__multi_item_list__test_impl)

list_helpers__is_unique_list__empty_list__test = unittest.make(_list_helpers__is_unique_list__empty_list__test_impl)
list_helpers__is_unique_list__none_list__test = unittest.make(_list_helpers__is_unique_list__none_list__test_impl)
list_helpers__is_unique_list__single_item_list__test = unittest.make(_list_helpers__is_unique_list__single_item_list__test_impl)
list_helpers__is_unique_list__multi_item_list__test = unittest.make(_list_helpers__is_unique_list__multi_item_list__test_impl)
