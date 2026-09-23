#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

DIGITAL_PATH=""
PROGRAM=""
INPUT_FILE=""
EXPECTED_FILE=""
TIMEOUT=10
QUIET=0
CIRCUIT="$PROJECT_DIR/RV5-PROCESSOR.dig"

usage() {
    cat << EOF >&2
Usage: $(basename "$0") <digital_jar> <program> [options]

Options:
  -i, --input <file>     Input file (or pipe to stdin)
  -e, --expected <file>  Compare against expected file (prints program output to stdout if omitted)
  -t, --timeout <sec>    Timeout in seconds (default: 10)
  -q, --quiet            Suppress compilation messages
  -h, --help             Show this help
EOF
    exit "${1:-1}"
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)
            INPUT_FILE="$2"
            shift 2
            ;;
        -e|--expected)
            EXPECTED_FILE="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -q|--quiet)
            QUIET=1
            shift
            ;;
        -h|--help)
            usage 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage 1
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
    usage 1
fi

DIGITAL_PATH="${POSITIONAL[0]}"
PROGRAM="${POSITIONAL[1]}"

log() {
    if [[ $QUIET -eq 0 ]]; then
        echo "$@" >&2
    fi
}

if [[ ! -f "$DIGITAL_PATH" ]]; then
    echo "File not found: $DIGITAL_PATH" >&2
    exit 1
fi

if [[ ! -f "$PROGRAM" ]]; then
    echo "File not found: $PROGRAM" >&2
    exit 1
fi

if [[ -n "$INPUT_FILE" && ! -f "$INPUT_FILE" ]]; then
    echo "File not found: $INPUT_FILE" >&2
    exit 1
fi

if [[ -n "$EXPECTED_FILE" && ! -f "$EXPECTED_FILE" ]]; then
    echo "File not found: $EXPECTED_FILE" >&2
    exit 1
fi

BIN_FILE=""
if [[ "$PROGRAM" == *.s || "$PROGRAM" == *.S || "$PROGRAM" == *.asm || "$PROGRAM" == *.ASM ]]; then
    log "Compiling: $PROGRAM"
    make -C "$PROJECT_DIR" "$PROGRAM" >&2
    DIRNAME=$(dirname "$PROGRAM")
    BASENAME=$(basename "$PROGRAM")
    STEM="${BASENAME%.*}"
    if [[ "$DIRNAME" == "." ]]; then
        BIN_FILE="$PROJECT_DIR/${STEM}.bin"
    else
        BIN_FILE="$PROJECT_DIR/${DIRNAME}/${STEM}.bin"
    fi
    if [[ ! -f "$BIN_FILE" ]]; then
        echo "Build failed: $BIN_FILE" >&2
        exit 1
    fi
elif [[ "$PROGRAM" == *.bin ]]; then
    BIN_FILE="$PROGRAM"
else
    echo "Unsupported file type: $PROGRAM" >&2
    exit 1
fi

make -C "$PROJECT_DIR" firmware >/dev/null 2>&1

AUTORUN_TARGET="$PROJECT_DIR/autorun.bin"
INPUT_TARGET="$PROJECT_DIR/input.txt"

BACKUP_AUTORUN=0
if [[ -f "$AUTORUN_TARGET" ]]; then
    mv "$AUTORUN_TARGET" "$AUTORUN_TARGET.bak.$$"
    BACKUP_AUTORUN=1
fi

BACKUP_INPUT=0
if [[ -f "$INPUT_TARGET" ]]; then
    mv "$INPUT_TARGET" "$INPUT_TARGET.bak.$$"
    BACKUP_INPUT=1
fi

FIFO_DIR=$(mktemp -d)
FIFO="$FIFO_DIR/sim_pipe"
mkfifo "$FIFO"
SIM_PID=""

cleanup() {
    if [[ -n "$SIM_PID" ]]; then
        kill -9 "$SIM_PID" 2>/dev/null || true
        wait "$SIM_PID" 2>/dev/null || true
        SIM_PID=""
    fi
    pkill -f openocd >/dev/null 2>&1 || true
    rm -rf "$FIFO_DIR"
    rm -f "$AUTORUN_TARGET" "$INPUT_TARGET"
    if [[ $BACKUP_AUTORUN -eq 1 && -f "$AUTORUN_TARGET.bak.$$" ]]; then
        mv "$AUTORUN_TARGET.bak.$$" "$AUTORUN_TARGET"
    fi
    if [[ $BACKUP_INPUT -eq 1 && -f "$INPUT_TARGET.bak.$$" ]]; then
        mv "$INPUT_TARGET.bak.$$" "$INPUT_TARGET"
    fi
}
trap cleanup EXIT INT TERM

cp "$BIN_FILE" "$AUTORUN_TARGET"

if [[ -n "$INPUT_FILE" ]]; then
    cp "$INPUT_FILE" "$INPUT_TARGET"
elif [[ ! -t 0 ]]; then
    cat > "$INPUT_TARGET"
fi

java -cp "$DIGITAL_PATH" CLI run -dig "$CIRCUIT" > "$FIFO" 2>/dev/null &
SIM_PID=$!

OUTPUT=""
IN_OUTPUT=0
FINISHED=0
DEADLINE=$(( $(date +%s) + TIMEOUT ))

exec 3< "$FIFO"
while true; do
    NOW=$(date +%s)
    REMAINING=$(( DEADLINE - NOW ))
    if (( REMAINING <= 0 )); then
        break
    fi

    if ! IFS= read -r -t "$REMAINING" -u 3 line; then
        # read timed out or EOF reached
        break
    fi

    if [[ "$line" == *"--- BEGIN PROGRAM OUTPUT ---"* ]]; then
        IN_OUTPUT=1
        suffix="${line#*--- BEGIN PROGRAM OUTPUT ---}"
        suffix="${suffix#$'\n'}"
        if [[ -n "$suffix" ]]; then
            OUTPUT+="$suffix"$'\n'
        fi
        continue
    fi

    if [[ "$line" == *"--- END PROGRAM OUTPUT ---"* ]]; then
        prefix="${line%--- END PROGRAM OUTPUT ---*}"
        if [[ -n "$prefix" ]]; then
            OUTPUT+="$prefix"$'\n'
        fi
        FINISHED=1
        break
    fi

    if [[ $IN_OUTPUT -eq 1 ]]; then
        OUTPUT+="$line"$'\n'
    fi
done
exec 3<&-

# Terminate simulator
if [[ -n "$SIM_PID" ]]; then
    kill -9 "$SIM_PID" 2>/dev/null || true
    wait "$SIM_PID" 2>/dev/null || true
    SIM_PID=""
fi
pkill -f openocd >/dev/null 2>&1 || true

if [[ $FINISHED -eq 0 ]]; then
    echo "Timeout (${TIMEOUT}s)" >&2
    exit 124
fi

if [[ -n "$EXPECTED_FILE" ]]; then
    if diff -u "$EXPECTED_FILE" <(printf '%s' "$OUTPUT") >/dev/null 2>&1; then
        echo "PASS"
        exit 0
    else
        echo "FAIL"
        diff -u --label expected --label actual "$EXPECTED_FILE" <(printf '%s' "$OUTPUT")
        exit 1
    fi
else
    printf '%s' "$OUTPUT"
fi
