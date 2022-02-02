;*****************************************************************************
;			       INPUT DATA
;*****************************************************************************

INPUT_CLEAR:	CALL	CLEAR_INP

INPUT_DATA:	MOV	[CS:CURADDR],0
		MOV	[CS:VALIDATE],0

		MOV	AX,[CS:ENTRYCNT]	;NUMBER OF ENTRYS
		MOV	[CS:THISENTRY],AX	;COPIED TO THIS ONE

@@LOOP:		CALL	WAIT_FLY

		MOV	DS,[CS:INPUTRAM]

		CALL	DISP_INPUT

		CALL	GET_KEY
		AND	AL,AL
		JZ	@@NOKEY

		CMP	AL,13
		JZ	EDIT_ENTER

		CMP	AL,""
		JZ	EDIT_QUIT

		CALL	EDIT_KEYS
		JC	@@KEYHIT

		CALL	VALIDTEST
		JC	@@NOKEY

		CALL	CLR_VALID

		CALL	PUT_CHR
		CALL	CURSOR_R

@@KEYHIT:	MOV	[CS:INSERTCOUNT],-1
		CALL	DISP_INPUT

		CALL	EDIT_RELEASE
		JMP	@@LOOP

@@NOKEY:	MOV	[CS:KEYREPEAT],60
		JMP	@@LOOP

;*********************************
;	    ENTRY ENTERED
;*********************************

EDIT_ENTER:	CALL	WAIT_RELEASE

		MOV	[CS:CURADDR],-1
		CALL	DISP_INPUT

		CALL	STORE_INPUT		;@@ NEW PREV BUFF

		CLC
		RET

;*********************************
;	     QUIT EDIT
;*********************************

EDIT_QUIT:	CALL	WAIT_RELEASE

		MOV	[CS:CURADDR],-1
		CALL	DISP_INPUT

		MOV	[CS:INPUTERROR],1

		STC
		RET

;*********************************
;	ACCEPT CONTROL KEYS
;*********************************

INPCTRLTAB:
		DB	""
		DW	OFFSET GET_LAST_ENTRY

		DB	""
		DW	OFFSET GET_NEXT_ENTRY

		DB	""	
		DW	OFFSET CURSOR_R

		DB	""	
		DW	OFFSET CURSOR_L

		DB	""
		DW	OFFSET CURSOR_BS

		DB	14
		DW	OFFSET CURSOR_DEL

		DB	26
		DW	OFFSET CURSOR_HOME

		DB	25
		DW	OFFSET CURSOR_END

		DB	15
		DW	OFFSET SET_INSERT

		DB	0

EDIT_KEYS:	MOV	SI,OFFSET INPCTRLTAB
		JMP	TEST_KEYS

;*********************************
;	TEST FOR CONTROL KEY
;*********************************

TEST_KEYS:

@@LOOP:		CMP	[BYTE CS:SI],0
		JZ	@@QUIT

		CMP	[BYTE CS:SI],AL
		JZ	@@FOUND

		ADD	SI,3
		JMP	@@LOOP

@@FOUND:	CALL	[WORD CS:SI+1]			;DO COMMAND
		STC		
		RET
		
@@QUIT:		CLC
		RET


;****************************************
;  TEST FOR LABELS,DECIMAL,HEX,BINARY
;    CYSET IF NOT IN THIS CATAGORY
;****************************************

VALIDTEST:	CMP	AL,32
		JNC	@@GOODCHR

@@BADCHR:	STC
		RET

@@GOODCHR:	CLC
		RET

;****************************************
;  TEST FOR LABELS,DECIMAL,HEX,BINARY
;    CYSET IF NOT IN THIS CATAGORY
;****************************************

VALIDCHR	DB	" 1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ™Ž_.-*"
		DB	"abcdefghijklmnopqrstuvwxyz"
		DB	"?!#$%&()=?:;_\/+><',@œ${[]}|"
		DB	34,255

IF	0

VALIDTEST:	PUSH	BX

		MOV	BX,OFFSET VALIDCHR

@@LOOP:		CMP	[BYTE CS:BX],255
		JZ	@@BADCHR

		CMP	[CS:BX],AL
		JZ	@@GOODCHR

		INC	BX
		JMP	@@LOOP

@@BADCHR:	POP	BX
		STC
		RET

@@GOODCHR:	POP	BX
		CLC
		RET
ENDIF

;*********************************
;	 PUT A CHARACTER
;*********************************

PUT_CHR:	CALL	INSERT_CHAR

PUT_CHRA:	MOV	BX,[CS:CURADDR]
		MOV	AH,[DS:BX]

		CALL	VALIDTEST
		JC	@@QUIT

		MOV	[DS:BX],AL
@@QUIT:		RET

;*********************************
;	 GET A CHARACTER
;*********************************

GET_CHR:	MOV	BX,[CS:CURADDR]
		MOV	AH,[DS:BX]
		RET

;*********************************
;	    SET INSERT
;*********************************

SET_INSERT:	XOR	[WORD CS:INSERTMODE],1
		RET

;*********************************
;	   CURSOR RIGHT
;*********************************

