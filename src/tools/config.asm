
.ifdef CONFIG_FILE
.org $0000
.endif

_config_start:   .byt "Z8000 config v1", $0A, $0D, 26

_floppy_present: .byt $00
_hd_filename:    .byt "HDD     BIN"
_fd_filename:    .byt "DISK1   BIN"
_video_mode:     .byt $00
_reserved:       .res 16, $00
_config_end:

.ifdef CONFIG_FILE
.res ($0400-*), $00
.endif
