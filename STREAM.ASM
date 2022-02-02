;*****************************************************************************
;* 			STRING AND MACRO HANDLING
;*****************************************************************************

EOF_CHR		= 1AH

;****************************************
;	      REDIRECT FILE
;	   AX = CHANNEL NUMBER
;****************************************

CHANRAM		DW	0
CHANPTR		DW	0

CURRENT_CHAN	DW	-1			;INITIALIZE NO CHANNEL
CHANNEL_INFO	DB	40 DUP (0FFH)

REDIRECT:	CMP	AX,[CS:CURRENT_CHAN]
		JZ	@@QUIT

		PUSH	BX
		PUSH	AX	 

		PUSH	AX

		MOV	BX,[CS:CURRENT_CHAN]
		CMP	BX,-1
		JZ	@@NOCHAN

		ADD	BX,BX
		ADD	BX,BX

		MOV	AX,[CS:CHANRAM]
		MOV	[WORD CS:BX+OFFSET CHANNEL_INFO],AX

		MOV	AX,[CS:CHANPTR]
		MOV	[WORD CS:BX+OFFSET CHANNEL_INFO+2],AX

@@NOCHAN:	POP	AX

		MOV	[CS:CURRENT_CHAN],AX

		MOV	BX,AX
		ADD	BX,BX
		ADD	BX,BX

		MOV	AX,[WORD CS:BX+OFFSET CHANNEL_INFO]
		MOV	[CS:CHANRAM],AX

		MOV	AX,[WORD CS:BX+OFFSET CHANNEL_INFO+2]
		MOV	[CS:CHANPTR],AX

		POP	AX
		POP	BX
@@QUIT:		RET

;****************************************
;	      SET A CHANNEL
;	   AX = CHANNEL NUMBER
;****************************************

SET_CHANNEL:
SET_REDIRECT:	MOV	BX,AX
		ADD	BX,BX
		ADD	BX,BX
		MOV	[WORD CS:BX+OFFSET CHANNEL_INFO],DS
		MOV	[WORD CS:BX+OFFSET CHANNEL_INFO+2],SI

		CMP	AX,[CS:CURRENT_CHAN]	;IF CURRENT CHANNEL
		JNZ	@@QUIT			;WE MUST UPDATE IT

		MOV	[CS:CHANRAM],DS
		MOV	[CS:CHANPTR],SI

@@QUIT:		RET

;****************************************
;	 PUSH REDIRECTION CHANNELS
;		 KILLS DI
;****************************************

PUSH_CHAN:	POP	[CS:RETADD]

		PUSH	[CS:CURRENT_CHAN]

		PUSH	[CS:CHANRAM]
		PUSH	[CS:CHANPTR]

		PUSH	[DWORD CS:CHANNEL_INFO+0]
		PUSH	[DWORD CS:CHANNEL_INFO+4]
		PUSH	[DWORD CS:CHANNEL_INFO+8]
		PUSH	[DWORD CS:CHANNEL_INFO+12]	

		PUSH	[CS:RETADD]
		RET

;****************************************
;        POP REDIRECTION CHANNELS
;		 KILLS DI
;****************************************

POP_CHAN:	POP	[CS:RETADD]

		POP	[DWORD CS:CHANNEL_INFO+12]
		POP	[DWORD CS:CHANNEL_INFO+8]
		POP	[DWORD CS:CHANNEL_INFO+4]
		POP	[DWORD CS:CHANNEL_INFO+0]	

		POP	[CS:CHANPTR]
		POP	[CS:CHANRAM]

		POP	[CS:CURRENT_CHAN]

		PUSH	[CS:RETADD]
		RET

;****************************************
;	    GET CHR AT FILEPTR
;****************************************

GETCHR:		PUSH	SI
		PUSH	DS

		MOV	DS,[CS:CHANRAM]
		MOV	SI,[CS:CHANPTR]
		LODSB

		POP	DS
		POP	SI
		RET

;****************************************
;	    GET CHR AT FILEPTR
;****************************************

NEXTCHR:	PUSH	SI
		PUSH	DS

		MOV	DS,[CS:CHANRAM]
		MOV	SI,[CS:CHANPTR]
		LODSB
		MOV	[CS:CHANPTR],SI

		POP	DS
		POP	SI
		RET

;****************************************
;	  GET LAST CHR AT FILEPTR
;****************************************

LASTCHR:	PUSH	SI
		PUSH	DS

		MOV	DS,[CS:CHANRAM]
		MOV	SI,[CS:CHANPTR]

		MOV	AL,[SI]
		CMP	SI,0
		JZ	@@ERROR

		DEC	SI
		MOV	[CS:CHANPTR],SI

		POP	DS
		POP	SI
		CLC
		RET

@@ERROR:	POP	DS
		POP	SI
		STC
		RET

;****************************************
;	       WRITE CODE
;****************************************

OUTPUT_FLAG	DW	1

XOUTCHR:
		RET

;****************************************
;       SKIP RUBBISH TO NEXT DATA
;****************************************

LINEPOS		DW	0

SKIP_EXP:	CALL	GETCHR

		CMP	AL,32
		JZ	@@SKIP

		CMP	AL,9
		JZ	@@SKIP

		RET

@@SKIP:		CALL	NEXTCHR
		INC	[CS:LINEPOS]

		JMP	SKIP_EXP

;********************************************************************************
;			 	OLD STUFF HERE
;********************************************************************************

		IF	0

;****************************************
;	GET STACK ON MACRO STACK
;****************************************

BALPTR		DW	OFFSET BALBUFFER
BALCNT		DW	0

GET_MACRO_STACK:

		INC	[CS:BALCNT]
		CMP	[CS:BALCNT],100
		JZ	@@ERR1

		MOV	AX,[CS:LABSTKCNT1]	;SAVE COUNTS

		MOV	DI,[CS:BALPTR]
		MOV	[CS:DI],AX
		ADD	DI,2
		MOV	[CS:BALPTR],DI

		RET

@@ERR1:		CERROR	"Balancing stack overflow"

;****************************************
;	TEST MACRO STACK ON EXIT
;****************************************

TEST_STACK_EXIT:
		CMP	[CS:BALCNT],0
		JZ	@@ERR2

		DEC	[CS:BALCNT]

		MOV	DI,[CS:BALPTR]
		SUB	DI,2
		MOV	AX,[CS:DI]
		MOV	[CS:BALPTR],DI

		CMP	AX,[CS:LABSTKCNT1]	;MAKE SURE COUNT IS THE SAME
		JNZ	@@ERR1		 	;AS WHEN WE ARRIVED
		RET

@@ERR1:		CERROR	"Unbalanced label stack on exit, macro '%' "

@@ERR2:		CERROR	"Balancing stack underflow"

;****************************************
;	  TEST STACK AND REPORT
;****************************************

TEST_STACK_REPORT:

		CMP	[CS:BALCNT],0
		JZ	@@ERR1

		DEC	[CS:BALCNT]

		MOV	DI,[CS:BALPTR]
		SUB	DI,2
		MOV	AX,[CS:DI]
		MOV	[CS:BALPTR],DI

		CMP	AX,[CS:LABSTKCNT1]	;MAKE SURE COUNT IS THE SAME
		JNZ	FORCE_ERROR

		JMP	SKIP_FORCE_ERROR

@@ERR1:		CERROR	"Balancing stack underflow"

		ENDIF
