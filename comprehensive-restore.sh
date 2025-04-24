#!/bin/bash
# Comprehensive script to restore both deleted files and revert changes from target commits

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Starting comprehensive restoration process ===${NC}"

# Commits to process
COMMITS=(
    "be22674f8c1ac84e1cff89947ff4a6753070f21b" 
    "31e1d4f839118b59398ca6f871929fc0e286e13c"
    "be7d646e8314ccf1f125818f3589b78d8e3262eb"
    "faae1218fa0b590e4e3f55b7d41780eec8c281f9"
    "a5958bf7f0da207e02065a88355b8afae0b5e256"
    "751a23af0f5a9612b8e28af1400896a3026ee331" 
    "9dbc79dc96a4cf439adbead5563e46d1eb301391"
)

COMMIT_MSGS=(
    "Remove fpkg code"
    "Remove dead code"
    "Remove need for cryptopp build"
    "Getting rid of the Separate Update Folder option"
    "remove leftover from #2707"
    "Qt GUI: Update Translation"
    "New Crowdin updates"
)

# Create a working branch
BRANCH_NAME="pkg-feature-restoration-$(date +%Y%m%d%H%M%S)"
git checkout -b $BRANCH_NAME
echo -e "${GREEN}Created working branch: $BRANCH_NAME${NC}"

# Function to restore deleted files and modified files from a commit
restore_commit() {
    local commit=$1
    local commit_msg=$2
    local commit_index=$3
    
    echo -e "${BLUE}Processing commit: $commit - $commit_msg${NC}"
    
    # Create folders to store changes
    mkdir -p restored_files/deleted_$commit_index
    mkdir -p restored_files/modified_$commit_index
    
    # Extract deleted files
    echo -e "${YELLOW}Extracting deleted files from commit $commit${NC}"
    git show $commit --name-status | grep ^D | cut -f2- > restored_files/deleted_$commit_index/file_list.txt
    
    # Extract modified files
    echo -e "${YELLOW}Extracting modified files from commit $commit${NC}"
    git show $commit --name-status | grep ^M | cut -f2- > restored_files/modified_$commit_index/file_list.txt
    
    # Restore deleted files from the version before deletion
    echo -e "${GREEN}Restoring deleted files...${NC}"
    while read file; do
        if [[ -n "$file" ]]; then
            # Create directory if it doesn't exist
            dir=$(dirname "$file")
            mkdir -p "$dir"
            
            # Checkout the file from the version before the commit
            git checkout $commit~1 -- "$file"
            echo -e "  ${GREEN}Restored: $file${NC}"
        fi
    done < restored_files/deleted_$commit_index/file_list.txt
    
    # Revert changes for modified files
    echo -e "${GREEN}Reverting changes in modified files...${NC}"
    while read file; do
        if [[ -n "$file" ]]; then
            if [[ -f "$file" ]]; then
                # Save current version for potential conflict resolution
                cp "$file" "restored_files/modified_$commit_index/$(basename "$file").current"
                
                # Get the version before the commit
                git show $commit~1:"$file" > "restored_files/modified_$commit_index/$(basename "$file").original"
                
                # Apply the original content
                cp "restored_files/modified_$commit_index/$(basename "$file").original" "$file"
                echo -e "  ${GREEN}Reverted changes: $file${NC}"
            else
                echo -e "  ${RED}Warning: File $file doesn't exist anymore${NC}"
            fi
        fi
    done < restored_files/modified_$commit_index/file_list.txt
}

# Process each commit
for i in "${!COMMITS[@]}"; do
    restore_commit "${COMMITS[$i]}" "${COMMIT_MSGS[$i]}" "$i"
done

# Setup .gitattributes for future automation
echo -e "${BLUE}Setting up .gitattributes for future automation${NC}"
cat > .gitattributes <<EOL
# PKG feature preservation
# These files should be preserved during merges
src/core/crypto/* merge=ours
src/core/file_format/pkg* merge=ours
src/qt_gui/pkg_viewer* merge=ours
src/core/loader* merge=ours
src/qt_gui/install_dir_select* merge=ours
cmake/Findcryptopp.cmake merge=ours
EOL

# Add and commit all changes
git add .
git commit -m "Restore PKG feature removed in multiple commits

Restored deleted files and reverted changes from the following commits:
- be22674f - Remove fpkg code
- 31e1d4f - Remove dead code
- be7d646 - Remove need for cryptopp build
- faae121 - Getting rid of the Separate Update Folder option
- a5958bf - Remove leftover from cryptopp
- 751a23a - Qt GUI: Update Translation
- 9dbc79d - New Crowdin updates

Also added .gitattributes to help manage these files in future merges."

echo -e "${BLUE}=== Restoration process complete ===${NC}"
echo -e "${GREEN}The PKG feature has been restored on branch: $BRANCH_NAME${NC}"
echo -e "${YELLOW}Note: You may need to resolve some integration issues manually.${NC}"
echo -e "${YELLOW}Run tests and verify the functionality before merging.${NC}"