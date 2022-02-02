;*****************************************************************************
;			   DISPLAY PROGRAMS
;*****************************************************************************

DISPMEM		DW	0A000H
DISP_ON		DW	0

SCRTIME		= 2400			;600		;2400 REAL

;*********************************
;	VBLANK SIMULATION
;*********************************

UPDATE		DW	0

SCR_DIRTY:
		MOV	[BYTE CS:OLD_BGP],0
		MOV	[BYTE CS:OLD_OBP0],0
		MOV	[BYTE CS:OLD_OBP1],0
		RET

FORCE_SCR:
		MOV	[BYTE CS:OLD_BGP],0
		MOV	[BYTE CS:OLD_OBP0],0
		MOV	[BYTE CS:OLD_OBP1],0

		JMP	PRINT_SCR
		

UPDATE_SCR:
		DEC	[CS:UPDATE]
		JZ	@@DISP
		RET

@@DISP:	
		MOV	[CS:UPDATE],SCRTIME

PRINT_SCR:

		MOV		DS,[CS:Z80_SEG]
		CALL	SET_BGP_PAL
		CALL	SET_SPR0_PAL
		CALL	SET_SPR1_PAL

		CALL	DISPSCR
		CALL	DISPWIN
		CALL	DISPSPR

;		CALL	WAIT_FLY
		CALL	PR_SCR
		RET

;*********************************
;	   LY SIMULATION
;*********************************

UPDATE_LY:	MOV	DS,[CS:Z80_SEG]

		AND	[BYTE STAT],11111011B		;CLR LYC

		MOV	AX,[CS:TIME]
		AND	AX,3
		JNZ	@@EXIT

		MOV	AL,[STAT]
		XOR	AL,2
		MOV	[STAT],AL

		INC	[BYTE LY]

		MOV	AL,[BYTE LYC]
		CMP	AL,[BYTE LY]
		JNZ	@@EXIT

		OR	[BYTE STAT],00000100B		;SET LYC

@@EXIT:	

		RET

;*********************************
;	   UPDATE KEYS
;*********************************

UPDATE_KEYS:

		MOV	DS,[CS:Z80_SEG]

		MOV	AL,[P1]
		AND	AL,30H

		CMP	AL,20H
		JZ	GETJOY

		CMP	AL,10H
		JZ	GETPAD

		RET

;*********************************
;	   READ JOY KEYS
;*********************************

GETJOY:	
		MOV	DL,0

		KEY	RIGHTARROW_KEY
		JZ	@@NOT1

		OR	DL,1

@@NOT1:		KEY	LEFTARROW_KEY
		JZ	@@NOT2

		OR	DL,2

@@NOT2:		KEY	UPARROW_KEY
		JZ	@@NOT3

		OR	DL,4

@@NOT3:		KEY	DOWNARROW_KEY
		JZ	@@NOT4

		OR	DL,8

@@NOT4:	
		NOT	DL
		AND	DL,0FH		

		MOV	AL,[P1]
		AND	AL,0F0H
		OR	AL,DL
		MOV	[P1],AL

		JMP	KEYINT

;*********************************
;	   READ PAD KEYS
;*********************************

GETPAD:
		MOV	DL,0

		KEY	A_KEY
		JZ	@@NOT1

		OR	DL,1

@@NOT1:		KEY	B_KEY
		JZ	@@NOT2

		OR	DL,2

@@NOT2:		KEY	F1_KEY
		JZ	@@NOT3

		OR	DL,4

@@NOT3:		KEY	F2_KEY
		JZ	@@NOT4

		OR	DL,8

@@NOT4:		NOT	DL
		AND	DL,0FH		

		MOV	AL,[P1]
		AND	AL,0F0H
		OR	AL,DL
		MOV	[P1],AL

		JMP	KEYINT

;********************************
;     P10-P13 KEY INTERRUPT
;********************************

KEYINT:	
		TEST	[BYTE I_E],00010000B
		JZ	@@NOPE
	
		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[CS:Z80_PC],60H		;MAKE THIS THE NEW PC ADDRESS
		MOV	[BYTE IME],0		;DO DI

@@NOPE:
		RET

;********************************
;     LCDC STATUS INTERRUPT
;********************************

