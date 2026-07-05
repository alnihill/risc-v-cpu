riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -ffreestanding -nostdlib -c main.c -o main.o
riscv64-elf-gcc -march=rv32i_zicsr -mabi=ilp32 -c boot.s -o boot.o
riscv64-elf-ld -m elf32lriscv -T link.ld boot.o main.o -o main.elf
riscv64-elf-objcopy -O binary main.elf main.bin
riscv64-elf-objdump -D -b binary -m riscv:rv32i main.bin > main.asm
perl -0777 -ne 'print pack("(a4)*", map { $_, $_ } unpack("(a4)*", $_))' main.bin > interlaced.bin
