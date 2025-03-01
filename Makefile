
ROM = bin/emulate.bin bin/emulate.prg bin/boot.bin
STUB = bin/stub.bin bin/stub.prg
SD = bin/sd.bin bin/sd.prg
BOOT = bin/boot.bin bin/boot.prg
SRC_MAIN = src/main.asm src/defs.asm src/trace.asm src/emul.asm src/menu/menu.asm src/menu/config.asm src/tools/config.asm
SRC_CBM = src/cbm2.asm src/cbm2/init.asm src/cbm2/screen.asm src/cbm2/irq.asm src/cbm2/kbd.asm src/cbm2/serial.asm src/cbm2/stub.asm
SRC_EMUL = src/emul/scc.asm src/emul/cio.asm src/emul/cio2.asm src/emul/disk.asm src/emul/irq.asm
SRC_SD = src/sd/init.asm src/sd/access.asm src/sd/fat32.asm
SRC = $(SRC_MAIN) $(SRC_CBM) $(SRC_EMUL) $(SRC_SD)
SRC_BOOT = src/boot/init.asm src/boot/boot.asm src/boot/defs.asm $(SRC_SD)

all: $(ROM) $(STUB) $(SD) $(BOOT)
disk: bin/disk.d80

bin/emulate.bin: $(SRC)
	ca65 src/main.asm
	ld65 src/main.o -C src/main.cfg -o bin/emulate.bin
	rm src/main.o

bin/emulate.prg: $(SRC)
	ca65 src/main.asm -DPRG -DDEBUG
	ld65 src/main.o -C src/main.cfg -o bin/emulate.prg
	rm src/main.o

bin/boot.bin: $(SRC_BOOT)
	ca65 -t c64 src/boot/init.asm
	ld65 src/boot/init.o -C src/boot/boot.cfg -o bin/boot.bin
	rm src/boot/init.o

bin/boot.prg: $(SRC_BOOT)
	ca65 -t c64 src/boot/init.asm -DPRG
	ld65 src/boot/init.o -C src/boot/boot.cfg -o bin/boot.prg
	rm src/boot/init.o

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

upload_boot: bin/boot.prg
	tools/cbmlink -c serial com1 -b 15 -lr,4096 bin/boot.prg

bin/config.cfg: src/tools/config.asm
	ca65 src/tools/config.asm -DCONFIG_FILE
	ld65 src/tools/config.o -C src/main.cfg -o bin/config.cfg
	rm src/tools/config.o

config:	bin/config.cfg

