LIBS = lib/*.sl
BINS = cat.bin init.bin ls.bin mkdir.bin sh.bin pwd.bin echo.bin stat.bin rm.bin slangc.bin asm.bin hd.bin grep.bin more.bin wc.bin head.bin mv.bin slc.bin kilo.bin reboot.bin diskid.bin baud.bin

.PHONY: all test clean

all: $(BINS) lib.o

.PRECIOUS: %.bin
%.bin: %.hex %.anhex
	../util/hex2bin $*.hex > $*.bin.tmp
	mv $*.bin.tmp $*.bin

%.hex: lib/head.s %.opt.s lib/foot.s
	cat lib/head.s $*.opt.s lib/foot.s | ../asm/asm > $*.hex.tmp
	mv $*.hex.tmp $*.hex

.PRECIOUS: %.anhex
%.anhex: lib/head.s %.opt.s lib/foot.s
	cat lib/head.s $*.opt.s lib/foot.s | ../asm/asm -v > $*.anhex.tmp
	mv $*.anhex.tmp $*.anhex

%.opt.s: %.s
	../compiler/peepopt $*.s | ../compiler/peepopt > $*.opt.s.tmp
	mv $*.opt.s.tmp $*.opt.s

%.s: %.sl $(LIBS)
	../compiler/slangc $*.sl > $*.s.tmp
	mv $*.s.tmp $*.s

lib.o: $(LIBS)
	./make-lib

clean:
	rm -f *.bin *.hex *.anhex *.s *.tmp lib.o lib.s.build lib.h
