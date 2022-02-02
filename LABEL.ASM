;*****************************************************************************
;			     LABEL HANDLING
;
;STRUCTURE: 	TYPE(B),VALUE(L),NAMELEN(B),NAME(NAMELEN)
;
;*****************************************************************************

TYPE_NULL	=	00H		;NOTHING

TYPE_REDEF	=	01H		;=
TYPE_EQU	=	02H		;EQU

TYPE_SLONG	=	03H		;VAR LONG SIGNED
TYPE_ULONG	=	04H		;VAR LONG UNSIGNED

TYPE_SWORD	=	05H		;VAR WORD SIGNED
TYPE_UWORD	=	06H		;VAR WORD UNSIGNED

TYPE_UBYTE	=	07H		;VAR BYTE SIGNED
TYPE_SBYTE	=	08H		;VAR BYTE UNSIGNED

;TYPE_SPACE	=	09H		;DEFSPACE
TYPE_PROC	=	0AH		;PROCEDURE

TYPE_FIXED	=	0BH		;FIXED POINT NUMBER
TYPE_FLOAT	=	0CH		;FLOATING POINT NUMBER
TYPE_EXTRA	=	0DH		;FLOATING POINT NUMBER

TYPE_DIRECT	=	80H		;DIRECTIVE
TYPE_COMMAND	=	81H		;A COMMAND
TYPE_FUNC	=	82H		;FUNCTION
TYPE_OPER	=	83H		;MATHS OPERATER
TYPE_FIXUP	=	84H		;MACRO FIXUP
TYPE_TOKEN	=	85H		;SYSTEM TOKEN
TYPE_USERDEF	=	86H		;USER DEFINABLE
TYPE_IDENTIF	=	87H		;A TABLE IDENTIFIER
TYPE_PROTO	=	88H		;A FUNCTION PROTOTYPE
TYPE_MARKER	=	89H		;LINE ADDRESS MARKER
TYPE_MACRO	=	8AH		;MACRO
TYPE_STRUCT	=	8BH		;STRUCTURE
TYPE_INTFUNC	=	8CH		;INT EXP FUNCTION
TYPE_EXECTOKEN	=	8DH		;EXECUTABLE SYSTEM TOKEN

TYPE_END	=	0E0H
TYPE_PASS1	=	0E1H		;PASS 1 ERROR TYPE             

TYPE_STORAGE	=	0F0H		;STORAGE FOR FUNCTION PARAMETERS
TYPE_OPCODE	=	0F1H		;STORAGE OPCODE

;*********************************
;     CLEAR OUT LABEL TABLE
;*********************************

CLR_LAB_TAB:	MOV	CX,SYMBANKS
		MOV	ES,[CS:SYMRAM]		;AT LABTAB SEGMENT

@@NEXT:		PUSH	CX

		MOV	AX,0			;FILL WITH NULL
		MOV	CX,8000H		;FILL #8000 WORDS
		MOV	DI,0
		REP	STOSW

		POP	CX

		MOV	AX,ES
		ADD	AX,1000H
		MOV	ES,AX		

		LOOP	@@NEXT

		RET

;*********************************
;	 STORE NAME BUFFER
;*********************************

STORE_LABEL:	MOV	AX,[CS:CODERAM]
		MOV	ES,AX
		MOV	DS,AX

	       	MOV	SI,OFFSET LABNAME
	       	MOV	DI,OFFSET COPYLABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		
		MOV	CX,256
		REP	MOVSB
		RET	   

;*********************************
;	  RESTORE NAME BUFFER
;*********************************

RESTORE_LABEL:	MOV	AX,[CS:CODERAM]
		MOV	ES,AX
		MOV	DS,AX

	       	MOV	DI,OFFSET LABNAME
	       	MOV	SI,OFFSET COPYLABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		
		MOV	CX,256
		REP	MOVSB
		RET

;*********************************
;   GET LABEL NAME IN FILERAM
;	PUT IT IN LABBUF
;*********************************

LABLEN		DW	0

GET_LABEL_NAME:	
		CALL	GETCHR	    		;@@NEW STUFF
		CALL	VALID_LAB
		JC	GET_ANY_NAME

