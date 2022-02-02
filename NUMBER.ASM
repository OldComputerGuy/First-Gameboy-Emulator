;*****************************************************************************
;		    GETTING NUMBERS AND PUTTING NUMBERS
;*****************************************************************************

;*********************************
;       PUT NUMBER TO OUTPUT
;*********************************

;LEADZERO	DW	0
NUMOUTADD	DW	0
NUMLEN		DW	0

PUTSIGNED:	MOV	[CS:NUMLEN],0

		AND	EAX,EAX
		JNS	PUTNUM

		PUSH	AX			;PRINT '-' SIGN

		MOV	AL,"-"
		CALL	DCHAR

		POP	AX

		NEG	EAX			;NEGATE EAX

PUTNUM:	  	PUSH	EAX
		PUSH	EDX
		PUSH	ECX

		MOV	[CS:LEADZERO],0

		MOV	EDX,-1000000000
		CALL	PUTDIG

		MOV	EDX,-100000000
		CALL	PUTDIG

		MOV	EDX,-10000000
		CALL	PUTDIG

		MOV	EDX,-1000000
		CALL	PUTDIG

		MOV	EDX,-100000
		CALL	PUTDIG

		MOV	EDX,-10000
		CALL	PUTDIG

		MOV	EDX,-1000
		CALL	PUTDIG

		MOV	EDX,-100
		CALL	PUTDIG

		MOV	EDX,-10
		CALL	PUTDIG

		MOV	[CS:LEADZERO],1

		MOV	CL,AL
		CALL	PUT1

		POP	ECX
		POP	EDX
		POP	EAX

		MOV	[CS:NUMOUTADD],0		;SWITCH IT OFF
		RET

;*********************************
;          PRINT A DIGIT
;*********************************

PUTDIG:		XOR	CL,CL

@@LOOP:		INC	CL
		ADD	EAX,EDX
		JC	@@LOOP

		SBB	EAX,EDX
		DEC	CL

PUT1:		AND	CL,CL
		JNZ	@@NOTZERO

		CMP	[CS:LEADZERO],0
		JZ	@@ZERO

@@NOTZERO:	MOV	[CS:LEADZERO],1

		PUSH	AX
		MOV	AL,CL
		ADD	AL,48
		CALL	DCHAR

		POP	AX

@@ZERO:		RET

;****************************************
;		NUMBER OUTPUT
;****************************************

NUMOUT:		RET

		INC	[CS:NUMLEN]

		;CMP	[CS:NUMOUTADD],0
		;JZ	OUTCHR

		MOV	DI,[CS:NUMOUTADD]
		MOV	[CS:DI],AL
		INC	DI
		MOV	[CS:NUMOUTADD],DI
		RET

;****************************************
;         DIGIT WITH CASE CHANGE
;****************************************

TESTCASE:	CMP	AL,"z"
		JG	@@EXIT

		CMP	AL,"a"
		JL	@@EXIT

		AND	AL,11011111B
@@EXIT:		RET

;****************************************
;             GET A DIGIT
;****************************************

TEST_DIGIT:	CMP	[CS:BASE],10
		JZ	DIGIT

		CMP	[CS:BASE],2
		JZ	DIGIT_BIN

		JMP	DIGIT_HEX

;****************************************
;             GET A DIGIT
;****************************************

DIGIT:		CALL	GETCHR

DIG_09:		CMP	AL,":"
		CMC
		JC	@@EXIT

		CMP	AL,"0"
		JC	@@EXIT

		SUB	AL,48
@@EXIT:		RET

;****************************************
;             GET HEX DIGIT
;****************************************

DIGIT_HEX:	CALL	GETCHR
		CALL	TESTCASE

		CMP	AL,"A"
		JC	DIGIT

		CMP	AL,"G"
		CMC
		JC	@@EXIT

		SUB	AL,55
@@EXIT:		RET

;****************************************
;             GET BINARY DIGIT
;****************************************

DIGIT_BIN:	CALL	GETCHR

		CMP	AL,"2"
		CMC
		JC	@@EXIT

		CMP	AL,"0"
		JC	@@EXIT

		SUB	AL,48
@@EXIT:		RET

;****************************************
;          MULTIPLY BY BASE 10
;****************************************

BASE		DW	0

MULBASE:	ADD	EBX,EBX

		CMP	[CS:BASE],2
		JZ	@@EXIT

		MOV	EDX,EBX

		ADD	EBX,EBX
		ADD	EBX,EBX
		ADD	EBX,EDX

		CMP	[CS:BASE],10
		JZ	@@EXIT

		ADD	EBX,EDX
		ADD	EBX,EDX
		ADD	EBX,EDX

@@EXIT:		RET

;****************************************
;      GET A NUMBER OFF SCREEN
;****************************************

LASTNUM		DD	0
FIXED		DW	0

GETNUM:		MOV	EBX,0

@@LOOP:		CALL	MULBASE

		XOR	EAX,EAX

		CALL	TEST_DIGIT
		JC	@@EXIT

		ADD	EBX,EAX

		CALL	NEXTCHR

		CALL	TEST_DIGIT
		JNC	@@LOOP

