#include "common.h"

#define MCAUSE_ECALL_M   11u

#define SYS_PUTNUM        1u
#define SYS_PUTSTR        4u
#define SYS_GETNUM        5u
#define SYS_EXIT         10u
#define SYS_PUTCHAR      11u
#define SYS_CLOSEFILE    57u
#define SYS_READFILE     63u
#define SYS_WRITEFILE    64u
#define SYS_OPENFILE   1024u

extern void shell_main(void) __attribute__((noreturn));

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

static uint32_t highest_handle = -1; // We reserve file handle -1 for the loader.
static uint32_t handle_sizes[16];
static uint32_t handle_modes[16];

__attribute__((noinline, section(".text")))
static uint32_t open_file(const char *path, uint32_t mode)
{
    if (highest_handle >= 15 && highest_handle != (uint32_t)-1) {
        return (uint32_t)-1;
    }

    uint32_t handle = ++highest_handle;
    if (handle >= 16) {
        return (uint32_t)-1;
    }

    unsigned int i = 0;
    while (*path && i < 255) {
        *(volatile char*)(FILEMAP_PATH + i) = *path;
        i++;
        path++;
    }
    *(volatile char*)(FILEMAP_PATH + i) = '\0';

    // Write the file handle/slot we want
    *(volatile unsigned int*)(FILEMAP_HANDLE) = handle;
    
    // Remember our open mode
    handle_modes[handle] = mode;

    // Tell the file mapper componenent to do its job
    switch (mode) {
        case 0: // read-only
            *(volatile unsigned int*)(FILEMAP_COMMAND) = 1;
            break;
        case 1: // write-only
            *(volatile unsigned int*)(FILEMAP_COMMAND) = 2;
            break;
    }    

    // We get our size:
    handle_sizes[handle] = *(volatile unsigned int*)(FILEMAP_SIZE);

    // Now go back to the loader's handle so that loaded programs can properly run
    *(volatile unsigned int*)(FILEMAP_HANDLE) = -1;

    if (*(volatile unsigned int*)(FILEMAP_ERROR) == 1)
        return handle;
    else
        return (uint32_t)-1;
}

__attribute__((noinline, section(".text")))
static uint32_t read_file(uint32_t handle, uint8_t *buffer, uint32_t len)
{
    if (handle >= 16) {
        return 0;
    }

    if (handle_modes[handle] != 0) {
        return 0;
    }

    uint32_t to_read = len;
    if (to_read > handle_sizes[handle]) {
        to_read = handle_sizes[handle];
    }

    *(volatile unsigned int*)(FILEMAP_HANDLE) = handle;

    for (uint32_t i = 0; i < to_read; i++) {
        buffer[i] = ((volatile uint8_t*)FILEMAP_BUFFER)[i];
    }
    buffer[to_read] = '\0';

    *(volatile unsigned int*)(FILEMAP_HANDLE) = -1;

    return to_read;
}

__attribute__((noinline, section(".text")))
static uint32_t write_file(uint32_t handle, const uint8_t *buffer, uint32_t len)
{
    if (handle >= 16) {
        return 0;
    }

    switch (handle_modes[handle]) {
        case 1: { // write-only
            *(volatile unsigned int*)(FILEMAP_HANDLE) = handle;

            // Change the len!
            handle_sizes[handle] = len;
            *(volatile unsigned int*)(FILEMAP_SIZE) = len;

            // Now that we have our space set aside, write to it!
            for (uint32_t i = 0; i < len; i++) {
                ((uint8_t*)FILEMAP_BUFFER)[i] = buffer[i];
            }

            // Do our write!
            *(volatile unsigned int*)(FILEMAP_COMMAND) = 4;

            // Reset our handle to the loader reserved one:
            *(volatile unsigned int*)(FILEMAP_HANDLE) = -1;
            
            if (*(volatile unsigned int*)(FILEMAP_ERROR) == 1)
                return len;
            else
                return 0;
        }
        case 9: { // append
            *(volatile unsigned int*)(FILEMAP_HANDLE) = handle;
            uint8_t *end = (uint8_t*)FILEMAP_BUFFER + handle_sizes[handle];

            // Change the len
            handle_sizes[handle] += len;
            *(volatile unsigned int*)(FILEMAP_SIZE) = handle_sizes[handle];

            // Now that we have our space allocated, write to it.
            for (uint32_t i = 0; i < len; i++, end++) {
                *end = buffer[i];
            }

            // Do our write!
            *(volatile unsigned int*)(FILEMAP_COMMAND) = 4;

            // Reset our handle to the loader reserved one:
            *(volatile unsigned int*)(FILEMAP_HANDLE) = -1;

            if (*(volatile unsigned int*)(FILEMAP_ERROR) == 1)
                return len;
            else
                return 0;
        }
        default:
            return 0;
    }
}

__attribute__((section(".text.firmware.predebug"), used))
static uint32_t trap_dispatch(uint32_t arg0, uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4, uint32_t arg5, uint32_t arg6, uint32_t syscall_num)
{
    if (csr_read_mcause() != MCAUSE_ECALL_M) {
        for (;;) { } // Wasn't an ecall.. I guess just hang here.
    }

    uint32_t result = arg0;

    switch (syscall_num) {
    case SYS_PUTCHAR:
        print_char((uint8_t)arg0);
        break;
    case SYS_PUTSTR:
        print_str((const char *)arg0);
        break;
    case SYS_EXIT:
        print_char('\n'); // Doesn't hurt to add a newline so programs that don't terminate with one don't punish the system.
        csr_write_mepc((uint32_t)&shell_main);
        return result;
    case SYS_GETNUM:
        result = read_number();
        break;
    case SYS_PUTNUM:
        print_int32((int32_t)arg0);
        break;
    case SYS_OPENFILE:
        result = open_file((char*)arg0, (uint32_t)arg1);
        break;
    case SYS_READFILE:
        result = read_file(arg0, (uint8_t*)arg1, arg2);
        break;
    case SYS_WRITEFILE:
        result = write_file(arg0, (uint8_t*)arg1, arg2);
        break;
    case SYS_CLOSEFILE:
        break; // Currently nothing to do
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
        "tail shell_main\n"
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
