def _download_and_extract_rpm_file(repository_ctx, rpm_package_url, rpm_package_sha256):
    """
    Given a provided RPM URL this method:
        1. Downloads the given rpm file
        2. Verifies its checksum
        3. Extracts the package into a given target directory
        4. Converts absolute symlinks of the extracted files to relative symlinks, such that no symlink points outside the sysroot
    """
    if repository_ctx.attr.python_interpreter:
        path_to_python_interpreter = str(repository_ctx.path(repository_ctx.attr.python_interpreter))
    else:
        path_to_python_interpreter = "python3"  # luck shot in case there is no hermetic pyhton toolchain
    rpm_file_name = rpm_package_url.rpartition("/")[2]
    rpm_file_absolute_path = str(repository_ctx.path(rpm_file_name))

    repository_ctx.download(url = rpm_package_url, output = rpm_file_absolute_path, sha256 = rpm_package_sha256)
    arguments = [
        path_to_python_interpreter,
        str(repository_ctx.path(repository_ctx.attr._extract_rpm_file_and_fix_symlinks)),
        "--rpm_file",
        rpm_file_absolute_path,
        "--destination_folder",
        str(repository_ctx.path(".")),
    ]

    # Do not print the output of the script to standard out.
    # To enable it for debugging purposes set quite=False
    # In the default case Bazel prints the whole output to the command line if the
    # execution fails (non 0 return code)
    result = repository_ctx.execute(arguments, quiet = True)
    if result.return_code == 0:
        deletion_successful = repository_ctx.delete(rpm_file_absolute_path)
        if not deletion_successful:
            fail(
                "Could not clean up deleted rpm file {rpm_file}".format(
                    rpm_file = str(repository_ctx.path(rpm_file_absolute_path)),
                ),
            )
    else:
        rpm_file_absolute_path = repository_ctx.path(rpm_file_name)
        fail(
            "Could not extract rpm file: {rpm_file} downloaded from {url}.\nCall to {command} failed with {return_code}.\nStderr: {stderr}\nStdout: {stdout}".format(
                rpm_file = rpm_file_absolute_path,
                url = rpm_package_url,
                command = " ".join(arguments),
                return_code = result.return_code,
                stderr = result.stderr,
                stdout = result.stdout,
            ),
        )

def _centos_sysroot_impl(repository_ctx):
    # Iterates over the provided list of RPM packages and extracts them into a common output folder
    for rpm_package_url, rpm_package_sha256 in repository_ctx.attr.rpm_packages.items():
        _download_and_extract_rpm_file(
            repository_ctx = repository_ctx,
            rpm_package_url = rpm_package_url,
            rpm_package_sha256 = rpm_package_sha256,
        )

    # Generates the repositories root BUILD.bazel files as a copy of the provided default build file.
    repository_ctx.template("BUILD.bazel", repository_ctx.path(repository_ctx.attr._sysroot_build_file))

centos_sysroot = repository_rule(
    doc = """
        This repository rule creates a hermetic sysroot consisting of the provided rpm packages.
        It purely extracts these rpm files (without running any scripts) and rearranges the contained
        symlinks such that no symlink points to a location outside of the sysroot's root folder
    """,
    implementation = _centos_sysroot_impl,
    attrs = {
        "_extract_rpm_file_and_fix_symlinks": attr.label(default = "//toolchain/rules/sysroot:extract_rpm_file_and_fix_symlinks.py", doc = "The tool for extracting the rpm files and fixing their symlinks."),
        "_sysroot_build_file": attr.label(default = "//toolchain/rules/sysroot:centos_sysroot.BUILD", doc = "The template build file for the sysroot's external repository."),
        "python_interpreter": attr.label(allow_single_file = True, doc = "The label of the python interpreter used to call the extraction script."),
        "rpm_packages": attr.string_dict(doc = "The list of rpm packages that are used to create the final sysroot. The keys in this dictionary represent the package's URL's. The values contain the corresponding sha256 checksums."),
    },
)
