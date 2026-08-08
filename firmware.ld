OUTPUT_ARCH(riscv)

ENTRY(_start)

SECTIONS
{
  /* The real entrypoint is at 0x0 */
  . = 0x0;
  .text.firmware.entry : {
    *(.text.firmware.entry)
  }
  .text.firmware.predebug : {
    *(.text.firmware.predebug)
  }

  /* The debug rom will always live at exactly 0x310 */
  . = 0x310;
  .debug_rom : {
    KEEP(*(.debug_rom))
  }

  /* data0 needs to be at a location smaller than 0x1000.
     For now, this is 0x318.
  */

  /* The c code is placed after all of that */
  . = 0x31c;
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

  _stack_top = 0x0FC00;
  _kernel_stack_top = 0x10000;
}