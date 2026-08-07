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
  addi sp, sp, -32
  sw t0, 0(sp)
  sw t1, 4(sp)
  sw t2, 8(sp)
  sw t3, 12(sp)
  sw t4, 16(sp)
  sw t5, 20(sp)
  sw t6, 24(sp)
  sw s0, 28(sp)
  
  # Check mcause to see why we're here.
  csrr t0, mcause
  li t1, 11
  bne t0, t1, other_trap_logic

  # Do whatever we wanna do
  # (Check against a7 and do stuff accordingly.)

  # print char
  bne t1, a7, print_char_end # (t1 is still 11)
  li t0, 0x10000
  sb a0, 0(t0)
  j ecall_handled
print_char_end:

  # print string
  li t1, 4
  bne t1, a7, print_string_end
  mv t1, a0
  li t0, 0x10000
print_string_loop:
  lbu t2, 0(t1)
  beq t2, zero, ecall_handled
  sb t2, 0(t0)
  addi t1, t1, 1
  j print_string_loop
print_string_end:

  # get numeric input
  # TODO: negatives
  li t1, 5
  bne t1, a7, get_numeric_input_end

  li t0, 0x10000
  li t2, 4
  li t3, 10
  li a0, 0
  li t6, 0
  li s0, 8

get_numeric_input_loop:
  lbu t1, 0(t0)
  beq t1, t2, get_numeric_input_loop
  
  beq t1, t3, get_numeric_input_submit
  beq t1, s0, get_numeric_input_backspace
  sb t1, 0(t0)
  addi t6, t6, 1
  j get_numeric_input_backspace_done
get_numeric_input_backspace:
  beq t6, zero, get_numeric_input_loop
  sb t1, 0(t0)
  addi t6, t6, -1
  lw a0, 0(sp)
  addi sp, sp, 4
  j get_numeric_input_loop
get_numeric_input_backspace_done:

  addi sp, sp, -4
  sw a0, 0(sp)

  addi t1, t1, -48
  slli t4, a0, 3
  slli t5, a0, 1
  add a0, t4, t5
  
  add a0, a0, t1

  j get_numeric_input_loop

get_numeric_input_submit:
  sb t3, 0(t0)
get_numeric_input_pop_stack_loop:
  beq t6, zero, get_numeric_input_pop_stack_loop_done
  addi sp, sp, 4
  addi t6, t6, -1
  j get_numeric_input_pop_stack_loop
get_numeric_input_pop_stack_loop_done:
  j ecall_handled
get_numeric_input_end:

  # numeric print
  # TODO: finish
  li t1, 1
  bne t1, a7, numeric_print_end
  li t0, 0x10000
  li t2, 45
  bge a0, zero, numeric_print_neg_end
  sb t2, 0(t0)
  sub a0, zero, a0
numeric_print_neg_end:
  
numeric_print_end:

ecall_handled:
  

  # increment PC
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0

  lw s0, 28(sp)
  lw t6, 24(sp)
  lw t5, 20(sp)
  lw t4, 16(sp)
  lw t3, 12(sp)
  lw t2, 8(sp)
  lw t1, 4(sp)
  lw t0, 0(sp)
  addi sp, sp, 32

  csrrw sp, mscratch, sp

  mret

other_trap_logic:
  # Wasn't an ecall... just hang here I guess.
  j other_trap_logic
  
hang:
  j hang

# =========================================================
# DEBUG ROM (Park Loop) - Sits exactly at 0x190
# =========================================================
.section .debug_rom, "ax", @progbits
.global debug_entry

debug_entry:
  # The CPU jumps here when DM asserts haltreq.
  
park_loop:
  # 1. The CPU spins here infinitely while halted.
  j park_loop

.global debug_resume
debug_resume:
  # 2. When GDB sends a resume command, the DM hardware forces
  #    the CPU's PC to this specific instruction.
  dret
