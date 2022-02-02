;*****************************************************************************
;			      DISASSEMBLER
;*****************************************************************************

DISCUR		DW	0100H		;DISPLAY TOP
DIS_ADDR	DW	0100H		;CURSOR ADDRESS

;*********************************
;	   GET SCAN CODED KEY
;  AH = SCAN CODE : AL = ASCII
;*********************************

GET_KEY:
		MOV		AH,0
		INT		16H
;		JZ		@@NOKEY

		RET
@@NOKEY:
		XOR		AX,AX
		RET


;*********************************
;    SCROLL UP AND DOWN WINDOW
;*********************************

DIS_WINDOW:
;		MOV	AX,[WORD CS:Z80_PC]
;		MOV	[WORD CS:DISCUR],AX
;		MOV	[WORD CS:DIS_ADDR],AX

@@LOOP:
		CALL	DIS_ASS
		CALL	DRAW_REGS

@@LP:	CALL	GET_KEY
;		AND		AL,AL
;		JZ		@@LP

		CMP		AL,"X"
		JZ		@@EXIT

		CMP		AL,"x"
		JZ		@@EXIT

		CALL	CONTROL_KEYS
		JMP		@@LOOP

@@EXIT:	RET

;*********************************
;	WAIT FOR KEY RELEASE
;*********************************

CTRLTAB:
		DB	72
		DW	DIS_U

		DB	80
		DW	DIS_D				

		DB	73
		DW	DIS_PU				

		DB	81
		DW	DIS_PD				

		DB	71
		DW	DIS_HOME

		DB	60
		DW	DIS_BP

		DB	65
		DW	DIS_TRACE

		DB	66
		DW	DIS_TRACE_OVER

		DB	67
		DW	DIS_GOFAST		

		DB	63
		DW	SHOW_SCR		

		DB	68
		DW	DIS_FASTTRACE

		DB	0

CONTROL_KEYS:
		MOV		SI,OFFSET CTRLTAB

@@LOOP:	CMP		[BYTE CS:SI],0
		JZ		@@QUIT

		CMP		[BYTE CS:SI],AH
		JZ		@@FOUND

		ADD		SI,3
		JMP		@@LOOP

@@FOUND:
		CALL	[WORD CS:SI+1]			;DO COMMAND
		STC		
		RET
		
@@QUIT:	CLC
		RET

;*********************************
;
;*********************************

SHOW_SCR:
		CALL	SET_VGA

		CALL	FORCE_SCR
		CALL	GET_KEY

		CALL	SET_TEXT_MODE
		CALL	UPDATE_MON
		RET
		
;*********************************
;	   CURSOR DOWN
;*********************************

DIS_D:
		MOV		BX,[CS:DISCUR]
		CALL	GET_INST_LEN

		MOV		BX,[CS:DISCUR]
		ADD		BX,[CS:INSTLEN]
		MOV		[CS:DISCUR],BX
	
		CALL	DIS_ASS

		CMP		[BYTE CS:CURFOUND],1
		JZ		@@OK		

		MOV		BX,[CS:DISTOP]
		CALL	GET_INST_LEN

		MOV		BX,[CS:DIS_ADDR]
		ADD		BX,[CS:INSTLEN]
		MOV		[CS:DIS_ADDR],BX

@@OK:	RET

;*********************************
;	   CURSOR DOWN
;*********************************

DIS_U:
		DEC		[WORD CS:DISCUR]
		CALL	DIS_ASS

		CMP		[BYTE CS:CURFOUND],1
		JZ		@@OK		

		DEC		[WORD CS:DISCUR]
		CALL	DIS_ASS

		CMP		[BYTE CS:CURFOUND],1
		JZ		@@OK		

		DEC		[WORD CS:DISCUR]
		CALL	DIS_ASS
		
@@OK:
		CMP		[BYTE CS:CURFOUND],1
		JZ		@@DONE		

		SUB		[WORD CS:DIS_ADDR],3

@@DONE:
		RET

;*********************************
;	   CURSOR PAGE DOWN
;*********************************

DIS_PD:
		MOV		CX,10
@@LOOP:
		PUSH	CX
		CALL	DIS_D
		POP		CX
		LOOP	@@LOOP

		RET

;*********************************
;	   CURSOR PAGE DOWN
;*********************************

DIS_PU:
		MOV		CX,7
@@LOOP:
		PUSH	CX
		CALL	DIS_U
		POP		CX
		LOOP	@@LOOP
		RET

;*********************************
;	   TRACE COMMAND
;*********************************

