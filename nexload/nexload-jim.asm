;-------------------------------
; .nexload 
; © Jim Bagley 2018
;-------------------------------
	device zxspectrum48
;-------------------------------

;	DEFINE testing
;	DEFINE testing8000	; define this to test just loading images
	
;							offset	;size
HEADER_NEXT					= 0		;4
HEADER_VERSION				= 4		;4
HEADER_RAMREQ				= 8		;1
HEADER_NUMBANKS 			= 9		;1
HEADER_LOADSCR				= 10	;1
HEADER_BORDERCOL			= 11	;1
HEADER_SP					= 12	;2
HEADER_PC					= 14	;2
HEADER_NUMFILES				= 16	;2
HEADER_BANKS				= 18	;48+64
HEADER_LOADBAR				= 130	;1
HEADER_LOADCOL				= 131	;1
HEADER_LOADDEL				= 132	;1
HEADER_STARTDEL				= 133	;1
HEADER_DONTRESETNEXTREGS	= 134	;1
HEADER_CORE_MAJOR			= 135	;1
HEADER_CORE_MINOR			= 136	;1
HEADER_CORE_SUBMINOR		= 137	;1
HEADER_HIRESCOL				= 138	;1	// if non zero is to be 

LAYER_2_PAGE				= 9
LAYER_2_PAGE_0				= 9
LAYER_2_PAGE_1				= 10
LAYER_2_PAGE_2				= 11

M_GETSETDRV  				equ $89
F_OPEN       				equ $9a
F_CLOSE      				equ $9b
F_READ       				equ $9d
F_WRITE      				equ $9e
F_SEEK       				equ $9f
F_GET_DIR    				equ $a8
F_SET_DIR    				equ $a9
FA_READ      				equ $01
FA_APPEND    				equ $06
FA_OVERWRITE 				equ $0E

TURBO_CONTROL_REGISTER			equ $07		;Turbo mode 0=3.5Mhz, 1=7Mhz, 2=14Mhz
SPRITE_CONTROL_REGISTER			equ $15		;Enables/disables Sprites and Lores Layer, and chooses priority of sprites and Layer 2.
PALETTE_INDEX_REGISTER			equ $40		;Chooses a ULANext palette number to configure.
PALETTE_VALUE_REGISTER			equ $41		;Used to upload 8-bit colors to the ULANext palette.
PALETTE_FORMAT_REGISTER			equ $42
PALETTE_CONTROL_REGISTER		equ $43		;Enables or disables ULANext interpretation of attribute values and toggles active palette.
PALETTE_VALUE_BIT9_REGISTER		equ $44		;Holds the additional blue color bit for RGB333 color selection.
MMU_REGISTER_0				equ $50		;Set a Spectrum RAM page at position 0x0000 to 0x1FFF
MMU_REGISTER_1				equ $51		;Set a Spectrum RAM page at position 0x2000 to 0x3FFF
MMU_REGISTER_2				equ $52		;Set a Spectrum RAM page at position 0x4000 to 0x5FFF
MMU_REGISTER_3				equ $53		;Set a Spectrum RAM page at position 0x6000 to 0x7FFF
MMU_REGISTER_4				equ $54		;Set a Spectrum RAM page at position 0x8000 to 0x9FFF
MMU_REGISTER_5				equ $55		;Set a Spectrum RAM page at position 0xA000 to 0xBFFF
MMU_REGISTER_6				equ $56		;Set a Spectrum RAM page at position 0xC000 to 0xDFFF
MMU_REGISTER_7				equ $57		;Set a Spectrum RAM page at position 0xE000 to 0xFFFF

COPPER_CONTROL_LO_BYTE_REGISTER		equ $61
COPPER_CONTROL_HI_BYTE_REGISTER		equ $62

GRAPHIC_PRIORITIES_SLU			= %00000000	; sprites over l2 over ula
GRAPHIC_PRIORITIES_LSU			= %00000100
GRAPHIC_PRIORITIES_SUL			= %00001000
GRAPHIC_PRIORITIES_LUS			= %00001100
GRAPHIC_PRIORITIES_USL			= %00010000
GRAPHIC_PRIORITIES_ULS			= %00010100
GRAPHIC_OVER_BORDER				= %00000010
GRAPHIC_SPRITES_VISIBLE			= %00000001
LORES_ENABLE					= %10000000