CURSOR_R:	CALL	MAKE_VALID

		MOV	BX,[CS:CURADDR]
 		MOV	AL,[DS:BX+1]

		CMP	AL,13
		JZ	@@SKIPENT

		;CMP	AL,","
		;JZ	@@SKIP

		CMP	AL,0
		JZ	@@STOP

		INC	BX
		MOV	[CS:CURADDR],BX
@@STOP:		RET

@@SKIPENT:	INC	BX

@@SKIP:		ADD	BX,2
		MOV	[CS:CURADDR],BX
		RET

;*********************************
;	   CURSOR LEFT
;*********************************

CURSOR_L:	CALL	MAKE_VALID

		MOV	BX,[CS:CURADDR]
		MOV	AL,[DS:BX-1]

		CMP	AL,10
		JZ	@@SKIPENT

		;CMP	AL,","
		;JZ	@@SKIP

		CMP	BX,0
		JZ	@@STOP

		DEC	BX
		MOV	[CS:CURADDR],BX
@@STOP:		RET

@@SKIPENT:	DEC	BX

@@SKIP:		SUB	BX,2
		MOV	[CS:CURADDR],BX
		RET

;*********************************
;      CURSOR HOME ON LINE
;*********************************

CURSOR_HOME:

		CALL	MAKE_VALID
		MOV	CX,0

@@LOOP:		MOV	BX,[CS:CURADDR]
		MOV	AL,[DS:BX-1]

		CMP	AL,10
		JZ	@@FOUND
		CMP	BX,0
		JZ	@@FOUND

		CALL	CURSOR_L
		INC	CX

		JMP	@@LOOP

@@FOUND:	RET

;*********************************
;      CURSOR HOME ON LINE
;*********************************

CURSOR_END:
		CALL	MAKE_VALID

		MOV	BX,[CS:LASTNOTSPACE]
		CMP	BX,[CS:INPUTLEN]
		JNZ	@@OK
     		DEC	BX
@@OK:		MOV	[CS:CURADDR],BX
		RET

;*********************************
;	   STEP FORWARD
;*********************************

STEP_FORWARD:	AND	CX,CX
		JZ	@@QUIT

@@LOOP:		CALL	CURSOR_R

		MOV	BX,[CS:CURADDR]
		MOV	AL,[DS:BX+1]

		CMP	AL,13
		JZ	@@QUIT

		CMP	AL,0
		JZ	@@QUIT

		LOOP	@@LOOP
@@QUIT:		RET

;*********************************
;	   CURSOR DOWN
;*********************************

CURSOR_D:	CALL	CURSOR_HOME
		
	 	PUSH	CX
		CALL	CURSOR_END
		POP	CX

		INC	CX
		CALL	STEP_FORWARD
		RET

;*********************************
;	   CURSOR DOWN
;*********************************

CURSOR_U:	CALL	CURSOR_HOME
		
	 	PUSH	CX
		CALL	CURSOR_L
		CALL	CURSOR_HOME
		POP	CX

		CALL	STEP_FORWARD
		RET

;*********************************
;	       ENTER
;*********************************

CURSOR_ENTER:	CALL	CURSOR_HOME
		CALL	CURSOR_D		
		RET

;*********************************
;	        TAB
;*********************************

CURSOR_TAB:
@@LOOP:		MOV	BX,[CS:CURADDR]
		MOV	AL,[DS:BX+1]

		CMP	AL,13
		JZ	CURSOR_ENTER

		CMP	AL,0
		JZ	CURSOR_ENTER

		;CMP	AL,","
		;JZ	@@FOUND

		CALL	CURSOR_R
		JMP	@@LOOP

@@FOUND:	CALL	CURSOR_R
		RET

;*********************************
;	     BACKSPACE
;*********************************

CURSOR_BS:
		CALL	MAKE_VALID

	    	CMP	[WORD CS:INSERTMODE],1
		JZ	@@BSINS

		CALL	CURSOR_L
		MOV	AL,32
		CALL	PUT_CHRA
	  	RET

@@BSINS:	CMP	[CS:CURADDR],0
		JZ	@@QUIT

		CALL	CURSOR_L
		CALL	DELETE_CHAR
@@QUIT:	  	RET

;*********************************
;	     DELETE
;*********************************

CURSOR_DEL:
		CALL	CLR_VALID
		CALL	DELETE_CHAR
	 	RET

;*********************************
;	    INSERT CHARS
;*********************************

INSERT_CHAR:	CMP	[WORD CS:INSERTMODE],0
		JZ	@@EXIT

		PUSH	AX

		MOV	DS,[CS:INPUTRAM]

		MOV	CX,[CS:INPUTLEN]
		MOV	SI,CX
		DEC	SI

@@LOOP:		MOV	AX,[CS:CURADDR]
		CMP	SI,AX
		JC	@@QUIT

		CMP	SI,-1
		JZ	@@QUIT

		MOV	AL,[SI-1]
		MOV	[SI],AL
		DEC	SI

		JMP	@@LOOP

@@QUIT:		POP	AX

@@EXIT:		RET

;*********************************
;	    DELETE CHARS
;*********************************

DELETE_CHAR:
		PUSH	AX

		MOV	DS,[CS:INPUTRAM]
		MOV	SI,[CS:CURADDR]

		MOV	CX,[CS:INPUTLEN]
		DEC	CX

