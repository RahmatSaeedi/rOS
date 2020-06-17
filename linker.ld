ENTRY(main)
OUTPUT_FORMAT(binary)

MEMORY
{
    IVT (wx) : ORIGIN = 0, LENGTH = 1024
    BDA (wx) : ORIGIN = 0x400, LENGTH = 256
    LOWER_MEMORY (wx) : ORIGIN = 0x500, LENGTH = 0x7700
    BOOT_SECTOR (rwx) : ORIGIN = 0x7C00, LENGTH = 1024
    HIGHER_MEMORY (wx) : ORIGIN = 0x8000, LENGTH = 0x78000
    KERNEL (wx) : ORIGIN = 0x00100000, LENGTH = 1M
}

SECTIONS {
    
    
    ._BOOT_SECTOR : 
    {
        bootloader.o(.text)
    } > BOOT_SECTOR AT> BOOT_SECTOR



    /DISCARD/ :
    {
        *(.fini_array*)
        *(.comment)
    }
}