DIS_TRACE:
     	MOV	[WORD CS:BREAK],0
		CALL	TRACEONE

		MOV	SI,[WORD CS:Z80_PC]
		MOV	[CS:DISCUR],SI

		CALL	CHECK_CUR
		RET

;*********************************
;	   TRACE COMMAND
;*********************************

DIS_TRACE_OVER:	
		MOV		[WORD CS:BREAK],0
		CALL	TRACEOVER

		MOV		SI,[WORD CS:Z80_PC]
		MOV		[CS:DISCUR],SI

		CALL	CHECK_CUR
		RET

;*********************************
;	   GO FAST COMMAND
;*********************************

DIS_GOFAST:
		CALL	SET_VGA

		CALL	TRACEONE
		CALL	GOFAST

		MOV	SI,[WORD CS:Z80_PC]
		MOV	[CS:DISCUR],SI

		CALL	SET_TEXT_MODE
		CALL	UPDATE_MON
		CALL	CHECK_CUR
		RET

;*********************************
;	   GO FAST COMMAND
;*********************************

DIS_FASTTRACE:

		CALL SETKEYINT

		MOV	[WORD CS:BREAK],0

@@LOOP:
		CALL	TRACEONE

		MOV	SI,[WORD CS:Z80_PC]
		MOV	[CS:DISCUR],SI

		CALL	CHECK_CUR
		CALL	DIS_ASS
		CALL	DRAW_REGS
		
		CMP	[WORD CS:BREAK],0
		JNZ	@@STOP

		MOV	SI,[WORD CS:Z80_PC]
		CALL	TEST_BP
		JC	@@STOP

		KEY	ESC_KEY
		JZ	@@LOOP

@@STOP:
		CALL RESKEYINT
		RET

;*********************************
;	   SET BP COMMAND
;*********************************

DIS_BP:		MOV	SI,[CS:DISCUR]
		CALL	PUT_BP
		RET

;*********************************
;
;*********************************

DIS_HOME:
		MOV	AX,[WORD CS:Z80_PC]
		MOV	[WORD CS:DISCUR],AX
		MOV	[WORD CS:DIS_ADDR],AX

		CALL	CHECK_CUR
		RET

;*********************************
;
;*********************************

CHECK_CUR:
		CALL	DIS_ASS

		CMP		[BYTE CS:CURFOUND],1
		JZ		@@OK		

		MOV	AX,[WORD CS:Z80_PC]
		MOV	[WORD CS:DISCUR],AX
		MOV	[WORD CS:DIS_ADDR],AX

		CALL	DIS_PU

		MOV	AX,[WORD CS:Z80_PC]
		MOV	[WORD CS:DISCUR],AX

@@OK:
		RET

;*********************************
;	DISASSEMBLE TO WINDOW
;*********************************

CURFOUND	DB	0
DISTOP		DW	0

DIS_ASS:
		MOV	[BYTE CS:CURFOUND],0

		MOV	SI,[CS:DIS_ADDR]
		MOV	[CS:DISTOP],SI

		MOV	CX,0C01H
		CALL	SETPOS_REAL

		MOV	CX,37		;37
@@LOOP:
		PUSH	SI
		PUSH	CX

		MOV	[CS:ATTR],0011110B

;		CALL	SWITCH_CACHE
		CALL	SWITCH_CUR
		CALL	SWITCH_BP


		MOV		BX,SI
		CALL	SHOW_WORD_HEX

;		CALL	SWITCH_CACHE
		CALL	SWITCH_BP
		CALL	SWITCH_CUR

;		CALL	SHOW_PC_MARK

		CALL	HEX_INFO

		PUSH	SI

		MOV		AL,15
		CALL	SPACES

		mov		ax,si
		call	HUNT_ADD

		MOV		AL,30
		CALL	SPACES

		POP	SI

		MOV		BX,SI
		CALL	GET_INST_LEN
		CALL	PRINTINST

		MOV		AL,59
		CALL	SPACES
		
		CALL	ENT
		CALL	CURR

		POP	CX
		POP	SI

		AND	CX,CX
		JZ	@@QUIT

		ADD	SI,[CS:INSTLEN]
		LOOP	@@LOOP

@@QUIT:
		RET

;*********************************
;	   SHOW CURSOR MARKER
;*********************************

SWITCH_CUR:	
		CMP	SI,[WORD CS:DISCUR]
		JNZ	@@QUIT

		MOV	[CS:ATTR],0101110B

		MOV	[BYTE CS:CURFOUND],1
		RET

@@QUIT:	RET

;*********************************
;	   SHOW CURSOR MARKER
;*********************************