UPDATE_LCD:
		MOV	AX,[CS:TIME]
		AND	AX,3FFH
		JNZ	@@NOPE

		TEST	[BYTE I_E],00000010B
		JZ	@@NOPE
	
		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		;MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		;CALL	PUSHDI

		;MOV	[CS:Z80_PC],48H		;MAKE THIS THE NEW PC ADDRESS
		;MOV	[BYTE IME],0		;DO DI

@@NOPE:	
		RET

;*********************************
;	UPDATE DMA SIMULATION
;*********************************

UPDATE_DMA:	MOV	AX,[CS:Z80_SEG]

		MOV	DS,AX
		MOV	ES,AX

		MOV	AL,[DMA]		;IS DMA SET
		AND	AL,AL
		JZ	@@EXIT

		MOV	AH,AL
		MOV	AL,0

		PUSH	AX
		POP	SI
	
		MOV	DI,0FE00H
		MOV	CX,140

		REP	MOVSB
		
		MOV	[BYTE DMA],0		;RESET DMA


;** ARH 98
;		MOV	[CS:UPDATE],100		;RESET DMA
;**		

@@EXIT:		RET

;********************************
;      	   SET PC TO DI
;********************************

INTFLAG		DW	0

UPDATE_INT:	TEST	[BYTE I_E],00000001B
		JZ	@@NOPE
	
		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		DEC	[CS:INSTCNT]		;INC INT COUNT   
		JNZ	@@NOPE

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[CS:Z80_PC],40H		;MAKE THIS THE NEW PC ADDRESS

		MOV	[BYTE IME],0		;DO DI
		MOV	[BYTE CS:INTFLAG],1

		MOV	[CS:INSTCNT],INTTIME
		RET

@@NOPE:		MOV	[BYTE CS:INTFLAG],0
		RET

;********************************
;    SIMULATE SIO INTERRUPT
;********************************

SIOTIME		DW	0

UPDATE_SIO:	TEST	[BYTE I_E],00001000B
		JZ	@@NOPE

		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		MOV	AX,[CS:SIOTIME]
		AND	AX,AX
		JNZ	@@COUNT

		MOV	DS,[CS:Z80_SEG]
		MOV	AL,[SC]
		AND	AL,80H
		JZ	@@NOPE			;SEND FLAG SET JMP IF NOT

		MOV	[CS:SIOTIME],50
		RET

@@COUNT:	DEC	[CS:SIOTIME]
		JNZ	@@NOPE
				
		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[BYTE IME],0		;DISABLE INTERRUPTS
		MOV	[CS:Z80_PC],58H		;MAKE THIS THE NEW PC ADDRESS

@@NOPE:		RET

;********************************
;    SIMULATE TIMER INTERRUPT
;********************************

UPDATE_TMA:	TEST	[BYTE I_E],00000100B
		JZ	@@NOPE

		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		TEST	[BYTE TAC],00000100B
		JZ	@@NOPE		

		MOV	AL,[BYTE TMA]		;ADD TIMA=TIMA+TMA
		ADD	[BYTE TIMA],AL
		JNC	@@NOPE

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[BYTE IME],0		;DISABLE INTERRUPTS
		MOV	[CS:Z80_PC],50H		;MAKE THIS THE NEW PC ADDRESS

@@NOPE:		RET

;*********************************
;       CLEAR VGA SCREEN
;*********************************

CLS_GB:	MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,0 			;BASE OF SCREEN
		MOV	AX,8484H
		MOV	CX,8000H
		REP	STOSW
    	RET

;*********************************
;       PRINT BACK SCREEN
;*********************************

PR_SCR:
		mov		ax,[cs:DISP_ON]
		and		ax,ax
		jz		@@nope
		
		PUSH	DS

		MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	DS,AX
		MOV	SI,320*8+8

		MOV	AX,0A000H
		MOV	ES,AX
		MOV	DI,320*24+72		;BASE OF SCREEN
       
		MOV	CX,144
@@LOOP:		
		REPT	40
		MOVSD
		ENDM

		ADD	DI,160
		ADD	SI,160

		LOOP	@@LOOP

		POP	DS
		
@@nope:
    	RET