@@NOPE:		MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

@@LOOP:		CALL	GETCHR
		CALL	VALID_LAB
		JC	@@END

		STOSB
		INC	DX

		CMP	DX,250
		JNC	@@TOOBIG

		CALL	NEXTCHR
		JMP	@@LOOP

@@END:		CMP	DX,0
		JZ	@@ERR1

		MOV	[CS:LABLEN],DX
		RET

@@ERR1:		CERROR	"Unexpected character or illegal Label length"
@@TOOBIG:	CERROR	"Label too big"

;****************************************
;  TEST FOR LABELS,DECIMAL,HEX,BINARY
;    CYSET IF NOT IN THIS CATAGORY
;****************************************

VALID_LAB:	TSTR	"1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_."
		RET

;*********************************
;    GET FUNCTION PARAMETERS
;	PUT IT IN LABBUF
;*********************************

GET_PARAM:	MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

		CALL	GETCHR

		CMP	AL,"("
		JNZ	@@ERR1

		STOSB
		INC	DX

		CALL	NEXTCHR

@@LOOP:		CALL	GETCHR
		STOSB

		INC	DX

		CMP	AL,13
		JZ	@@MISS

		CMP	AL,")"
		JZ	@@END

		CMP	DX,250
		JNC	@@TOOBIG

		CALL	NEXTCHR
		JMP	@@LOOP

@@END:		CALL	NEXTCHR			;SKIP ')'

		MOV	[CS:LABLEN],DX
		RET

@@TOOBIG:	CERROR	"parameters too big"
@@MISS:		CERROR	"Userdef or functions end missing ')'"
@@ERR1:		CERROR	"Function and Userdef parameters must be bound with '('"

;*********************************
;     GET QUOTE BOUND STRING
;	PUT IT IN LABBUF
;*********************************

GET_QUOTES:	MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

		CALL	GETCHR

		CMP	AL,34			;'""
		JZ	@@OK

		CMP	AL,"'"
		JNZ	@@MISS

@@OK:		MOV	CL,AL

		STOSB
		INC	DX

		CALL	NEXTCHR

@@LOOP:		CALL	GETCHR
		STOSB

		INC	DX

		CMP	AL,13
		JZ	@@MISS

		CMP	AL,CL			;END QUOTE
		JZ	@@END

		CMP	DX,250
		JNC	@@TOOBIG

		CALL	NEXTCHR
		JMP	@@LOOP

@@END:		CALL	NEXTCHR			;SKIP ')'

		MOV	[CS:LABLEN],DX
		RET

@@TOOBIG:	CERROR	"parameters too long"
@@MISS:		CERROR	"Parameter must be bound in quotes"

;*********************************
;       GET ANY NAME DATA
;	PUT IT IN LABBUF
;*********************************

GET_ANY_NAME:	MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

@@LOOP:		CALL	GETCHR

		CALL	VALID_END
		JNC	@@END

		STOSB
		INC	DX

		CMP	DX,250
		JNC	@@TOOBIG

		CALL	NEXTCHR
		JMP	@@LOOP

@@END:		CMP	DX,0
		JZ	@@ERR1

		MOV	[CS:LABLEN],DX
		RET

@@ERR1:		CERROR	"Unexpected character or illegal operator length"
@@TOOBIG:	CERROR	"Operator too big"

;****************************************
;        TEST FOR ENDING CHARS
;    CYSET IF NOT IN THIS CATAGORY
;****************************************

VALID_END:	CALL	DO_INSTR
		DB	" ,:;(){}"
		DB	9
		DB	13
		DB	0
		RET

;*********************************
;       GET FILE NAME DATA
;	 PUT IT IN LABBUF
;*********************************

GET_FILE_NAME:	MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

@@LOOP:		CALL	GETCHR

		CALL	VALID_FILE_END
		JNC	@@END

		STOSB
		INC	DX

		CMP	DX,250
		JNC	@@TOOBIG

		CALL	NEXTCHR
		JMP	@@LOOP

@@END:		CMP	DX,0
		JZ	@@ERR1

		MOV	[CS:LABLEN],DX
		RET

