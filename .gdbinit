set remotetimeout unlimited
set remote p-packet on
set remote P-packet on
mem 0 0x100000000 cache
set dcache size 512
set dcache line-size 64
set trust-readonly-sections on
set remote threads-packet off
set remote target-features-packet off

# These sort of hobble GDB's capabilities as a C debugger.. but help us with performance!
set print frame-arguments none
set print entry-values no
set backtrace limit 1
set print frame-info short-location

# Let's get our firmware elf loaded.
file firmware-out/firmware.elf
