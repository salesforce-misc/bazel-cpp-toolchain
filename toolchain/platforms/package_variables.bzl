load("@rules_pkg//pkg:providers.bzl", "PackageVariablesInfo")

def _package_variables_impl(ctx):
    return PackageVariablesInfo(values = ctx.attr.substitutions)

package_variables = rule(
    implementation = _package_variables_impl,
    attrs = {
        "substitutions": attr.string_dict(
            doc = "Substitutions for template expansion",
        ),
    },
)
