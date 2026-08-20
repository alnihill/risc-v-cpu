# Installation 

## MacOS
### Homebrew (Reccomended)
1. [Install homebrew if you don't already have it](https://brew.sh). 
2. You'll need my [fork of Digital](https://github.com/alnihill/Digital/releases/latest). This implements a few additional components that allow the CPU to be debugged, among other things. Click the hyperlink, download the lastest release, and extract it somewhere.
3. We need a compiler that supports risc-v. The makefile is configured to look for ``riscv64-elf-gcc``, which you can install with: ``brew install riscv64-elf-gcc``. 
4. We also need a version of ``gdb`` with riscv support. Run: ``brew install riscv64-elf-gdb``. **When you want to run it, you will call:** ``riscv64-elf-gdb`` (the executable and package share the same name!).
5. My Digital fork uses a special program called OpenOCD for facilitating debugging. Install this with ``brew install openocd``. 
6. And of course, you'll need a copy of this repo! Either ``git clone https://github.com/alnihill/risc-v-cpu.git`` or head to Code > Download ZIP in GitHub.
### Manual
1. You'll need my [fork of Digital](https://github.com/alnihill/Digital/releases/latest).
2. Download the darwin version of [the riscv gcc xpack](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/latest). If you are on Apple Silicon, this will be the one ending in ``darwin-arm64.tar.gz``. If you have an Intel CPU, this will end in ``darwin-x64.tar.gz``. Extract this somewhere nice. Edit your ~/.zshrc (or ~/.bashrc if you use bash instead of zsh) to include ``export PATH="[path to the bin directory of the extracted archive]:$PATH"``. Restart your shell and give ``riscv-none-elf-gcc`` a spin. Your system will probably complain about its signing and refuse to run it. Head to Privacy & Security in Settings to allow it. It loads some shared libraries that are also not signed, so keep running it and allowing things in Settings until it loads up cleanly. 
3. The version of gdb you'll need is bundled with the xpack you installed for gcc. Run ``riscv-none-elf-gdb`` and sort through the security errors. **Remember this command - it is how you will run gdb!**
4. Download the correct darwin version of [the riscv openocd xpack](https://github.com/xpack-dev-tools/openocd-xpack/releases/latest). Extract it somewhere. You can add its bin directory to the path just like what you did with gcc, or you can point Digital to the openocd executable in Digital settings. Whatever you want. 
5. And of course, you'll need a copy of this repo! Either ``git clone https://github.com/alnihill/risc-v-cpu.git`` or head to Code > Download ZIP in GitHub.
## Linux
### Debian-based (Debian, Ubuntu, Linux Mint, etc.)
1. Get a copy of my [Digital fork](https://github.com/alnihill/Digital/releases/latest).
2. Install everything else: ``sudo apt install gcc-riscv64-unknown-elf gdb-multiarch openocd``. **Your gdb command will be ``gdb-multiarch``**
3. Don't forget to download or clone this repo!
### Arch-based (Arch, Manjaro)
1. Get a copy of my [Digital fork](https://github.com/alnihill/Digital/releases/latest).
2. Grab important stuff: ``sudo pacman -S riscv64-elf-gcc riscv64-elf-gdb openocd``. **Your gdb executable will be called ``riscv64-elf-gdb``**
3. Finally, download or clone this repo!
### Fedora-based
1. Get a copy of my [Digital fork](https://github.com/alnihill/Digital/releases/latest).
2. Run: ``sudo dnf install gcc-riscv64-unknown-elf gdb openocd``. **Your gdb executable will simply be ``gdb``.**
3. Of course, download or clone this repo!

# Usage
## Running the CPU
Open a terminal and navigate to your copy of this repository. Run ``make firmware`` to build the firmware for the CPU (which you only need do once). Then, open RV5-PROCESSOR.dig in Digital and start the simulation. It should create a terminal-like window and print some text. This is the CPU in action!
## Running programs on the CPU
Of course, a CPU that does nothing is boring. Why don't you write some assembly for it? When you're done, run ``make [your .s/.asm file]``. This will produce an output called ``[your file's name].bin``. To try it out, run the simulation and enter the command: ``load [your file's name].bin``. (Ex: you write ``main.s``, you run ``make main.s``, you get ``main.bin``, you run the sim and enter ``load main.bin`` into the console).
## Debugging your program
Oh no! Your program isn't working as expected. Or maybe you just want to look around its internals at runtime. Either way, gdb has you covered. Run your gdb command in a terminal somewhere and then start the sim. Then, tell gdb: ``set remotetimeout unlimited`` and ``target extended-remote localhost:3333`` (the first is optional but can help with dropped connections on slow sims). This will connect your debugger and pause the CPU. If you run ``layout asm`` you'll get to see the instruction you halted on. Right now, it will just be somewhere in the firmware. Create a breakpoint at the start of  
[TODO: Finish this. Maybe need to write about symbol loading.]

# Todo: 
## Circuit Form
RV5-PCU: **Done**  
RV5-CONTROL: **Done**  
RV5-CSR: **Done**  
RV5-IMM-GEN: **Done**  
RV5-ALU: **Done**  
RV5-MEMORY: **Done**  
RV5-MEM-CONTROL: **Done**  
RV5-ALU-CONTROL: **Done**  
RV5-BRANCH-CONTROL: **Done**  
RV5-JUMP-CONTROL: **Done**  
RV5-SYSTEM-CONTROL: **Done**  
Simplify is-debug and in-progbuf logic: **Done**  
Standardize tunnel naming scheme: **Done** 
## Student Experience
### Most important (nobody else could do as quickly as I could)
- [x] Implement syscalls for labs
- [x] Finish the loader program
  - Just need to make it support custom .bin paths. Pretty easy.
- [x] Make dummy JTAG TAP for parallel writes.
- [ ] Document setup
### Less important (easy for anyone to do) 
- [ ] Rewrite lab macro calls and pseudoinstructions to work with the GNU standard instead of RARS 
## Digital Fork
- [x] Finalize FileMapper
- [x] Make GdbServer configureable