@@LOOP:		MOV	AL,[SI+1]
		MOV	[SI],AL
		INC	SI
		LOOP	@@LOOP

@@QUIT:		POP	AX

@@EXIT:		RET


;*********************************
;	  PRINT INPUT DATA
;*********************************

CURADDR		DW	0
EDITXY		DW	0800H
MAXLINES	DW	0
CURSOR_ON	DW	0
DISPADD		DW	0

KEYREPEAT	DW	0
INPUTERROR	DW	0
INSERTMODE	DW	0	;1 = INSERT MODE
INSERTCOUNT	DW	0

VALIDATE	DW	0	;IF 1 HIGHLIGTH

LASTNOTSPACE	DW	0

DISP_INPUT:	MOV	CX,[CS:INPUTXY]		;SET INPUT POS
		CALL	SETPOS			

		MOV	AL,[CS:ATTR]		;SAVE ATTR
		PUSH	AX

		MOV	SI,[CS:DISPADD]
		MOV	DS,[CS:INPUTRAM]
		MOV	CX,[CS:INPUTLEN]

@@LOOP:		PUSH	CX

		LODSB

		CMP	AL,0
		JNZ	@@NOZERO

		MOV	AL,32
		MOV	[SI-1],AL

@@NOZERO:	CMP	AL,32
		JZ	@@SPACE

		MOV	[CS:LASTNOTSPACE],SI

@@SPACE:	PUSH	AX			;SAVE UNDERCHR
		CALL	INPUT_CURSOR
		POP	AX

		CALL	DCHAR

		POP	CX
		LOOP	@@LOOP

		POP	AX			;GET ATTR
		MOV	[CS:ATTR],AL

		MOV	DS,[CS:INPUTRAM]
		MOV	BX,[CS:INPUTLEN]
		MOV	[BYTE BX],0

		INC	[CS:INSERTCOUNT]	;INC BLINK COUNT
		RET

;*********************************
;	 PLOT INPUT CURSOR
;	SI = INPUT POSITION
;*********************************

INPUT_CURSOR:	MOV	[CS:ATTR],00000011B

		MOV	CX,[CS:CURADDR]
		INC	CX
		CMP	SI,CX
		JNZ	@@NOTFOUND

		CMP	[WORD CS:INSERTMODE],0
		JZ	@@NOTINSERT
	    
		MOV	AX,[CS:INSERTCOUNT]
		AND	AX,16
		JZ	@@NOTFOUND		;BLINK

@@NOTINSERT:	MOV	[CS:ATTR],00110000B

@@NOTFOUND:	MOV	CX,[CS:CURADDR]
		INC	CX
		CMP	SI,CX
		JNC	@@EXIT

		CMP	[CS:VALIDATE],0
		JZ	@@EXIT

		MOV	[CS:ATTR],01110000B
@@EXIT:		RET

;*********************************
;     COPY INPUT DATA TO CS:DI
;*********************************

COPY_INPUT:	MOV	DS,[CS:INPUTRAM]
		MOV	CX,[CS:INPUTLEN]
		MOV	SI,0

@@LOOP:		MOV	AL,[DS:SI]
		MOV	[CS:DI],AL
		INC	DI
		INC	SI
		LOOP	@@LOOP

		MOV	[BYTE CS:DI],13
		RET

;*********************************
;	    WAIT RELEASE
;*********************************

WAIT_RELEASE:	CALL	WAIT_FLY

		MOV	DI,[CS:LASTKEYTAB]
		CMP	[BYTE CS:DI],0
		JNZ	WAIT_RELEASE
@@QUIT:		RET

;*********************************
;	WAIT FOR KEY RELEASE
;*********************************

RELEASE:	DEC	[CS:KEYREPEAT]
		JZ	@@QUIT

		CALL	WAIT_FLY

		MOV	DI,[CS:LASTKEYTAB]
		CMP	[BYTE CS:DI],0
		JNZ	RELEASE

@@QUIT:		MOV	[CS:KEYREPEAT],2
		RET

;*********************************
;	WAIT FOR KEY RELEASE
;*********************************

EDIT_RELEASE:	DEC	[CS:KEYREPEAT]
		JZ	@@QUIT

		CALL	WAIT_FLY

		MOV	DI,[CS:LASTKEYTAB]
		CMP	[BYTE CS:DI],0
		JNZ	EDIT_RELEASE

@@QUIT:		MOV	[CS:KEYREPEAT],4
		RET

;*********************************
;          CLEAR TEXT SCREEN
;*********************************

CLS:		MOV	AX,0B800H
		MOV	ES,AX
		MOV	DI,0

		MOV	AX,0000H

		MOV	CX,80*50
		REP	STOSW
    		RET

;*****************************************************************************
;			    PRINTING SYSTEM
;*****************************************************************************

;*********************************
;          PRINT COMMAND
;*********************************

STOP		=	0
AT		=	1
COL		=	2
SPC		=	3
BOX		=	4
PRSTR		=	5
INP		=	6
OFFS		=	7

SHOW32		=	0ffh-0
SWITCHCOL	=	0ffh-1
DEC32		=	0ffh-2
BIN32		=	0ffh-3
BIN16		=	0ffh-4
DEC16		=	0ffh-5
SHOW16		=	0ffh-6
SHOW8		=	0ffh-7
BIN8		=	0ffh-8

