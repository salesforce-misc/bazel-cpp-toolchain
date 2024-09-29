# Macro to define a matching config setting for selects with every platform

def platform_with_config_setting(name, constraint_values):
    native.platform(
        name = name,
        constraint_values = constraint_values,
        visibility = ["//visibility:public"],
    )

    native.config_setting(
        name = "is_{name}".format(name = name),
        constraint_values = constraint_values,
        visibility = ["//visibility:public"],
    )
