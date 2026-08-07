static inline char read_char() {
    volatile char *to_read = (volatile char*)0x10000;
    return *to_read;
}

static inline void print_char(char c) {
    volatile char* to_write = (volatile char*)0x10000;
    *to_write = c;
}

static inline void print_str(const char* s) {
    while (*s) print_char(*s++);
}

unsigned int div(unsigned int dividend, unsigned int divisor) {
    if (divisor == 0) return 0;
    
    unsigned int quotient = 0;
    unsigned int remainder = 0;
    
    for (int i = 31; i >= 0; i--) {
        remainder = (remainder << 1) | ((dividend >> i) & 1);
        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= (1U << i);
        }
    }
    return quotient;
}

unsigned int mod(unsigned int dividend, unsigned int divisor) {
    if (divisor == 0) return 0;
    
    unsigned int remainder = 0;
    
    for (int i = 31; i >= 0; i--) {
        remainder = (remainder << 1) | ((dividend >> i) & 1);
        if (remainder >= divisor) {
            remainder -= divisor;
        }
    }
    return remainder;
}

static inline void print_int(int n) {
    if (n < 0) {
        print_char('-');
        n = -n;
    }

    if (div(n, 10)) {
        print_int(div(n, 10));
    }

    print_char(mod(n, 10) + '0');
}

static inline unsigned int map_file(const char *path) {
    unsigned int i = 0;
    while (*path && i < 255) {
        *(volatile char*)(0x20000 + i) = *path;
        i++;
        path++;
    }
    *(volatile char*)(0x20000 + i) = '\0';

    *(volatile unsigned int*)(0x20100) = 1;

    unsigned int status = *(volatile unsigned int*)(0x20104);
    if (status == 2 || status == 3) {
        return -1;
    }

    return *(volatile unsigned int*)(0x20108);
}

static inline char read_file(unsigned int address) {
    return *(volatile char*)(0x21000 + address);
}

static inline int strcmp(const char *a, const char *b) {
    while (*a && (*a == *b)) {
        a++;
        b++;
    }
    return *(unsigned char*)a - *(unsigned char *)b;
}

static inline void print_help() {
    print_str("Available commands: \n"
        "help: displays these commands\n"
        "about: tells you about this environment\n"
        "load [path-to-file]: [UNIMPLEMENTED]\n");
    print_char('\n');
}

static inline void print_about() {
    print_str("This is a very simple ROM configured to be loaded "
        "into memory automatically by Digital when you start the simulation. "
        "It is running on the CPU schematic and interacts with special "
        "memory-mapped components that allow it to communicate with a "
        "terminal and read files. "
        "Its purpose is to be a landing place from which you can load "
        "assembly programs.\n");
    print_char('\n');
}

#define COMMAND_LEN 26

typedef void (*Entrypoint)(void);

int main() {
    print_help();

    char command[COMMAND_LEN];
    while (true) {
        print_char('$');
        print_char(' ');
        char input = '\0';
        unsigned int i = 0;
        while ((input = read_char()) != '\n' && i < COMMAND_LEN - 1) {
            if (input >= 32 && input <= 126) {
                print_char(input);
                command[i] = input;
                i++;
            }
            if (input == '\b' && i > 0) {
                print_char('\b');
                i--;
            }
        }
        command[i] = '\0';
        print_char('\n');

        if (!strcmp(command, "help")) {
            print_help();
        }
        else if (!strcmp(command, "about")) {
            print_about();
        }
        else if (!strcmp(command, "test")) {
            unsigned int size = map_file("./main.bin");
            if (size == -1) {
                print_str("Failed to map file\n");
            }
            else {
                print_str("Mapped file!\n"); 
                print_int(*(unsigned char*)(0x21000));
                print_char('\n');
                print_int(*(unsigned char*)(0x21001));
                print_char('\n');
                print_int(*(unsigned char*)(0x21002));
                print_char('\n');
                print_int(*(unsigned char*)(0x21003));
                print_char('\n');

                Entrypoint entrypoint = (Entrypoint)(0x21000);
                entrypoint();

                /*
                print_str("Here is its contents:\n");
                print_char('\n');

                for (unsigned int j = 0; j < size; j++) {
                    print_char(read_file(j));
                }
                print_char('\n');
                */
            }
        }
        else {
            print_str("Unrecognized command!\n");
        }
    }
    return 0;
}