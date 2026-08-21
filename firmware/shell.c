#include "common.h"

// The file mapper supports mounting a nothing string to treat it as RAM.
static inline unsigned int map_ram() {
    *(volatile char*)(FILEMAP_PATH) = '\0'; // We want this to be ram!
    *(volatile unsigned int*)(FILEMAP_HANDLE) = -1; // use our reserved handle
    *(volatile unsigned int*)(FILEMAP_COMMAND) = 2; // Open in write mode
    return *(volatile unsigned int*)(FILEMAP_ERROR);
}

static inline unsigned int map_file(const char *path, unsigned int* size) {
    // Write our file path
    unsigned int i = 0;
    while (*path && i < 255) {
        *(volatile char*)(FILEMAP_PATH + i) = *path;
        i++;
        path++;
    }
    *(volatile char*)(FILEMAP_PATH + i) = '\0';

    // Write the file handle/slot we want
    *(volatile unsigned int*)(FILEMAP_HANDLE) = -1; // -1 is what the firmware reserves for us.

    // Tell the file mapper componenent to open the file in read mode
    *(volatile unsigned int*)(FILEMAP_COMMAND) = 1;

    *size = *(volatile unsigned int*)(FILEMAP_SIZE); // size
    return *(volatile unsigned int*)(FILEMAP_ERROR); // error
}

static inline char read_file(unsigned int address) {
    return *(volatile char*)(FILEMAP_BUFFER + address);
}

static inline void print_help() {
    print_str("Available commands: \n"
        "help: displays these commands\n"
        "about: tells you about this environment\n"
        "load [path-to-file]: loads a file into memory and then branches to it\n");
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

#define COMMAND_LEN 56

typedef void (*Entrypoint)(void);

int shell_main() {
    map_ram(); // So we can write to this location from gdb or whatever.
    print_help();

    char command[COMMAND_LEN];
    while (true) {
        print_char('$');
        print_char(' ');
        char input = '\0';
        unsigned int i = 0;
        while ((input = read_char()) != '\n') {
            if (input >= 32 && input <= 126) {
                if (i < COMMAND_LEN - 1) {
                    print_char(input);
                    command[i] = input;
                    i++;
                }
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
        else if (!strcmp(command, "load")) {
            print_str("load needs an argument!\n");
        }
        else if (!strncmp(command, "load ", strlen("load "))) {
            if (!command[5]) {
                print_str("load needs an argument!\n");
            }
            else {
                unsigned int size;
                unsigned int status = map_file(&command[5], &size);
                if (status == 2 || status == 3) {
                    print_str("Failed to map file\n");
                }
                else {
                    print_str("Branching to file..!\n");
                    Entrypoint entrypoint = (Entrypoint)(FILEMAP_BUFFER);
                    entrypoint();
                }
            }
        }
        else {
            print_str("Unrecognized command!\n");
        }
    }
    return 0;
}