NEXT_VERSION_REGISTER			equ $01
CORE_VERSION_REGISTER			equ $0E
PERIPHERAL_1_REGISTER			equ $05		;Sets joystick mode, video frequency, Scanlines and Scandoubler.
PERIPHERAL_2_REGISTER			equ $06		;Enables Acceleration, Lightpen, DivMMC, Multiface, Mouse and AY audio.
PERIPHERAL_3_REGISTER			equ $08		;Enables Stereo, Internal Speaker, SpecDrum, Timex Video Modes, Turbo Sound Next and NTSC/PAL selection.
TBBLUE_REGISTER_SELECT			equ $243B

	MACRO SetSpriteControlRegister:NEXTREG_A SPRITE_CONTROL_REGISTER:ENDM
	MACRO Set14mhz:NEXTREG_nn TURBO_CONTROL_REGISTER,%10:ENDM
	MACRO BREAK:dw $01DD:ENDM
	MACRO ADD_HL_A:dw $31ED:ENDM
	MACRO SWAPNIB: dw $23ED: ENDM
	MACRO NEXTREG_A register:dw $92ED:db register:ENDM			; Set Next hardware register using A
	MACRO NEXTREG_nn register, value:dw $91ED:db register:db value:ENDM	; Set Next hardware register using an immediate value

;-------------------------------

	IFDEF testing

	IFDEF testing8000
		org $8000
	ELSE
		org	$4000
	ENDIF
start
	ld	ix,testfile
	jp	loadbig

;testfile db	"l2.nex",0
;testfile db	"ula.nex",0
testfile db	"lo.nex",0
;testfile db	"shr.nex",0
;testfile db	"shc.nex",0

;testfile db	"bis.nex",0
;testfile db	"warhawk.nex",0
	ELSE

	org	$2000
start
	ld	a,h:or l:jr nz,.gl
	ld	hl,emptyline:call print_rst16:jr finish
.gl	ld	de,filename:ld b,127
.bl	ld	a,(hl):cp ":":jr z,.dn:or a:jr z,.dn:cp 13:jr z,.dn:bit 7,a:jr nz,.dn
	ld	(de),a:inc hl:inc de:djnz .bl
.dn	xor	a:ld (de),a

	; the filename passed may have trailing spaces... the index needs to update to omit them

	ld	ix,filename
	call 	stripLeading
	call	loadbig
finish
	xor	a:ret

	ENDIF
;-------------------------------
stripLeading					; remove leading spaces ix = pointer
	ld a,ixh:ld h,a:ld a,ixl:ld l,a		; hl = pointer to filename
	ld b,127
.l1	ld a,(hl):cp ' ':jp nz,.ok
	inc hl
	djnz .l1
.ok	ld a,h:ld ixh,a:ld a,l:ld ixl,a		; set ix to current
	ret
;-------------------------------
getCurrentCore
        ld a,NEXT_VERSION_REGISTER
        ld bc,TBBLUE_REGISTER_SELECT
        out (c),a:inc b:in a,(c)		; major and minor
        ld c,a
        and %00001111:ld (CoreMinor),a
        ld a,c:SWAPNIB:and %00001111:ld (CoreMajor),a

        ld a,NEXT_VERSION_REGISTER
        ld bc,CORE_VERSION_REGISTER
        out (c),a:inc b:in a,(c):ld (CoreSub),a		; sub minor
	ret
;-------------------------------

getrealbank
	cp	8:ret nc
	ld	hl,.table:add a,l:ld l,a:adc a,h:sub l:ld h,a:ld a,(hl):ret
.table	db	5,2,0,1,3,4,6,7
;-------------------------------
loadbig
	ld (oldStack),sp
	push ix:call setdrv:pop ix:push ix:call fopen:pop ix:ret c

	call getCurrentCore

	; set transparency on ULA
	NEXTREG_nn 66, 15
	NEXTREG_nn PALETTE_CONTROL_REGISTER, 0
	NEXTREG_nn PALETTE_CONTROL_REGISTER, 0
	NEXTREG_nn PALETTE_INDEX_REGISTER, 	$18
	NEXTREG_nn PALETTE_VALUE_REGISTER, 	$e3
	xor a:out (254),a
	ld	hl,$5800:ld de,$5801:ld bc,$2ff:ld (hl),0:ldir
	ld	bc,4667:ld a,0:out (c),a
	NEXTREG_nn SPRITE_CONTROL_REGISTER,GRAPHIC_PRIORITIES_SLU + GRAPHIC_SPRITES_VISIBLE

	Set14mhz

	di
	IFDEF testing
		IFDEF testing8000
			ld	sp,$7fff
		ELSE
			ld	sp,$4800
		ENDIF
	ELSE
	ld	sp,$3fff
	ENDIF

