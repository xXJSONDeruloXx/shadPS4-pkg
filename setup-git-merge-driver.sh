#!/bin/bash
# Set up a custom merge driver for PKG feature files

# Define color codes for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Setting up Git merge driver for PKG feature files ===${NC}"

# Configure the custom merge driver
git config --local merge.merge-pkg-feature.name "PKG Feature File Merger"
git config --local merge.merge-pkg-feature.driver "bash $(pwd)/resolve-pkg-conflicts.sh %O %A %B"

# Configure our merge strategy
git config --local merge.ours.driver true

echo -e "${GREEN}Custom merge driver configured successfully.${NC}"
echo -e "${YELLOW}The merge driver will automatically resolve conflicts in PKG feature files when merging or rebasing.${NC}"
echo -e "${YELLOW}For manual conflict resolution, run: ./resolve-pkg-conflicts.sh${NC}"