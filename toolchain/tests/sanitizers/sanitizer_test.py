import argparse
import platform
import re
import subprocess

from pathlib import Path
from typing import List


def check_sanitizer_output(executable: Path, expected_stack_line_regexes: List[str]):
    """ Verify that the executable fails and fails with the expected errors. This helps us verify that each sanitizer prints a developer friendly stack trace that is actionable. """

    assert len(expected_stack_line_regexes) != 0
    assert platform.system() != "Windows", "The Bazel toolchain currently does not support sanitizers on Windows."

    try:
        subprocess.check_output([executable], stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as exc:
        # Process is expected to fail, save the output for verification
        output = exc.output.decode("utf-8")
    else:
        assert False, "Sanitizer didn't raise error."

    for expected_stack_line_regex in expected_stack_line_regexes:
        assert re.search(expected_stack_line_regex, output), f"Did not find error regex ({expected_stack_line_regex}) information in output.\nOutput:{output}"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--executable_path')
    parser.add_argument('--expected_stack_line_regex', nargs='+')
    args = parser.parse_args()
    check_sanitizer_output(args.executable_path, args.expected_stack_line_regex)
