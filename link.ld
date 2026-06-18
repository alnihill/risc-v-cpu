OUTPUT_ARCH(riscv)

ENTRY(_start)

SECTIONS
{
  /* 1. Boot code goes at 0x0 */
  . = 0x0;
  .text.init : {
    *(.text.init)
  }

  /* 2. Linker pad to EXACTLY 0x190, completely immune to relaxation */
  . = 0x190;
  .debug_rom : {
    KEEP(*(.debug_rom))
  }

  /* 3. All C code safely placed AFTER the debug ROM */
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

  _stack_top = 0x0C00;
  _kernel_stack_top = 0x1000;
}