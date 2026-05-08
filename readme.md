# How to compile & run code (for now)
Edit main.c. Then run b.sh. 
(b.sh is our temporary build script, and it links boot.s to main.c and converts that into something Digital can read.) 
Then simulate the circuit in Digital. If nothing happens, make sure the clock is configured to run automatically (right click > start real time clock).

# Todo
- [ ] Implement GDB server.
  - [ ] Finish implementing debug spec in circuit (JTAG stuff)
  - [ ] Modify Digital to communicate through JTAG to CPU & host GDB server
- [ ] Make ROM just an address space in memory block
- [ ] Reorganize circuit to be more readable/left-to-right
- [ ] Modify Digital so that file IO can be done through memory-mapped component(s)
- [ ] Write the program for the ROM for loading programs into RAM.