;*********************************
;	     TEST CHR
;*********************************

DISPSCR:	MOV	DS,[CS:Z80_SEG]

		MOV	AL,[SCX]
		OR	AL,[SCY]
		JZ	STATIC_SCR

		MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,320*8+8

		MOV	AL,[SCX]
		AND	AL,7
		MOV	CL,AL
		MOV	CH,0
		SUB	DI,CX

		MOV	AL,[SCY]
		AND	AL,7
		MOV	AH,0
		MOV	CX,320
		MUL	CX
		SUB	DI,AX

		CALL	SELMAP

		MOV	AL,[SCY]
		SHR	AL,3
		CBW
		SHL	AX,5

		MOV	CL,[SCX]
		SHR	CL,3
		MOV	CH,0
		ADD	BX,CX
		ADD	BX,AX

		MOV	CX,19			;18

@@MAIN:		PUSH	CX
		PUSH	BX
		PUSH	DI

		MOV	CX,21			;20
@@LOOP:		PUSH	CX

		PUSH	BX

		MOV	BL,[BYTE DS:BX]
		MOV	BH,0

		CALL	PR_CHR
		POP	BX

		POP	CX

		MOV	AL,BL
		AND	AL,11100000B
		INC	BL
		AND	BL,00011111B
		OR	BL,AL

		ADD	SI,16
		ADD	DI,8

		LOOP	@@LOOP

		POP	DI
		POP	BX
		POP	CX

		MOV	AX,BX
		AND	AX,1111110000000000B
		ADD	BX,32
		AND	BX,0000001111111111B
		OR	BX,AX

		ADD	DI,8*320

		LOOP	@@MAIN
		RET

;*********************************
;	     TEST CHR
;*********************************

STATIC_SCR:	MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,320*8+8

		CALL	SELMAP

		MOV	CX,18			;18

@@MAIN:		PUSH	CX
		PUSH	BX
		PUSH	DI

		MOV	CX,20			;20
@@LOOP:		PUSH	CX

		PUSH	BX

		MOV	BL,[BYTE DS:BX]
		MOV	BH,0

		CALL	PR_CHR
		POP	BX

		POP	CX

		INC	BX

		ADD	SI,16
		ADD	DI,8

		LOOP	@@LOOP

		POP	DI
		POP	BX
		POP	CX

		ADD	BX,32
		ADD	DI,8*320

		LOOP	@@MAIN
		RET

;*********************************
;	     TEST CHR
;*********************************

WINXL		DW	0

DISPWIN:	MOV	DS,[CS:Z80_SEG]

		MOV	AL,[LCDC]		;IS WINDOW ON
		AND	AL,00100000B
		JZ	@@QUIT

		MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,0

		MOV	AL,[WX]
		MOV	AH,0
		ADD	DI,AX

		MOV	AL,[WY]
		MOV	AH,0
		ADD	AX,8
		MOV	CX,320
		MUL	CX
		ADD	DI,AX

		CALL	WINMAP

		MOV	AL,[WX]
		SHR	AL,3
		MOV	AH,0

		MOV	CX,21			;18
		SUB	CX,AX	
		JC	@@QUIT
		JZ	@@QUIT

		MOV	[CS:WINXL],CX

		MOV	AL,[WY]
		SHR	AL,3
		MOV	AH,0
		INC	AX
		MOV	CX,19			;18
		SUB	CX,AX	
		JC	@@QUIT
		JZ	@@QUIT

@@MAIN:		PUSH	CX
		PUSH	BX
		PUSH	DI

		MOV	CX,[CS:WINXL]			;20
@@LOOP:		PUSH	CX

		MOV	AL,[BYTE DS:BX]
		PUSH	BX

		MOV	BL,AL
		MOV	BH,0

		CALL	PR_CHR
		POP	BX

		POP	CX

		MOV	AL,BL
		AND	AL,11100000B
		INC	BL
		AND	BL,00011111B
		OR	BL,AL

		ADD	SI,16
		ADD	DI,8

		LOOP	@@LOOP

		POP	DI
		POP	BX
		POP	CX

		MOV	AX,BX
		AND	AX,1111110000000000B
		ADD	BX,32
		AND	BX,0000001111111111B
		OR	BX,AX

		ADD	DI,8*320

		LOOP	@@MAIN
