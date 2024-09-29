FunctionInfo = provider(fields = ["function_name", "starlark_file_declaring_function"], doc = "Provider of basic function information.")

def function_info(function):
    """
    Given a function `function`, we extract the information that can be extracted from its string representation
    and return it in a struct.

    :param function (macro): A Starlark function
    """
    if function == None:
        fail(msg = "Provided None function parameter to function_info")

    # String representation of function has form: <function FUNCTION_NAME from STARLARK_FILE>
    # Extract the fields we are interested in:
    function_keyword, function_name, from_keyword, starlark_file_declaring_function = str(function).lstrip("<").rstrip(">").split(" ")

    if function_keyword != "function" or from_keyword != "from":
        fail(msg = "The string representation of function could not be parsed, expected: <function FUNCTION_NAME from STARLARK_FILE> format, got: " + str(function))

    # Return these in a FunctionInfo
    return FunctionInfo(
        function_name = function_name,
        starlark_file_declaring_function = starlark_file_declaring_function,
    )
