# System calls reference

System calls are made by pushing arguments onto the stack, in the order specified
in the reference, and calling the function pointed to at the system call address.

Example:

    # putchar(1, 'A')
    .def sys_putchar 0xfefc
    push 1
    push 65
    call (sys_putchar)

Note that stack contents will be in TPA, so system calls that overwrite the TPA
probably need to copy the arguments first.

System calls must act like normal SLANG functions: `r255` (`sp`) must consume the passed
arguments. `r254` must be left alone. Other pseudoregs can be trashed at will.

## System calls

### 0xfeff: exit(rc)

    Return: n/a
    Implemented: no
    Errors: n/a

Exit the current process and return `rc` to the parent.

### 0xfefe: exec([cmd, args])

    Return: -ERR on error
    Implemented: no
    Errors: NOTFOUND

Replace the current process with a new one.

`cmd` should be a fully-qualified path. `args` should be terminated with a 0.

### 0xfefd: system(TOP, [cmd, args])

    Return: rc of child process, or -ERR on error
    Implemented: no
    Errors: NOTFOUND

Suspend the current process, start a child. When the child calls `exit(rc)`, resume the
current process and return `rc`.

`cmd` should be a fully-qualified path. `args` should be terminated with a 0.

### 0xfefc: putchar(fd, ch)

    Return: 0, or -ERR on error
    Implemented: no
    Errors: BADFD, NOWRITE

Write a single character to the given file descriptor.

### 0xfefb: write(fd, buf, sz)

    Return: 0, or -ERR on error
    Implemented: no
    Errors: BADFD, NOWRITE

Write multiple characters to the given file descriptor.

### 0xfefa: getchar(fd)

    Return: character, or -ERR on error
    Implemented: no
    Errors: BADFD, NOREAD

Read a single character from the given file descriptor.

### 0xfef9: read(fd, buf, sz)

    Return: number of characters read, or -ERR on error
    Implemented: no
    Errors: BADFD, NOREAD

Read multiple characters from the given file descriptor.

### 0xfef8: open(name, mode)

    Return: new file descriptor, or -ERR on error
    Implemented: no
    Errors: NOTFOUND, NOWRITE, NOREAD

Open the file at the given path with the given mode.

Mode flags are:

    0x01: O_READ
    0x02: O_WRITE
    0x04: O_CREAT

### 0xfef7: close(fd)

    Return: 0, or -ERR on error
    Implemented: no
    Errors: BADFD

Close the given file descriptor.

### 0xfef6: seek(fd, pos)

    Return: old position, or -ERR on error
    Implemented: no
    Errors: BADFD, NOSEEK
    TODO: how do we take >16-bit positions?

Seek to the given position on the given file descriptor.

### 0xfef5: tell(fd)

    Return: current position, or -ERR on error
    Implemented: no
    Errors: BADFD, NOSEEK
    TODO: how do we give >16-bit positions?

Return the current position on the given file descriptor.

### 0xfef4: chdir(path)

    Return: 0, or -ERR on error
    Implemented: no
    Errors: NOTFOUND, NOTDIR

Change the current working directory.

### 0xfef3: mkdir(path)

    Return: 0, or -ERR on error
    Implemented: no
    Errors: NOTFOUND, NOTDIR

Create a directory at the given path.

### 0xfef2: opendir(path)

    Return: new file descriptor, or -ERR on error
    Implemented: no
    Errors: NOTFOUND, NOTDIR

Open the directory at the given path for reading.

### 0xfef1: readdir(fd, buf, sz)

    Return: number of entries read, or -ERR on error
    Implemented: no
    Errors: BADFD

Read entries from the given directory fd into buf. Each directory entry is a nul-terminated
string containing the filename. `buf` will contain N concatenated nul-terminated strings.

To read the entire directory, call `readdir()` repeatedly until 0 directory entries are returned.

It is not sound to add or remove files to the directory while the directory is open.

### 0xfef0: stat(path, buf)

    Return: 0, or -ERR on error
    Implemented: no
    Errors: NOTFOUND

Fill in `buf` with information about the file at the given path.

Fields are:

    0: length of file in bytes
    1: file type (0 = dir, 1 = file)

### 0xfeef: unlink(path)

    Return: 0, or -ERR on error
    Implemented: no
    Errors: NOTFOUND

Remove the file at the given path.

### 0xfeee: copyfd(fd, curfd)

    Return: the old mapping of fd, or -ERR on error
    Implemented: no
    Errors: BADFD

Make `fd` go to/from the same place as `curfd`.

By convention programs should take input from fd *0*, output to fd *1*, and send error messages
to fd *2*. Fds *3..n* should be permanently mapped to serial ports, with fd *3* being the
console.

Example: To make stdin and stderr go to the console, but stdout go to a file, and then
restore it later

    var logfd = open("log", O_WRITE|O_CREAT);
    var old_stdin  = copyfd(0, 3);
    var old_stdout = copyfd(1, logfd);
    var old_stderr = copyfd(2, 3);
    # ...
    # now stdin/err are console, and stdout is the file 
    # ...
    copyfd(0, old_stdin);
    copyfd(1, old_stdout);
    copyfd(2, old_stderr);
    close(logfd);
    # now the original configuration is restored

### 0xfeed: osbase()

    Return: the first address above the TPA
    Implemented: no
    Errors: n/a

Return the first address of the OS, i.e. the lowest address that the user heap is not allowed
to grow into.

### 0xfeec: cmdargs()

    Return: pointer to argument list
    Implemented: no
    Errors: n/a

Return a pointer to the argument list, including the command name, exactly as passed to `exec()`/`system()`.

Example:

    system(["ls", "-l", "/home", 0]);

    cmdargs() returns ["ls", "-l", "/home", 0]

## Errors

Errors are generally returned from system calls as `-ERR`, with the following meanings:

### -1: EOF

Reached end-of-file.

### -2: NOTFOUND

File with given name does not exist.

### -3: NOTFILE

The given path exists but is not a file (e.g. it's a directory).

### -4: NOTDIR

The given path exists but is not a directory (e.g. it's a file).

### -5: BADFD

File descriptor not allocated.

### -6: NOWRITE

The given fd is not writable.

### -7: NOREAD

The given fd is not readable.

### -8: NOSEEK

The given fd is not seekable (e.g. it's a serial port).