INPUTLEN	DW	10
INPUTXY		DW	10
OFFXY		DW	0

PRINT:		MOV	[CS:OLDBX],BX
		POP	BX		;GET STK ADDRESS

@@LOOP:
		MOV	AL,[CS:BX]	;GET BYTE FROM STRING

		CMP	AL,STOP
		JZ	@@END

		CMP	AL,OFFS
		JZ	@@SETOFFS

		CMP	AL,SWITCHCOL
		JZ	@@SWITCH

		CMP	AL,SHOW32
		JZ	@@SHOW32

		CMP	AL,SHOW16
		JZ	@@SHOW16

		CMP	AL,SHOW8
		JZ	@@SHOW8

		CMP	AL,DEC32
		JZ	@@DEC32

		CMP	AL,DEC16
		JZ	@@DEC16

		CMP	AL,BIN32
		JZ	@@BIN32

		CMP	AL,BIN16
		JZ	@@BIN16

		CMP	AL,BIN8
		JZ	@@BIN8

		CMP	AL,PRSTR
		JZ	@@PRSTR

		CMP	AL,INP
		JZ	@@INP

		CMP	AL,AT
		JZ	@@AT

		CMP	AL,BOX
		JZ	@@BOX

		CMP	AL,COL
		JZ	@@COL

		CMP	AL,SPC
		JZ	@@SPC

		;CMP	AL,"%"
		;JZ	@@ERRORNO

		CMP	AL,"?"
		JNZ	@@QUEST

		MOV	AL," "

@@QUEST:	PUSH	BX
		CALL	PRCHAR
		CALL	CURR
		POP	BX

		INC	BX
		JMP	@@LOOP

@@END:		INC	BX
		PUSH	BX

		MOV	BX,[CS:OLDBX]
		RET

@@AT:		MOV	CH,[CS:BX+1]
		MOV	CL,[CS:BX+2]
		CALL	SETPOS
		
		ADD	BX,3
		JMP	@@LOOP


@@BOX:		MOV	CH,[CS:BX+1]
		MOV	CL,[CS:BX+2]
		CALL	SETPOS
		
		MOV	CH,[CS:BX+3]
		MOV	CL,[CS:BX+4]

		PUSH	BX
		CALL	PRINT_BOX
		POP	BX

		ADD	BX,5
		JMP	@@LOOP

@@COL:		MOV	AL,[CS:BX+1]
		MOV	[CS:ATTR],AL
		
		ADD	BX,2
		JMP	@@LOOP

@@SPC:		MOV	CL,[CS:BX+1]
		XOR	CH,CH
		
		MOV	AL,[CS:BX+2]

		PUSH	BX

@@LOOP2:	PUSH	CX
		PUSH	AX
		CALL	PRCHAR
		CALL	CURR
		POP	AX
		POP	CX
		LOOP	@@LOOP2	

		POP	BX

		ADD	BX,3
		JMP	@@LOOP

@@PRSTR:	PUSH	BX
		PUSH	SI
		MOV	SI,[CS:BX+1]

@@STRLP:	MOV	AL,[CS:SI]
		CMP	AL,STOP
		JZ	@@LAST
		
		CALL	PRCHAR
		CALL	CURR
	
		INC	SI
		JMP	@@STRLP

@@LAST:		POP	SI
		POP	BX

		ADD	BX,3
		JMP	@@LOOP

@@INP:		PUSH	BX
		MOV	AL,[CS:BX+1]
		MOV	AH,0
		MOV	[CS:INPUTLEN],AX

		MOV	AX,[CS:LASTXY]
		MOV	[CS:INPUTXY],AX

		MOV	DI,[CS:BX+2]

		PUSH	DI
		CALL	INPUT_CLEAR
		POP	DI

		CMP	[CS:INPUTERROR],1
		JZ	@@NOCOPY
		
		CALL	COPY_INPUT
@@NOCOPY:	POP	BX

		ADD	BX,4
		JMP	@@LOOP

@@SETOFFS:	MOV	AX,[CS:BX+1]
		XCHG	AL,AH
		MOV	[CS:OFFXY],AX
		ADD	BX,3
		JMP	@@LOOP


@@SHOW32:	PUSH	BX

		MOV	AL,[CS:ATTR]
		PUSH	AX

		AND	[CS:ATTR],0FEH

		MOV	SI,[CS:BX+1]
		MOV	EAX,[DWORD CS:SI]
		MOV	SI,[CS:BX+3]
		CMP	EAX,[DWORD CS:SI]
		JZ	@@NOSET

		MOV	[DWORD CS:SI],EAX
		OR	[CS:ATTR],1

@@NOSET:	CALL	SHOW_32

		POP	AX
		MOV	[CS:ATTR],AL

		POP	BX

		ADD	BX,5

		JMP	@@LOOP

@@SHOW16:	PUSH	BX

		MOV	AL,[CS:ATTR]
		PUSH	AX

		AND	[CS:ATTR],0FEH

		MOV	SI,[CS:BX+1]
		MOV	AX,[WORD CS:SI]
		MOV	SI,[CS:BX+3]
		CMP	AX,[WORD CS:SI]
		JZ	@@NOSETXX

		MOV	[WORD CS:SI],AX
		OR	[CS:ATTR],1

