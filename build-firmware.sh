riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -nostdlib -c firmware.c -g -Os -o firmware.o
riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -nostdlib -c loader.c -g -O3 -o loader.o
riscv64-elf-ld -m elf32lriscv -T firmware.ld loader.o firmware.o -o firmware.elf
riscv64-elf-objcopy -O binary firmware.elf firmware.bin
riscv64-elf-objdump -D -b binary -m riscv:rv32i firmware.bin > firmware.asm
