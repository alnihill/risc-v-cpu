The RV5 processor firmware currently supports a core subset of system calls originally supported by MARS and RARS, matching the calling conventions and call numbers of the [RARS Environment Calls specification](https://github.com/TheThirdOne/rars/wiki/Environment-Calls).

They can be called by loading the call number into `a7`, any other arguments into `a0`-`a6`, and calling `ecall`. The following exits the program:

```assembly
li a7, 10
ecall
```

Note: all registers besides the output are guaranteed not to change.

All supported system calls are shown below.

| Name | Call Number (a7) | Description | Inputs | Outputs |
| --- | --- | --- | --- | --- |
| PrintInt | 1 | Prints an integer | a0 = integer to print | N/A |
| PrintString | 4 | Prints a null-terminated string to the console | a0 = the address of the string | N/A |
| ReadInt | 5 | Reads an int from input console | N/A | a0 = the int |
| Exit | 10 | Exits the program and returns to the shell | N/A | N/A |
| PrintChar | 11 | Prints an ascii character | a0 = character to print (only lowest byte is considered) | N/A |
| Close | 57 | Close a file | a0 = the file descriptor to close | N/A |
| Read | 63 | Read from a file descriptor into a buffer | a0 = the file descriptor<br>a1 = address of the buffer<br>a2 = maximum length to read | a0 = the length read or 0 if error |
| Write | 64 | Write to a file descriptor from a buffer | a0 = the file descriptor<br>a1 = the buffer address<br>a2 = the length to write | a0 = the number of characters written or 0 if error |
| Open | 1024 | Opens a file from a path<br>Supported flags (a1) are read-only (0), write-only (1), and write-append (9). write-only flag creates file if it does not exist. write-append will start writing at end of existing file. | a0 = Null-terminated string for the path<br>a1 = flags | a0 = the file descriptor or -1 if an error occurred |

### Using File I/O (FileMapper)

File services (`Open`, `Read`, `Write`, `Close`) interact with host files through the memory-mapped `FileMapper` component in Digital.

- **File Descriptors**: Up to 16 user file handles (`0`–`15`) can be open simultaneously. Handle `-1` is reserved for the loader.
- **Open Flags (`a1`)**:
  - `0`: Read-only
  - `1`: Write-only (creates file if it does not exist)
  - `9`: Write-append (appends to existing file)
- **Buffer Conventions**:
  - `Read` (63) copies data from the mapped file into the user memory buffer at `a1` and appends a null terminator (`\0`).
  - `Write` (64) transfers data from the user buffer at `a1` to the file and commits the write.
