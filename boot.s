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
  addi sp, sp, -80
  sw ra, 0(sp)
  sw a1, 4(sp)
  sw t0, 8(sp)
  sw t1, 12(sp)
  sw t2, 16(sp)
  sw t3, 20(sp)
  sw t4, 24(sp)
  sw t5, 28(sp)
  sw t6, 32(sp)
  sw s0, 36(sp)
  sw s1, 40(sp)
  sw s2, 44(sp)
  sw s3, 48(sp)
  sw s4, 52(sp)
  sw s5, 56(sp)
  sw s6, 60(sp)
  sw s7, 64(sp)
  sw s8, 68(sp)
  sw s9, 72(sp)
  
  # Check mcause to see why we're here.
  csrr s0, mcause
  li s1, 11
  bne s0, s1, other_trap_logic

  # Do whatever we wanna do
  # (Check against a7 and do stuff accordingly.)

  # print char
  bne s1, a7, print_char_end # (s1 is still 11)
  li s0, 0x10000
  sb a0, 0(s0)
  j ecall_handled
print_char_end:

  # print string
  li s1, 4
  bne s1, a7, print_string_end
  mv s1, a0
  li s0, 0x10000
print_string_loop:
  lbu s2, 0(s1)
  beq s2, zero, ecall_handled
  sb s2, 0(s0)
  addi s1, s1, 1
  j print_string_loop
print_string_end:

  # program exit
  li s1, 10
  bne s1, a7, program_exit_end
  addi sp, sp, 80
  csrrw sp, mscratch, sp
  la s0, main
  csrw mepc, s0
  mret

program_exit_end:

  # get numeric input
  # TODO: negatives
  li s1, 5
  bne s1, a7, get_numeric_input_end

  li s0, 0x10000
  li s2, 4
  li s3, 10
  li a0, 0
  li s6, 0
  li s7, 8

get_numeric_input_loop:
  lbu s1, 0(s0)
  beq s1, s2, get_numeric_input_loop
  
  beq s1, s3, get_numeric_input_submit
  beq s1, s7, get_numeric_input_backspace
  sb s1, 0(s0)
  addi s6, s6, 1
  j get_numeric_input_backspace_done
get_numeric_input_backspace:
  beq s6, zero, get_numeric_input_loop
  sb s1, 0(s0)
  addi s6, s6, -1
  lw a0, 0(sp)
  addi sp, sp, 4
  j get_numeric_input_loop
get_numeric_input_backspace_done:

  addi sp, sp, -4
  sw a0, 0(sp)

  addi s1, s1, -48
  slli s4, a0, 3
  slli s5, a0, 1
  add a0, s4, s5
  
  add a0, a0, s1

  j get_numeric_input_loop

get_numeric_input_submit:
  sb s3, 0(s0)
  slli s6, s6, 2
  add sp, sp, s6
get_numeric_input_pop_stack_loop_done:
  j ecall_handled
get_numeric_input_end:
  # numeric print
    li s1, 1
    bne s1, a7, numeric_print_end
    addi sp, sp, -16
    li s0, 0x10000
    li s2, 45
    bge a0, zero, numeric_print_neg_end
    sb s2, 0(s0)
    sub a0, zero, a0
numeric_print_neg_end:
    li s8, 0
    addi s9, sp, 16
numeric_print_calc_loop:
    li a1, 10
    call udiv_umod
    addi s9, s9, -1
    sb a1, 0(s9)
    addi s8, s8, 1
    bnez a0, numeric_print_calc_loop
numeric_print_output_loop:
    beqz s8, numeric_print_output_loop_end
    lbu s2, 0(s9)
    addi s9, s9, 1
    addi s8, s8, -1
    addi s2, s2, 48
    sb s2, 0(s0)
    
    j numeric_print_output_loop
numeric_print_output_loop_end:
    addi sp, sp, 16
numeric_print_end:

