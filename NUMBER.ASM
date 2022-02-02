;*****************************************************************************
;		    GETTING NUMBERS AND PUTTING NUMBERS
;*****************************************************************************

;*********************************
;       PUT NUMBER TO OUTPUT
;*********************************

LEADZERO	DW	0
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