@@QUIT:		RET

;*********************************
;   CLEAR SCREEN EDGE WITH BLUE
;*********************************

CLR_EDGES:	MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,0

		MOV	CX,8
		MOV	AX,8585H

@@LOOP:		PUSH	CX
		PUSH	DI
		
		MOV	CX,22*4
		REP	STOSW

		POP	DI
		PUSH	DI

		ADD	DI,(19*8)*320

		MOV	CX,22*4
		REP	STOSW

		POP	DI
		POP	CX

		ADD	DI,320

		LOOP	@@LOOP

		MOV	DI,320*8
		MOV	CX,8*18+1

@@LOOP2:	MOV	[ES:DI+0],AX
		MOV	[ES:DI+2],AX
		MOV	[ES:DI+4],AX
		MOV	[ES:DI+6],AX

		MOV	[ES:DI+168],AX
		MOV	[ES:DI+170],AX
		MOV	[ES:DI+172],AX
		MOV	[ES:DI+174],AX

		ADD	DI,320
		LOOP	@@LOOP2
		RET

;*********************************
;	  SELECT MAP AREA
;*********************************

WINMAP:
		TEST	[BYTE LCDC],01000000B
		JNZ	@@AREA1

		MOV	BX,9800H
		RET

@@AREA1:
		MOV	BX,9C00H
		RET		

;*********************************
;	  SELECT MAP AREA
;*********************************

SELMAP:
		TEST	[BYTE LCDC],00001000B
		JNZ	@@AREA1

		MOV	BX,9800H
		RET

@@AREA1:
		MOV	BX,9C00H
		RET		

;*********************************
;	  SELECT CHR AREA
;*********************************

;		LCDC	   76543210
;			   ||||||||_________ BG        ON(1)/OFF
;			   |||||||__________ SPR       ON(1)/OFF
;			   ||||||___________ OBJ      8X8(0)/8X16
;			   |||||____________ BG MAP  9800(0)/9C00
;			   ||||_____________ BG CHR  8800(0)/8000
;			   |||______________ WIN       ON(1)/OFF
;			   ||_______________ WIN MAP 9800(0)/9C00
;			   |________________ CONTROL   ON(1)/OFF
;

SELCHR:		TEST	[BYTE LCDC],00010000B
		JNZ	@@AREA1

		XOR	BL,80H
		SHL	BX,4

		ADD	BX,8800H
		MOV	SI,BX
		RET

@@AREA1:	SHL	BX,4
		ADD	BX,8000H
		MOV	SI,BX
 		RET

;*********************************
;     PIXEL PRINTING MACROS
;*********************************

		MACRO	ONEPIX
		XOR	DL,DL
		RCL	AH,1
		ADC	DL,DH
		ADD	DL,DL
		RCL	AL,1
		ADC	DL,CH
		MOV	[ES:DI],DL
		INC	DI
		ENDM


		MACRO	TWOPIX
		XOR	AX,AX
		RCL	DH,1
		ADC	AL,CL
		ADD	AL,AL
		RCL	DL,1
		ADC	AL,CH
		RCL	DH,1
		ADC	AH,CL
		ADD	AH,AH
		RCL	DL,1
		ADC	AH,CH
		STOSW
		ENDM

;*********************************
;	    PRINT A CHR
;	      CX = XY
;        BX = CHR ADDRESS
;*********************************
     
		IF	0
	
PR_XY:		MOV	DL,CH
		MOV	DH,0
		MOV	AX,320
		MUL	DX
		MOV	CH,0
		ADD	AX,CX
		MOV	DI,AX
						;BX = CHR NUM
PR_CHR:		CALL	SELCHR
						;DS:SI = VRAM CHR
						;ES:DI = SCR ADDR
GB_CHR:		MOV	CH,128
		MOV	CL,0

		MOV	DH,0

@@LOOP:		REPT	8

		LODSW
		MOV	DX,AX

		TWOPIX
		TWOPIX
		TWOPIX
		TWOPIX

		ADD	DI,320-8
		ENDM

		SUB	DI,320*8
		RET

		ENDIF