ecall_handled:
  

  # increment PC
  csrr s0, mepc
  addi s0, s0, 4
  csrw mepc, s0

  lw ra, 0(sp)
  lw a1, 4(sp)
  lw t0, 8(sp)
  lw t1, 12(sp)
  lw t2, 16(sp)
  lw t3, 20(sp)
  lw t4, 24(sp)
  lw t5, 28(sp)
  lw t6, 32(sp)
  lw s0, 36(sp)
  lw s1, 40(sp)
  lw s2, 44(sp)
  lw s3, 48(sp)
  lw s4, 52(sp)
  lw s5, 56(sp)
  lw s6, 60(sp)
  lw s7, 64(sp)
  lw s8, 68(sp)
  lw s9, 72(sp)
  addi sp, sp, 80
  csrrw sp, mscratch, sp

  mret

other_trap_logic:
  # Wasn't an ecall... just hang here I guess.
  j other_trap_logic
  
hang:
  j hang

udiv_umod:
    beqz a1, udiv_umod_divide_by_zero
    beqz a0, udiv_umod_return_zero

    li t4, 32
    mv t2, a0

    # We check chunks of bits. If a chunk is entirely zeros, we 
    # subtract that amount from our loop counter and shift the 
    # dividend left to skip them.

    # Check top 16 bits
    srli t5, t2, 16
    bnez t5, udiv_umod_skip16
    addi t4, t4, -16 # we found 16 zeros, reduce loop count by 16
    slli t2, t2, 16  # shift dividend left to consume the zeros
udiv_umod_skip16:

    # Check top 8 bits (of the remaining active bits)
    srli t5, t2, 24
    bnez t5, udiv_umod_skip8
    addi t4, t4, -8
    slli t2, t2, 8
udiv_umod_skip8:

    # Check top 4 bits
    srli t5, t2, 28
    bnez t5, udiv_umod_skip4
    addi t4, t4, -4
    slli t2, t2, 4
udiv_umod_skip4:

    # Check top 2 bits
    srli t5, t2, 30
    bnez t5, udiv_umod_skip2
    addi t4, t4, -2
    slli t2, t2, 2
udiv_umod_skip2:

    # Check top 1 bit
    srli t5, t2, 31
    bnez t5, udiv_umod_skip1
    addi t4, t4, -1
    slli t2, t2, 1
udiv_umod_skip1:

    # At this point:
    # t2 is perfectly aligned (its most significant bit is now exactly at bit 31)
    # t4 contains the exact number of loop iterations needed (32 - leading zeros)
    
    li t1, 0            # t1 = remainder accumulator

udiv_umod_loop:
    slli t1, t1, 1 # shift remainder accumulator left by 1
    srli t3, t2, 31 # extract the MSB of the dividend
    or t1, t1, t3 # insert the MSB into the LSB of the remainder
    slli t2, t2, 1 # shift dividend left by 1

    bltu t1, a1, udiv_umod_skip_sub # If remainder < divisor, skip subtraction

    sub t1, t1, a1 # subtract divisor from remainder
    ori t2, t2, 1 # set the LSB of t2 (Quotient bit = 1)

udiv_umod_skip_sub:
    addi t4, t4, -1 # decrement our dynamically calculated loop counter
    bnez t4, udiv_umod_loop # loop if not zero

    # 4. Move results to standard return registers
    mv a0, t2 # quotient
    mv a1, t1 # remainder
    ret

udiv_umod_return_zero:
    li a0, 0 # quotient = 0
    li a1, 0 # remainder = 0
    ret

udiv_umod_divide_by_zero:
    mv t0, a0 # save dividend
    li a0, -1 # quotient = -1 (0xFFFFFFFF)
    mv a1, t0 # remainder = Dividend
    ret

# Debug ROM - where the CPU waits for debug signals
.section .debug_rom, "ax", @progbits
.global debug_entry

debug_entry:
  # The CPU jumps here when DM asserts haltreq.
  
park_loop:
  # The CPU spins here infinitely while halted.
  j park_loop

.global debug_resume
debug_resume:
  # When GDB sends a resume command, the DM hardware forces the CPU's PC to this specific instruction.
  dret
