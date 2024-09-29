load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

# Commented out actions are currently not used by us and therefore
# not supported.
#
# CLIF is a google tool for creating C++ wrappers, but not all language
# generators are publicly available. The action clif_match extracts the language
# agnostic model for a given C++ header. We don't need this, so all occurencies
# of ACTIONS_NAMES.clif_match in this file have been removed.
#
# Toolchain doesn't contain objective C support, objc* actions have been removed.
#
# This toolchain currently does not have support for c++ modules.
# This implies that the toolchain does not have support for the following actions:
# cpp_header_parsing, cpp_module_compile and cpp_module_codegen
#
# Currently this toolchain does not have support for linkstamp_compile.
# For details please see: https://github.com/bazelbuild/bazel/issues/6997
#
# We also deliberately omitted the objcopy_embed_data action and the accompanying feature,
# as the objcopy_embed_data action is not even contained in the ACTION_NAMES struct.

compile_actions_without_assemble = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.preprocess_assemble,
    #ACTION_NAMES.linkstamp_compile,
    #ACTION_NAMES.cpp_header_parsing,
    #ACTION_NAMES.cpp_module_compile,
    #ACTION_NAMES.cpp_module_codegen,
    #ACTION_NAMES.lto_backend,
]

all_compile_actions = compile_actions_without_assemble + [ACTION_NAMES.assemble]

all_cpp_compile_actions = [
    ACTION_NAMES.cpp_compile,
    #ACTION_NAMES.linkstamp_compile,
    #ACTION_NAMES.cpp_header_parsing,
    #ACTION_NAMES.cpp_module_compile,
    #ACTION_NAMES.cpp_module_codegen,
]

preprocessor_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.preprocess_assemble,
    #ACTION_NAMES.linkstamp_compile,
    #ACTION_NAMES.cpp_header_parsing,
    #ACTION_NAMES.cpp_module_compile,
]

codegen_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    #ACTION_NAMES.linkstamp_compile,
    #ACTION_NAMES.cpp_module_codegen,
    #ACTION_NAMES.lto_backend,
]

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

# We keep the LTO actions list, even if we don't support LTO right now,
# to preserve the information in which features it is needed.
lto_index_actions = [
    #    ACTION_NAMES.lto_index_for_dynamic_library,
    #    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
    #    ACTION_NAMES.lto_index_for_executable,
]
