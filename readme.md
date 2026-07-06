# Prereqs
1. Maven (for building the Digital fork)
2. My [digital fork](https://github.com/alnihill/Digital)
  > Clone the repo, then run ``mvn install -DskipTests`` (The tests should pass, they just take a while..) 
  > The final output will be ``./target/Digital.jar``. 
3. A version of ``gdb`` with riscv support 
  > On homebrew there's a ``riscv64-elf-gdb`` package. This is what I use on MacOS. I know that you can install ``gdb-multiarch`` on Debian & Ubuntu. Not sure about the process on Windows. 
4. OpenOCD
  > Currently the Digital fork expects OpenOCD to be in the path, since I haven't yet added a spot in settings where you specify where it is. 

... and let's hope I didn't forget anything!

# How to compile & run code (for now)
1. Edit main.c. Then run b.sh. This will create (among other things) a main.bin in the working directory.
2. Open the main CPU circuit, navigate to Edit > Circuit specific settings > Advanced, and ensure that "Program file" points to the ouptted main.bin.
3. Run the simulation
4. Run ``gdb-multiarch``/``riscv64-elf-gdb``/whatever you have. Then run ``set remotetimeout unlimited``. Then run ``target remote localhost:3333``.
Then simulate the circuit in Digital. If nothing happens, make sure the clock is configured to run automatically (right click > start real time clock).

# Todo
- [x] Implement GDB server.
  - [x] Finish implementing debug spec in circuit (JTAG stuff)
  - [x] Modify Digital to communicate through JTAG to CPU & host GDB server
- [x] Make ROM just an address space in memory block
- [ ] Reorganize circuit to be like the one in the textbook 
- [ ] Implement system calls like what is available in RARS
- [ ] Write the program for the ROM for loading programs into RAM. (Maybe even verifying output?)
