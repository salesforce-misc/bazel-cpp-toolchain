def list_for(conditions, list, dict_only = False):
    """
    `list_for` is a convenience function, to simplify the creation of configurable attribute values (aka select) which for
    a set of conditions always assign the same value.
    For instance

    ```
    list_for(
        ["//toolchain/platforms:is_linux", "//toolchain/platforms:is_macos"],
        [":my_posix_label"]
    )
    ```
    is converted into
    ```
    select({
        "//toolchain/platforms:is_linux": [":my_posix_label"]
        "//toolchain/platforms:is_macos": [":my_posix_label"]
        "//conditions:default": []
    })
    ```

    :params conditions: the list of conditions for which the provided list should be available
    :params list: the list that should be available only under a certain set of conditions
    :params dict_only Determines if the returned conditions are wrapped in a select struct or not.
                      Using a dictionary only becomes quite useful if you want to postprocess the condition later, because
                      select structures are currently opaque structures and the encapsulated dictionary cannot be accessed
                      by macros.
    :returns: The created condition. If dict_only is True the plain conditions as a dictionary.
              If dict_only is False, which is the default, the returned conditions are wrapped in a `select` struct
    """
    mapping = {condition: list for condition in conditions}
    mapping["//conditions:default"] = []
    return mapping if dict_only else select(mapping)

def list_not_for(conditions, list, dict_only = False):
    """
    `list_not_for` is a convenience function, that works like `list_for`, but adds a NOT to the conditions.
    """
    mapping = {condition: [] for condition in conditions}
    mapping["//conditions:default"] = list
    return mapping if dict_only else select(mapping)
