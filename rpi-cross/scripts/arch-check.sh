#!/bin/bash

function usage() {
    echo "$0 [--ensure <ARCH> [--no-print-arch] [--no-print-matching]] [--] <FILES> ..."
    echo ""
    echo "Analyzes the architecture of the specified binary files."
    echo ""
    echo "  --ensure <ARCH>"
    echo "  Checks that all the binaries match the architecture <ARCH>."
    echo "  Returns 0 if that's the case, 1 otherwise."
    echo ""
    echo "  --no-print-arch"
    echo "  Omits printing the architecture of the binaries that are not matching <ARCH>."
    echo ""
    echo "  --no-print-matching"
    echo "  Omits printing the architecture of the binaries that are matching <ARCH>."
}

FILES=()
ENSURE_ARCH=""
PRINT_ARCH=1
PRINT_MATCHING=1

while [ $# -gt 0 ]; do
    case "$1" in
        --ensure|-e)
            shift
            ENSURE_ARCH="$1"
            ;;
        --no-print-arch|-na)
            PRINT_ARCH=0
            ;;
        --no-print-matching|-nm)
            PRINT_MATCHING=0
            ;;
        *)
            if [ "$1" == "--" ]; then
                shift
                break
            else
                FILES+=("$1")
            fi
            ;;
    esac
    shift
done

if [ $# -gt 0 ]; then
    FILES+=("$@")
fi

if [ ${#FILES[@]} -eq 0 ]; then
    usage
    exit
fi

function gnu-readelf-arch() {
    readelf -A "$1" | grep -F 'Tag_CPU_arch:' | head -n1 | awk '{print $2}'
}

function llvm-readelf-arch() {
    llvm-readelf --arm-attributes "$1" | grep -F "Description: ARM" | head -n1 | awk '{print $3}'
}

# Determine which readelf to use
if command -v readelf > /dev/null; then
    READELF=gnu-readelf-arch
elif command -v llvm-readelf > /dev/null; then
    READELF=llvm-readelf-arch
else
    echo "Please install readelf, e.g. via"
    echo "$ sudo apt install llvm-dev # or"
    echo "$ sudo apt install binutils"
    exit 1
fi

if ! command -v file > /dev/null; then
    echo "Please install file, e.g. via"
    echo "$ sudo apt install file"
    exit 1
fi


ALL_ARCHS=$(file "${FILES[@]}" |
    grep '\(ELF\|ar archive\)' |
    cut -d: -f1 |
    while read -r FILE; do
        echo "${FILE}: $(${READELF} "${FILE}")"
    done)

if [ -n "${ENSURE_ARCH}" ]; then
    MATCHING_ARCHS=$(echo "${ALL_ARCHS}" | grep ": ${ENSURE_ARCH}\$")
    if [ $PRINT_ARCH -ne 0 ]; then
        echo "${ALL_ARCHS}" | sort -u
    elif [ $PRINT_MATCHING -ne 0 ]; then
        echo "${MATCHING_ARCHS}" | sort -u
    fi
    N_TOTAL=$(echo "$ALL_ARCHS" | cut -d: -f1 | sort -u | wc -l)
    N_MATCHING=$(echo "$MATCHING_ARCHS" | cut -d: -f1 | sort -u | wc -l)
    N_MISMATCHING=$(( N_TOTAL - N_MATCHING ))

    if [ $N_MISMATCHING -eq 0 ]; then
        echo "All the ${N_TOTAL} binaries analyzed match the architecture ${ENSURE_ARCH}."
        exit 0
    else
        echo "There are ${N_MISMATCHING} out of ${N_TOTAL} binaries whose architecture does not match ${ENSURE_ARCH}."
        exit 1
    fi
else
    echo "$ALL_ARCHS"
fi