SWITCH_BP:
			CALL	TEST_BP
			JNC	@@QUIT

			MOV	[CS:ATTR],01000111B
@@QUIT:		RET

;*********************************
;	  SHOW HEX INFO
;*********************************

HEX_INFO:

		PUSH	SI
 		PUSH	BX
 
 		CALL	SPACE
		
 		MOV		BX,SI

		PUSH	BX
		CALL	GET_INST_LEN
		POP		BX
		
		MOV		CX,[CS:INSTLEN]

@@LOOP:	
		PUSH	BX	

 		CALL	GET_MEMORY_AL
		MOV		BL,AL

		CALL	SHOW_BYTE_HEX
		CALL	SPACE

		POP		BX
		
		INC		BX
		LOOP	@@LOOP

		POP		BX
		POP		SI
		RET
		
;*****************************************************************************
;			    BREAKPOINT CODE
;*****************************************************************************

;********************************
;	 BREAKPOINT LIST
;********************************

;FORMAT		ADDR,OLD,FLAG

BP_OPC		= 0004H

BP_LIST		DB	 5*32 DUP (0)

BP_ADDR		= 0
BP_OLD		= 2
BP_FLAG		= 4

BP_NULL		= 0
BP_SET		= 1
BP_TEMP		= 2

;*********************************
;	 SET BREAKPOINTS
;*********************************

SET_BP:
		MOV		CX,32		
		MOV		SI,OFFSET BP_LIST

@@LOOP:
		CMP		[BYTE CS:SI+BP_FLAG],0
		JZ		@@NOBP

		MOV		BX,[CS:SI+BP_ADDR]	;GET ADDRESS

		CALL	GET_MEMORY_AL
		MOV		[CS:SI+BP_OLD],AL	;SAVE IT
		
		MOV		AL,0FDH				;BP_OPC
		CALL 	PUT_MEMORY_AL

@@NOBP:
		ADD	SI,5
		LOOP	@@LOOP
		RET

;*********************************
;	 RESET BREAKPOINTS
;*********************************

RES_BP:
		MOV		CX,32		
		MOV		SI,OFFSET BP_LIST

@@LOOP:
		CMP		[BYTE CS:SI+BP_FLAG],0
		JZ		@@NOBP

		MOV		BX,[CS:SI+BP_ADDR]	;GET ADDRESS
		MOV		AL,[CS:SI+BP_OLD]	;GET OLD CODE

		CALL 	PUT_MEMORY_AL

		CMP		[BYTE CS:SI+BP_FLAG],BP_TEMP
		JNZ		@@NOBP

		MOV		[BYTE CS:SI+BP_FLAG],0

@@NOBP:
		ADD		SI,5
		LOOP	@@LOOP
		RET

;*********************************
;	  TEST BREAKPOINTS
;*********************************

TEST_BP:
		MOV		CX,32		
		MOV		BX,OFFSET BP_LIST

@@LOOP:
		CMP		[BYTE CS:BX+BP_FLAG],0
		JZ		@@NOBP

		CMP		[CS:BX+BP_ADDR],SI
		JNZ		@@NOBP

		STC
		RET

@@NOBP:
		ADD		BX,5
		LOOP	@@LOOP

		CLC
		RET

;*********************************
;	   SET BREAKPOINT
;	    SI = ADDRESS
;*********************************

PUT_BP:
		CALL	TEST_BP
		JNC		@@NOBP

		MOV		[BYTE CS:BX+BP_FLAG],0
		RET

@@NOBP:
		MOV		CX,32		
		MOV		BX,OFFSET BP_LIST

@@LOOP:
		CMP		[BYTE CS:BX+BP_FLAG],0
		JZ		@@OK

		ADD		BX,5
		LOOP	@@LOOP
		RET

@@OK:
		MOV		[BYTE CS:BX+BP_FLAG],BP_SET
		MOV		[CS:BX+BP_ADDR],SI
		RET

;*********************************
;	   SET BREAKPOINT
;	    SI = ADDRESS
;*********************************

PUT_TEMP_BP:
		CALL	TEST_BP
		JC		@@QUIT

		MOV		CX,32		
		MOV		BX,OFFSET BP_LIST

@@LOOP:	CMP		[BYTE CS:BX+BP_FLAG],0
		JZ		@@OK

		ADD		BX,5
		LOOP	@@LOOP
		RET

@@OK:	MOV		[BYTE CS:BX+BP_FLAG],BP_TEMP
		MOV		[CS:BX+BP_ADDR],SI
@@QUIT:	RET

