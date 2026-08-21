#include <stdint.h>
#include <stdbool.h>

#define CONSOLE_IO      ((volatile uint8_t *)0x10000u)

#define FILEMAP_BASE 0x4000000
#define FILEMAP_PATH FILEMAP_BASE
#define FILEMAP_COMMAND FILEMAP_BASE + 0x100
#define FILEMAP_ERROR FILEMAP_BASE + 0x104
#define FILEMAP_SIZE FILEMAP_BASE + 0x108
#define FILEMAP_HANDLE FILEMAP_BASE + 0x10C
#define FILEMAP_BUFFER FILEMAP_BASE + 0x1000

#define GETNUM_NO_INPUT   ((uint8_t)0)
#define GETNUM_SUBMIT     ((uint8_t)10) // \n
#define GETNUM_BACKSPACE  ((uint8_t)8)  // backspace

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

static inline void print_char(uint8_t c)
{
    *CONSOLE_IO = c;
}

static inline void print_str(const char* s) {
    while (*s) print_char((uint8_t)*s++);
}

static inline uint8_t read_char(void) {
    uint8_t c;
    do {
        c = *CONSOLE_IO;
    } while (c == GETNUM_NO_INPUT);
    return c;
}

static inline int32_t read_number(void)
{
    uint32_t undo[32];
    uint32_t depth = 0;
    uint32_t value = 0;
    bool is_negative = false;

    for (;;) {
        uint8_t byte = *CONSOLE_IO;
        if (byte == GETNUM_NO_INPUT) continue;

        if (byte == GETNUM_SUBMIT) {
            print_char(GETNUM_SUBMIT);
            break;
        }

        if (byte == GETNUM_BACKSPACE) {
            if (depth == 0) continue;
            print_char(GETNUM_BACKSPACE);
            depth--;
            if (depth == 0 && is_negative) {
                is_negative = false;
                value = 0;
            } else {
                value = undo[depth];
            }
            continue;
        }

        if (byte == '-' && depth == 0 && !is_negative) {
            print_char('-');
            is_negative = true;
            if (depth < (sizeof(undo) / sizeof(undo[0]))) {
                undo[depth++] = 0;
            }
            continue;
        }

        if (byte >= '0' && byte <= '9') {
            print_char(byte);
            if (depth < (sizeof(undo) / sizeof(undo[0]))) {
                undo[depth++] = value;
            }
            value = value * 10u + (uint32_t)(byte - '0');
        }
    }

    if (is_negative) {
        return (int32_t)(0u - value);
    }
    return (int32_t)value;
}

static inline void print_uint32(uint32_t mag)
{
    uint8_t digits[11];
    int n = 0;
    do {
        uint32_t rem;
        mag = udivmod32(mag, 10, &rem);
        digits[n++] = (uint8_t)rem;
    } while (mag != 0);

    while (n > 0) print_char((uint8_t)('0' + digits[--n]));
}

static inline void print_int32(int32_t value)
{
    if (value < 0) {
        print_char('-');
        print_uint32(0u - (uint32_t)value);
    } else {
        print_uint32((uint32_t)value);
    }
}

static inline unsigned int strlen(const char *a) {
    unsigned int res = 0;
    for (; *a; a++, res++) {}

    return res;
}

static inline int strcmp(const char *a, const char *b) {
    while (*a && (*a == *b)) {
        a++;
        b++;
    }
    return *(unsigned char*)a - *(unsigned char *)b;
}

static inline int strncmp(const char *a, const char *b, unsigned int n) {
    for (; n > 0; a++, b++, n--) {
        if (*a != *b || !*a) {
            return (unsigned char)*a - (unsigned char)*b;
        }
    }

    return 0;
}