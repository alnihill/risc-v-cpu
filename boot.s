.section .text.init
.global _start

_start:
  la sp, _stack_top

  la t0, trap_handler
  csrw mtvec, t0
  la t0, _kernel_stack_top
  csrw mscratch, t0

  call main

trap_handler:
  csrrw sp, mscratch, sp
  addi sp, sp, -16
  sw t0, 0(sp)
  sw t1, 4(sp)
  sw t2, 8(sp)
  sw a0, 12(sp)
  
  # Check mcause to see why we're here.
  csrr t0, mcause
  li t1, 11
  bne t0, t1, other_trap_logic

  # Do whatever we wanna do
  # (Check against a7 and do stuff accordingly.)

  # increment PC
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0

  lw a0, 12(sp)
  lw t2, 8(sp)
  lw t1, 4(sp)
  lw t0, 0(sp)
  addi sp, sp, 16

  csrrw sp, mscratch, sp

  mret

other_trap_logic:
  # Wasn't an ecall... just hang here I guess.
  j other_trap_logic
  

hang:
  j hang
