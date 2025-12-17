#!/bin/bash

clear_screen() {
    command -v clear >/dev/null && clear
}

usage() {
    printf "Usage: $0 <arch> <target> [--list] [--imports import1, import2, ...]\n\n"
}

list() {
    printf "Architectures:\n" 
    echo "  ├─ aarch64 - Most used in SBCs and phones"
    echo "  ├─ riscv64 - RISC-V 64-bit architecture"
    echo "  ├─ ppc64le - Used in IBM Power Systems"
    echo "  ├─ x86_64 - Most common 64-bit architecture"
    echo "  ├─ mips64 - Used in routers and IoT devices"
    echo "  ├─ armv7l - Mostly used in IoT devices"
    echo "  ├─ armv8l - ARM 64-bit (alternate naming)"
    echo "  ├─ s390x - IBM mainframe architecture"
    printf "  └─ i386 - Most common 32-bit architecture\n\n"
}

die() {
    clear_screen
    usage
    exit 1
}

for arg in "$@"; do
    if [ "$arg" = "--list" ]; then
        clear_screen
        list
        usage
        exit 0
    fi
done

ARCH=$1
TARGET=$2
HIDDEN_IMPORTS=""
IMPORTS=""

if [ -z "$ARCH" ] || [ -z "$TARGET" ]; then
    die
fi

shift 2
while (( "$#" )); do
    case "$1" in
        --imports)
            [ -z "$2" ] && { echo "Missing argument for --imports"; exit 1; }
            IFS=',' read -ra ADDR <<< "$2"
            for i in "${ADDR[@]}"; do
                i=$(echo "$i" | xargs)
                HIDDEN_IMPORTS+=" --hidden-import $i"
                IMPORTS+=" $i"
            done
            shift 2;;
        --list)
            clear_screen
            list
            usage
            exit 0;;
        *)
            shift;;
    esac
done

run_builder() {
    printf "[\e[34m - \e[0m] \e[34mBuilding %s for %s and imports %s...\e[0m\n\n" \
        "$TARGET" "$ARCH" "$IMPORTS"

    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes > /dev/null 2>&1

    TARGET_FILE=$(basename "$TARGET")
    ELF_FILE="${TARGET_FILE%.py}"

    docker run --platform "$1" --rm -t -v "$(pwd):/root/" "$2" /bin/bash -c "apt -qq update 2> /dev/null > /dev/null; \
    apt -qq install gcc zlib1g-dev -y 2> /dev/null > /dev/null; \
    pip3 -q install --upgrade pip 2> /dev/null; \
    pip3 install -q pyinstaller==5.13.2 $IMPORTS 2> /dev/null; \
    pyinstaller /root/$TARGET --distpath /root/ --onefile --clean $HIDDEN_IMPORTS > /dev/null 2>&1; \
    mv /root/$ELF_FILE /root/${ELF_FILE}-$ARCH"

    if [ $? -ne 0 ]; then
        echo -e "[\e[31mERROR\e[0m] Build failed for $ARCH"
        exit 1
    fi

    echo -e "[ \e[32mOK\e[0m ] Build completed successfully for $ARCH"
    rm -rf "$(pwd)/.cache" "$(pwd)/build" "$(pwd)/${ELF_FILE}.spec"
}

case $ARCH in
    "x86_64") run_builder "linux/amd64" "amd64/python:3.6-jessie" ;;
    "i386") run_builder "linux/i386" "i386/python:3.6-jessie" ;;
    "armv7l") run_builder "linux/arm/v7" "arm32v7/python:3.6-jessie" ;;
    "armv8l") run_builder "linux/arm64" "arm64v8/python:3.6-jessie" ;;
    "aarch64") run_builder "linux/arm64" "arm64v8/python:3.6-jessie" ;;
    "ppc64le") run_builder "linux/ppc64le" "ppc64le/python:3.6-jessie" ;;
    "mips64") run_builder "linux/mips64le" "mips64le/python:3.9.0a5-buster" ;;
    "s390x") run_builder "linux/s390x" "s390x/python:3.6-jessie" ;;
    "riscv64") run_builder "linux/riscv64" "riscv64/python:3.9-buster" ;;
    *) 
    
    echo "Error: Unknown architecture '$ARCH'"
    list;;
esac