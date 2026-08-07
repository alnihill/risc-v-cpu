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
1. Run ``build-firmware.sh``. This only needs to be done once unless you pull new changes to the firmware.
2. Edit main.asm. Then run build.sh. This will create (among other things) a main.bin in the working directory.
3. Run the simulation. If nothing happens, make sure the clock is configured to run automatically (right click > start real time clock). Also make sure it is running at a high speed. (Right now "unlimited" is best for comfortable debugging, although I'm hoping the TAP changes will reduce that requirement.)
5. Run ``gdb-multiarch``/``riscv64-elf-gdb``/whatever you have. Then run ``set remotetimeout unlimited``. Then run ``target remote localhost:3333``.
6. Set whatever breakpoints you want. Then resume the process with ``continue``.
7. In the terminal that appeared within digital, enter the command ``test``. Later it will be ``load main.bin``, but right now it is ``test``.

# Todo
- [x] Implement GDB server.
  - [x] Finish implementing debug spec in circuit (JTAG stuff)
  - [x] Modify Digital to communicate through JTAG to CPU & host GDB server
- [x] Make ROM just an address space in memory block
- [x] Ensure JTAG TAP runs well when not on the same clock 
- [ ] Reorganize circuit to be like the one in the textbook
- [ ] Implement dmihardreset in JTAG TAP
- [ ] Make dummy JTAG TAP for parallel writes
- [ ] Implement system calls like what is available in RARS
- [ ] Write the program for the ROM for loading programs into RAM. (Maybe even verifying output?)
- [ ] Write proper setup documentation


<img width="622" height="350" alt="Screenshot 2026-08-06 at 7 41 05 PM" src="https://github.com/user-attachments/assets/34b9bcc6-c28a-46cd-abf1-58cc598b8216" />
<img width="2178" height="1460" alt="transitional" src="https://github.com/user-attachments/assets/63275d6b-d3eb-4a07-8ce5-265c2ae90745" />
