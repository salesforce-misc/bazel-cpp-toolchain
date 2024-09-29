import argparse
import os
import stat
from pathlib import PurePosixPath, PurePath, Path
from typing import Mapping

import rpmfile


class RpmFileMetaDataEntry:
    """
    A helper class that stores the meta data of an entry in side the RPM file
    """
    path: PurePosixPath
    file_mode: int
    potential_link_target: PurePosixPath

    def __init__(self, path: PurePosixPath, file_mode: int, potential_link_target: PurePosixPath):
        self.path = path
        self.file_mode = file_mode
        self.potential_link_target = potential_link_target

    def is_directory(self):
        return stat.S_ISDIR(self.file_mode)

    def is_symlink(self):
        return stat.S_ISLNK(self.file_mode)


def _normalize_directory_name(directory: bytes) -> PurePosixPath:
    """
    Ensures that we use platform agnostic forward slashes in the processed directory names
    :param directory: The raw bytes of the directory name encoded in utf-8
    :return: A relative posix Path representation of the provided directory
    """
    return str(PurePosixPath(directory.decode("utf-8")))


def _to_uint16(signed_int):
    """
    Helper method to convert the signed integer to its actually unsigned 16 bit representation
    """
    return signed_int if signed_int > 0 else (signed_int + (1 << 16))


def _rpm_file_meta_data_table(rpm) -> Mapping[PurePosixPath, RpmFileMetaDataEntry]:
    """
    Helper method that creates an index of the entries contained in the provided rpm file.
    This is important to interpret each entry in a proper way and to finally be able to extract
    these entries.
    """
    base_names = rpm.headers.get("basenames")
    dirindexes = rpm.headers.get("dirindexes")
    file_modes = rpm.headers.get("filemodes")
    potential_link_targets = rpm.headers.get("filelinktos")
    rpm_entries: Mapping[str, RpmFileMetaDataEntry] = {}

    directories = [PurePosixPath(directory.decode("utf-8")) for directory in rpm.headers.get("dirnames")]

    for base_name, dirindex, file_mode, potential_link_target in zip(base_names, dirindexes, file_modes,
                                                                     potential_link_targets):
        path = directories[dirindex] / base_name.decode("utf-8")

        # RPMTAG_FILEMODES corresponds to the st_mode field of the stat struct and is an unsigend integer
        file_mode = _to_uint16(file_mode)
        link_target = PurePosixPath(potential_link_target.decode("utf-8")) if len(potential_link_target) > 0 else None

        rpm_entries[path] = RpmFileMetaDataEntry(path=path, file_mode=file_mode, potential_link_target=link_target)

    return rpm_entries


def extract_rpm_file_and_fix_symlinks(rpm_file: Path, extraction_root: Path) -> None:
    """
    Extracts all entries from the provided rpm file and changes absolute symlinks contained in the rpm
    file to be relative to the provided extraction_root.

    :param rpm_file: The rpm file that should be extracted
    :param extraction_root: The target folder to extract the entries of the rpm file to
    """
    with rpmfile.open(str(rpm_file)) as rpm:
        rpm_meta_data_table: Mapping[PurePosixPath, RpmFileMetaDataEntry] = _rpm_file_meta_data_table(rpm=rpm)

        for index, entry in enumerate(rpm.getmembers()):
            meta_data_entry = rpm_meta_data_table[PurePosixPath("/") / entry.name]
            destination_path = extraction_root.joinpath(entry.name)
            destination_path.parent.mkdir(parents=True, exist_ok=True)
            if meta_data_entry.is_directory():
                print("Creating directory: " + str(destination_path))
                destination_path.mkdir(exist_ok=True)
            elif meta_data_entry.is_symlink():
                if destination_path.exists():
                    print("Symlink already existed: " + str(destination_path))
                    continue

                potential_link_target = meta_data_entry.potential_link_target
                if potential_link_target.is_absolute():
                    relative_path_to_sysroot = os.path.relpath(extraction_root, destination_path.parent)
                    link_target = PurePath(str(relative_path_to_sysroot) + "/" + str(potential_link_target))
                else:
                    link_target = potential_link_target
                print("Creating symlink: " + str(destination_path) + " -> " + str(link_target))
                destination_path.symlink_to(link_target)
            else:
                print("Extracting file: " + str(destination_path))
                with rpm.extractfile(entry.name) as rpmfileobj:
                    with destination_path.open("wb") as outfile:
                        outfile.write(rpmfileobj.read())

                # Apply the file mode bits from the metadata entry.
                # This ensures that executables get the needed +x permissions.
                os.chmod(destination_path, meta_data_entry.file_mode)


def parse_args():
    parser = argparse.ArgumentParser(description="""
        Changes all absolute symlinks in a sysroot to be relative to the sysroot
        e.g.
        The following symlink <sysroot>/usr/lib/my_lib.so -> /usr/lib/my_lib.so.1
        would be converted into
        <sysroot>/usr/lib/my_lib.so -> ../../usr/lib/my_lib.so.1
    """)
    parser.add_argument("--rpm_file", type=Path, help="The rpm file to extract.")
    parser.add_argument("--destination_folder", type=Path, help="The directory to extract the files to.")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    extract_rpm_file_and_fix_symlinks(args.rpm_file, args.destination_folder)
