def unique_list(input_list):
    """
    Given a list, returns a unique list.

    :param input_list: List of items to be deduplicated.
    """
    if input_list == None:
        return None
    return dict(zip(input_list, input_list)).values()

def is_unique_list(input_list):
    """
    Given a list, returns True iff it is a unique list.

    :param input_list: List of items to be checked for uniqueness.
    """
    if input_list == None:
        return None
    return len(input_list) == len(unique_list(input_list))
