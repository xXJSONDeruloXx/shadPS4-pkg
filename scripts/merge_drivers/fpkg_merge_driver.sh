#!/bin/bash

# This script serves as a custom merge driver for conflicts related to FPKG code
# It automatically resolves conflicts by favoring the older version of the code
# (equivalent to 'git checkout --theirs')

# Parameters received from Git:
# $1 = %O: name of the temporary file containing the common ancestor
# $2 = %A: name of the temporary file containing the "our" version
# $3 = %B: name of the temporary file containing the "their" version
# $4 = path to the file being merged

# Print what's happening for debugging
echo "FPKG merge driver: Resolving conflicts in $4" >&2

# Keep "their" version (the one being reverted to)
cat "$3" > "$2"

# Return success
exit 0