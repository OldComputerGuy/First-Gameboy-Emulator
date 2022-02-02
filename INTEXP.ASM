;********************************************************************************
;			 EVALUATE INTERNAL EXPRESSION
;	   		   RESULT RETURNED IN EBX
;********************************************************************************

NUMPTR		DW	OFFSET NUMSTK

INTBRKCNT	DW	0
NEGFLAG		DW	0

RPN		= 0

INTERNAL_EXP:	
		CALL	PUSH_LABEL

		PUSH	[CS:NEGFLAG]
		PUSH	[CS:INTBRKCNT]

		MOV	[CS:NEGFLAG],0
		MOV	[CS:INTBRKCNT],0

		;MOV	[CS:NUMPTR],OFFSET NUMSTK

		CALL	RECURSE

		CALL	UNSTK_EBX

		CMP	[CS:INTBRKCNT],0
		JNZ	@@ERR1

		POP	[CS:INTBRKCNT]
		POP	[CS:NEGFLAG]

		CALL	POP_LABEL
		RET

@@ERR1:		CERROR	"Bracket ')' missing in internal expression"

;****************************************
;   INTERNAL EXPRESSION TO LABEL RAM
;	  RETURNS EBX = NUMBER
;****************************************

INTERNAL_EXP_LABEL:

		CALL	INTERNAL_EXP			;GET EXPRESSION

PRINT_EBX:	PUSH	EAX

		MOV	EAX,EBX
		MOV	[NUMOUTADD],OFFSET LABNAME

		PUSH	EBX
		CALL	PUTSIGNED
		POP	EBX

		MOV	AX,[CS:NUMLEN]			;GET LENGTH OF NUM
		MOV	[CS:LABLEN],AX

		POP	EAX
		RET

;****************************************
;		PRINT EAX
;****************************************

PRINT_EAX:	PUSH	EAX
		MOV	[NUMOUTADD],OFFSET LABNAME

		PUSH	EBX
		CALL	PUTSIGNED
		POP	EBX

		MOV	AX,[CS:NUMLEN]			;GET LENGTH OF NUM
		MOV	[CS:LABLEN],AX

		POP	EAX
		RET

;****************************************
;	 PRINT A NUMBER TO CS:DI
;	        EAX = NUMBER
;****************************************

PRNUM_DI:	MOV	[NUMOUTADD],DI

		PUSH	DI
		CALL	PUTSIGNED
		POP	DI

		ADD	DI,[CS:NUMLEN]			;GET LENGTH OF NUM
		RET

;****************************************
;	RECURSE INTO EXPRESSION
;****************************************

RECURSE:	PUSH	OFFSET 0	;PUT A ZERO ON THE STK

RP_LOOP:	CALL	GETCHR
		CMP	AL,"("		;FOUND A LEFT BRACKET
		JZ	BRACKL		;RECURSE PARSE

		CALL	STKNUM
		
		CALL	SKIP_EXP

RP_OPER:	CALL	GETCHR
		CMP	AL,")"
		JZ	BRACKR

		CALL	END_EXP		;FOUND END STATMENT
		JC	DROPSIGN

		PUSH	[CS:CHANPTR]

		CALL	GET_OPER_NAME	;GET'S OPERATOR SYMBOLS
		CALL	GET_OPER_SI	;FIND OPERATOR TABLE ENTRY

		POP	[CS:CHANPTR]

		MOV	CH,[CS:SI]	;GET CURRENT SIGNS PRIORITY IN CL

@@LOOP:		POP	SI		;GET TOP TABLE ENTRY
		PUSH	SI

		CMP	SI,0		;IS IT THE LAST ONE
		JZ	@@PRIOR		;JUMP IF LAST ENTRY

		CMP	[CS:SI],CH	;WHICH SIGN IS GREATER
		JC	@@PRIOR

		POP	SI 		;UNSTK A SIGN
		
		CALL	[WORD CS:SI+1]	;DO THIS SIGN : SAVE CX

		JMP	@@LOOP

@@PRIOR:	CALL	GET_OPER_NAME	;GET'S OPERATOR SYMBOLS
		CALL	GET_OPER_SI	;FIND OPERATOR TABLE ENTRY
		PUSH	SI

		CALL	SKIP_EXP	;SKIP TO NEXT PART OF EXPRESSION
		JMP	RP_LOOP		;GET NEXT NUMBER

