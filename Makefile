# Target RISC-V GCC toolchain (auto-detects macOS Homebrew, Linux apt, and macOS/Windows xPack)
ifeq ($(OS),Windows_NT)
  # Detect if running under cmd.exe or a POSIX shell (e.g. Git Bash, MSYS, sh)
  IS_CMD := $(if $(findstring Windows_NT,$(shell echo %OS%)),1,0)
else
  IS_CMD := 0
endif

ifeq ($(IS_CMD),1)
  WHICH   ?= where.exe
  DEVNULL ?= nul
  MKDIR_P  = if not exist "$(subst /,\,$(1))" mkdir "$(subst /,\,$(1))"
  RMDIR_P  = if exist "$(subst /,\,$(1))" rmdir /s /q "$(subst /,\,$(1))"
  RM_F     = if exist "$(subst /,\,$(1))" del /f /q "$(subst /,\,$(1))"
else
  WHICH   ?= which
  DEVNULL ?= /dev/null
  MKDIR_P  = mkdir -p $(1)
  RMDIR_P  = rm -rf $(1)
  RM_F     = rm -f $(1)
endif

PREFIXES ?= riscv64-elf- riscv64-unknown-elf- riscv-none-elf- riscv32-unknown-elf- riscv32-elf- riscv-none-embed-

ifeq ($(CROSS_COMPILE),)
  FIRST_GCC := $(firstword $(shell $(WHICH) $(foreach p,$(PREFIXES),$(p)gcc) 2>$(DEVNULL)))
  ifneq ($(FIRST_GCC),)
    CROSS_COMPILE := $(patsubst %gcc.exe,%,$(patsubst %gcc,%,$(notdir $(FIRST_GCC))))
  endif
endif

ifeq ($(CROSS_COMPILE),)
  XPACK_GCC := $(lastword $(wildcard \
    $(HOME)/Library/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf-gcc \
    $(HOME)/.local/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf-gcc \
    $(HOME)/opt/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf-gcc \
    $(APPDATA)/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf-gcc.exe \
    $(USERPROFILE)/AppData/Roaming/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf-gcc.exe \
    $(USERPROFILE)/Downloads/xpack-riscv-none-elf-gcc-*/bin/riscv-none-elf-gcc.exe \
    C:/xpack-riscv-none-elf-gcc-*/bin/riscv-none-elf-gcc.exe))
  ifneq ($(XPACK_GCC),)
    CROSS_COMPILE := $(dir $(XPACK_GCC))riscv-none-elf-
  endif
endif

CC      := $(CROSS_COMPILE)gcc -march=rv32i_zicsr -mabi=ilp32
LD      := $(CROSS_COMPILE)ld -m elf32lriscv --no-warn-rwx-segments
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

.PHONY: all firmware clean $(filter %.s %.S %.asm %.ASM,$(MAKECMDGOALS))

all: firmware

firmware: firmware-out/firmware.bin

firmware-out/firmware.bin: firmware/firmware.c firmware/shell.c firmware/firmware.ld firmware/common.h
	@$(call MKDIR_P,firmware-out)
	$(CC) -ffreestanding -nostdlib -Ifirmware -g -Os -c firmware/firmware.c -o firmware-out/firmware.o
	$(CC) -ffreestanding -nostdlib -Ifirmware -g -O3 -c firmware/shell.c -o firmware-out/shell.o
	$(LD) -T firmware/firmware.ld firmware-out/firmware.o firmware-out/shell.o -o firmware-out/firmware.elf
	$(OBJCOPY) -O binary firmware-out/firmware.elf firmware-out/firmware.bin
	$(OBJDUMP) -D -b binary -m riscv:rv32i firmware-out/firmware.bin > firmware-out/firmware.asm
	@echo Built: firmware-out/firmware.bin

# Build any assembly file (e.g. 'make Lab3.s' or 'make Lab3.asm' -> creates 'Lab3.bin')
$(filter %.s %.S %.asm %.ASM,$(MAKECMDGOALS)):
	$(CC) -g -x assembler-with-cpp -I"$(dir $@)" -I. -I"local/fixed labs" -c "$@" -o "$(basename $@).o"
	$(LD) -T link.ld "$(basename $@).o" -o "$(basename $@).elf"
	$(OBJCOPY) -O binary "$(basename $@).elf" "$(basename $@).bin"
	@$(call RM_F,$(basename $@).o)
	@echo Built: $(basename $@).bin

clean:
	@$(call RMDIR_P,firmware-out)
