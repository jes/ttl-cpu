SOURCES = *.sl

.PHONY: all prof test clean

all: os.disk kernel.anhex

prof: kernel.prof kernel.anhex
	../emulator/profhtml -x kernel.anhex < kernel.prof > kernel.prof.html
	xdg-open kernel.prof.html

kernel.prof: os.disk
	../emulator/scamp -i os.disk -c -p kernel.prof

os.disk: kernel.hex fs.in ../sys/*.bin motd
	../fs/mkfs < /dev/null > os.disk.tmp
	../fs/fs os.disk.tmp < fs.in
	mv os.disk.tmp os.disk

kernel.hex: head.s kernel.opt.s foot.s
	cat head.s kernel.opt.s foot.s | ../asm/asm > kernel.hex.tmp
	mv kernel.hex.tmp kernel.hex

kernel.anhex: head.s kernel.opt.s foot.s
	cat head.s kernel.opt.s foot.s | ../asm/asm -v > kernel.anhex.tmp
	mv kernel.anhex.tmp kernel.anhex

kernel.opt.s: kernel.s
	../compiler/peepopt kernel.s | ../compiler/peepopt > kernel.opt.s.tmp
	mv kernel.opt.s.tmp kernel.opt.s

kernel.s: $(SOURCES)
	../compiler/slangc kernel.sl > kernel.s.tmp
	mv kernel.s.tmp kernel.s

clean:
	rm -f os.disk kernel.prof kernel.hex kernel.anhex kernel.opt.s kernel.s *.tmp kernel.prof.html