;*********************************
;      CLEAR ALL BREAKPOINT
;*********************************

CLR_BP:	
		MOV		CX,32		
		MOV		BX,OFFSET BP_LIST

@@LOOP:
		MOV		[BYTE CS:BX+BP_FLAG],0
		ADD		BX,5
		LOOP	@@LOOP
		RET

;*********************************
;  
;*********************************

UPDATE_MON:
		CALL	PRINT
		DB	13,10,"Gameboy GBMON Symbolic debugger v1.5",13,10
		DB	"(C) Copyright A.R.Hartley 1992-99",13,10,13,10,0

		CALL	Draw
		DB	OFFS,11,0
		DB	COL,0011110B
		DB	BOX,0,0,39,80-18

		DB	OFFS,11,62
		DB	COL,0011110B
		DB	BOX,0,0,39,18
		DB	STOP

		call	DIS_ASS
		CALL	DRAW_REGS
		RET
		
;*********************************
;  
;*********************************
		
DRAW_REGS:
		CALL	Draw

		DB	OFFS,11,62
		DB	COL,0011010B

		DB	AT,02,2,"HL  = ",SHOW16
		DW	OFFSET Z80_HL,OFFSET OLD_Z80_HL

		DB	AT,03,2,"DE  = ",SHOW16
		DW	OFFSET Z80_DE,OFFSET OLD_Z80_DE

		DB	AT,04,2,"BC  = ",SHOW16
		DW	OFFSET Z80_BC,OFFSET OLD_Z80_BC

		DB	AT,05,2,"A   = ",SHOW8
		DW	OFFSET Z80_AF+1,OFFSET OLD_Z80_AF+1

		DB	AT,06,2,"SP  = ",SHOW16
		DW	OFFSET Z80_SP,OFFSET OLD_Z80_SP

		DB	AT,07,2,"PC  = ",SHOW16
		DW	OFFSET Z80_PC,OFFSET OLD_Z80_PC

		DB	AT,10,2,"FLAGS - "
		
		DB	COL,0011110B
		DB	SWITCHCOL		;COMMAND
		DW	OFFSET FLAGS	;VAR LOC
		DB	6,00000110B		;BIT,COL
		DB	"Z"

		DB	COL,0011110B
		DB	SWITCHCOL		;COMMAND
		DW	OFFSET FLAGS	;VAR LOC
		DB	0,00000110B		;BIT,COL
		DB	"C"


		DB	STOP
	
		RET
		
;********************************
;	TRACE OVER FUNCTION
;********************************

TRACEOVER:
		MOV		BX,[CS:DISCUR]
		CALL	GET_MEMORY_AL
		
		CMP		AL,0CDH				;CALL NN
		JZ		@@TOVER

		AND		AL,11100111B		;CALL CC,NN
		CMP		AL,11000100B
		JZ		@@TOVER
		
		AND		AL,11000111B		;RES T
		CMP		AL,11000111B
		JZ		@@TOVER
		
		JMP		TRACEONE

@@TOVER:
		CALL SETKEYINT
	
		MOV		BX,[CS:Z80_PC]
		CALL	GET_INST_LEN

		MOV		SI,[CS:Z80_PC]
		ADD		SI,[CS:INSTLEN]
		CALL	PUT_TEMP_BP

		MOV		[WORD CS:BREAK],0	;CLEAR BREAK VALUE
		CALL	SET_BP				;SET ALL BREAKPOINTS

@@LOOP:
		CALL	ONE_INST			;DO IT

		CMP		[WORD CS:BREAK],0	;KEEP DOING IT UNTIL BP
		JNZ		@@STOP

		KEY		ESC_KEY
		JZ		@@LOOP

@@STOP:
		CALL	RES_BP
		CALL 	RESKEYINT
		RET

;********************************
;	    TRACE ONE
;********************************

TRACEONE:
		CALL	ONE_INST
		RET

;********************************
;	   GO FULL SPEED
;********************************

GOFAST:
		CALL SET_VGA
		CALL SETKEYINT
		CALL SCR_DIRTY

		MOV	[WORD CS:BREAK],0	;CLEAR BREAK VALUE
		CALL	SET_BP			;SET ALL BREAKPOINTS

@@LOOP:
		CALL	ONE_INST		;DO IT

		CMP	[WORD CS:BREAK],0	;KEEP DOING IT UNTIL BP
		JNZ	@@STOP

		KEY	ESC_KEY
		JZ	@@LOOP

@@STOP:
		CALL	RES_BP

		CALL RESKEYINT
		CALL SET_TEXT_MODE
		RET
				
