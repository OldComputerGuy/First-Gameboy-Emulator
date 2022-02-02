;*****************************************************************************
;			  SWITCH ROUTINES
;*****************************************************************************

SWDATA		DW	256 DUP (0)

;*********************************
;	   GET SWITCHES
;*********************************

GETSWITCH:	CALL	SKIP_EXP

		CMP	AL,"/"
		JZ	@@OK

		CMP	AL,"-"
		JNZ	@@QUIT

@@OK:		CMP	AL,13
		JZ	@@QUIT

		CALL	NEXTCHR			;SKIP '-'
		CALL	GETCHR			;GET SWITCH

@@ANOTHER:	MOV	BL,AL
		MOV	BH,0
		INC	[BYTE CS:OFFSET SWDATA+BX]

		CALL	NEXTCHR

		CMP	AL,13
		JZ	@@QUIT

		CMP	AL,32
		JZ	GETSWITCH

		JMP	@@ANOTHER
	  
@@QUIT:		RET

;*********************************
;	   TEST SWITCH
;	AL = SWITCH TO TEST
;
;RETURNS: ZFSET IF NO SWITCH
;*********************************

TEST_SWITCH:  	PUSH	BX

		MOV	BL,AL
		MOV	BH,0
		MOV	AL,[BYTE CS:OFFSET SWDATA+BX]

		AND	AL,AL
		POP	BX
		RET

;*********************************
;  GET A COMMAND TAIL PARAMETER
;
; SI:DS = POINTS TO COMMAND TAIL
;    DI:ES = PARAM POINTER  
;*********************************

GET_PARA:	CALL	SKIP_EXP

@@LOOP: 	CALL	GETCHR
	 	
		CMP	AL,32
		JZ	@@QUIT

		CMP	AL,13
		JZ	@@QUIT

		MOV	[CS:DI],AL
		INC	DI

		CALL	NEXTCHR
		JMP	@@LOOP

@@QUIT:		MOV	[BYTE CS:DI],0
		RET