@@NOSETXX:	CALL	SHOW_16

		POP	AX
		MOV	[CS:ATTR],AL

		POP	BX

		ADD	BX,5

		JMP	@@LOOP

@@SHOW8:	PUSH	BX

		MOV	AL,[CS:ATTR]
		PUSH	AX

		AND	[CS:ATTR],0FEH

		MOV	SI,[CS:BX+1]
		MOV	AL,[BYTE CS:SI]
		MOV	SI,[CS:BX+3]
		CMP	AL,[BYTE CS:SI]
		JZ	@@NOSETYY

		MOV	[BYTE CS:SI],AL
		OR	[CS:ATTR],1

@@NOSETYY:	CALL	SHOW_8

		POP	AX
		MOV	[CS:ATTR],AL

		POP	BX

		ADD	BX,5

		JMP	@@LOOP



@@DEC32:	PUSH	BX

		MOV	AL,[CS:ATTR]
		PUSH	AX

		AND	[CS:ATTR],0FEH

		MOV	SI,[CS:BX+1]
		MOV	EAX,[DWORD CS:SI]
		MOV	SI,[CS:BX+3]
		CMP	EAX,[DWORD CS:SI]
		JZ	@@NOSET2

		MOV	[DWORD CS:SI],EAX
		OR	[CS:ATTR],1

@@NOSET2:	CALL	PUTSIGNED

		POP	AX
		MOV	[CS:ATTR],AL

		POP	BX

		ADD	BX,5

		JMP	@@LOOP

@@DEC16:	PUSH	BX

		MOV	AL,[CS:ATTR]
		PUSH	AX

		AND	[CS:ATTR],0FEH

		MOV	SI,[CS:BX+1]
		MOVZX	EAX,[WORD CS:SI]
		MOV	SI,[CS:BX+3]
		CMP	AX,[WORD CS:SI]
		JZ	@@NOSETX

		MOV	[WORD CS:SI],AX
		OR	[CS:ATTR],1

@@NOSETX:	CALL	PUTSIGNED

		POP	AX
		MOV	[CS:ATTR],AL

		POP	BX

		ADD	BX,5

		JMP	@@LOOP



@@BIN32:	PUSH	BX

		MOV	AL,[CS:ATTR]
		PUSH	AX

		AND	[CS:ATTR],0FEH

		MOV	SI,[CS:BX+1]
		MOV	EAX,[DWORD CS:SI]
		MOV	SI,[CS:BX+3]
		CMP	EAX,[DWORD CS:SI]
		JZ	@@NOSET3

		MOV	[DWORD CS:SI],EAX
		OR	[CS:ATTR],1

@@NOSET3:	CALL	BIN_32

		POP	AX
		MOV	[CS:ATTR],AL

		POP	BX

		ADD	BX,5

		JMP	@@LOOP

@@BIN16:	PUSH	BX

		MOV	AL,[CS:ATTR]
		PUSH	AX

		AND	[CS:ATTR],0FEH

		MOV	SI,[CS:BX+1]
		MOV	AX,[WORD CS:SI]
		MOV	SI,[CS:BX+3]
		CMP	AX,[WORD CS:SI]
		JZ	@@NOSET4

		MOV	[WORD CS:SI],AX
		OR	[CS:ATTR],1

@@NOSET4:	CALL	BIN_16

		POP	AX
		MOV	[CS:ATTR],AL

		POP	BX

		ADD	BX,5

		JMP	@@LOOP

@@BIN8:		PUSH	BX

		MOV	AL,[CS:ATTR]
		PUSH	AX

		AND	[CS:ATTR],0FEH

		MOV	SI,[CS:BX+1]
		MOV	AL,[BYTE CS:SI]
		MOV	SI,[CS:BX+3]
		CMP	AL,[BYTE CS:SI]
		JZ	@@NOSET4D

		MOV	[BYTE CS:SI],AL
		OR	[CS:ATTR],1

@@NOSET4D:	CALL	BIN_8

		POP	AX
		MOV	[CS:ATTR],AL

		POP	BX

		ADD	BX,5

		JMP	@@LOOP

@@SWITCH:	PUSH	BX

		MOV	SI,[CS:BX+1]
		MOV	EAX,[DWORD CS:SI]
		MOV	CL,[CS:BX+3]
		
		INC	CL
		SHR	EAX,CL

		JNC	@@NOPE

		MOV	AL,[CS:BX+4]
		MOV	[BYTE CS:ATTR],AL

@@NOPE:		POP	BX

		ADD	BX,5
		JMP	@@LOOP

@@ERRORNO:	PUSH	BX
		
		MOVZX	EAX,[WORD CS:ERRORPC]
		CALL	SHOW_32

		POP	BX
		INC	BX
		JMP	@@LOOP

;*********************************
;      GET CHRACTER POSITION
;	      CX = YX
;*********************************

CHPOS:		ADD	CL,[BYTE CS:OFFXY]
		ADD	CH,[BYTE CS:OFFXY+1]