;****************************************
;	    RIGHT BRACKET FOUND
;****************************************

BRACKR:		CMP	[CS:INTBRKCNT],0
		JZ	DROPSIGN

		DEC	[CS:INTBRKCNT]

		CALL	NEXTCHR
		CALL	SKIP_EXP

		JMP	DROPSIGN

@@ERR1:		CERROR	"Bracket '(' missing in internal expression"

;****************************************
;	     DROP SIGN STACK
;****************************************

DROPSIGN:				;FOUND END OF STATEMENT
					;DROP ALL SIGNS AND EXIT

@@DROPLOOP:	POP	SI		;IS THIS THE END OF THE STK

		CMP	SI,0
		JZ	@@EXIT		;IF IT IS THEN END

		CALL	[WORD CS:SI+1]	;ELSE, PERFORM IT'S FUNCTION

		JMP	@@DROPLOOP

@@EXIT:		RET

;****************************************
;	   BRACKET LEFT FOUND
;         SO RECURSE EVALUATOR
;****************************************

BRACKL:		INC	[CS:INTBRKCNT]

		CALL	NEXTCHR		;GO TO NEXT CHR
		CALL	SKIP_EXP

		CALL	RECURSE		;EVALUATE TILL BRACKET RIGHT

		JMP	RP_OPER		;RETURN TO LOOP


;****************************************
;   TEST FOR A VALID END OF EXPRESSION
;       CYSET IF END OF EXPRESSION
;****************************************

END_EXP:	CALL	GETCHR
		CALL	DO_INSTR
		DB	",;:",13,0
		CMC
		RET

;****************************************
;	    TEST NUMBERS BASE
;****************************************

GETBASE:	CALL	GETCHR

		CMP	AL,"-"
		JNZ	@@NOTUNARY

		MOV	[CS:NEGFLAG],1
		CALL	NEXTCHR
		CALL	GETCHR		

@@NOTUNARY:	CMP	AL,"%"			;TEST BINARY
		JZ	@@SETBIN 		;JUMP IF NOT BIN

		CMP	AL,"#"
		JZ	@@SETHEX

		CMP	AL,"$"
		JZ	@@SETHEX

		CALL	DIG_09
		JNC	@@SETDEC

		MOV	[CS:BASE],-1		;SIGNIFY LABEL
		RET

@@SETDEC:	MOV	[CS:BASE],10		;SAY DECIMAL
		RET

@@SETBIN:	MOV	[CS:BASE],2		;SAY BINARY
		JMP	NEXTCHR

@@SETHEX:	MOV	[CS:BASE],16		;SAY HEX
		JMP	NEXTCHR

;****************************************
;      GET NUM WITH BASE OF LABEL
;****************************************

GETNUM_BASE:	CALL	STKNUM
		JMP	UNSTK_EBX

;****************************************
;	       STK NUMBER
;****************************************

MEMFLAG		DB	0

STKNUM:		CALL	GETBASE

		CALL	GETCHR

		CMP	AL,"'"
		JNZ	@@NO

		CALL	GET_CHR_NUM
		JMP	@@TESTNEG

@@NO:		CMP	[CS:BASE],-1
		JZ	GETLABEL

		CALL	GETNUM

		CALL	GETCHR
		CMP	AX,"x"
		JNZ	@@TESTNEG
		
		CALL	NEXTCHR	    		;GET C STYLE HEX
		MOV	[CS:BASE],16		;SAY HEX

		CALL	GETNUM

@@TESTNEG:	CMP	[CS:NEGFLAG],1
		JNZ	@@NONEG	

		NEG	EBX

@@NONEG:	CALL	STK_EBX
   		RET

;****************************************
;	       STK LABEL
;****************************************

GETLABEL:	CALL	GET_LABEL_NAME
		CALL	FIND_LABEL
		JNC	@@ERR1

		CMP	AL,TYPE_PASS1
		JZ	@@OK

		CMP	AL,TYPE_INTFUNC
		JZ	@@INTFUNC

		CMP	AL,TYPE_TOKEN
		JNZ	@@NOTTOKEN

		MOV	EBX,[CS:BX]
		JMP	@@OK

