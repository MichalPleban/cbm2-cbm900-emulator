
.bss

.org $00E8

sd_sector:      .res 4
sd_ptr:         .res 2
sd_loop:        .res 2
fat32_ptr_1:    .res 2
fat32_ptr_2:    .res 2
scratchpad:     .res 5
screen_ptr:     .res 2
fat32_cluster_sectors:  .res 1
fat32_fat_copies:   .res 1
fat32_sector_number:    .res 1
sd_initialized: .res 1
sd_bank:        .res 1
bank_save:      .res 1


.org $0200

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

fat32_buffer = $0400
file_mapping = $0600
