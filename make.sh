#!/usr/local/bin/zsh

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

for dir in $(find . -type d -name "lab*" -exec test -e "{}/Makefile" \; -print); do
    cd "$dir"
    if [[ $1 == "--clean" ]]; then
        echo -e "${RED}Cleaning $dir${NC}"
        make clean
    else
        echo -e "${GREEN}Building $dir${NC}"
        make all
    fi
    cd - > /dev/null
    echo -e "${YELLOW}Leaving $dir${NC}"
done