;*********************************
;	    PRINT A CHR
;	      CX = XY
;        BX = CHR ADDRESS
;*********************************

		MACRO	PIX4

		RCL	DH,1
		SETC	AL
		ADD	AL,AL
		RCL	DL,1
		ADC	AL,CH

		RCL	DH,1
		SETC	AH
		ADD	AH,AH
		RCL	DL,1
		ADC	AH,CH

		BSWAP	EAX

		RCL	DH,1
		SETC	AH
		ADD	AH,AH
		RCL	DL,1
		ADC	AH,CH

		RCL	DH,1
		SETC	AL
		ADD	AL,AL
		RCL	DL,1
		ADC	AL,CH

		BSWAP	EAX
		STOSD
		ENDM

	
PR_XY:		MOV	DL,CH
		MOV	DH,0
		MOV	AX,320
		MUL	DX
		MOV	CH,0
		ADD	AX,CX
		MOV	DI,AX
						;BX = CHR NUM
PR_CHR:		CALL	SELCHR
						;DS:SI = VRAM CHR
						;ES:DI = SCR ADDR
GB_CHR:		MOV	CH,128
		MOV	CL,0

		EVEN

@@LOOP:		REPT	8

		LODSW
		MOV	DX,AX

		PIX4
		PIX4

		ADD	DI,320-8
		ENDM

		SUB	DI,320*8
		RET

;*********************************
;	    PRINT A SPR
;	      CX = XY
;        BX = CHR ADDRESS
;*********************************

A_SPR:		
		MOV	AX,[CS:DISPMEM]
		MOV	ES,AX

		MOV	CH,[BX+0]
		SUB	CH,8

		MOV	CL,[BX+1]

		MOV	BX,[BX+2]
		MOV	[CS:SPRATTR],BH

		MOV	BH,0

		CMP	CH,8*18			;DO SOME CLIPPING
		JNC	@@EXIT

		CMP	CL,8*21
		JNC	@@EXIT

		CALL	SPR_XY
@@EXIT:		RET

;*********************************
;	    PRINT A SPR
;	      CX = XY
;        BX = CHR ADDRESS
;*********************************

SPR_XY:		MOV	DL,CH
		MOV	DH,0
		MOV	AX,320
		MUL	DX
		MOV	CH,0
		ADD	AX,CX
		MOV	DI,AX

		ADD	BX,BX
		ADD	BX,BX
		ADD	BX,BX
		ADD	BX,BX
		ADD	BX,8000H
		MOV	SI,BX

		MOV	CX,8

		TEST	[BYTE LCDC],00000100B
		JZ	@@8X8

		MOV	CX,16

@@8X8:		TEST	[BYTE CS:SPRATTR],00100000B	
		JNZ	@@MIRROR

		EVEN

@@LOOP:		LODSW

       		CALL	PIXEL
		INC	DI       
		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL

		ADD	DI,320-7
		LOOP	@@LOOP
		RET

@@MIRROR:	ADD	DI,8

		EVEN

@@L2:		LODSW

       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL

		ADD	DI,320+7
		LOOP	@@L2
		RET

;*********************************
;	    PRINT 1 PIXEL
;*********************************

PIXEL:		CMP	[BYTE ES:DI],85H
		JZ	@@EXIT

		MOV	DL,0
		RCL	AH,1
		ADC	DL,0
		ADD	DL,DL
		RCL	AL,1
		ADC	DL,0
		ADD	DL,124

		CMP	DL,124
		JZ	@@EXIT

		MOV	[ES:DI],DL

@@EXIT:		RET

;*********************************
;	  DISPLAY SPRITES
;*********************************

SPRATTR		DB	0

DISPSPR:	MOV	DS,[CS:Z80_SEG]

		MOV	BX,0FE00H
		MOV	CX,40

@@LOOP:		PUSH	CX
		PUSH	BX

		CALL	A_SPR

		POP	BX
		POP	CX

		ADD	BX,4
		LOOP	@@LOOP     
		RET

;*********************************
;          SET UP COLORS
;*********************************

SET_COLORS:	;MOV	SI,OFFSET COLOR_BUF
		MOV	CX,256
		MOV	BX,0
		JMP	SETCOL

