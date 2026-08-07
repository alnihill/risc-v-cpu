riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -c main.s -o main.o
riscv64-elf-ld -m elf32lriscv -T link.ld main.o -o main.elf
riscv64-elf-objcopy -O binary main.elf main.bin
riscv64-elf-objdump -D -b binary -m riscv:rv32i main.bin > main.asm