@@NOTTOKEN:	CMP	AL,TYPE_REDEF
		JZ	@@OK

		CMP	AL,TYPE_EQU
		JNZ	@@ERR2
		
@@OK:		CMP	[CS:NEGFLAG],1
		JNZ	@@NONEG	

		NEG	EBX

@@NONEG:	CALL	STK_EBX
		RET

@@INTFUNC:	JMP	BX

@@ERR1:		CERROR	"Label '#' in internal expression not found"
@@ERR2:		CERROR	"Wrong label type '#' used in internal expression"

;****************************************
;	      BYTE FUNCTION
;****************************************

BYTE_FUNC:	CALL	SKIP_EXP
		CALL	GETCHR
		CMP	AL,"("
		JNZ	@@ERR1

		PUSH	[CS:NEGFLAG]
		CALL	RECURSE			;get funtion result
		POP	[CS:NEGFLAG]

		CALL	UNSTK_EBX

		MOV	EDI,EBX			;GET MEMLOC
		CALL	GET_MEMORY_AL
		MOVZX	EBX,AL

		CMP	[CS:NEGFLAG],1
		JNZ	@@NONEG	

		NEG	EBX

@@NONEG:	CALL	STK_EBX
		RET

@@ERR1:		CERROR	"Functions must be bound by '()' in expressions"

;****************************************
;	      WORD FUNCTION
;****************************************

WORD_FUNC:	CALL	SKIP_EXP
		CALL	GETCHR
		CMP	AL,"("
		JNZ	@@ERR1

		PUSH	[CS:NEGFLAG]
		CALL	RECURSE			;get funtion result
		POP	[CS:NEGFLAG]

		CALL	UNSTK_EBX

		MOV	EDI,EBX			;GET MEMLOC
		CALL	GET_MEMORY_AX
		MOVZX	EBX,AX

		CMP	[CS:NEGFLAG],1
		JNZ	@@NONEG	

		NEG	EBX

@@NONEG:	CALL	STK_EBX
		RET

@@ERR1:		CERROR	"Functions must be bound by '()' in expressions"

;****************************************
;	      LONG FUNCTION
;****************************************

LONG_FUNC:	CALL	SKIP_EXP
		CALL	GETCHR
		CMP	AL,"("
		JNZ	@@ERR1

		;PUSH	[CS:NEGFLAG]
		;CALL	RECURSE			;get funtion result
		;POP	[CS:NEGFLAG]

		CALL	INTERNAL_EXP		;get funtion result

		;CALL	UNSTK_EBX

		MOV	EDI,EBX			;GET MEMLOC
		CALL	GET_MEMORY_EAX
		MOV	EBX,EAX

		CMP	[CS:NEGFLAG],1
		JNZ	@@NONEG	

		NEG	EBX

@@NONEG:	CALL	STK_EBX
		RET

@@ERR1:		CERROR	"Functions must be bound by '()' in expressions"

;****************************************
;	  DEFINE OPERATOR MACRO
;****************************************

		MACRO DEFOP @1,@2,@3
		DB	@1,0
		DB	@2
		DW	OFFSET @3
		ENDM

;****************************************
;        GET SIGN TABLE ADDRESS
;	 ~~~~~~~~~~~~~~~~~~~~~~
;	 RETURNS SI POINTING TO
; 	 PRIORITY AND THEN ROUTE
;****************************************

PRIORTAB:	DEFOP	"*" ,15,INT_MUL
		DEFOP	"/" ,15,INT_DIV
		DEFOP	"%" ,15,INT_REM
		DEFOP	"-" ,14,INT_SUB
		DEFOP	"+" ,14,INT_ADD
		DEFOP	"<<",13,INT_SHL
		DEFOP	">>",13,INT_SHR
		DEFOP	"<" ,12,INT_LT
		DEFOP	"<=",12,INT_LTE
		DEFOP	">" ,12,INT_GT
		DEFOP	">=",12,INT_GTE
		DEFOP	"==",11,INT_E
		DEFOP	"=" ,11,INT_E
		DEFOP	"!=",11,INT_NE
		DEFOP	"<>",11,INT_NE
		DEFOP	"&" ,10,INT_BITAND

		DEFOP	"^" ,9 ,INT_BITXOR
		DEFOP	"|" ,8 ,INT_BITOR

		DEFOP	"&&",7 ,INT_LOGAND
		DEFOP	"AND",7,INT_LOGAND

		DEFOP	"||",6 ,INT_LOGOR
		DEFOP	"OR",6 ,INT_LOGOR
		DB	0