@@ERR1:		CERROR	"Unexpected character or illegal filename length"
@@TOOBIG:	CERROR	"Filename too long"

;****************************************
;        TEST FOR ENDING CHARS
;    CYSET IF NOT IN THIS CATAGORY
;****************************************

VALID_FILE_END:	CALL	DO_INSTR
		DB	",;"
		DB	32
		DB	9
		DB	13
		DB	0
		RET

;*********************************
;  GET OPERATOR NAME IN FILERAM
;	PUT IT IN LABBUF
;*********************************

GET_OPER_NAME:
		CALL	GETCHR	    		;@@NEW STUFF
		CALL	VALID_OPER
		JC	GET_ANY_NAME

		MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

@@LOOP:		CALL	GETCHR
		CALL	VALID_OPER
		JC	@@END

		STOSB
		INC	DX

		CMP	DX,250
		JNC	@@TOOBIG

		CALL	NEXTCHR
		JMP	@@LOOP

@@END:		CMP	DX,0
		JZ	@@ERR1

		MOV	[CS:LABLEN],DX
		RET

@@ERR1:		CERROR	"Unexpected character or illegal operator length"
@@TOOBIG:	CERROR	"String too big"

;****************************************
;      TEST FOR VALID OPERATORS
;    CYSET IF NOT IN THIS CATAGORY
;****************************************

VALID_OPER:	TSTR	"+-/*=<>|&%^?"
		RET

;*********************************
;  	 GET OPCODE DATA
;	PUT IT IN LABBUF
;*********************************

GET_OPCODE:	MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

@@LOOP:		CALL	GETCHR
		STOSB
		INC	DX

		CALL	NEXTCHR

		CMP	AL,":"
		JZ	@@END

		CMP	DX,250
		JNC	@@TOOBIG

		JMP	@@LOOP

@@END:		CMP	DX,0
		JZ	@@ERR1

		MOV	[CS:LABLEN],DX
		RET

@@ERR1:		CERROR	"Unexpected character or illegal opcode length"
@@TOOBIG:	CERROR	"Opcode data too long"

;*********************************
;   GET EVERYTHING TO ',' OR ')'
;	 PUT IT IN LABBUF
;*********************************

GET_ALL_NAME:	MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

		MOV	BX,0			;BRACKET COUNT

@@LOOP:		CALL	GETCHR

		CMP	AL,EOF_CHR
		JZ	@@ERR1

		CMP	AL,13
		JZ	@@ERR1

		CMP	AL,"("
		JNZ	@@NOTLB

		INC	BX
		JMP	@@NOTSEMI

@@NOTLB:	CMP	AL,","
		JNZ	@@NOTCOMMA

		CMP	BX,0
		JZ	@@END

		JMP	@@NOTSEMI

@@NOTCOMMA:	CMP	AL,")"
		JNZ	@@NOTRB

		CMP	BX,0
		JZ	@@END

		DEC	BX
		JMP	@@NOTSEMI

@@NOTRB:
		;CMP	AL,";"
		;JNZ	@@NOTSEMI
		;MOV	AL,","

@@NOTSEMI:	STOSB
		INC	DX

		CMP	DX,250
		JNC	@@TOOBIG

		CALL	NEXTCHR
		JMP	@@LOOP

@@END:		CMP	DX,0
		JZ	@@ERR1

		MOV	[CS:LABLEN],DX
		RET

@@ERR1:		CERROR	"Unexpected character or illegal string length"
@@TOOBIG:	CERROR	"string too big"


;*********************************
;      GET EVERYTHING TO ']'
;	 PUT IT IN LABBUF
;*********************************

GET_INDEX_STRING:

		MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	DX,0

		MOV	BX,0			;BRACKET COUNT

@@LOOP:		CALL	GETCHR

		CMP	AL,EOF_CHR
		JZ	@@ERR1

		CMP	AL,13
		JZ	@@ERR1

		CMP	AL,"["
		JNZ	@@NOTLB

		INC	BX
		JMP	@@NOTRB

@@NOTLB:	CMP	AL,"]"
		JNZ	@@NOTRB

		CMP	BX,0
		JZ	@@END

		DEC	BX