CHPOS_REAL:	PUSH	DX
		MOV	AL,CH
		MOV	AH,0

		MOV	DX,80*2
		MUL	DX

		MOV	CH,0
		SHL	CX,1

		ADD	AX,CX
		POP	DX
		RET		

;*********************************
;	SET SCREEN POSITION
;*********************************

LASTXY		DW	0

SETPOS:		MOV	[CS:LASTXY],CX

		CALL	CHPOS
		MOV	[CS:SCRADD],AX
		RET

;*********************************
;	SET SCREEN POSITION
;*********************************

SETPOS_REAL:	MOV	[CS:LASTXY],CX

		CALL	CHPOS_REAL
		MOV	[CS:SCRADD],AX
		RET

;*********************************
;	PRINT A CHAR DIRECT
;
;	 AL = CHR  TO PRINT
;	 AH = ATTR TO PRINT
;  [SCRADD] = SCREEN ADDR
;*********************************

SCRADD		DW	20
SCRSEG		DW	0B800H
ATTR		DB	9

PRCHAR:		MOV	AH,[CS:ATTR]

CHAR:		PUSH	BX
		MOV	ES,[CS:SCRSEG]
		MOV	BX,[CS:SCRADD]
		MOV	[ES:BX],AL
		MOV	[ES:BX+1],AH
		POP	BX
		RET	   	

;*********************************
;	   PRINT SPACE
;*********************************

SPACE:		MOV	AL,32

DCHAR:		PUSH	BX
		CALL	PRCHAR
		CALL	CURR
		POP	BX
		RET

;*********************************
;	   CURSOR RIGHT
;*********************************

CURR:		PUSH	BX

		MOV	BX,[CS:SCRADD]
		ADD	BX,2
		
		CMP	BX,8000
		JC	@@OK

		SUB	BX,8000

@@OK:		MOV	[CS:SCRADD],BX

		INC	[BYTE CS:LASTXY]
		CMP	[BYTE CS:LASTXY],80
		JNZ	@@QUIT

		MOV	[BYTE CS:LASTXY],0

		INC	[BYTE CS:LASTXY+1]
		CMP	[BYTE CS:LASTXY+1],50
		JNZ	@@QUIT
			
		MOV	[BYTE CS:LASTXY+1],0

@@QUIT:		POP	BX
		RET

;*********************************
;	   ENTER COMMAND
;*********************************

ENT:		MOV	AX,[CS:LASTXY]

		XOR	AL,AL
		INC	AH

		CMP	AH,50
		JC	@@OK

		;XOR	AH,AH

@@OK:		MOV	[CS:LASTXY],AX

		MOV	CX,AX
		CALL	SETPOS_REAL
		RET	

;*********************************
;	      TAB TO AL
;*********************************

TAB:		MOV	AH,[BYTE CS:LASTXY+1]
		MOV	[CS:LASTXY],AX

		MOV	CX,AX
		CALL	SETPOS_REAL
		RET	

;*********************************
;	        SPACES
;*********************************

SPACES:	
		CMP	AL,80			;CHECK FOR ERRORS
		JC	@@LOOP			;JUMP IF OK

		MOV	AL,79			;SET TO LIMIT
     		
@@LOOP:		CMP	[BYTE CS:LASTXY],AL
		JZ	@@OK

		PUSH	AX
		CALL	SPACE
		POP	AX

		JMP	@@LOOP
       
@@OK:		RET	

;*********************************
;     PRINT A BOX FROM SCRADD
; 	 CH = Y : CL = X
;*********************************

PRINT_BOX:	SUB	CH,2
		JC	@@ERROR

		MOV	DL,"Ú"
		MOV	DH,"Ä"
		MOV	AL,"¿"
		CALL	BOXLINE

@@LOOP:		MOV	DL,"³"
		MOV	DH," "
		MOV	AL,"³"
		CALL	BOXLINE
       
		DEC	CH
		JNZ	@@LOOP
	
		MOV	DL,"À"
		MOV	DH,"Ä"
		MOV	AL,"Ù"
		CALL	BOXLINE
@@ERROR:	RET

;*********************************
;	 PRINT A BOX LINE
; 	 DL,DH,AL CL LEN
;*********************************

BOXLINE:	PUSH	CX

		XOR	CH,CH

		SUB	CX,2
		JC	@@ERROR

		MOV	BX,[CS:SCRADD]
		PUSH	BX

		PUSH	AX

		MOV	AL,DL		;PRINT FIRST
		CALL	PRCHAR
		CALL	CURR

@@LOOP:		MOV	AL,DH		;PRINT FIRST
		CALL	PRCHAR
		CALL	CURR

		LOOP	@@LOOP

		POP	AX		;PRINT LAST
		CALL	PRCHAR
		CALL	CURR

		POP	BX
		ADD	BX,160		;NEXT LINE
		MOV	[CS:SCRADD],BX

@@ERROR:	POP	CX
		RET

;*********************************
;	  SHOW 32 BIT HEX
;*********************************

SHOW_32:	MOV	EBX,EAX
		JMP	SHOW_LONG_HEX

SHOW_16:	MOV	BX,AX
		JMP	SHOW_WORD_HEX

SHOW_8:		MOV	BL,AL
		JMP	SHOW_BYTE_HEX

;*********************************
;	   SHOW LONG HEX
;	     EBX = NUM
;*********************************

