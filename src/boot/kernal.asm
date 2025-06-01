
IndReg		= $0001
SaveAdrLow	= $0093
TapeBufPtrSeg	= $00A5
rs232BufPtrSeg	= $00A8
PgmKeyBuf	= $00C0

SysMemBot	     = $0352
SysMemTop	     = $0355
UsrMemBot	     = $0358
UsrMemTop	     = $035B
TapeVec		     = $036A
wstvec           = $03F8
WstFlag		     = $03FA

jmp_scrinit			= $E004
jmp_funkey			= $E022
do_ioinit			= $F9FB
do_memtop			= $FB78
do_restor			= $FBA2
do_tape				= $FE5D

CHKIN = $ffc6
CHKOUT = $ffc9
BSOUT = $ffd2
GETIN = $ffe4
