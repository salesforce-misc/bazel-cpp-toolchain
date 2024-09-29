#!/bin/zsh

set +e

# Expects "Command Line Tools.pkg" to be present in this folder
# Doesn't delete original package after extraction

# Create temp dirs
mkdir tmp out

# Exract
xar -xf "Command Line Tools.pkg" -C ./tmp
for file in ./tmp/*.pkg; do
  pbzx -n "$file/Payload" | (cd ./out && cpio -i)
done
mv out/Library/Developer/CommandLineTools/usr .

# Cleanup
rm -rf tmp out