;*********************************
;	     SET COLORS
;	     ~~~~~~~~~~
;	   SI = COLOR TAB
;	   CX = AMOUNT
;          BX = START COLOR
;*********************************

TEMPC		DB	0,0,0

SETCOL:		PUSH	CX

		MOV	AL,[CS:SI]
		SHR	AL,1
		SHR	AL,1
		MOV	[CS:TEMPC],AL

		MOV	AL,[CS:SI+1]
		SHR	AL,1
		SHR	AL,1
		MOV	[CS:TEMPC+1],AL

		MOV	AL,[CS:SI+2]
		SHR	AL,1
		SHR	AL,1
		MOV	[CS:TEMPC+2],AL

		MOV	DX,OFFSET TEMPC
		MOV	ES,[CS:CODERAM]
		MOV	CX,1

		MOV	AX,1012H		;SET RGB REG
		INT	10H

		POP	CX

		INC	BX
		ADD	SI,3

		LOOP	SETCOL
		RET

;*********************************
;   SET COLORS 0 - 3 AS GAMEBOY
;    VGA COLS START 128 - 131
;*********************************

MONO_COLS:

COL0:		DB	000H,000H,000H		;BLACK
COL1:		DB	03FH,03FH,03FH		;GREY #7F OR #3F
COL2:		DB	07FH,07FH,07FH		;GREY #7F OR #3F
COL3:		DB	0BFH,0BFH,0BFH		;WHITE

		DB	01FH,01FH,01FH		;BLACK ISH
		DB	000H,000H,080H		;BLACK ISH

SET_MONO:	MOV	SI,OFFSET MONO_COLS
		MOV	CX,6
		MOV	BX,128
		JMP	SETCOL

;*********************************
;
;*********************************

OLD_BGP			DB	0
OLD_OBP0		DB	0
OLD_OBP1		DB	0

SET_BGP_PAL:	MOV	BX,131

		MOV	AL,[DS:BGP]
		CMP	AL,[CS:OLD_BGP]
		JZ	@@NOSET

		MOV	[CS:OLD_BGP],AL
				
		AND	AL,3
		CALL	GET_GB_PAL

		MOV	AL,[DS:BGP]
		SHR	AL,1
		SHR	AL,1
		AND	AL,3
       		CALL	GET_GB_PAL

		MOV	AL,[DS:BGP]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		AND	AL,3
		CALL	GET_GB_PAL

		MOV	AL,[DS:BGP]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

@@NOSET:
		RET

;*********************************
;	  SPR PAL 0 AT 124
;*********************************

SET_SPR0_PAL:	
		MOV	BX,126

		MOV	AL,[DS:OBP0]
		CMP	AL,[CS:OLD_OBP0]
		JZ	@@NOSET

		MOV	[CS:OLD_OBP0],AL

		CALL	GET_GB_PAL

		MOV	BX,127
		MOV	AL,[DS:OBP0]
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

		MOV	BX,124
		MOV	AL,[DS:OBP0]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

		MOV	BX,125
		MOV	AL,[DS:OBP0]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

@@NOSET:
		RET

;*********************************
;	  SPR PAL 1 AT 124
;*********************************

SET_SPR1_PAL:	
		MOV	BX,116

		MOV	AL,[DS:OBP1]
		CMP	AL,[CS:OLD_OBP1]
		JZ	@@NOSET

		MOV	[CS:OLD_OBP1],AL

		CALL	GET_GB_PAL

		MOV	BX,117
		MOV	AL,[DS:OBP1]
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

		MOV	BX,114
		MOV	AL,[DS:OBP1]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

		MOV	BX,115
		MOV	AL,[DS:OBP1]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

@@NOSET:
		RET

;*********************************
;
;*********************************

GET_GB_PAL:	PUSH	BX

		MOV	SI,OFFSET COL0

		AND	AL,3
		JZ	@@OK

		MOV	SI,OFFSET COL1

		CMP	AL,1
		JZ	@@OK

		MOV	SI,OFFSET COL2

		CMP	AL,2
		JZ	@@OK

		MOV	SI,OFFSET COL3

@@OK:		MOV	CX,1
		CALL	SETCOL

		POP	BX

		DEC	BX
		RET
