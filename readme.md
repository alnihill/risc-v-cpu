# Prereqs
1. Maven (for building the Digital fork)
2. My [digital fork](https://github.com/alnihill/Digital)
  > Clone the repo, then run ``mvn install -DskipTests`` (~~The tests pass, they just take a while.. so I skip them.~~ The tests *do not* currently pass because I don't feel like updating the translation files until I'm done with what I'm working on.) 
  > The final output will be ``./target/Digital.jar``. 
3. A version of ``gdb`` with riscv support 
  > On homebrew there's a ``riscv64-elf-gdb`` package. This is what I use on MacOS. I know that you can install ``gdb-multiarch`` on Debian & Ubuntu. Not sure about the process on Windows. 
4. OpenOCD
  > Currently the Digital fork expects OpenOCD to be in the path, since I haven't yet added a spot in settings where you specify where it is. 

... and let's hope I didn't forget anything!

# How to compile & run code (for now)
1. Run ``build-firmware.sh``. This only needs to be done once unless you pull new changes to the firmware.
2. Edit ``main.asm``. Then run ``build.sh``. This will create (among other things) a ``main.bin`` in the working directory.
3. Run the simulation. If nothing happens, make sure the clock is configured to run automatically (right click > start real time clock). Also make sure it is running at a high speed. (Right now "unlimited" is best for comfortable debugging, although I'm hoping the TAP changes will reduce that requirement.)
5. Run ``gdb-multiarch``/``riscv64-elf-gdb``/whatever you have. Then run ``set remotetimeout unlimited``. Then run ``target remote localhost:3333``.
6. Set whatever breakpoints you want. Then resume the process with ``continue``.
7. In the terminal that appeared within digital, enter the command ``test``. Later it will be ``load main.bin``, but right now it is ``test``.

# Todo: 
## Circuit Form
RV5-PC-SELECT: Needs to transition to be RV5-PCU  
RV5-CONTROL: Needs documentation  
RV5-CSR: Needs documentation and logic simplification  
RV5-IMM-GEN: **Done**  
RV5-ALU: Needs documentation and to transition to new output format  
RV5-MEMORY: Needs logic simplification  
RV5-MEM-CONTROL: Needs documentation  
RV5-ALU-CONTROL: Needs documentation  
RV5-BRANCH-CONTROL: Needs documentation  
RV5-JUMP-CONTROL: Needs documentation  
RV5-SYSTEM-CONTROL: Needs documentation  
## Student Experience
### Most important (nobody else could do as quickly as I could)
- [ ] Implement syscalls for labs
  - Part way there! I have syscalls for printing characters, strings, and getting numeric input.
- [ ] Finish the loader program
  - Just need to make it support custom .bin paths. Pretty easy.
- [ ] Make dummy JTAG TAP for parallel writes. Potentially implement dmihardreset?
- [ ] Document setup
### Less important (easy for anyone to do) 
- [ ] Rewrite lab macro calls and pseudoinstructions to work with the GNU standard instead of RARS 
## Digital Fork
- [ ] Finalize FileMapper
