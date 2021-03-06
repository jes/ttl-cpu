# SCAMP Boot Process

When the machine is reset, the program counter becomes 0. The first 256 words are ROM, and contain the bootloader.

The bootloader loads the kernel from disk, see `bootrom.s`.

The first 3 words of the disk should be:

  1. magic number (0x5343)
  2. start address
  3. length

I'm not yet sure whether I'll be forced to read from the disk bytewise. Regardless, words are to be
stored big-endian as viewed from a byte-oriented system.

So the disk will look like:

    [magic][start addr][length][kernel code][ ... gap ... ][filesystem data]

The "... gap ..." is there to allow the kernel code to be replaced with a longer one without
having to relocate the filesystem.

Once the kernel is loaded, its job is:

  1. initialise system call jump vectors or whatever
  2. initialise peripherals
  3. load init and execute it

Init's job is probably just to execute the shell, at which point the system is booted and ready
to use.

The program in `util/hex2disk` can take in a machine code program and turn it into a disk image
that will load it into address 0x100.

Example usage:

    $ asm/asm < prog.s > prog.hex
    $ util/hex2disk < prog.hex > prog.disk
    $ cd emulator/; ./scamp -i ../prog.disk
