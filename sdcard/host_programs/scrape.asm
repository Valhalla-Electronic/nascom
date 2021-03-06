;;; PolyDos utility: SCRAPE DISK
;;;
;;; Utility for use with nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Load and execute at 1000
;;; Intended to be loaded onto PolyDos floppy and executed from
;;; there. Uses PolyDos SCALs and therefore PolyDos must be
;;; booted in order to run this!
;;;
;;; Prompts for a disk in drive 0 then copies all of its sectors
;;; to an SDcard image with an auto-selected file name of the
;;; form NASxxx.BIN (where xxx is a 3 digit decimal number: 000,
;;; 001 and so on).
;;;
;;; Uses PolyDos SCALs to size drive 0 and copy all of its sectors
;;;
;;; Format is 35 track DSDD disk with 18 sectors per side, each
;;; of 256 bytes (so 35*18*2*256=322,560 bytes per disk).
;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:  EQU     $1000
BUFFER: EQU     $2000

;;; Macros for using NAS-SYS routines
SCAL:   MACRO FOO
        RST 18H
        DB FOO
        ENDM

RCAL:   MACRO FOO
        RST 10H
        DB FOO - $ - 1
        ENDM

RIN:    EQU     $8
PRS:    EQU     $28
ROUT:   EQU     $30

;;; Equates for NAS-SYS SCALs
ZMRET:  EQU     $5b
ZTBCD3: EQU     $66
ZCRLF:  EQU     $6a
ZERRM:  EQU     $6b
;;; Equates for NAS-SYS workspace
ARGN:   EQU     $0c0b
ARG1:   EQU     $0c0c
ARG2:   EQU     $0c0e
ARG3:   EQU     $0c10
ARG4:   EQU     $0c12
;;; Equates for PolyDOS SCALs
ZDSIZE: equ     $80
ZDRD:   equ     $81

        ORG     START
        jp      scrape

;;; Defines and low-level subroutines
        include "sd_sub_defs.asm"
        include "sd_sub1.asm"

hwinit: include "sd_sub2.asm"
        ret

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; more subroutines, just for these utilities.
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; open a file for READ. Fatal error on fail, return on
;;; success.
;;; filename is NASxxx.BIN where xxx comes from low
;;; 12 bits of (HL) and (HL+1) converted from bin to ASCII
;;; corrupts: HL, AF, DE
fopenr: ld      a, COPENR
        call    putcmd
        jr      fman

;;; open a file. Fatal error on fail, return on success.
;;; Carry=0 -> auto-pick filename
;;; Carry=1 -> filename is NASxxx.BIN where xxx comes from low
;;; 12 bits of (HL) and (HL+1) converted from bin to ASCII
;;; corrupts: HL, AF, DE
fopen:  push    af              ;preserve C
        ld      a, COPEN
        call    putcmd

        pop     af
        jr      nc,fauto

fman:   ld      a,'N'
        call    putval
        ld      a,'A'
        call    putval
        ld      a,'S'
        call    putval

;;; number in HL used as xxx part of file name
        ld      a,h
        and     0fh             ;ms digit
        add     30h             ;convert to ASCII
        call    putval
        ld      a,l
        rra                     ;shift nibble down
        rra
        rra
        rra
        and     0fh             ;mid digit
        add     30h             ;convert to ASCII
        call    putval
        ld      a,l
        and     0fh             ;ls digit
        add     30h             ;convert to ASCII
        call    putval

;;; extension
        ld      a,'.'
        call    putval
        ld      a,'B'
        call    putval
        ld      a,'I'
        call    putval
        ld      a,'N'
        call    putval

fauto:  xor     a
        call    putval          ;0-length/end of filename
        ;; get status, return if OK, msg/exit on error
        ld      de,eopen
        jr      t2rs2t


;;; go from tx to rx, get status then go to tx.
;;; Interpret status byte; on error, print message at (DE)
;;; then exit. On success, return.
;;; corrupts: AF
t2rs2t: call    gorx

