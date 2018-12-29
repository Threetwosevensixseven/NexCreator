; main.asm

zeusemulate             "Next"
 zoLogicOperatorsHighPri = false
zoSupportStringEscapes  = false
zxAllowFloatingLabels   = false
zoParaSysNotEmulate     = false
zoDebug                 = true
Zeus_PC                 = Start
Stack                   equ $BE00
Zeus_P7FFD              = $10
Zeus_IY                 = $5C3A
Zeus_AltHL              = $5C3A
Zeus_IM                 = 1
Zeus_IE                 = false
optionsize 5
Cspect optionbool 15, -15, "Cspect", false

                        org $8000
Start:
                        di
                        ld iy, $5C3A
                        ld sp, Stack
                        ld a, $80
                        ld i, a
                        im 1
                        Turbo(MHz14)
                        Contention(false)
                        //Border(Black)
                        ClsAttrFull(BrightWhiteBlackP)
                        ei
                        halt

                        ld hl, Font
                        ld (FZX_FONT), hl
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


FreezeX:                //Border(Red)
                        //Border(Blue)
                        jp FreezeX
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

                        include "constants.asm"                 ; Global constants
                        include "macros.asm"                    ; Zeus macros
FZX_ORG:                include "FZXdriver.asm"                 ; Font routines
Font:                   import_bin "..\fonts\TinyFixed.fzx"     ; Font

                        ds $C000-$, $F2                 ; Fill up 16k bank 2 with $F2

org $5FFF:              ds 1, $F5                       ; Fill up 16k bank 5 with $F5
org $7FFF:              ds 1, $F5                       ; Fill up 16k bank 5 with $F5

org $C000:              ds $4000, $F0                   ; Fill up 16k bank 0 with $F0

org $C000:
dispto zeuspage(1):     ds $4000, $F1                   ; Fill up 16k bank 1 with $F1

org $C000:
dispto zeuspage(3):     ds $4000, $F3                   ; Fill up 16k bank 3 with $F3

org $C000:
dispto zeuspage(4):     ds $4000, $F4                   ; Fill up 16k bank 4 with $F4

org $C000:
dispto zeuspage(6):     ds $4000, $F6                   ; Fill up 16k bank 6 with $F6

org $C000:
dispto zeuspage(7):     ds $4000, $F7                   ; Fill up 16k bank 7 with $F7
disp 0

// 8k banks 128-133 are not being referenced correctly. It appears they all map to bank 133.
// 8k banks 134-223 generate a syntax error when passed in to zeusmmu().
/*for n = 8 to 66
  org zeusmmu(n*2):     ds $2000, n*2                   ; Fill up 8k bank nn with nn
  org zeusmmu((n*2)+1): ds $2000, (n*2)+1
  output_bin            BankName(n), zeusmmu(n*2), $4000
next ;n
*/

[[
function BankName(A)
  begin
    return "..\nex\bank" + tostr(A) + ".bin"
  end
]]

output_sna "..\nex\NexTest.sna", $FF40, Start

if enabled Cspect
  zeusinvoke "..\build\NexCreator.bat"
  zeusinvoke "..\build\CSpect.bat", "", false
endif

