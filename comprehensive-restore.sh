#!/bin/bash
# Comprehensive script to restore PKG feature functionality
# This script:
# 1. Syncs with upstream shadps4-emu/shadPS4 main branch
# 2. Restores deleted PKG files and reverts changes from target commits
# 3. Pushes the restored branch to your fork (xXJSONDeruloXx/shadPS4-pkg)

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
UPSTREAM_REPO="https://github.com/shadps4-emu/shadPS4.git"
UPSTREAM_BRANCH="main"
YOUR_FORK="xXJSONDeruloXx/shadPS4-pkg"
YOUR_REMOTE="origin" # Assuming your fork is configured as origin

echo -e "${BLUE}=== Starting comprehensive PKG feature restoration process ===${NC}"

# Check if there are uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${YELLOW}You have uncommitted changes in your working directory.${NC}"
    echo -e "${YELLOW}Please commit or stash your changes before running this script.${NC}"
    echo -e "${YELLOW}Run 'git stash' to temporarily save your changes.${NC}"
    exit 1
fi

# Save current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "${GREEN}Current branch: $CURRENT_BRANCH${NC}"

# Check if upstream remote exists, if not add it
if ! git remote | grep -q "upstream"; then
    echo -e "${BLUE}Adding upstream remote: $UPSTREAM_REPO${NC}"
    git remote add upstream $UPSTREAM_REPO
fi

# Update upstream remote URL in case it changed
git remote set-url upstream $UPSTREAM_REPO

# Fetch latest from upstream
echo -e "${BLUE}Fetching latest changes from upstream repository...${NC}"
git fetch upstream
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to fetch from upstream.${NC}"
    exit 1
fi
echo -e "${GREEN}Successfully fetched from upstream.${NC}"

# Create a new branch from upstream's main branch
BRANCH_NAME="pkg-feature-restoration-$(date +%Y%m%d%H%M%S)"
echo -e "${BLUE}Creating new branch '$BRANCH_NAME' from upstream/$UPSTREAM_BRANCH...${NC}"
git checkout -b $BRANCH_NAME upstream/$UPSTREAM_BRANCH
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create branch from upstream/$UPSTREAM_BRANCH.${NC}"
    git checkout $CURRENT_BRANCH
    exit 1
fi
echo -e "${GREEN}Created working branch: $BRANCH_NAME${NC}"

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

