;*****************************************************************************
;		    GET SYMBOLS FROM FILE 'SYM.TAB'
;*****************************************************************************

;****************************************
;	     OPEN SYMBOL FILE
;       TEMPORARLY USE SCEEN RAM
;****************************************

SYMNAME		DB	"SYM.TAB",0
EXTRANAME	DB	"EXTRA.TAB",0

GET_EXTRA_SYM:	MOV	DX,OFFSET EXTRANAME
		MOV	BX,OFFSET READ_SYMBOLS
		JMP	LOAD_STREAM

GET_SYM:	MOV	DX,OFFSET SYMNAME
		MOV	BX,OFFSET READ_SYMBOLS
		JMP	LOAD_STREAM

;****************************************
;	      READ IN SYMBOLS
;****************************************

READ_SYMBOLS:
		MOV	SI,0
		MOV	DS,[CS:TEMPRAM]

		MOV	AX,0	    		;MAKE CHANNEL 0 COMMAND LINE
		CALL	SET_REDIRECT

		MOV	AX,0			;REDIRECT TO CHANNEL 0
		CALL	REDIRECT

@@LOOP:		CALL	GETCHR

		CMP	AL,1AH			;EOF ?
		JZ	@@QUIT

		CMP	AL,"$"			;NUMBER ?
		JNZ	@@SKIP

		CALL	TRY_GET_SYM	

@@SKIP:		CALL	SKIP_LINE
		JMP	@@LOOP

@@QUIT:		RET

;****************************************
;	      READ IN SYMBOLS
;****************************************

USEUPPER	DB	0

TRY_GET_SYM:
		CALL	NEXTCHR			;SKIP '$'

		MOV	[CS:BASE],16
		CALL	GETNUM			;NUM IN EBX

		PUSH	EBX			;SAVE ADDRESS

		CALL	SKIP_EXP		;SKIP SHITE

		CALL	GETCHR			;GET TYPE DATE
		CMP	AL,"N"			;TEST FOR NORMAL SYMBOL
		JZ	@@NORM

		CALL	GETCHR			;GET TYPE DATE
		CMP	AL,"L"			;TEST FOR LOCAL SYMBOL
		JZ	@@NORM

		CALL	GETCHR			;GET TYPE DATE
		CMP	AL,"E"			;TEST FOR EQU TYPE SYMBOL
		JZ	@@EQU

		POP	EBX
		RET

@@NORM:		CALL	NEXTCHR			;SKIP '$'

		CALL	SKIP_EXP		;SKIP SHITE

		CALL	GET_LABEL_NAME		;GET LABEL

		CMP	[BYTE CS:USEUPPER],1
		JZ	@@NOUPP1

		CALL	MAKE_UPPER

@@NOUPP1:	POP	EBX

		MOV	AL,TYPE_REDEF		;SET LABEL TYPE
		CALL	PUT_LABEL

		RET

@@EQU:		CALL	NEXTCHR			;SKIP '$'

		CALL	SKIP_EXP		;SKIP SHITE

		CALL	GET_LABEL_NAME		;GET LABEL

		CMP	[BYTE CS:USEUPPER],1
		JZ	@@NOUPP2

		CALL	MAKE_UPPER

@@NOUPP2:	POP	EBX

		MOV	AL,TYPE_EQU		;SET LABEL TYPE
		CALL	PUT_LABEL

		RET