GET_OPER_SI:	MOV	BX,[CS:LABLEN]			;SET END OF LAB TO 0
		MOV	[BYTE CS:OFFSET LABNAME+BX],0

		MOV	SI,OFFSET PRIORTAB
		MOV	DS,[CS:CODERAM]

@@LOOP:		CMP	[BYTE CS:SI],0
		JZ	@@ERR1

		CALL	SEARCH_PRI
		JNC	@@LOOP
		RET

@@ERR1:		CERROR	"Unrecognized internal operator '#' in priorty table"

;****************************************
;	   SEARCH PRIORITY TABLE
;     DS:SI = TABLE LACATION TO TEST
;****************************************
	
SEARCH_PRI:	MOV	DI,OFFSET LABNAME
		MOV	DX,0

@@LOOP:		LODSB
		CMP	AL,[CS:DI]
		JZ	@@OK

		INC	DX			;FLAG AN ERROR

@@OK:		CMP	AL,0
		JZ	@@FOUND

		INC	DI

		JMP	@@LOOP

@@FOUND:	CMP	DX,0
		JNZ	@@NOPE

		STC
		RET

@@NOPE:		ADD	SI,3			;SKIP PRI AND ADDR
		CLC				;SAY NOT FOUND
		RET

;****************************************
;	      STK A NUMBER
;****************************************

STK:		MOV	DI,[CS:NUMPTR]
		MOV	[CS:DI],EAX
		ADD	DI,4
		MOV	[CS:NUMPTR],DI
		RET

;****************************************
;	      STK A NUMBER
;****************************************

STK_EBX:	MOV	DI,[CS:NUMPTR]
		MOV	[CS:DI],EBX
		ADD	DI,4
		MOV	[CS:NUMPTR],DI
		RET

;****************************************
;	     UNSTK A NUMBER
;****************************************

UNSTK:		MOV	DI,[CS:NUMPTR]
		SUB	DI,4
		MOV	EAX,[CS:DI]
		MOV	[CS:NUMPTR],DI
		RET

;****************************************
;	     UNSTK A NUMBER
;****************************************

UNSTK_EBX:	MOV	DI,[CS:NUMPTR]
		SUB	DI,4
		MOV	EBX,[CS:DI]
		MOV	[CS:NUMPTR],DI
		RET

;********************************************************************************
;		  INTERNAL EXPRESSION OPERATOR FUNCTIONS
;********************************************************************************

;****************************************
;	     ADD TOP STK
;****************************************

INT_ADD:	CALL	UNSTK_EBX
		CALL	UNSTK

		ADD	EAX,EBX
		JMP	STK

;****************************************
;	     SUB TOP STK
;****************************************

INT_SUB:	CALL	UNSTK_EBX
		CALL	UNSTK

		SUB	EAX,EBX
		JMP	STK

;****************************************
;	     MULT TOP STK
;****************************************

INT_MUL:	CALL	UNSTK_EBX
		CALL	UNSTK

		IMUL	EBX
		JMP	STK

;****************************************
;	    DIVIDE TOP STK
;****************************************

INT_DIV:	CALL	UNSTK_EBX
		CALL	UNSTK

		IDIV	EBX
		JMP	STK

;****************************************
;	      GET REMAINDER
;****************************************

INT_REM:   	CALL	UNSTK_EBX
		CALL	UNSTK
		IDIV	EBX
		MOV	EAX,EDX
		JMP	STK

;****************************************
;      		SHIFT LEFT
;****************************************

INT_SHL:	CALL	UNSTK_EBX
		CALL	UNSTK

		MOV	CL,BL
		SHL	EAX,CL

		JMP	STK

;****************************************
;      		SHIFT RIGHT
;****************************************

INT_SHR:	CALL	UNSTK_EBX
		CALL	UNSTK

		MOV	CL,BL
		SHR	EAX,CL

		JMP	STK

;****************************************
;          CONDITION LESS THAN
;****************************************