SHOW_LONG_HEX: 	ROR	EBX,16
		CALL	SHOW_WORD_HEX
		ROR	EBX,16
		JMP	SHOW_WORD_HEX

;*********************************
;	   SHOW WORD HEX
;	     BX = NUM
;*********************************

SHOW_WORD_HEX: 	ROR	BX,8
		CALL	SHOW_BYTE_HEX
		ROR	BX,8
		JMP	SHOW_BYTE_HEX

;*********************************
;	   SHOW BYTE HEX
;	     BL = NUM
;*********************************

HEXTAB		DB	"0123456789ABCDEF"

SHOW_BYTE_HEX:
		PUSH	BX
		XOR	BH,BH

		PUSH	BX

		SHR	BL,4
		MOV	AL,[CS:BX+OFFSET HEXTAB]
		CALL	PRCHAR
		CALL	CURR

		POP	BX		

		AND	BL,0FH
		MOV	AL,[CS:BX+OFFSET HEXTAB]
		CALL	PRCHAR
		CALL	CURR
		POP	BX
		RET

;*********************************
;	   SHOW BINARY
;	    AL = BYTE
;*********************************

SHOW_BYTE_BIN:
		MOV	CX,8
		MOV	DL,AL

@@LOOP:		MOV	DH,"0"

		SHL	DL,1
		JNC	@@NOT1

		MOV	DH,"1"

@@NOT1:		PUSH	DX
		MOV	AL,DH
		CALL	DCHAR
		POP	DX

		LOOP	@@LOOP
		RET

;*********************************
;	   SHOW BINARY
;	    EAX = LONG
;*********************************

BIN_32:
		MOV	CX,32
		MOV	EBX,EAX

@@LOOP:		MOV	DH,"0"

		SHL	EBX,1
		JNC	@@NOT1

		MOV	DH,"1"

@@NOT1:		PUSH	EBX
		MOV	AL,DH
		CALL	DCHAR

		MOV	AL,CL
		DEC	AL

		AND	AL,AL
		JZ	@@NN

		AND	AL,11B
		JNZ	@@NN

		;MOV	AL,"-"
		;CALL	DCHAR

@@NN:		POP	EBX

		LOOP	@@LOOP
		RET

;*********************************
;	   SHOW BINARY
;	    AX = LONG
;*********************************

BIN_16:
		MOV	CX,16
		MOV	BX,AX

@@LOOP:		MOV	DH,"0"

		SHL	BX,1
		JNC	@@NOT1

		MOV	DH,"1"

@@NOT1:		PUSH	EBX
		MOV	AL,DH
		CALL	DCHAR
		POP	EBX

		LOOP	@@LOOP
		RET

;*********************************
;	   SHOW BINARY
;	    EAX = LONG
;*********************************

BIN_8:
		MOV	CX,8
		MOV	BL,AL

@@LOOP:		MOV	DH,"0"

		SHL	BL,1
		JNC	@@NOT1

		MOV	DH,"1"

@@NOT1:		PUSH	EBX
		MOV	AL,DH
		CALL	DCHAR

		MOV	AL,CL
		DEC	AL

		AND	AL,AL
		JZ	@@NN

		AND	AL,11B
		JNZ	@@NN

		;MOV	AL,"-"
		;CALL	DCHAR

@@NN:		POP	EBX

		LOOP	@@LOOP
		RET

;*****************************************************************************
;		     GET PREVIOUS ENTRYS IN INPUT
;*****************************************************************************

ENTRYPTR	DW	OFFSET ENTRYBUF
ENTRYCNT	DW	0
THISENTRY	DW	0

ENTRYBUF	DB	-1
		DB	1023 DUP (0)

;*********************************
;  STORE INPUT DATA TO BUFFER
;*********************************

STORE_INPUT:	
		CALL	ENTRY_EXIST		;ALREADY PRESENT
		JC	@@QUIT			;JUMP IF SO

		CALL	REMOVE_ONE		;MAKE SPACE IF NEEDED

		MOV	DS,[CS:INPUTRAM]
		MOV	SI,[CS:DISPADD]

		MOV	ES,[CS:CODERAM]
		MOV	DI,[CS:ENTRYPTR]

		MOV	CX,[CS:LASTNOTSPACE]

		AND	CX,CX
		JZ	@@QUIT

		CMP	CX,1
		JZ	@@QUIT

		CMP	CX,64
		JNC	@@QUIT

		REP	MOVSB

		XOR	AL,AL			;TERMINATE STRING
		STOSB

		MOV	[CS:ENTRYPTR],DI	;SAVE NEXT PTR LOC

		MOV	AL,-1			;TERMINATE LIST
		STOSB

		INC	[WORD CS:ENTRYCNT]
@@QUIT:		RET

;*********************************
; CHECK IF ENTRY ALREADY EXISTS
;*********************************

ENTRY_EXIST:
		MOV	DS,[CS:INPUTRAM]
		MOV	SI,[CS:DISPADD]
		MOV	BX,[CS:LASTNOTSPACE]
		MOV	[BYTE DS:SI+BX],13

		MOV	CX,[CS:ENTRYCNT]
		AND	CX,CX
		JZ	@@NO

		MOV	DX,0