;	ld	a,LAYER_2_PAGE_0*2:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7:ld	hl,$c000:ld de,$c001:ld bc,$3fff:ld (hl),l:ldir
;	ld	a,LAYER_2_PAGE_1*2:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7:ld	hl,$c000:ld de,$c001:ld bc,$3fff:ld (hl),l:ldir
;	ld	a,LAYER_2_PAGE_2*2:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7:ld	hl,$c000:ld de,$c001:ld bc,$3fff:ld (hl),l:ldir

	ld a,5*2:NEXTREG_A MMU_REGISTER_2	; warning if this 16K bank isn't 5 on loading this then it will crash on testing but 5 is default so should be ok.
	inc a:NEXTREG_A MMU_REGISTER_3
	ld a,2*2:NEXTREG_A MMU_REGISTER_4
	inc a:NEXTREG_A MMU_REGISTER_5
	xor a:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7

;	pop ix
;	push ix:call setdrv:pop ix:call fopen
	ld	ix,$c000:ld bc,$200:call fread
	ld	hl,$c000+HEADER_BANKS:ld de,LocalBanks:ld bc,48+64:ldir
	ld	hl,($c000+HEADER_PC):ld (PCReg),hl
	ld	hl,($c000+HEADER_SP):ld (SPReg),hl
	ld	hl,($c000+HEADER_LOADBAR):ld (LoadBar),hl
	ld	hl,($c000+HEADER_LOADDEL):ld (LoadDel),hl

	ld hl,(CoreMajor):ld de,(CoreSub)
	ld a,($c000+HEADER_CORE_MAJOR)					:cp l:jr z,.o1:jp nc,coreUpdate:jr .ok
.o1	ld a,($c000+HEADER_CORE_MINOR)                  :cp h:jr z,.o2:jp nc,coreUpdate:jr .ok
.o2	ld a,($c000+HEADER_CORE_SUBMINOR)               :cp e:jr z,.ok:jp nc,coreUpdate
.ok

	ld	a,($c000+HEADER_DONTRESETNEXTREGS):or a:jp nz,.dontresetregs
;Reset All registers
;stop copper
	NEXTREG_nn COPPER_CONTROL_HI_BYTE_REGISTER, 0	; stop
	NEXTREG_nn COPPER_CONTROL_LO_BYTE_REGISTER, 0
;reset AY sound chips enabled
;    ld a,6:ld bc,$243b:out (c),a:inc b:in a,(c):or 3:out (c),a	 ;PERIPHERAL_3_REGISTER

