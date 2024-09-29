load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "with_feature_set",
)
load(
    "//toolchain:clang/clang_toolchain_actions.bzl",
    "all_compile_actions",
)
load(
    "//toolchain/helper:platform_helpers.bzl",
    "PLATFORM_WINDOWS",
)

def create_hyper_features(platform):
    features = [
        _create_hyper_warning_flags_feature(platform),
        _create_hyper_cxx20_compat(),
        _create_hyper_platform_defines(platform),
    ]
    return features

def _create_hyper_warning_flags_feature(platform):
    flag_sets = [
        flag_set(
            actions = all_compile_actions,
            flag_groups = [
                flag_group(
                    flags = [
                        "-Wc++11-narrowing",
                        "-Wcast-qual",
                        "-Wdelete-non-virtual-dtor",
                        "-Wdocumentation",
                        "-Wenum-compare",
                        "-Wextra-semi",
                        "-Wformat",
                        "-Wformat-security",
                        "-Wimplicit-fallthrough",
                        "-Wmissing-declarations",
                        "-Wmissing-include-dirs",
                        "-Wnon-virtual-dtor",
                        "-Wold-style-cast",
                        "-Woverloaded-virtual",
                        "-Wpointer-arith",
                        "-Wself-assign",
                        "-Wshadow",
                        "-Wshift-sign-overflow",
                        "-Wsuggest-override",
                        "-Wuninitialized",
                        "-Wunreachable-code",
                        "-Wunreachable-code-aggressive",
                        "-Wunreachable-code-return",
                        "-Wunused",
                        "-Wunused-const-variable",
                        "-Wunused-exception-parameter",
                        "-Wunused-function",
                        "-Wfloat-conversion",
                        # Disabled warnings
                        "-Wno-unqualified-std-cast-call",  # In Hyper, we rather freely use `using namespace std;`. We don't want to be warned about it.
                        # Enable additional [[nodiscard]] annotations in the standard library
                        "-D_LIBCPP_ENABLE_NODISCARD",
                        # Remove non-standardized transitive includes from the standard library
                        "-D_LIBCPP_REMOVE_TRANSITIVE_INCLUDES",
                    ],
                ),
            ],
        ),
    ]

    if platform == PLATFORM_WINDOWS:
        flag_sets.append(flag_set(
            actions = all_compile_actions,
            flag_groups = [
                flag_group(
                    flags = ["/W4"],
                ),
            ],
        ))
    else:
        flag_sets.append(flag_set(
            actions = all_compile_actions,
            flag_groups = [
                flag_group(
                    flags = [
                        # -Wextra and -Wall are not required on Windows
                        "-Wextra",
                        "-Wall",
                        # Enable thread safety analysis when not on Windows
                        "-Wthread-safety",
                        # Enable thread safety annotations for std::mutex and std::lock_guard. Our Windows toolchain lacks these annotations
                        "-D_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS",
                    ],
                ),
            ],
        ))

    return feature(
        name = "hyper_warning_flags",
        enabled = False,
        flag_sets = flag_sets,
    )

def _create_hyper_cxx20_compat():
    """ We need these flags to ensure our code keeps working with C++23
    """
    return feature(
        name = "hyper_cxx20_compat",
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-D_SILENCE_CXX20_OLD_SHARED_PTR_ATOMIC_SUPPORT_DEPRECATION_WARNING",
                            "-D_SILENCE_CXX20_U8PATH_DEPRECATION_WARNING",
                        ],
                    ),
                ],
                # C++23 is the default, thus we always apply the defines if no other c++ mode is set
                with_features = [with_feature_set(not_features = ["c++11", "c++14"])],
            ),
        ],
    )

def _create_hyper_platform_defines(platform):
    if platform == PLATFORM_WINDOWS:
        return feature(
            name = "hyper_platform_defines",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = all_compile_actions,
                    flag_groups = [
                        flag_group(
                            flags = [
                                # Exclude less common Windows API declarations (such as Cryptography, DDE, RPC, Shell, and Windows Sockets) from <Windows.h> by default.
                                "-DWIN32_LEAN_AND_MEAN",
                                # Prevent <Windows.h> from defining min/max macros.
                                "-DNOMINMAX",
                                # Enable Unicode support in the Windows API and the CRT.
                                # Use the Unicode versions of the Windows API declarations instead of the Windows code page versions.
                                # See [Conventions for Function Prototypes](https://msdn.microsoft.com/en-us/library/windows/desktop/dd317766(v=vs.85).aspx).
                                "-DUNICODE",
                                "-D_UNICODE",
                            ],
                        ),
                    ],
                ),
            ],
        )
    else:
        return feature(name = "hyper_platform_defines")