@@LOOP:		MOV	AX,DX

		PUSH	DX
		PUSH	CX
		CALL	FIND_ENTRY
		POP	CX
		POP	DX

		JC	@@NO

		MOV	DS,[CS:INPUTRAM]
		MOV	SI,[CS:DISPADD]

@@CMPLP:	MOV	AL,[CS:DI]
		AND	AL,AL
		JZ	@@ZERO

		CMP	AL,-1
		JZ	@@NO

		CMP	AL,[DS:SI]
		JNZ	@@CONT

		INC	SI
		INC	DI
		JMP	@@CMPLP

@@ZERO:		CMP	[BYTE DS:SI],13
		JZ	@@YES

@@CONT:		INC	DX
		LOOP	@@LOOP

@@NO:		CLC
		RET	

@@YES:		STC
		RET

;*********************************
;	GET LAST INPUT ENTRY
;*********************************

GET_LAST_ENTRY:
		;CALL	WAIT_RELEASE

		DEC	[CS:THISENTRY]
		MOV	AX,[CS:THISENTRY]
		CALL	RESTORE_INPUT
		JNC	@@OK

		INC	[CS:THISENTRY]

@@OK:		RET

;*********************************
;
;*********************************

GET_NEXT_ENTRY:
		;CALL	WAIT_RELEASE

		INC	[CS:THISENTRY]
		MOV	AX,[CS:THISENTRY]
		CALL	RESTORE_INPUT
		JNC	@@OK

		DEC	[CS:THISENTRY]

@@OK:		RET


;*********************************
;	 CLEAR INPUT RAM
;*********************************

CLEAR_INP:	PUSH	DI
		PUSH	CX
		PUSH	AX

		MOV	DI,0			;CLEAR OUT THE INPUT BUFFER
		MOV	ES,[CS:INPUTRAM]
		MOV	CX,[CS:INPUTLEN]
		ADD	CX,2
		MOV	AL,32
		REP	STOSB

		POP	AX
		POP	CX
		POP	DI
	  	RET

;*********************************
;	  RESTORE INPUT
;       AX = RECORD NUMBER
;*********************************

RESTORE_INPUT:
		CALL	FIND_ENTRY
		JC	@@ERROR
	
		MOV	[CS:VALIDATE],1
		CALL	CLEAR_INP

		MOV	DS,[CS:INPUTRAM]
		MOV	SI,0
		XOR	DX,DX

@@LOOP:		MOV	AL,[CS:DI]
		AND	AL,AL
		JZ	@@END

		CMP	AL,13
		JZ	@@END

		MOV	[DS:SI],AL
		INC	SI
		INC	DI

		INC	DX
		JMP	@@LOOP		

@@END:		
		CMP	DX,[CS:INPUTLEN]
		JNZ	@@OK

		DEC	DX

@@OK:		MOV	[CS:CURADDR],DX
		CLC

@@ERROR:	RET

;********************************
;	  FIND AN ENTRY
;	   AX = NUMBER
;OUT:      DI = ENTRY ADDRESS
;********************************

FIND_ENTRY:	MOV	DI,OFFSET ENTRYBUF
		MOV	CX,AX

@@LOOP:		CMP	[BYTE CS:DI],-1		;SAY CANT FIND IT
		JZ	@@ERROR

		AND	CX,CX
		JZ	@@OK

@@SKIP:		CMP	[BYTE CS:DI],0
		JZ	@@NEXT

		INC	DI		
		JMP	@@SKIP

@@NEXT:		INC	DI			;SKIP 0

		DEC	CX
		JMP	@@LOOP

@@OK:		CLC
		RET

@@ERROR:	STC
		RET

;*********************************
;	 REMOVE ONE ENTRY
;	    IF NEEDED
;*********************************

REMOVE_ONE:	CMP	[WORD CS:ENTRYPTR],OFFSET ENTRYBUF+896
		JC	@@QUIT

@@LOOP:		MOV	AL,[BYTE CS:ENTRYBUF]
		CMP	AL,-1
		JZ	@@QUIT

		CMP	AL,0
		JZ	@@ONEMORE

		CALL	SCROLLENTRY
		JMP	@@LOOP

@@ONEMORE:	DEC	[WORD CS:ENTRYCNT]
		JMP	SCROLLENTRY

@@QUIT:		RET

;*********************************
;     SCROLL BACK BUFFER 1
;*********************************
      
SCROLLENTRY:
		MOV	DS,[CS:CODERAM]
		MOV	SI,OFFSET ENTRYBUF+1

		MOV	ES,[CS:CODERAM]
		MOV	DI,OFFSET ENTRYBUF

		MOV	CX,1023
		REP	MOVSB

		DEC	[WORD CS:ENTRYPTR]
		RET
	
;*********************************
;	  CLEAR VALIDATE
;*********************************

CLR_VALID:	PUSH	AX

		CMP	[CS:VALIDATE],0
		JZ	@@NOCLR

		CALL	CLEAR_INP
		MOV	[CS:CURADDR],0
		MOV	[CS:VALIDATE],0

@@NOCLR:	POP	AX
	     	RET

;*********************************
;	  CLEAR VALIDATE
;*********************************

MAKE_VALID:	MOV	[CS:VALIDATE],0
	     	RET
