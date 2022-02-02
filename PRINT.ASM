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

DRAW:
		MOV	[CS:OLDBX],BX
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
		
;		MOVZX	EAX,[WORD CS:ERRORPC]
;		CALL	SHOW_32

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

SETPOS_REAL:
		MOV	[CS:LASTXY],CX

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

PRCHAR:
		MOV	AH,[CS:ATTR]

CHAR:
		PUSH	BX
		push	es
		MOV	ES,[CS:SCRSEG]
		MOV	BX,[CS:SCRADD]
		MOV	[ES:BX],AL
		MOV	[ES:BX+1],AH
		pop		es
		POP		BX
		RET	   	

;*********************************
;	   PRINT SPACE
;*********************************

SPACE:
		MOV	AL,32

DCHAR:
		PUSH	BX
		CALL	PRCHAR
		CALL	CURR
		POP		BX
		RET

;*********************************
;	   CURSOR RIGHT
;*********************************

CURR:
		PUSH	BX

		MOV	BX,[CS:SCRADD]
		ADD	BX,2
		
		CMP	BX,8000
		JC	@@OK

		SUB	BX,8000

@@OK:
		MOV	[CS:SCRADD],BX

		INC	[BYTE CS:LASTXY]
		CMP	[BYTE CS:LASTXY],80
		JNZ	@@QUIT

		MOV	[BYTE CS:LASTXY],0

		INC	[BYTE CS:LASTXY+1]
		CMP	[BYTE CS:LASTXY+1],50
		JNZ	@@QUIT
			
		MOV	[BYTE CS:LASTXY+1],0

@@QUIT:
		POP	BX
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

SHEXTAB		DB	"0123456789ABCDEF"

SHOW_BYTE_HEX:
		PUSH	BX
		XOR	BH,BH

		PUSH	BX

		SHR	BL,4
		MOV	AL,[CS:BX+OFFSET SHEXTAB]
		CALL	PRCHAR
		CALL	CURR

		POP	BX		

		AND	BL,0FH
		MOV	AL,[CS:BX+OFFSET SHEXTAB]
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
