#!/bin/bash
# PKG-Feature Merge Conflict Resolution Script
# This script helps resolve merge conflicts for PKG feature files

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== PKG Feature Merge Conflict Resolution ===${NC}"

# Array of file patterns to preserve during merge conflicts
PRESERVED_PATTERNS=(
    "src/core/crypto/*"
    "src/core/file_format/pkg*"
    "src/qt_gui/pkg_viewer*"
    "src/core/loader*"
    "src/qt_gui/install_dir_select*"
    "cmake/Findcryptopp.cmake"
)

# Check if there are merge conflicts
if [[ -z $(git diff --name-only --diff-filter=U) ]]; then
    echo -e "${GREEN}No merge conflicts found.${NC}"
    exit 0
fi

echo -e "${YELLOW}Merge conflicts detected. Resolving PKG feature conflicts...${NC}"

# Resolve conflicts for each preserved pattern
for pattern in "${PRESERVED_PATTERNS[@]}"; do
    # Find conflicted files matching the pattern
    conflicted_files=$(git diff --name-only --diff-filter=U | grep -E "$pattern" || echo "")
    
    if [[ -n "$conflicted_files" ]]; then
        echo -e "${YELLOW}Processing conflicts in pattern: $pattern${NC}"
        
        # Process each conflicted file
        echo "$conflicted_files" | while read file; do
            echo -e "  ${BLUE}Resolving conflict: $file${NC}"
            
            # Keep "our" version (the restored PKG feature)
            git checkout --ours -- "$file"
            git add "$file"
            echo -e "  ${GREEN}Resolved: $file (kept our version)${NC}"
        done
    fi
done

# Check if all conflicts are resolved
remaining_conflicts=$(git diff --name-only --diff-filter=U)
if [[ -n "$remaining_conflicts" ]]; then
    echo -e "${YELLOW}The following conflicts still need manual resolution:${NC}"
    echo "$remaining_conflicts" | sed 's/^/  - /'
    echo -e "${YELLOW}Please resolve these conflicts manually.${NC}"
else
    echo -e "${GREEN}All PKG feature conflicts have been resolved.${NC}"
    echo -e "${YELLOW}You can continue with your merge by running:${NC}"
    echo -e "  git commit -m \"Merge resolution: preserved PKG feature\""
fi