@@EXIT:		MOV	EAX,EBX
		MOV	[CS:LASTNUM],EBX

		CALL	GETCHR
		CMP	AL,"."		;MUST BE FIXED POINT
		JZ	@@FIXED

		MOV	[CS:FIXED],0
		RET

@@FIXED:	CMP	[CS:BASE],10
		JNZ	@@ERR1

		PUSH	EBX

		CALL	NEXTCHR		;SKIP '.'
		CALL	GETFIXED
		MOV	[CS:FIXED],BX

		POP	EBX
		RET

@@ERR1:		CERROR	"Illegal base, fixedpoint numbers must be decimal"

;****************************************
;    GET NUMBERS AFTER A FIXED POINT
;****************************************

GETFIXED:	MOV	EBX,0

@@LOOP:	 	MOV	ECX,655360
		CALL	ADD_DIGIT
		JC	@@QUIT

		MOV	ECX,65536
		CALL	ADD_DIGIT
		JC	@@QUIT

		MOV	ECX,6553
		CALL	ADD_DIGIT
		JC	@@QUIT

		MOV	ECX,655
		CALL	ADD_DIGIT
		JC	@@QUIT

		MOV	ECX,65
		CALL	ADD_DIGIT
		JC	@@QUIT

		MOV	ECX,6
		CALL	ADD_DIGIT
		JC	@@QUIT

		CALL	SKIP_DIGIT

@@QUIT:		MOV	EAX,EBX
		MOV	EBX,100
		DIV	EBX
		MOV	EBX,EAX

		CMP	EDX,8000H
		JC	@@OK

		INC	EBX

@@OK:		RET       

;****************************************
;    	      ADD FIXED POINT
;****************************************

ADD_DIGIT:	XOR	EAX,EAX

		CALL	DIGIT
		JC	@@QUIT

		MUL	ECX			;EAX * ECX
		ADD	EBX,EAX

		CALL	NEXTCHR

		CLC
@@QUIT:		RET

;****************************************
;	   SKIP ANY MORE DIGITS
;****************************************

SKIP_DIGIT:	MOV	CX,64

@@LOOP:		CALL	DIGIT
		JC	@@QUIT

		CALL	NEXTCHR
		LOOP	@@LOOP
	   
		CERROR	"Too many digits in fixedpoint number "

@@QUIT:		RET

;****************************************
;	     GET CHAR NUMBER
;   GET NUMBERS IN THE FORM OF 'AB'
;****************************************

GET_CHR_NUM:	CALL	NEXTCHR			;SKIP "'"

		MOV	EBX,0
		MOV	CX,0

		CALL	GETCHR			;CAN'T BE EMPTY
		CMP	AL,"'"
		JZ	@@ONE

@@LOOP:		CALL	GETCHR

		CMP	AL,"'"
		JZ	@@QUIT

@@ONE:		CMP	AL,13
		JZ	@@ERR1

		CMP	AL,EOF_CHR
		JZ	@@ERR1

		SHL	EBX,8  			;SHIFT UP
		MOV	BL,AL			;SET LOW PART

		CALL	NEXTCHR
		JMP	@@LOOP

@@QUIT:		CALL	NEXTCHR			;SKIP THE "'"
		RET

@@ERR1:		CERROR	"Illegally terminated character field",0	 

;****************************************
;		PUSH NUMBER
;****************************************

NUMBERPTR	DW	OFFSET NUMBERSTK
NUMBERCNT	DW	0

UNARYFLAG	DW	0

PUSH_NUMBER:	PUSH	DI
		PUSH	EAX

		MOV	AX,[CS:NUMBERCNT]
		CMP	AX,10
		JZ	@@ERR1

		INC	[CS:NUMBERCNT]

		MOV	DI,[CS:NUMBERPTR]

		MOV	EAX,[CS:LASTNUM]
		MOV	[CS:DI],EAX

		MOV	AX,[CS:FIXED]
		MOV	[CS:DI+4],AX

		MOV	AX,[CS:UNARYFLAG]
		MOV	[CS:DI+6],AL

		ADD	DI,7
		MOV	[CS:NUMBERPTR],DI

		POP	EAX
		POP	DI
		RET

@@ERR1:		FATAL	"No more space in number stack (PUSH_NUMBER)"

;****************************************
;	   	POP NUMBER
;****************************************

POP_NUMBER:	PUSH	DI
		PUSH	EAX

		MOV	AX,[CS:NUMBERCNT]
		CMP	AX,0
		JZ	@@ERR1

		DEC	[CS:NUMBERCNT]

		MOV	DI,[CS:NUMBERPTR]
		SUB	DI,7
		MOV	[CS:NUMBERPTR],DI

		MOV	EAX,[CS:DI]
		MOV	[CS:LASTNUM],EAX

		MOV	AX,[CS:DI+4]
		MOV	[CS:FIXED],AX

		MOV	[CS:DI+6],AL
		MOV	AH,0
		MOV	[CS:UNARYFLAG],AX

		POP	EAX
		POP	DI
		RET

@@ERR1:		FATAL	"End of number stack reached in (POP_NUMBER)"

