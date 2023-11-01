
ROM = bin/emulate.bin bin/emulate.prg
STUB = bin/stub.bin bin/stub.prg
SRC = src/main.asm src/defs.asm src/cbm/screen.asm src/cbm/irq.asm src/cbm/kbd.asm src/cbm/serial.asm src/emul.asm src/emul/scc.asm src/emul/cio.asm

all: $(ROM) $(STUB)
disk: bin/disk.d80

bin/emulate.bin: $(SRC)
	ca65 src/main.asm
	ld65 src/main.o -C src/main.cfg -o bin/emulate.bin
	rm src/main.o

bin/emulate.prg: $(SRC)
	ca65 src/main.asm -DPRG -DDEBUG
	ld65 src/main.o -C src/main.cfg -o bin/emulate.prg
	rm src/main.o

bin/stub.bin: src/stub.asm
	ca65 src/stub.asm
	ld65 src/stub.o -C src/main.cfg -o bin/stub.bin
	rm src/stub.o

bin/stub.prg: src/stub.asm
	ca65 src/stub.asm -DPRG -DDEBUG
	ld65 src/stub.o -C src/main.cfg -o bin/stub.prg
	rm src/stub.o

bin/disk.d80: bin/emulate.prg bin/stub.prg
	tools/c1541.exe -format Z8000,00 d80 bin/disk.d80 -attach bin/disk.d80 -write bin/run.prg run -write bin/stub.prg stub -write bin/emulate.prg emulate

upload: bin/emulate.prg
	tools/cbmlink -c serial com1 -b 1 -lo,1024 bin/emulate.prg

upload_stub: bin/stub.prg
	tools/cbmlink -c serial com1 -b 15 -lo,1020 bin/stub.prg
