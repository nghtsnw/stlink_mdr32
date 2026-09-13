    .syntax unified
    .text
    .thumb
    .cpu cortex-m3

    /*
     * Milandr 1986VE9x (MDR32) flash loader.
     *
     * The MDR32 programs its flash through a dedicated EEPROM/flash memory
     * controller at 0x40018000 (registers CMD/ADR/DI/DO/KEY). Unlike the
     * STM32 flash interface it has no BUSY/status bit: every program pulse is
     * driven by writing the CMD bits (XE/PROG/NVSTR/YE) and waiting a fixed
     * software delay.
     *
     * Arguments (stlink convention):
     *   r0 - source memory ptr (SRAM)
     *   r1 - target memory ptr (flash)
     *   r2 - count of bytes (multiple of 4)
     *
     * The controller is unlocked (KEY = 0x8AAA5551), CON is set, one 32-bit
     * word is programmed per loop iteration, and the controller is relocked
     * (KEY = 0) before the final breakpoint. Clobbers r3-r7.
     */

    .global copy
    .thumb_func
copy:
    ldr   r3, flash_base          @ EEPROM/flash controller base
    ldr   r4, key_value           @ unlock key
    str   r4, [r3, #0x10]         @ KEY = unlock
    ldr   r4, [r3, #0x00]         @ r4 = CMD
    movs  r5, #0x38               @ DELAY field mask (bits 5:3)
    ands  r4, r4, r5              @ keep delay, drop everything else
    movs  r5, #1                  @ CON
    orrs  r4, r4, r5              @ enable controller access
    str   r4, [r3, #0x00]         @ CMD = (delay) | CON

loop:
    str   r1, [r3, #0x04]         @ ADR = target address
    ldr   r5, [r0, #0x00]         @ r5 = *source
    str   r5, [r3, #0x08]         @ DI = word to program

    ldr   r5, xe_prog             @ XE | PROG
    orrs  r4, r4, r5
    str   r4, [r3, #0x00]         @ CMD |= XE | PROG
    movs  r5, #14                 @ ~5 us
1:  subs  r5, r5, #1
    bne   1b

    ldr   r5, nvstr               @ NVSTR
    orrs  r4, r4, r5
    str   r4, [r3, #0x00]         @ CMD |= NVSTR
    movs  r5, #27                 @ ~10 us
2:  subs  r5, r5, #1
    bne   2b

    movs  r5, #0x80               @ YE
    orrs  r4, r4, r5
    str   r4, [r3, #0x00]         @ CMD |= YE
    movs  r5, #107                @ ~40 us program pulse
3:  subs  r5, r5, #1
    bne   3b

    movs  r5, #0x80               @ YE
    bics  r4, r4, r5
    str   r4, [r3, #0x00]         @ CMD &= ~YE

    ldr   r5, prog                @ PROG
    bics  r4, r4, r5
    str   r4, [r3, #0x00]         @ CMD &= ~PROG
    movs  r5, #14                 @ ~5 us
4:  subs  r5, r5, #1
    bne   4b

    ldr   r5, xe_nvstr            @ XE | NVSTR
    bics  r4, r4, r5
    str   r4, [r3, #0x00]         @ CMD &= ~(XE | NVSTR)

    adds  r0, r0, #4              @ source += 4
    adds  r1, r1, #4              @ target += 4
    subs  r2, r2, #4              @ count -= 4
    bgt   loop

    movs  r5, #0x38               @ DELAY field mask
    ands  r4, r4, r5              @ clear CON and operation bits
    str   r4, [r3, #0x00]         @ CMD = delay
    movs  r5, #0
    str   r5, [r3, #0x10]         @ KEY = lock
    bkpt  #0

    .align 2
flash_base:
    .word 0x40018000
key_value:
    .word 0x8AAA5551
xe_prog:
    .word 0x00001040
nvstr:
    .word 0x00002000
prog:
    .word 0x00001000
xe_nvstr:
    .word 0x00002040
