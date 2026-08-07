riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -nostdlib -c firmware.c -g -O3 -o firmware.o
riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -c boot.s -o boot.o
riscv64-elf-ld -m elf32lriscv -T firmware.ld boot.o firmware.o -o firmware.elf
riscv64-elf-objcopy -O binary firmware.elf firmware.bin
riscv64-elf-objdump -D -b binary -m riscv:rv32i firmware.bin > firmware.asm