;	NEXTREG_nn 6,200
;	11001000
	ld a,PERIPHERAL_2_REGISTER:ld bc,TBBLUE_REGISTER_SELECT:out (c),a:inc b:in a,(c)
    	set 7,a				; turbo on
    	res 6,a				; dac i2s (don't think this does anything)
	res 5,a    			; lightpen off
    	res 4,a				; DivMMC automatic paging off
    	set 3,a				; mulitface - add to build options so can be selected
;    	res 2,a				; 2 = ps2 mode - leave to option control
;    	set 1,a:set 0,a			; set AY (rather than YM) - * Causes Silence *

	; 			bits 1-0 = Audio chip mode (0- = disabled, 10 = YM, 11 = AY)
	;			11 = disable audio, or appears to be the case

    	out (c),a

;	NEXTREG_nn 8,254
; 	11111110
	ld a,PERIPHERAL_3_REGISTER:ld bc,TBBLUE_REGISTER_SELECT:out (c),a:inc b:in a,(c)
	set 7,a			; disable locked paging
	set 6,a			; disable contention
	res 5,a			; stereo to ABC   (perhaps leave to options?)
	set 4,a 		; enable internal speaker
	set 3,a 		; enable specdrum
	set 2,a 		; enable timex
	set 1,a 		; enable turbosound
	res 0,a 		; must be 0

	out (c),a

;    ld a,8:ld bc,$243b:out (c),a:inc b:in a,(c):set 1,a:set 5,a:out (c),a	 ;PERIPHERAL_3_REGISTER

	NEXTREG_nn 7,%10	; turbo 14Mhz

	NEXTREG_nn 18,9														; layer2 page
	NEXTREG_nn 19,12													; layer2 shadow page
	NEXTREG_nn 20,$e3													; transparent index
	NEXTREG_nn 21,1														; priorities + sprite over border + sprite enable
	NEXTREG_nn 22,0:NEXTREG_nn 23,0										; layer2 xy scroll
	NEXTREG_nn 27,7														; clipwindow index reset all 3
	NEXTREG_nn 24,0:NEXTREG_nn 24,255:NEXTREG_nn 24,0:NEXTREG_nn 24,191	; clip window layer2
	NEXTREG_nn 25,0:NEXTREG_nn 25,255:NEXTREG_nn 25,0:NEXTREG_nn 25,191	; clip window sprites
	NEXTREG_nn 26,0:NEXTREG_nn 26,255:NEXTREG_nn 26,0:NEXTREG_nn 26,191	; clip window ula
	NEXTREG_nn 45,0														; sound drive reset
	NEXTREG_nn 50,0:NEXTREG_nn 51,0										; lores XY scroll
	NEXTREG_nn 67,0														; ula palette
	NEXTREG_nn 66,15													; allow flashing
	NEXTREG_nn 64,0
	call .ul
	NEXTREG_nn 64,128
	call .ul
	NEXTREG_nn 67,16													;layer2 palette
	call .pa
	NEXTREG_nn 67,32													;sprite palette
	call .pa
	NEXTREG_nn 74,0														; transparency fallback value
	NEXTREG_nn 75,$e3													; sprite transparency index
	NEXTREG_nn MMU_REGISTER_0,255
	NEXTREG_nn MMU_REGISTER_1,255

	jr .dontresetregs

.pa	NEXTREG_nn 64,0														;palette index
	xor a																;index 0
.rp	NEXTREG_A 65														;palette low 8
	inc a:jr nz,.rp														;reset all 256 colours
	ret
.ul	ld c,8
.u0	ld hl,DefaultPalette:ld b,16
.u2	ld a,(hl):inc hl:NEXTREG_A PALETTE_VALUE_REGISTER
	djnz .u2:dec c:jr nz,.u0
	ret

.dontresetregs

	ld	a,($c000+HEADER_LOADSCR):ld (IsLoadingScr),a:or a:jp z,.skpbmp
	ld	a,($c000+HEADER_BORDERCOL):ld (BorderCol),a
	ld	a,(IsLoadingScr):and 128:jr nz,.skppal
	ld	a,(IsLoadingScr):and %11010:jr nz,.skppal
	ld	ix,$c200:ld bc,$200:call fread	;palette
	ld a,(IsLoadingScr):and 4:jr z,.nlores
	NEXTREG_nn PALETTE_CONTROL_REGISTER,%00000001:jr .nl2	;layer2 palette
.nlores
	NEXTREG_nn PALETTE_CONTROL_REGISTER,%00010000	;layer2 palette
.nl2
	NEXTREG_nn PALETTE_INDEX_REGISTER, 	0
	ld	hl,$c200:ld b,0
.pl	ld a,(hl):inc hl:NEXTREG_A PALETTE_VALUE_BIT9_REGISTER
	ld a,(hl):inc hl:NEXTREG_A PALETTE_VALUE_BIT9_REGISTER
	djnz .pl
.skppal
	ld	a,(IsLoadingScr):and 1:jr z,.notbmp
	ld	a,LAYER_2_PAGE_0*2:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7:ld	ix,$c000:ld bc,$4000:call fread:ld a,6:jp c,.err
	ld	a,LAYER_2_PAGE_1*2:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7:ld	ix,$c000:ld bc,$4000:call fread:ld a,6:jp c,.err
	ld	a,LAYER_2_PAGE_2*2:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7:ld	ix,$c000:ld bc,$4000:call fread:ld a,6:jp c,.err
	ld	bc,4667:ld a,2:out (c),a
	NEXTREG_nn SPRITE_CONTROL_REGISTER,GRAPHIC_PRIORITIES_SLU + GRAPHIC_SPRITES_VISIBLE
	xor a:out (255),a
.notbmp
	ld	a,(IsLoadingScr):and 2:jr z,.notULA
	IFDEF testing
		IFDEF testing8000
			ld	ix,$4000:ld bc,$1b00:call fread
		ELSE
			ld	ix,$4800:ld bc,$800:call fread
			ld	ix,$4800:ld bc,$1b00-$800:call fread
		ENDIF
	ELSE
		ld	ix,$4000:ld bc,$1b00:call fread
	ENDIF
	ld	bc,4667:xor a:out (c),a
	NEXTREG_nn SPRITE_CONTROL_REGISTER,GRAPHIC_PRIORITIES_SLU + GRAPHIC_SPRITES_VISIBLE
	xor a:out (255),a
.notULA
	ld	a,(IsLoadingScr):and 4:jr z,.notLoRes
	IFDEF testing
		IFDEF testing8000
			ld	ix,$4000:ld bc,$1800:call fread
		ELSE
			ld	ix,$4800:ld bc,$800:call fread
			ld	ix,$4800:ld bc,$1800-$800:call fread
		ENDIF
	ELSE
		ld	ix,$4000:ld bc,$1800:call fread
	ENDIF
	ld	ix,$6000:ld bc,$1800:call fread
	ld	bc,4667:xor a:out (c),a
	NEXTREG_nn SPRITE_CONTROL_REGISTER,GRAPHIC_PRIORITIES_SLU + GRAPHIC_SPRITES_VISIBLE + LORES_ENABLE
	ld a,3:out (255),a
.notLoRes
	ld	a,(IsLoadingScr):and 8:jr z,.notHiRes
	IFDEF testing
		IFDEF testing8000
			ld	ix,$4000:ld bc,$1800:call fread
		ELSE
			ld	ix,$4800:ld bc,$800:call fread
			ld	ix,$4800:ld bc,$1800-$800:call fread
		ENDIF
	ELSE
		ld	ix,$4000:ld bc,$1800:call fread
	ENDIF
	ld	ix,$6000:ld bc,$1800:call fread
	ld	bc,4667:xor a:out (c),a
	NEXTREG_nn SPRITE_CONTROL_REGISTER,GRAPHIC_PRIORITIES_SLU + GRAPHIC_SPRITES_VISIBLE
	ld a,($c000+HEADER_HIRESCOL):and %111000:or 6:out (255),a
;	ld a,6+24:out (255),a
.notHiRes
	ld	a,(IsLoadingScr):and 16:jr z,.notHiCol
	IFDEF testing
		IFDEF testing8000
			ld	ix,$4000:ld bc,$1800:call fread
		ELSE
			ld	ix,$4800:ld bc,$800:call fread
			ld	ix,$4800:ld bc,$1800-$800:call fread
		ENDIF
	ELSE
		ld	ix,$4000:ld bc,$1800:call fread
	ENDIF
	ld	ix,$6000:ld bc,$1800:call fread
	ld	bc,4667:xor a:out (c),a
	NEXTREG_nn SPRITE_CONTROL_REGISTER,GRAPHIC_PRIORITIES_SLU + GRAPHIC_SPRITES_VISIBLE
	ld a,2:out (255),a
.notHiCol
	ld	a,(BorderCol):out (254),a
.skpbmp
	xor a:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7
	
	IFDEF testing
	BREAK
	ENDIF
	
	ld a,(LocalBanks+5):or a:jr z,.skb5
	IFDEF testing
		ld ix,$4800:ld bc,$800:call fread:ld a,5:jp c,.poperr
		ld ix,$4800:ld bc,$3800:call fread:ld a,5:jp c,.poperr
	ELSE
		ld ix,$4000:ld bc,$4000:call fread:ld a,5:jp c,.poperr
	ENDIF
.skb5
	ld a,(LocalBanks+2):or a:jr z,.skb2
	ld ix,$8000:ld bc,$4000:call fread:ld a,4:jp c,.poperr
.skb2
	ld a,(LocalBanks+0):or a:jr z,.skb0
	ld ix,$c000:ld bc,$4000:call fread:ld a,3:jp c,.poperr
.skb0

	ld	d,0:call progress:inc d:call progress:inc d:call progress
	ld a,3
.lp	push af:call getrealbank:ld e,a:ld hl,LocalBanks:ADD_HL_A:ld a,(hl):or a:jr z,.skpld
	ld a,e:add a,a:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7
	ld ix,$c000:ld bc,$4000:call fread:ld a,2:jp c,.poperr
.skpld
	ld a,(IsLoadingScr):or a:call nz,delay

	pop de:push de:call progress

	pop af:inc a:cp 112:jr nz,.lp;48+64:jr nz,.lp

	call fclose
	xor a:NEXTREG_A MMU_REGISTER_6
	inc a:NEXTREG_A MMU_REGISTER_7

;.stop	inc a:and 7:out (254),a:jr .stop

	ld a,(StartDel)
.ss	or a:jr z,.go:dec a:ei:halt:di:jp .ss
.go

	ld	hl,(PCReg):ld sp,(SPReg)
	ld a,h:or l:jr z,.returnToBasic
	IFDEF testing
		jp (hl)
	ELSE
		ld	hl,(PCReg)
		rst	$20
	ENDIF

.poperr
.err	out (254),a
	ld	bc,4667:xor a:out (c),a

.returnToBasic
	call fclose
	ld a,($5b5c):and 7:add a,a:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7
	ld sp,(oldStack)
	xor a
	ret

;--------------------
delay	ld a,(LoadDel)
.ss	or a:ret z:dec a:ei:halt:di:jp .ss
;--------------------
progress
	ld a,(LoadBar):or a:ret z
	ld a,LAYER_2_PAGE_2*2:NEXTREG_A MMU_REGISTER_6:inc a:NEXTREG_A MMU_REGISTER_7
	ld a,(LoadCol):ld e,a
	ld h,$fe:ld a,d:add a,a:add a,24-6:ld l,a:ld (hl),e:inc h:ld (hl),e:inc l:ld (hl),e:dec h:ld (hl),e
	ret
;--------------------
fileError
	ld a,1:out (254),a
	ret
;-------------
setdrv
	xor a:rst $08:db M_GETSETDRV
	ld (drive),a:ret
;-------------
fopen
	ld b,FA_READ:db $21
fcreate
	ld b,FA_OVERWRITE:db 62
drive	db 0
	push ix:pop hl:rst $08:db F_OPEN
	ld (handle),a:jp c, fileError
	ret
;--------------
fread
	push ix:pop hl:db 62
handle	db 1
	rst $08:db F_READ
	ret
;-------------
fclose
	ld a,(handle):rst $08:db F_CLOSE
	ret

;-------------
coreUpdate
	ld hl,coretext:call print_rst16
	ld hl,($c000+HEADER_CORE_MAJOR):ld h,0:call dec8:ld a,",":rst 16
	ld hl,($c000+HEADER_CORE_MINOR):ld h,0:call dec8:ld a,",":rst 16
	ld hl,($c000+HEADER_CORE_SUBMINOR):ld h,0:call dec8:ld a,13:rst 16
	ld hl,yourcoretext:call print_rst16
	ld hl,(CoreMajor):ld h,0:call dec8:ld a,",":rst 16
	ld hl,(CoreMinor):ld h,0:call dec8:ld a,",":rst 16
	ld hl,(CoreSub):ld h,0:call dec8:ld a,13:rst 16
	xor a:ret
	
dec8
	ld de,100
	call dec0
	ld de,10
	call dec0
	ld de,1
dec0
	ld a,"0"-1
.lp	inc a
	sub hl,de
	jr nc,.lp
	add hl,de
	rst 16
	ret

coretext
	db	"Sorry, this file needs Core",13,0
yourcoretext
	db	"Your Core is ",13,0

;-------------
DefaultPalette
	db	%00000000,%00000010,%10100000,%10100010,%00010100,%00010110,%10110100,%10110110
	db	%00000000,%00000011,%11100000,%11100111,%00011100,%00011111,%11111100,%11111111
;-------------
CoreMajor	db 	0
CoreMinor	db	0
CoreSub		db 	0

oldStack	dw	0
IsLoadingScr db 0
PCReg		dw	0
SPReg		dw	0
BorderCol	db	0
LoadBar		db	0
LoadCol		db	0
LoadDel		db	0
StartDel	db	0
NumFiles	dw	0
LocalBanks	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

print_rst16	ld a,(hl):inc hl:or a:ret z:rst 16:jr print_rst16

filename	db		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
			db		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
emptyline	db		".nexload <filename> to load nex file.",13,0

header		equ		$


	IFDEF testing
	savesna "nexload.sna",start
	ELSE
last
	savebin "NEXLOAD",start,last-start
	ENDIF

;-------------------------------
