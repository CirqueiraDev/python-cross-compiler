#!/bin/bash

usage() {
    printf "Usage: $0 <arch> <target> [--list] [--imports import1, import2, ...]\n"
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
    printf "  └─ i386 - Most common 32-bit architecture\n"
}

die() {
    usage
    exit 1
}

timestamp() {
    date '+%H:%M:%S'
}

for arg in "$@"; do
    if [ "$arg" = "--list" ]; then
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
            list
            usage
            exit 0;;
        *)
            shift;;
    esac
done

run_builder() {
    printf "[\e[34m - \e[0m] \e[34mBuilding %s for %s and imports %s...\e[0m\n" \
        "$TARGET" "$ARCH" "$IMPORTS"
    printf "[\e[33m ! \e[0m] \e[33mNote: Building may take several minutes depending on the architecture.\e[0m\n\n"

    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes > /dev/null 2>&1

    TARGET_FILE=$(basename "$TARGET")
    ELF_FILE="${TARGET_FILE%.py}"
    
    echo "[$(timestamp)] Preparing Docker environment..."
    
    docker run --platform "$1" --rm -t -v "$(pwd):/root/" "$2" /bin/bash -c "
    echo '[$(date +%H:%M:%S)] Updating apt...'; \
    apt-get update -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 > /dev/null 2>&1; \
    echo '[$(date +%H:%M:%S)] Installing system dependencies...'; \
    apt-get install -y gcc zlib1g-dev > /dev/null 2>&1; \
    echo '[$(date +%H:%M:%S)] Upgrading pip...'; \
    pip3 install --upgrade pip > /dev/null 2>&1; \
    echo '[$(date +%H:%M:%S)] Installing PyInstaller and dependencies...'; \
    pip3 install pyinstaller==5.13.2 $IMPORTS > /dev/null 2>&1; \
    echo '[$(date +%H:%M:%S)] Compiling with PyInstaller...'; \
    pyinstaller /root/$TARGET --distpath /root/ --onefile --clean $HIDDEN_IMPORTS > /dev/null 2>&1; \
    echo '[$(date +%H:%M:%S)] Build process completed.'; \
    mv /root/$ELF_FILE /root/${ELF_FILE}-$ARCH 2>&1"

    if [ $? -ne 0 ]; then
        echo -e "\n[\e[31mERROR\e[0m] Build failed for $ARCH"
        exit 1
    fi

    echo -e "\n[ \e[32mOK\e[0m ] Build completed successfully for $ARCH"
    rm -rf "$(pwd)/.cache" "$(pwd)/build" "$(pwd)/${ELF_FILE}.spec"
}

case $ARCH in
    "x86_64") run_builder "linux/amd64" "amd64/python:3.8-buster" ;;
    "i386") run_builder "linux/i386" "i386/python:3.8-buster" ;;
    "armv7l") run_builder "linux/arm/v7" "arm32v7/python:3.8-buster" ;;
    "armv8l") run_builder "linux/arm64" "arm64v8/python:3.8-buster" ;;
    "aarch64") run_builder "linux/arm64" "arm64v8/python:3.8-buster" ;;
    "ppc64le") run_builder "linux/ppc64le" "ppc64le/python:3.8-buster" ;;
    "mips64") run_builder "linux/mips64le" "mips64le/python:3.9-buster" ;;
    "s390x") run_builder "linux/s390x" "s390x/python:3.8-buster" ;;
    "riscv64") run_builder "linux/riscv64" "riscv64/python:3.9-buster" ;;
    *) 
    
    echo "Error: Unknown architecture '$ARCH'"
    list;;
esac
