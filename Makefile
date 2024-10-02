
ROM = bin/emulate.bin bin/emulate.prg
STUB = bin/stub.bin bin/stub.prg
SD = bin/sd.bin bin/sd.prg
SRC_MAIN = src/main.asm src/defs.asm src/trace.asm src/emul.asm
SRC_CBM = src/cbm2/screen.asm src/cbm2/irq.asm src/cbm2/kbd.asm src/cbm2/serial.asm src/cbm2/stub.asm
SRC_EMUL = src/emul/scc.asm src/emul/cio.asm src/emul/cio2.asm src/emul/disk.asm src/emul/irq.asm
SRC_SD = src/sd/init.asm src/sd/access.asm src/sd/fat32.asm
SRC = $(SRC_MAIN) $(SRC_CBM) $(SRC_EMUL) $(SRC_SD)

all: $(ROM) $(STUB) $(SD)
disk: bin/disk.d80

bin/emulate.bin: $(SRC)
	ca65 src/main.asm
	ld65 src/main.o -C src/main.cfg -o bin/emulate.bin
	rm src/main.o

bin/emulate.prg: $(SRC)
	ca65 src/main.asm -DPRG -DDEBUG_
	ld65 src/main.o -C src/main.cfg -o bin/emulate.prg
	rm src/main.o

bin/stub.bin: src/tools/stub.asm
	ca65 src/tools/stub.asm
	ld65 src/tools/stub.o -C src/main.cfg -o bin/stub.bin
	rm src/tools/stub.o

bin/stub.prg: src/tools/stub.asm
	ca65 src/tools/stub.asm -DPRG -DDEBUG
	ld65 src/tools/stub.o -C src/main.cfg -o bin/stub.prg
	rm src/tools/stub.o

bin/sd.bin: src/tools/sd.asm $(SRC_SD) src/sd/defs.asm
	ca65 src/tools/sd.asm
	ld65 src/tools/sd.o -C src/main.cfg -o bin/sd.bin
	rm src/tools/sd.o

bin/sd.prg: src/tools/sd.asm $(SRC_SD) src/sd/defs.asm
	ca65 src/tools/sd.asm -DPRG -DDEBUG
	ld65 src/tools/sd.o -C src/main.cfg -o bin/sd.prg
	rm src/tools/sd.o

bin/disk.d80: bin/emulate.prg bin/stub.prg
	tools/c1541.exe -format Z8000,00 d80 bin/disk.d80 -attach bin/disk.d80 -write bin/run.prg run -write bin/stub.prg stub -write bin/emulate.prg emulate

upload: bin/emulate.prg
	tools/cbmlink -c serial com1 -b 1 -lo,3 bin/emulate.prg

upload_stub: bin/stub.prg
	tools/cbmlink -c serial com1 -b 15 -lo,1020 bin/stub.prg

upload_sd: bin/sd.prg
	tools/cbmlink -c serial com1 -b 15 -lo,16384 bin/sd.prg
