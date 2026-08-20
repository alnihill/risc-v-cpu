# Target RISC-V GCC toolchain (auto-detects macOS Homebrew, Linux apt, and macOS/Windows xPack)
CROSS_COMPILE ?= $(firstword $(foreach p,riscv64-elf- riscv64-unknown-elf- riscv-none-elf- riscv32-unknown-elf- riscv32-elf- riscv-none-embed-,$(if $(shell which $(p)gcc 2>/dev/null),$(p))))
ifeq ($(CROSS_COMPILE),)
  CROSS_COMPILE := $(lastword $(wildcard $(HOME)/Library/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf- $(HOME)/.local/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf-))
endif

CC      := $(CROSS_COMPILE)gcc -march=rv32i_zicsr -mabi=ilp32
LD      := $(CROSS_COMPILE)ld -m elf32lriscv --no-warn-rwx-segments
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

.PHONY: all firmware clean $(filter %.s %.S %.asm %.ASM,$(MAKECMDGOALS))

all: firmware

firmware: firmware-out/firmware.bin

firmware-out/firmware.bin: firmware/firmware.c firmware/shell.c firmware/firmware.ld firmware/common.h
	@mkdir -p firmware-out
	$(CC) -ffreestanding -nostdlib -Ifirmware -g -Os -c firmware/firmware.c -o firmware-out/firmware.o
	$(CC) -ffreestanding -nostdlib -Ifirmware -g -O3 -c firmware/shell.c -o firmware-out/shell.o
	$(LD) -T firmware/firmware.ld firmware-out/firmware.o firmware-out/shell.o -o firmware-out/firmware.elf
	$(OBJCOPY) -O binary firmware-out/firmware.elf firmware-out/firmware.bin
	$(OBJDUMP) -D -b binary -m riscv:rv32i firmware-out/firmware.bin > firmware-out/firmware.asm
	@echo "Built: firmware-out/firmware.bin"

# Build any assembly file (e.g. 'make Lab3.s' or 'make Lab3.asm' -> creates 'Lab3.bin')
$(filter %.s %.S %.asm %.ASM,$(MAKECMDGOALS)):
	@dir="$$(dirname "$@")"; \
	stem="$$(basename "$@" | sed 's/\.[^.]*$$//')"; \
	$(CC) -g -x assembler-with-cpp -I"$$dir" -I. -I"local/fixed labs" -c "$@" -o "$$dir/$$stem.o" && \
	$(LD) -T link.ld "$$dir/$$stem.o" -o "$$dir/$$stem.elf" && \
	$(OBJCOPY) -O binary "$$dir/$$stem.elf" "$$dir/$$stem.bin" && \
	rm -f "$$dir/$$stem.o" && \
	echo "Built: $$dir/$$stem.bin"

clean:
	rm -rf firmware-out
