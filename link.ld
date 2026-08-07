OUTPUT_ARCH(riscv)

ENTRY(_start)

SECTIONS
{
  . = 0x3000;

  .text : {
    *(.text .text.*)
  }
  .rodata : {
    *(.rodata .rodata.*)
  }
  .data : {
    *(.data .data.*)
  }
  .bss : {
    *(.bss .bss.*)
  }
}