@@NOTRB:	STOSB
		INC	DX

		CMP	DX,250
		JNC	@@TOOBIG

		CALL	NEXTCHR
		JMP	@@LOOP

@@END:		CALL	NEXTCHR			;SKIP ']'

		CMP	DX,0
		JZ	@@ERR1

		MOV	[CS:LABLEN],DX
		RET

@@ERR1:		CERROR	"Unexpected character or illegal string length"
@@TOOBIG:	CERROR	"string too big"

;****************************************
;	 UNSTACK AND COPY LABEL
;****************************************

UNSTK_COPY_LABEL:
		CALL	POP_LABEL
		JMP	COPY_LABEL

;****************************************
;	COPY THE LABEL TO OUTPUT
;****************************************

COPY_LABEL:	PUSH	SI
		PUSH	DS
		PUSH	CX

		MOV	SI,OFFSET LABNAME
		MOV	DS,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	CX,[CS:LABLEN]

@@LOOP:		LODSB
		;CALL	OUTCHR
		LOOP	@@LOOP

		POP	CX
		POP	DS
		POP	SI
		RET

;****************************************
;	      PADOUT A LABEL
;****************************************

PADOUT_LABEL:	PUSH	SI
		PUSH	DS
		PUSH	CX

		MOV	SI,OFFSET LABNAME
		MOV	DS,[CS:CODERAM]		;AT LABTAB SEGMENT
		MOV	CX,[CS:LABLEN]

@@LOOP:		LODSB
		;CALL	OUTCHR
		LOOP	@@LOOP

		MOV	CX,12
		SUB	CX,[CS:LABLEN]
		JC	@@QUIT

@@LOOP2:	MOV	AL,32
		;CALL	OUTCHR
		LOOP	@@LOOP2

@@QUIT:		POP	CX
		POP	DS
		POP	SI
		RET

;*********************************
;	    FIND A VALUE
;*********************************

FIND_VALUE:	CALL	PUSH_LABEL

		POP	BX

		MOV	SI,OFFSET LABNAME
		MOV	CX,0

@@LOOP:		MOV	AL,[CS:BX]
		AND	AL,AL
		JZ	@@QUIT

		MOV	[CS:SI],AL
		INC	BX
		INC	SI
		INC	CX
		JMP	@@LOOP

@@QUIT:		MOV	[CS:LABLEN],CX

		INC	BX
		PUSH	BX

		CALL	FIND_LABEL

		CALL	POP_LABEL
		RET

;*********************************
;	    SET A VALUE
;*********************************

SET_VALUE:	CALL	PUSH_LABEL

		POP	DI

		MOV	SI,OFFSET LABNAME
		MOV	CX,0

@@LOOP:		MOV	AL,[CS:DI]
		AND	AL,AL
		JZ	@@QUIT

		MOV	[CS:SI],AL
		INC	DI
		INC	SI
		INC	CX
		JMP	@@LOOP

@@QUIT:		MOV	[CS:LABLEN],CX

		INC	DI
		PUSH	DI

		CALL	SET_REDEF

		CALL	POP_LABEL
		RET

;*********************************
;	 INSERT A SYMBOL
;*********************************

INSERT_SYM:	MOV	AH,0

		POP	SI
		CALL	COPY_LABNAME
		PUSH	SI

		JMP	PUT_LABEL

;*********************************
;	COPY BX TO LABNAME
;*********************************

COPY_LABNAME:	PUSH	EAX
		PUSH	EBX

		MOV	ES,[CS:CODERAM]
		MOV	DS,[CS:CODERAM]
		MOV	DI,OFFSET LABNAME
		MOV	CX,0

@@LOOP:		LODSB
		AND	AL,AL
		JZ	@@END

		STOSB
		INC	CX
		JMP	@@LOOP
		
@@END:		MOV	[CS:LABLEN],CX
		POP	EBX
		POP	EAX
		RET

;*********************************
;      MOVE LABNAME TO DI
;*********************************

MOVE_LABEL:	MOV	ES,[CS:CODERAM]

		MOV	SI,OFFSET LABNAME
		MOV	DS,[CS:CODERAM]

		MOV	CX,[CS:LABLEN]

		REP	MOVSB
		RET

