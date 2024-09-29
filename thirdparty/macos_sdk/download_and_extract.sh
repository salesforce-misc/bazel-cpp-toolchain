#!/bin/zsh

set +e

# Download
wget https://github.com/alexey-lysiuk/macos-sdk/releases/download/13.3/MacOSX13.3.tar.xz

# Extract
tar -xvf MacOSX13.3.tar.xz
mv MacOSX13.3.sdk/* .

# Remove ruby folder because a cyclic symlink confuses Bazel
rm -rf System/Library/Frameworks/Ruby.framework/Versions/2.6/Headers/ruby/ruby

# Cleanup
rm -rf MacOSX13.3.sdk
rm MacOSX13.3.tar.xz
