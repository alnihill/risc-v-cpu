OUTPUT_ARCH(riscv)

ENTRY(_start)

SECTIONS
{
  .text : {
    *(.text.init)
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

  _stack_top = 0x0C00;
  _kernel_stack_top = 0x1000;
}