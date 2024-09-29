# Architectures and their extensions: https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
X86_64_TOOLCHAIN_SUPPORTED_INSTRUCTION_SET_EXTENSIONS = [
    # Extensions of nehalem
    "sse",
    "sse2",
    "sse3",
    "ssse3",
    "sse4.1",
    "sse4.2",
    "popcnt",
    # cx16 required for 128bit atomics under POSIX
    "cx16",
    # Add more extensions here if needed
]

X86_64_TOOLCHAIN_DEFAULT_INSTRUCTION_SET_EXTENSIONS = [
    # Extensions that will be enabled by default (defining the default minspec of the project)
    "sse",
    "sse2",
    "sse3",
    "ssse3",
    "sse4.1",
    "sse4.2",
    "popcnt",
    "cx16",
]

PLATFORM_LINUX = "@platforms//os:linux"
PLATFORM_MACOS = "@platforms//os:macos"
PLATFORM_WINDOWS = "@platforms//os:windows"

def is_windows(ctx):
    # workaround for detecting windows
    # cf. https://github.com/bazelbuild/bazel/issues/2045 or
    return ctx.host_configuration.host_path_separator == ";"
