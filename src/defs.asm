
.data
.org $0000

EXEC_REG:       .res 1
IND_REG:        .res 1

                .res 1

; Vectors to access I/O chips
SCREEN:         .res 2
CRTC:           .res 2
CHIPSET:        .res 2
SID:            .res 2
CIA:            .res 2
ACIA:           .res 2
TPI1:           .res 2
TPI2:           .res 2

; Screen variables
screen_x:       .res 1
screen_y:       .res 1
screen_ptr:     .res 2
screen_invert:  .res 1

; Z8000 state
z8000_request:  .res 1
z8000_started:  .res 1
z8000_addr:     .res 2
z8000_data:     .res 1
z8000_status:   .res 1
z8000_code:     .res 2

; IRQ handler variables
.ifdef DEBUG
irq_delay:      .res 1
.endif

; NMI handler variables
nmi_save_a:     .res 1
nmi_save_x:     .res 1
nmi_save_y:     .res 1
nmi_save_ind:   .res 1

; Keyboard handling
kbd_col:        .res 2
kbd_row:        .res 1
kbd_current:    .res 1
kbd_last:       .res 1
kbd_shift:      .res 1
kbd_repeat:     .res 1
kbd_head:       .res 1
kbd_tail:       .res 1
kbd_stop:       .res 1

; RS-232 serial port
serial_ptr:     .res 2

; IO emulation 
io_jump:        .res 2
io_unimplemented: .res 1

; Disk emulation
disk_request:   .res 1
disk_unit:      .res 1
disk_sectors:   .res 1
disk_irq:       .res 1

; SD card access
sd_initialized: .res 1
sd_sector:      .res 4
sd_bank:        .res 1
sd_ptr:         .res 2
sd_bank_flags:  .res 1
sd_loop:        .res 2

; CIO chip emulation
timer_irq_enable: .res 1
timer_irq_pending: .res 1
timer_irq_vector: .res 1

; SCC chip emulation
scc_irq_pending: .res 1
scc_irq_enable: .res 1
scc_irq_vector: .res 1

; FAT32 variables
fat32_cluster_sectors:  .res 1
fat32_fat_copies:   .res 1
fat32_sector_number:    .res 1
fat32_ptr_1:    .res 2
fat32_ptr_2:    .res 2

; Menu
can_enter_menu: .res 1
menu_visible:   .res 1
menu_ptr_save:  .res 5
menu_file_pos:  .res 1
menu_file2_pos: .res 1
menu_file_max:  .res 1
menu_file_ptr:  .res 2
menu_file2_ptr: .res 2
menu_name_pos:  .res 1

; RS-232C variables
serial_head:	.res 1
serial_tail:	.res 1

; VGA card variables
vga_x:          .res 1
vga_y:          .res 1
vga_attr:       .res 1
vga_delay:      .res 1
vga_dirty:      .res 1
vga_segment:    .res 1
vga_ptr:        .res 2
vga_buffer:     .res 2
vga_mirror_buf: .res 2

; Temporary variables
scratchpad:     .res 8

.org $0200

; I/O register copies
cio_registers:  .res $40
cio2_registers: .res $40
scc_registers:  .res $20
sasi_command:   .res $20

.org $0300

; FAT32 variables
fat32_pointers:     .res 32

PARTITION_START     = 0
RESERVED_SECTORS    = 4
FAT_SECTORS         = 8
ROOT_CLUSTER        = 16
FAT_START           = 20
DATA_START          = 24

FILE_CLUSTER        = 0
FILE_SIZE           = 4

CURRENT_SECTOR      = 8
CURRENT_CLUSTER     = 12

TEMP_CLUSTER        = 0
FILE_SECTOR         = 28
