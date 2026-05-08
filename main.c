void print_char(char c) {
    char* to_write = (char*)0x1000;
    *to_write = c;
}

void print_str(const char* s) {
    while (*s) print_char(*s++);
}

int main() {
    print_str("Hello world!");
    return 0;
}