# Function to restore deleted files and modified files from a commit
restore_commit() {
    local commit=$1
    local commit_msg=$2
    local commit_index=$3
    
    echo -e "${BLUE}Processing commit: $commit - $commit_msg${NC}"
    
    # Create folders to store changes if they don't exist
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
            
            # Check if the file exists in the commit's parent
            if git cat-file -e "$commit~1:$file" 2>/dev/null; then
                # Checkout the file from the version before the commit
                git checkout $commit~1 -- "$file"
                echo -e "  ${GREEN}Restored: $file${NC}"
            else
                echo -e "  ${YELLOW}Warning: Could not find $file in commit $commit~1${NC}"
            fi
        fi
    done < restored_files/deleted_$commit_index/file_list.txt
    
    # Revert changes for modified files
    echo -e "${GREEN}Reverting changes in modified files...${NC}"
    while read file; do
        if [[ -n "$file" ]]; then
            # Check if the file exists in the current branch
            if [[ -f "$file" ]]; then
                # Save current version for potential conflict resolution
                cp "$file" "restored_files/modified_$commit_index/$(basename "$file").current" 2>/dev/null || true
                
                # Check if the file exists in the commit's parent
                if git cat-file -e "$commit~1:$file" 2>/dev/null; then
                    # Get the version before the commit
                    git show "$commit~1:$file" > "restored_files/modified_$commit_index/$(basename "$file").original" 2>/dev/null
                    
                    if [[ -f "restored_files/modified_$commit_index/$(basename "$file").original" ]]; then
                        # Apply the original content
                        cp "restored_files/modified_$commit_index/$(basename "$file").original" "$file"
                        echo -e "  ${GREEN}Reverted changes: $file${NC}"
                    else
                        echo -e "  ${YELLOW}Warning: Could not extract original content for $file${NC}"
                    fi
                else
                    echo -e "  ${YELLOW}Warning: Could not find $file in commit $commit~1${NC}"
                fi
            else
                echo -e "  ${YELLOW}Warning: File $file doesn't exist in current branch${NC}"
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
# PKG feature preservation configuration

# Crypto-related files - always prefer our version in merges
src/core/crypto/crypto.cpp merge=ours
src/core/crypto/crypto.h merge=ours
src/core/crypto/keys.h merge=ours

# PKG file format handling
src/core/file_format/pkg.cpp merge=ours
src/core/file_format/pkg.h merge=ours
src/core/file_format/pkg_type.cpp merge=ours
src/core/file_format/pkg_type.h merge=ours

# PKG loader components
src/core/loader.cpp merge=ours
src/core/loader.h merge=ours

# PKG GUI components
src/qt_gui/pkg_viewer.cpp merge=ours
src/qt_gui/pkg_viewer.h merge=ours
src/qt_gui/install_dir_select.cpp merge=ours
src/qt_gui/install_dir_select.h merge=ours

# CryptoPP dependencies
cmake/Findcryptopp.cmake merge=ours

# Conflicting modifications in main files that need special handling
# These should trigger a manual review during merges
src/qt_gui/main_window.cpp merge=merge-pkg-feature
src/qt_gui/main_window.h merge=merge-pkg-feature
src/common/config.cpp merge=merge-pkg-feature
src/common/config.h merge=merge-pkg-feature

# Prevent removal of crypto headers added as cryptopp replacements
src/common/aes.h merge-strategy=ours
src/common/sha1.h merge-strategy=ours

# Ensure documentation is preserved
documents/Quickstart/2.png merge=ours
EOL

# Set up Git merge driver
echo -e "${BLUE}Setting up Git merge driver for PKG feature files...${NC}"
git config --local merge.merge-pkg-feature.name "PKG Feature File Merger"
git config --local merge.merge-pkg-feature.driver "bash $(pwd)/resolve-pkg-conflicts.sh %O %A %B"
git config --local merge.ours.driver true
echo -e "${GREEN}Git merge driver configured.${NC}"

# Add and commit all changes
git add .
git status
echo -e "${YELLOW}Review the above changes before committing.${NC}"
echo -e "${YELLOW}Press Enter to commit or Ctrl+C to abort.${NC}"
read -r

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

# Push to your fork
echo -e "${BLUE}Would you like to push this branch to your fork ($YOUR_FORK)? [y/N]${NC}"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Pushing to your fork...${NC}"
    git push $YOUR_REMOTE $BRANCH_NAME
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully pushed to $YOUR_REMOTE/$BRANCH_NAME${NC}"
        echo -e "${BLUE}Branch URL: https://github.com/$YOUR_FORK/tree/$BRANCH_NAME${NC}"
    else
        echo -e "${RED}Failed to push to your fork.${NC}"
        echo -e "${YELLOW}You can manually push later with:${NC}"
        echo -e "  git push $YOUR_REMOTE $BRANCH_NAME"
    fi
fi

# Option to return to original branch
echo -e "${YELLOW}Do you want to return to your original branch: $CURRENT_BRANCH? [y/N]${NC}"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    git checkout $CURRENT_BRANCH
    echo -e "${GREEN}Returned to branch: $CURRENT_BRANCH${NC}"
    echo -e "${YELLOW}You can merge the PKG feature with:${NC}"
    echo -e "  git merge $BRANCH_NAME"
else
    echo -e "${GREEN}Staying on branch: $BRANCH_NAME${NC}"
fi

echo -e "${YELLOW}Note: You may need to resolve some integration issues manually.${NC}"
echo -e "${YELLOW}Run tests and verify the functionality before merging to your main branch.${NC}"
echo -e "${YELLOW}For conflict resolution in future merges, use: ./resolve-pkg-conflicts.sh${NC}"