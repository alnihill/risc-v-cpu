# Installation 

## Windows
1. If you don't have Java, you can install it with ``winget install EclipseAdoptium.Temurin.21.JRE``.
2. Get a copy of my [Digital fork](https://github.com/alnihill/Digital/releases/latest).
3. Download the Windows version of the [riscv gcc xpack](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/latest). Extract it somewhere nice, then press the Windows key, search for "environment variables", select "Edit the system environment variables", click the "Environment Variables..." button, find "Path" (under system or user, your preference), click "Edit", and add the full path to the bin directory of the extracted archive. Restart any terminals you have open so that this change applies. This xpack comes with gdb, which **you will be able to call with ``riscv-none-elf-gdb``**. 
4. Get a copy of openocd with ``winget install -e --id xpack-dev-tools.openocd-xpack``.
5. If you don't have make, run: ``winget install -e --id ezwinports.make``. 
6. And of course, grab a copy of this repo! Either clone it with git or head to Code > Download ZIP.
## MacOS
In both of these cases you'll have to deal with Apple's annoying permission system. If you choose the manual route, you'll be dealing with it a *lot*. If you're unfamiliar, what happens is MacOS prompts you the first time you run unverified code with two options: don't run or move to trash. You need to go into Privacy & Security settings to then mark the file as allowed, then try running it again. Only after all of that will it give you the option to approve execution.
### Homebrew (Reccomended)
1. [Install homebrew if you don't already have it](https://brew.sh). 
2. Install java if you don't have it: ``brew install --cask temurin``.
3. You'll need my [fork of Digital](https://github.com/alnihill/Digital/releases/latest). This implements a few additional components that allow the CPU to be debugged, among other things. Click the hyperlink, download the lastest release, and extract it somewhere.
4. We need a compiler that supports risc-v. The makefile is configured to look for ``riscv64-elf-gcc``, which you can install with: ``brew install riscv64-elf-gcc``. 
5. We also need a version of ``gdb`` with riscv support. Run: ``brew install riscv64-elf-gdb``. **When you want to run it, you will call:** ``riscv64-elf-gdb`` (the executable and package share the same name!).
6. My Digital fork uses a special program called OpenOCD for facilitating debugging. Install this with ``brew install openocd``. 
7. And of course, you'll need a copy of this repo! Either ``git clone https://github.com/alnihill/risc-v-cpu.git`` or head to Code > Download ZIP in GitHub.
### Manual
1. If you don't have Java, download it [here](https://adoptium.net/temurin/releases) and install it.
2. You'll need my [fork of Digital](https://github.com/alnihill/Digital/releases/latest).
3. Download the darwin version of [the riscv gcc xpack](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/latest). If you are on Apple Silicon, this will be the one ending in ``darwin-arm64.tar.gz``. If you have an Intel CPU, this will end in ``darwin-x64.tar.gz``. Extract this somewhere nice. Edit your ~/.zshrc (or ~/.bashrc if you use bash instead of zsh) to include ``export PATH="[path to the bin directory of the extracted archive]:$PATH"``. Restart your shell and give ``riscv-none-elf-gcc`` a spin. 
4. The version of gdb you'll need is bundled with the xpack you installed for gcc. Run ``riscv-none-elf-gdb`` and sort through the security errors. **Remember this command - it is how you will run gdb!**
5. Download the correct darwin version of [the riscv openocd xpack](https://github.com/xpack-dev-tools/openocd-xpack/releases/latest). Extract it somewhere. You can add its bin directory to the path just like what you did with gcc, or you can point Digital to the openocd executable in Digital settings. Whatever you want. 
6. And of course, you'll need a copy of this repo! Either ``git clone https://github.com/alnihill/risc-v-cpu.git`` or head to Code > Download ZIP in GitHub.
## Linux
### Debian-based (Debian, Ubuntu, Linux Mint, etc.)
NOTE: Apparently, the openocd that ships on Debian-based systems does not support JTAG VPI. Supposedly the one on Linuxbrew is fine... or you can get around this issue by swapping the GdbServerVPI and RV5-TAP-VPI in the debug module out for the non-vpi variants. (If you do so, remember to configure the GdbServer component to expect riscv!)
1. If you don't have Java: ``sudo apt install default-jre``. 
2. Get a copy of my [Digital fork](https://github.com/alnihill/Digital/releases/latest).
3. Install everything else: ``sudo apt install gcc-riscv64-unknown-elf gdb-multiarch openocd``. **Your gdb command will be ``gdb-multiarch``**
4. Don't forget to download or clone this repo!
### Arch-based (Arch, Manjaro)
1. If you don't have Java: ``sudo pacman -S jdk-openjdk``.
2. Get a copy of my [Digital fork](https://github.com/alnihill/Digital/releases/latest).
3. Grab important stuff: ``sudo pacman -S riscv64-elf-gcc riscv64-elf-gdb openocd``. **Your gdb executable will be called ``riscv64-elf-gdb``**
4. Finally, download or clone this repo!

# Usage
## Running the CPU
Open a terminal and navigate to your copy of this repository. Run ``make firmware`` to build the firmware for the CPU (which you only need do once). Then, open RV5-PROCESSOR.dig in Digital and start the simulation. It should create a terminal-like window and print some text. This is the CPU in action!
## Running programs on the CPU
Of course, a CPU that does nothing is boring. Why don't you write some assembly for it? When you're done, run ``make [your .s/.asm file]``. This will produce an output called ``[your file's name].bin``. To try it out, run the simulation and enter the command: ``load [your file's name].bin``. (Ex: you write ``main.s``, you run ``make main.s``, you get ``main.bin``, you run the sim and enter ``load main.bin`` into the console).
## Debugging your program
Oh no! Your program isn't working as expected. Or maybe you just want to look around its internals at runtime. Either way, gdb has you covered.
1. Run your gdb command in a terminal somewhere and then start the sim.
2. Then, tell gdb: ``set remotetimeout unlimited`` and ``target extended-remote localhost:3333`` (the first is optional but can help with dropped connections on slow sims). This will connect your debugger and pause the CPU. 3
3. If you run ``layout asm`` you'll get to see the instruction you halted on. Right now, it will just be somewhere in the firmware. 
4. Instead of calling ``load [your file's name].bin`` inside the simulation's console, run ``load [your file's name].elf`` inside GDB. Then run ``add-symbol-file [your file's name].elf``. (Note the ".elf". Also, it is important to note that this filepath is relative to where *gdb* was started.)

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
- [x] Document setup
### Less important (easy for anyone to do) 
- [ ] Rewrite lab macro calls and pseudoinstructions to work with the GNU standard instead of RARS 
## Digital Fork
- [x] Finalize FileMapper
- [x] Make GdbServer configureable
