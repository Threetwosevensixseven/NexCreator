; bank30.asm

Bank30                  proc
                        di
Frz:                    //Border(Green)
                        //Border(Yellow)
                        //jp Frz

                        ld iy, $5C3A
                        ld sp, Stack
                        ld a, $80
                        ld i, a
                        im 1
                        Turbo(MHz14)
                        Contention(false)
                        ClsAttrFull(BrightWhiteBlackP)
                        FillLDIR($4000, $1800, $00)
                        ei
                        halt

                        ld hl, Font
                        ld (FZX_START.FZX_FONT), hl
                        ld a, -1
                        ld (BankToCheck), a

                        ld b, 7                         ; Col number
                        ld c, 0
RowLoop:                push bc
                        ld a, c
                        add a, a
                        add a, a
                        add a, a
                        add a, a
                        add a, a
                        ld (X), a
                        xor a
                        ld (Y), a

                        ld a, 7
                        sub a, b
                        add a, a
                        call ToHex2
                        ld c, 0                         ; Row number
                        ld b, 32
                        ld d, 0
ColumnLoop:             push bc
                        push de

                        ld a, [BankToCheck]SMC
                        inc a
                        ld (BankToCheck), a
                        nextreg $57, a
                        ld a, ($FFFF)
                        call ToHex

                        ld a, d
                        cp 16
                        jp c, NoPLoReset
                        add a, -16
NoPLoReset:             cp 10
                        ld e, "0"
                        call nc, Hex
                        add a, e
                        ld (PLo), a
                        ld hl, PrintText
PrintLoop:              ld a, (hl)                      ; for each character of this string...
                        cp 255
                        jp z, PrintEnd                  ; check string terminator
                        push hl                         ; preserve HL
                        call FZX_START                  ; print character
                        pop hl                          ; recover HL
Skip:                   inc hl
                        jp PrintLoop
PrintEnd:               ld a, (PLo)
                        cp "F"
                        jp nz, NoPHiInc
                        ld hl, PHi
                        inc (hl)
NoPHiInc:
                        pop de
                        pop bc
                        ld a, c
                        add a, 6
                        ld c, a
                        ld (Y), a
                        inc d
                        djnz ColumnLoop

                        pop bc
                        inc c
                        djnz RowLoop

FreezeX:                jp FreezeX
Hex:
                        ld e, "A"-10
                        ret
ToHex:
                        push de
                        ld d, a
                        and %11110000
                        rlca
                        rlca
                        rlca
                        rlca
                        cp 10
                        ld e, "0"
                        call nc, Hex
                        add a, e
                        ld (VHi), a
                        ld a, d
                        and %1111
                        cp 10
                        ld e, "0"
                        call nc, Hex
                        add a, e
                        ld (VLo), a
                        pop de
                        ret
ToHex2:
                        push de
                        and %1111
                        cp 10
                        ld e, "0"
                        call nc, Hex
                        add a, e
                        ld (PHi), a
                        pop de
                        ret

PrintText:              db At, [Y]0, [X]0
                        db [PHi]"0", [PLo]"0"
                        db ":", [VHi]"0", [VLo]"0", 255

                        jp Bank30

FZX_ORG:                include "FZXdriver.asm"                 ; Font routines
Font:                   import_bin "..\fonts\TinyFixed.fzx"     ; Font
pend

db "HELLO!"

org $DFFF
db $88

org $FFFF
db $99

