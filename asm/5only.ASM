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
UploadNext optionbool 80, -15, "Next", false

                        org $6000
Start:
                        di
Loop:                   Border(1)
                        Border(2)
                        jp Loop

Border                  macro(Colour)
                        if Colour=0
                          xor a
                        else
                          ld a, Colour
                        endif
                        out ($FE), a
                        if Colour=0
                          xor a
                        else
                          ld a, Colour*8
                        endif
                        ld (23624), a
mend

output_sna "..\nex\5Only.sna", $FF40, Start