;****************************************
;      	     INSTR COMMAND
;    	  CARRY CLEAR IF FOUND
;****************************************

FOUNDFLAG	DW	0

DO_INSTR:	POP	BX
		MOV	[CS:FOUNDFLAG],0

		MOV	CX,1
		
@@LOOP:		CMP	[BYTE CS:BX],0
		JZ	@@ENDTAB

		CMP	[CS:BX],AL
		JNZ	@@NOTTHIS

		MOV	[CS:FOUNDFLAG],CX

@@NOTTHIS:	INC	BX
		INC	CX
		JMP	@@LOOP

@@ENDTAB:	INC	BX

		CMP	[CS:FOUNDFLAG],0
		JNZ	@@GOODCHR

		STC
		JMP	BX

@@GOODCHR:	CLC
		JMP	BX

;*********************************
;         PUSH ANY LABEL
;	    BX = DATA
;---------------------------------
;	  BX+0 = STKPTR
;	  BX+2 = STKCNT
;	  BX+4 = BUFFER
;*********************************

PUSH_ANY:	MOV	CX,BX
		ADD	CX,1000+4

		MOV	AX,[CS:BX]			;TEST FOR OVERFLOW
		CMP	AX,CX
		JNC	@@ERR1

		INC	[WORD CS:BX+2]

		MOV	DI,[CS:BX]
		MOV	ES,[CS:CODERAM]

		MOV	SI,OFFSET LABNAME
		MOV	DS,[CS:CODERAM]
		
		MOV	CX,[CS:LABLEN]
		
		REP	MOVSB

		MOV	AL,[BYTE CS:LABLEN]
		STOSB

		MOV	[CS:BX],DI

		CLC
		RET

@@ERR1:		STC
		RET

;*********************************
;         POP ANY LABEL
;	    BX = DATA
;---------------------------------
;	  BX+0 = STKPTR
;	  BX+2 = STKCNT
;	  BX+4 = BUFFER
;*********************************

POP_ANY:	MOV	AX,[CS:BX+2]
		CMP	AX,0
		JZ	@@ERR1

		DEC	[WORD CS:BX+2]

		MOV	SI,[CS:BX]
		MOV	DS,[CS:CODERAM]

		MOV	DI,OFFSET LABNAME
		MOV	ES,[CS:CODERAM]
		
		MOV	AL,[SI-1]
		MOV	[BYTE CS:LABLEN],AL	

		MOV	CL,AL
		MOV	CH,0

		SUB	SI,CX
		DEC	SI		
		MOV	[CS:BX],SI

		REP	MOVSB

		CLC
		RET

@@ERR1:		STC
		RET

;*********************************
;   PUSH LABNAME ON LABEL STACK
;*********************************

INIT_LAB_STACKS:
		MOV	[CS:STKLAB1],OFFSET LABSTACK1
		MOV	[CS:LABSTKCNT1],0

		;MOV	[CS:STKLAB2],OFFSET LABSTACK2
		;MOV	[CS:LABSTKCNT2],0

		;MOV	[CS:OPERSTKPTR],OFFSET OPERSTACK
		;MOV	[CS:OPERSTKCNT],0
		RET		

;*********************************
;   PUSH LABNAME ON LABEL STACK
;*********************************

PUSH_LABEL:
		CALL	PUSH_REGS

		MOV	BX,OFFSET STKLAB1
		CALL	PUSH_ANY
		JC	@@ERR1

		CALL	POP_REGS
		RET	   

@@ERR1:		FATAL	"No more space in label stack (PUSH_LABEL)"

;*********************************
;  POP LABNAME OFF LABELSTACK
;*********************************

POP_LABEL:	CALL	PUSH_REGS

		MOV	BX,OFFSET STKLAB1
		CALL	POP_ANY
		JC	@@ERR1

		CALL	POP_REGS
		RET

@@ERR1:		FATAL	"End of label stack reached in (POP_LABEL)"

		IF	0

;*********************************
;   PUSH LABNAME ON LABEL STACK
;*********************************