;;; FALL-THROUGH and subroutine
;;; get status then go to tx.
;;; Interpret status byte; on error, print message at (DE)
;;; then exit. On success, return.
;;; corrupts: AF
rs2t:   call    getval          ;status
        call    gotx            ;does not affect A
        or      a               ;update flags
        jr      z,mexit
        ret

;;; Exit with message. Can be used for successful or error/fatal
;;; exit. (DE) is null-terminated string (possibly 0-length).
;;; Print string then CR then return to NAS-SYS.
;;; Come here by CALL or JP/JR -- NAS-SYS will clean up the
;;; stack if necessary.
mexit:  ld      a,(de)
        or      a
        jr      z, mex1
        rst     ROUT
        inc     de
        jr      mexit

mex1:   SCAL    ZCRLF
        SCAL    ZMRET

;;; Start address in (ARG2), end address in (ARG3). Exit with
;;; HL=start, BC=byte count.
;;; corrupts: AF
e2len:  ld      de,(ARG2)       ;start address
        ld      hl,(ARG3)       ;end address
        ;; compute end - start + 1
        or      a               ;clear carry flag
        sbc     hl,de
        inc     hl              ;byte count in hl
        ld      b,h
        ld      c,l             ;byte count in bc

        ld      hl,(ARG2)       ;start address in hl
        ret

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SCRAPE
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scrape: rst     PRS
        defm    'Insert disk then press ENTER, or SPACE to quit'
        defb    0
        rst     RIN
        cp      ' '
        jr      nz, go
        SCAL    ZMRET

go:     SCAL    ZCRLF
        call    hwinit

        or      a               ;C=0
        call    fopen           ;open new file, auto-pick the name

        ld      c,0
        SCAL    ZDSIZE
;;; hl = number of sectors on drive 0

        rst     PRS
        defm    'Sectors to copy: 0x'
        defb    0
        SCAL    ZTBCD3
        SCAL    ZCRLF

;;; sectors are 256 bytes (0x100) each. Tried reading 8 at a time
;;; but the whole disk is NOT a xple of 8, leading to a messy
;;; end condition. Overall, easier to just read 2 at a time (all
;;; disks have an even number of sectors..)
;;; and buffer them in RAM. However, to be fast I'll
;;; do 10 (0xa) at a time.

        ld      de,0            ;start at 1st sector

nxtblk: push    hl              ;total #sectors
        ld      bc,$a00         ;a is #sectors, 0 is drive number
        ld      hl,BUFFER       ;where to put it

        SCAL    ZDRD
        ld      a,'*'           ;BAD reads
        jr      nz, report
        ld      a,'.'           ;GOOD reads
report: rst     ROUT

        ;; hl, bc unchanged
        ;; bc = $a00 - the number of bytes to write out to SD
        ;; need to fix c if using drive 1 etc.

        ld      a, CNWR         ;write
        call    putcmd
        ld      a, c            ;length in bytes, LS first
        call    putval
        ld      a, b
        call    putval
        xor     a
        call    putval
        xor     a
        call    putval

        ;; data transfer
snext:  ld      a, (hl)
        call    putval
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz, snext

        ;; get status, return if OK, msg/exit on error
        push    de
        ld      de,ewrt
        call    t2rs2t
        pop     de

        inc     de              ;increment sector count by
        inc     de              ;the number we've just copied
        inc     de
        inc     de
        inc     de

        inc     de
        inc     de
        inc     de
        inc     de
        inc     de              ;crude but effective!

        ;; we're done if hl=de
        pop     hl
        ld      a,h
        cp      d
        jr      nz, nxtblk
        ld      a,l
        cp      e
        jr      nz, nxtblk

        SCAL    ZCRLF
        jp      scrape

;;; exit messages
eopen:  DB "File open failed",0
ewrt:   DB "Write failed",0

;;; pad to 512bytes
size:   equ $ - START
        DS 200h - size, 0ffh
;;; end