INT_LT:		CALL	UNSTK_EBX
		CALL	UNSTK

		MOV	ECX,1

		CMP	EAX,EBX
		JL	@@YES

		MOV	ECX,0

@@YES:		MOV	EAX,ECX
		JMP	STK

;****************************************
;      CONDITION LESS THAN OR EQUAL
;****************************************

INT_LTE:	CALL	UNSTK_EBX
		CALL	UNSTK

		MOV	ECX,1

		CMP	EAX,EBX
		JLE	@@YES

		MOV	ECX,0

@@YES:		MOV	EAX,ECX
		JMP	STK

;****************************************
;         CONDITION GREATER THAN
;****************************************

INT_GT:		CALL	UNSTK_EBX
		CALL	UNSTK

		MOV	ECX,1

		CMP	EAX,EBX
		JG	@@YES

		MOV	ECX,0

@@YES:		MOV	EAX,ECX
		JMP	STK

;****************************************
;     CONDITION GREATER THAN OR EQUAL
;****************************************

INT_GTE:	CALL	UNSTK_EBX
		CALL	UNSTK

		MOV	ECX,1

		CMP	EAX,EBX
		JGE	@@YES

		MOV	ECX,0

@@YES:		MOV	EAX,ECX
		JMP	STK

;****************************************
;	     CONDITION EQUAL
;****************************************

INT_E:		CALL	UNSTK_EBX
		CALL	UNSTK

		MOV	ECX,0

		CMP	EAX,EBX
		JNZ	@@NOT

		MOV	ECX,1

@@NOT:		MOV	EAX,ECX
		JMP	STK

;****************************************
;	   CONDITION NOT EQUAL
;****************************************

INT_NE:		CALL	UNSTK_EBX
		CALL	UNSTK

		MOV	ECX,0

		CMP	EAX,EBX
		JZ	@@NOT

		MOV	ECX,1

@@NOT:		MOV	EAX,ECX
		JMP	STK

;****************************************
;		BITWISE AND
;****************************************

INT_BITAND:	CALL	UNSTK_EBX
		CALL	UNSTK
		AND	EAX,EBX
		JMP	STK

;****************************************
;		BITWISE XOR
;****************************************

INT_BITXOR:	CALL	UNSTK_EBX
		CALL	UNSTK
		XOR	EAX,EBX
		JMP	STK

;****************************************
;		BITWISE OR
;****************************************

INT_BITOR:	CALL	UNSTK_EBX
		CALL	UNSTK
		OR	EAX,EBX
		JMP	STK

;****************************************
;	        LOGICAL AND
;****************************************

INT_LOGAND:	CALL	UNSTK_EBX
		CALL	UNSTK

		CMP	EAX,0
		JZ	@@NOT

		CMP	EBX,0
		JZ	@@NOT

		MOV	EAX,1
		JMP	STK

@@NOT:		MOV	EAX,0
		JMP	STK

;****************************************
;	        LOGICAL OR
;****************************************

INT_LOGOR:	CALL	UNSTK_EBX
		CALL	UNSTK

		CMP	EAX,0
		JNZ	@@YEP

		CMP	EBX,0
		JNZ	@@YEP

@@NOT:		MOV	EAX,0
		JMP	STK

@@YEP:		MOV	EAX,1
		JMP	STK

;****************************************
;	   SET A REDEF TO EBX
;	    LABNAME HOLDS VAR
;****************************************

SET_REDEF:	PUSH	EBX			;SAVE NEW VALUE
		CALL	FIND_LABEL		;DOES LABEL ALREADY EXIST
		POP	EBX			;GET IT BACK

		JNC	@@NOTFOUND	  		;REDEFINE IF IT DOES

		CMP	AL,TYPE_PASS1
		JZ	@@NOTFOUND

		CMP	AL,TYPE_REDEF		;THIS TYPE ONLY
		JNZ	@@ERR2

	       	MOV	[SI+LAB_VALUE0],EBX	;REDEFINE LABEL VALUE
		RET

@@NOTFOUND:	MOV	AL,TYPE_REDEF		;STORE THE FIXUP
		MOV	AH,0
		CALL	PUT_LABEL_ALWAYS
@@QUIT:		RET

@@ERR2:		CERROR	"'#' is not a redefinable type"