PUSH_OPERATOR:
		CALL	PUSH_REGS

		MOV	BX,OFFSET OPERSTKPTR
		CALL	PUSH_ANY
		JC	@@ERR1

		CALL	POP_REGS
		RET	   

@@ERR1:		FATAL	"No more space in operator stack (PUSH_OPER)"

;*********************************
;  POP LABNAME OFF LABELSTACK
;*********************************

POP_OPERATOR:
		CALL	PUSH_REGS

		MOV	BX,OFFSET OPERSTKPTR
		CALL	POP_ANY
		JC	@@ERR1

		CALL	POP_REGS
		RET

@@ERR1:		FATAL	"End of label operator stack reached in (POP_OPER)"

;*********************************
;   PUSH LABNAME ON LABEL STACK
;*********************************

XPUSH_LABEL:
		CALL	PUSH_REGS

		MOV	BX,OFFSET STKLAB2
		CALL	PUSH_ANY
		JC	@@ERR1

		CALL	POP_REGS
		RET	   

@@ERR1:		FATAL	"No more space in label stack (XPUSH_LABEL)"

;*********************************
;  POP LABNAME OFF LABELSTACK
;*********************************

XPOP_LABEL:
		CALL	PUSH_REGS

 		MOV	BX,OFFSET STKLAB2
		CALL	POP_ANY
		JC	@@ERR1

		CALL	POP_REGS
		RET

@@ERR1:		FATAL	"End of label stack reached in (XPOP_LABEL)"

		ENDIF

;****************************************
;  COPY CURRENT FILE TO LABEL BUFFER
;	SI = FILE NAME ADDRESS
;****************************************

FILE_TO_LABEL:
		CALL	PUSH_REGS

		MOV	DS,[CS:CODERAM]
		MOV	ES,[CS:CODERAM]

		MOV	DI,OFFSET LABNAME

		MOV	CX,0

@@LOOP:		MOV	AL,[CS:SI]
		CMP	AL,0
		JZ	@@DONE

		INC	CX
		MOVSB

		JMP	@@LOOP

@@DONE:		MOV	[CS:LABLEN],CX

		CALL	POP_REGS
		RET		

;****************************************
;  COPY CURRENT LABEL TO FILE NAME
;	SI = FILE NAME ADDRESS
;****************************************

LABEL_TO_FILE:	CALL	PUSH_REGS

		MOV	DI,SI

		MOV	DS,[CS:CODERAM]
		MOV	ES,[CS:CODERAM]

		MOV	SI,OFFSET LABNAME
		MOV	CX,[CS:LABLEN]

		REP	MOVSB

		MOV	AL,0			;COPY AN EXTRA 0
		STOSB

		CALL	POP_REGS
		RET		

;****************************************
;	    MAKE INTO UPPERCASE
;****************************************

MAKE_UPPER:	MOV	SI,OFFSET LABNAME
		MOV	CX,[CS:LABLEN]
		AND	CX,CX
		JZ	@@QUIT

@@LOOP:		MOV	AL,[CS:SI]
		CALL	UPPERCASE
		MOV	[CS:SI],AL
		INC	SI
		LOOP	@@LOOP

@@QUIT:		RET

;****************************************
;	       MAKE UPPERCASE
;****************************************

UPPERCASE:	CMP	AL,"z"
		JG	@@EXIT

		CMP	AL,"a"
		JL	@@EXIT

		AND	AL,11011111B
@@EXIT:		RET

;****************************************
;	      PUSH ALL REGS
;****************************************

RETADD		DW	0

PUSH_REGS:	POP	[CS:RETADD]

		PUSHF

		PUSH	DS
		PUSH	ES

		PUSH	DI
		PUSH	SI

		PUSH	AX
		PUSH	BX
		PUSH	CX
		PUSH	DX

		PUSH	[CS:RETADD]
		RET

;****************************************
;	      POP ALL REGS
;****************************************

POP_REGS:	POP	[CS:RETADD]

		POP	DX
		POP	CX
		POP	BX
		POP	AX

		POP	SI
		POP	DI

		POP	ES
		POP	DS
		POPF

		PUSH	[CS:RETADD]
		RET







