#!/usr/bin/python
# This script generates a platform-specific symbol file out of a given input .sym file.
# The input sym file should contain a list of symbols to export on each line
# -------------------------------------
import os
import platform
import sys


def _generate_windows_def_file_content(symbol_list):
    """ Generate a .DEF file for exporting symbols on Windows

    https://docs.microsoft.com/en-us/cpp/build/exporting-from-a-dll-using-def-files?view=vs-2019
    """
    output = "EXPORTS\n"

    for symbol in symbol_list:
        output += symbol + "\n"

    return output


def _generate_mac_exported_symbols_list_file_content(symbol_list):
    """ Generate a exported_symbols list file for exporting symbols on Mac

    https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/DynamicLibraries/100-Articles/DynamicLibraryDesignGuidelines.html
    """
    output = ""
    for symbol in symbol_list:
        output += "_" + symbol + "\n"
    return output


def _generate_linux_version_script_content(symbol_list):
    """ Generate a version script for defining exported symbols on Linux

    https://www.gnu.org/software/gnulib/manual/html_node/LD-Version-Scripts.html
    """
    output = "{\nglobal:\n"
    for symbol in symbol_list:
        output += symbol + ";\n"
    output += "\nlocal:\n*;\n};\n"
    return output


def _generate_linux_ld_linker_script_content(symbol_list):
    """ Generate a linker script for defining exported symbols on Linux

    http://bravegnu.org/gnu-eprog/lds.html
    """
    output = ""
    for symbol in symbol_list:
        output += f"EXTERN({symbol});\nASSERT(DEFINED({symbol}), \"Symbol {symbol} not available\");\n"
    return output


def _generate_symbol_file(input_file_path, output_file_path):
    """ Read the symbol list file and create the proper symbol file for the platform in the output file path."""
    symbol_list = []
    with open(input_file_path, "r") as f:
        for line in f:
            symbol_list.append(line.rstrip())

    file_extension = os.path.splitext(output_file_path)[1]

    if file_extension == ".def":
        file_content = _generate_windows_def_file_content(symbol_list)
    elif file_extension == ".exp":
        file_content = _generate_mac_exported_symbols_list_file_content(symbol_list)
    elif file_extension == ".ver":
        file_content = _generate_linux_version_script_content(symbol_list)
    elif file_extension == ".lds":
        file_content = _generate_linux_ld_linker_script_content(symbol_list)
    else:
        raise NotImplemented("Unknown file type: " + file_extension)

    with open(output_file_path, "w") as f:
        f.write(file_content)


if __name__ == "__main__":
    import sys
    input_sym_file = sys.argv[1]
    output_file = sys.argv[2]
    _generate_symbol_file(input_sym_file, output_file)
