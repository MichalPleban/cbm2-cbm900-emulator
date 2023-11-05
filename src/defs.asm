
kbd_buffer      = $F000

.data
.org $0000

EXEC_REG:       .res 1
IND_REG:        .res 1

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
screen_charset: .res 1

; Z8000 state
z8000_addr:     .res 2
z8000_data:     .res 1
z8000_status:   .res 1
z8000_code:     .res 2

; IRQ handler variables
irq_save_a:     .res 1
irq_save_x:     .res 1
irq_save_y:     .res 1
irq_save_ind:   .res 1

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

; RS-232 serial port
serial_ptr:     .res 2

; IO emulation 
io_jump:        .res 2
io_unimplemented: .res 1

scratchpad:     .res 8

.org $0200

cio_registers:  .res $40
cio2_registers: .res $40
