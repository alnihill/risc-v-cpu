riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -nostdlib -c ./firmware/firmware.c -g -Os -o ./firmware-out/firmware.o
riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -nostdlib -c ./firmware/shell.c -g -O3 -o ./firmware-out/shell.o
riscv64-elf-ld -m elf32lriscv --no-warn-rwx-segments -T ./firmware/firmware.ld firmware-out/shell.o ./firmware-out/firmware.o -o ./firmware-out/firmware.elf
riscv64-elf-objcopy -O binary ./firmware-out/firmware.elf ./firmware-out/firmware.bin
riscv64-elf-objdump -D -b binary -m riscv:rv32i ./firmware-out/firmware.bin > ./firmware-out/firmware.asm
