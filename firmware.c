#include <stdint.h>

#define MCAUSE_ECALL_M   11u

#define SYS_PUTNUM        1u
#define SYS_PUTSTR        4u
#define SYS_GETNUM        5u
#define SYS_EXIT         10u
#define SYS_PUTCHAR      11u

#define CONSOLE_PORT      ((volatile uint8_t *)0x10000u)

#define GETNUM_NO_INPUT   4u
#define GETNUM_SUBMIT    10u // \n
#define GETNUM_BACKSPACE  8u // backspace

extern void main(void) __attribute__((noreturn));

static inline uint32_t csr_read_mcause(void)
{
    uint32_t v;
    __asm__ volatile("csrr %0, mcause" : "=r"(v));
    return v;
}

static inline uint32_t csr_read_mepc(void)
{
    uint32_t v;
    __asm__ volatile("csrr %0, mepc" : "=r"(v));
    return v;
}

static inline void csr_write_mepc(uint32_t v)
{
    __asm__ volatile("csrw mepc, %0" :: "r"(v));
}

static inline void put_raw(uint8_t c)
{
    *CONSOLE_PORT = c;
}

static inline void puts_raw(const char *s)
{
    while (*s) put_raw((uint8_t)*s++);
}

static inline uint32_t udivmod32(uint32_t dividend, uint32_t divisor, uint32_t *remainder_out)
{
    if (divisor == 0) {
        *remainder_out = dividend;
        return 0xFFFFFFFFu;
    }
    if (dividend == 0) {
        *remainder_out = 0;
        return 0;
    }

    uint32_t bits = 32;
    uint32_t val = dividend;
    if ((val >> 16) == 0) { bits -= 16; val <<= 16; }
    if ((val >> 24) == 0) { bits -= 8;  val <<= 8;  }
    if ((val >> 28) == 0) { bits -= 4;  val <<= 4;  }
    if ((val >> 30) == 0) { bits -= 2;  val <<= 2;  }
    if ((val >> 31) == 0) { bits -= 1;  val <<= 1;  }

    uint32_t remainder = 0;
    do {
        remainder = (remainder << 1) | (val >> 31);
        val <<= 1;
        if (remainder >= divisor) {
            remainder -= divisor;
            val |= 1;
        }
    } while (--bits);

    *remainder_out = remainder;
    return val;
}

__attribute((optimize("Os")))
static inline void print_unsigned(uint32_t mag)
{
    uint8_t digits[11];
    int n = 0;
    do {
        uint32_t rem;
        mag = udivmod32(mag, 10, &rem);
        digits[n++] = (uint8_t)rem;
    } while (mag != 0);

    while (n > 0) put_raw((uint8_t)('0' + digits[--n]));
}

static inline void print_signed(int32_t value)
{
    if (value < 0) {
        put_raw('-');
        print_unsigned(0u - (uint32_t)value);
    } else {
        print_unsigned((uint32_t)value);
    }
}

__attribute((optimize("Os")))
static inline uint32_t read_number(void)
{
    uint32_t undo[32];
    uint32_t depth = 0;
    uint32_t value = 0;

    for (;;) {
        uint8_t byte = *CONSOLE_PORT;
        if (byte == GETNUM_NO_INPUT) continue;

        if (byte == GETNUM_SUBMIT) {
            put_raw(GETNUM_SUBMIT);
            break;
        }

        if (byte == GETNUM_BACKSPACE) {
            if (depth == 0) continue;
            put_raw(GETNUM_BACKSPACE);
            value = undo[--depth];
            continue;
        }

        put_raw(byte);
        if (depth < (sizeof(undo) / sizeof(undo[0]))) {
            undo[depth++] = value;
        }
        value = value * 10u + (uint32_t)(byte - '0');
    }

    return value;
}

__attribute__((section(".text.firmware.predebug"), used))
static uint32_t trap_dispatch(uint32_t arg0, uint32_t syscall_num)
{
    if (csr_read_mcause() != MCAUSE_ECALL_M) {
        for (;;) { } // Wasn't an ecall.. I guess just hang here.
    }

    uint32_t result = arg0;

    switch (syscall_num) {
    case SYS_PUTCHAR:
        put_raw((uint8_t)arg0);
        break;

    case SYS_PUTSTR:
        puts_raw((const char *)arg0);
        break;

    case SYS_EXIT:
        csr_write_mepc((uint32_t)&main);
        return result;

    case SYS_GETNUM:
        result = read_number();
        break;

    case SYS_PUTNUM:
        print_signed((int32_t)arg0);
        break;

    default:
        break;
    }

    csr_write_mepc(csr_read_mepc() + 4);
    return result;
}

__attribute__((naked, aligned(4), section(".text.firmware.predebug"), used))
void trap_handler(void)
{
    __asm__ volatile(
        "addi sp, sp, -60\n"
        "sw   ra, 0(sp)\n"
        "sw   a1, 4(sp)\n"
        "sw   a2, 8(sp)\n"
        "sw   a3, 12(sp)\n"
        "sw   a4, 16(sp)\n"
        "sw   a5, 20(sp)\n"
        "sw   a6, 24(sp)\n"
        "sw   a7, 28(sp)\n"
        "sw   t0, 32(sp)\n"
        "sw   t1, 36(sp)\n"
        "sw   t2, 40(sp)\n"
        "sw   t3, 44(sp)\n"
        "sw   t4, 48(sp)\n"
        "sw   t5, 52(sp)\n"
        "sw   t6, 56(sp)\n"
        "mv   a1, a7\n"
        "call trap_dispatch\n"
        "lw   ra, 0(sp)\n"
        "lw   a1, 4(sp)\n"
        "lw   a2, 8(sp)\n"
        "lw   a3, 12(sp)\n"
        "lw   a4, 16(sp)\n"
        "lw   a5, 20(sp)\n"
        "lw   a6, 24(sp)\n"
        "lw   a7, 28(sp)\n"
        "lw   t0, 32(sp)\n"
        "lw   t1, 36(sp)\n"
        "lw   t2, 40(sp)\n"
        "lw   t3, 44(sp)\n"
        "lw   t4, 48(sp)\n"
        "lw   t5, 52(sp)\n"
        "lw   t6, 56(sp)\n"
        "addi sp, sp, 60\n"
        "mret\n"
    );
}

__attribute__((naked, section(".text.firmware.entry"), used))
void _start(void)
{
    __asm__ volatile(
        "la   sp, _stack_top\n"
        "la   t0, trap_handler\n"
        "csrw mtvec, t0\n"
        "tail main\n"
    );
}

__asm__(
    ".pushsection .debug_rom, \"ax\", @progbits\n"
    ".global debug_entry\n"
    "debug_entry:\n"
    "park_loop:\n"
    "    j park_loop\n"
    ".global debug_resume\n"
    "debug_resume:\n"
    "    dret\n"
    ".popsection\n"
);
