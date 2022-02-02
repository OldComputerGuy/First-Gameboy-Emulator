;*****************************************************************************
;			  general routines
;*****************************************************************************

;*********************************
;     WAIT FOR LOADS OF TIME
;*********************************

WAIT_KEY:	MOV	AH,08H		;WAIT FOR KEY
		INT	021H
		RET

;*********************************
;     GET CURRENT VIDEO MODE
;*********************************

GET_VMODE:	MOV	AH,0FH
		INT	10H
		MOV	[CS:OLDVMODE],AL
		RET

;*********************************
;     SET TO OLD VIDEO MODE
;*********************************

OLD_VMODE:	MOV	AL,[CS:OLDVMODE]
		MOV	AH,0
		INT	10H

		XOR	BL,BL			;SET 80 50 MODE
		MOV	AX,1112H
		INT	10H
		RET

;*********************************
;     SET TO VGA 320 x 200
;*********************************

CMODE		DW	0

SET_VGA:	MOV	AX,0013H		;MCGA 13H
		INT	010H

		MOV	[CS:CMODE],1
		RET

;********************************
;    GET MEM FOR PAGE MEMORY
;********************************
			      
GETMEM:		MOV	AH,048H
	      	INT	021H
		JC	@@NOMEM
		RET

@@NOMEM:	CALL	DOS_PRINT
		DB	"Not enough memory to run !",13,10,0

		JMP	BAD_DOS_RET

;*********************************
;       WAIT FOR FRAME FLY
;*********************************

WINDELAY	DW	0
VBLTIME		DW	0

WAIT_FLY:	MOV	DX,3DAH
		MOV	BX,0

@@W1:		IN	AL,DX
		INC	BX
		AND	AL,00001000B
		JZ	@@W1

@@W2:		IN	AL,DX
		INC	BX
		AND	AL,00001000B
		JNZ	@@W2

		RET

		MOV	[CS:VBLTIME],BX

;		CMP	BX,11000		;WINDOWS HAS FAST VBL
;		JNC	@@OK

;		MOV	CX,5000		;BIG DELAY
;		SUB	CX,BX

;@@W3:		JMP	@@CHC1
;@@CHC1:		JMP	@@CHC2
;@@CHC2:		JMP	@@CHC3
;@@CHC3:		JMP	@@CHC4
;@@CHC4:		NOP
;		LOOP	@@W3		

@@OK:		RET

;*********************************
; 	     ANDYKEY
;
; OUT:	AL = ASCII CODE OF KEY
;	AH = SCANCODE OF KEY
;	DH = SHIFT/CTRL/ALT KEYS
;*********************************

ANDYKEY:	PUSH	BX
		PUSH	CX	;DON'T TRUST BIOS
		PUSH	SI
		PUSH	DI
		PUSH	BP

		XOR	AH,AH	;GET KEY
		INT	16H

		PUSH	AX

		MOV	AH,2
		INT	16H	;READ KEYBOARD (SHIFT) STATUS

		AND	AL,0FH
		TEST	AL,3
		JE	@@2

		OR	AL,3

@@2:		MOV	DH,AL

		POP	AX
		POP	BP
		POP	DI
		POP	SI
		POP	CX
		POP	BX
		RET

;*********************************
;	   SHRINK MEMORY
;*********************************

SHRINK:		MOV	AX,ES			;AX = PSP
	      	MOV	BX,SS
	      	SUB	BX,AX
	      	ADD	BX,STACKSIZE/16		;020H
	      	MOV	AH,04AH			;SHRINK PROGRAM
	      	INT	021H
       		RET

;*********************************
;          DOS_PRINT COMMAND
;*********************************

OLDBX		DW	0
	
DOS_PRINT:	MOV	[CS:OLDBX],BX
		POP	BX		;GET STK ADDRESS

@@LOOP:		MOV	AL,[CS:BX]	;GET BYTE FROM STRING
		AND	AL,AL
		JZ	@@END

		CALL	DOS_CHAR

		INC	BX
		JMP	@@LOOP

@@END:		INC	BX
		PUSH	BX

		MOV	BX,[CS:OLDBX]
		RET

;*********************************
;        PRINT CHAR IN AL
;*********************************

SCRLOC		DW	0B800H

DOS_CHAR:	PUSH	AX
		PUSH	DX
		PUSH	BX
		PUSH	CX
		PUSH	SI
		PUSH	DI
		PUSH	ES

		CALL	GET_ATTR

		PUSH	AX
		PUSH	BX

		MOV	DL,AL
		MOV	AH,02H
		INT	021H

		POP	BX
		POP	AX

		CMP	AL,32
		JC	@@SKIP

		CMP	AL,13
		JC	@@SKIP

		CMP	AL,10
		JC	@@SKIP

		CMP	AL,9
		JC	@@SKIP

		CALL	TEXT_COLOR

		MOV	ES,[CS:SCRLOC]
		MOV	[ES:BX+1],AL	

@@SKIP:		POP	ES
		POP	DI
		POP	SI
		POP	CX
		POP	BX
		POP	DX
		POP	AX
		RET

;*********************************
;    GET ATTR ADDRESS IN BX
;*********************************

GET_ATTR:	PUSH	AX

		MOV	AH,3
		MOV	BH,0
		INT	10H

		MOV	CX,DX

		MOV	BL,CH
		MOV	BH,0

		MOV	AX,160
		MUL	BX

		MOV	BL,CL
		MOV	BH,0
		ADD	BX,BX

		ADD	BX,AX

		POP	AX
		RET

;****************************************
;		TEXT COLOR
;****************************************

COLOR		DB	7

BORDCOL		=	00000110B

COLTAB		DB	"Ú",BORDCOL
		DB	"Ä",BORDCOL
		DB	"¿",BORDCOL
		DB	"³",BORDCOL
		DB	"³",BORDCOL
		DB	"À",BORDCOL
		DB	"Ù",BORDCOL

		DB	"(",00000100B
		DB	")",00000100B
		DB	"[",2
		DB	"]",2
		DB	"*",2
		DB	"/",00000011B
		DB	"'",00000011B
		DB	"Ã",00000110B
		DB	"!",87H
		DB	0

TEXT_COLOR:	PUSH	BX

		MOV	BX,OFFSET COLTAB

@@LOOP:		CMP	[BYTE CS:BX],0
		JZ	@@QUIT

		CMP	[CS:BX],AL
		JZ	@@GOODCHR

		ADD	BX,2
		JMP	@@LOOP

@@QUIT:		MOV	AL,[CS:COLOR]
		POP	BX
		RET

@@GOODCHR:	MOV	AL,[CS:BX+1]
		POP	BX
		RET

;*********************************
;       NUMBER PRINTER IN AX
;*********************************

LEADZERO	DW	0

DOS_NUM:	PUSH	AX
		PUSH	DX
		PUSH	CX

		MOV	[CS:LEADZERO],0

		MOV	EDX,-1000000000
		CALL	PDIGIT

		MOV	EDX,-100000000
		CALL	PDIGIT

		MOV	EDX,-1000000
		CALL	PDIGIT

		MOV	EDX,-100000
		CALL	PDIGIT

		MOV	EDX,-10000
		CALL	PDIGIT

		MOV	EDX,-1000
		CALL	PDIGIT

		MOV	EDX,-100
		CALL	PDIGIT

		MOV	EDX,-10
    		CALL	PDIGIT

		MOV	[CS:LEADZERO],1

		MOV	CL,AL
		CALL	PRDIG

		POP	CX
		POP	DX
		POP	AX
		RET

;*********************************
;          PRINT A DIGIT
;*********************************

PDIGIT:		XOR	CL,CL

DIG1:		INC	CL
		ADD	EAX,EDX
		JC	DIG1

		SBB	EAX,EDX
		DEC	CL

PRDIG:		AND	CL,CL
		JNZ	@@NOTZERO

		CMP	[CS:LEADZERO],0
		JZ	@@ZERO

@@NOTZERO:	MOV	[CS:LEADZERO],1

		PUSH	AX

		MOV	AL,CL
		ADD	AL,48
		CALL	DOS_CHAR
		POP	AX
@@ZERO:		RET

;****************************************
;	   LOAD FILE AND PROCESS
;****************************************

DHAND		DW	0
FILEEXEC	DW	0

;DX FILENAME
;BX EXEC ADDR

LOAD_STREAM:	MOV	[CS:FILEEXEC],BX
		MOV	DS,[CS:CODERAM]

		MOV	AH,03DH			;READ ONLY FILE INPUT
		MOV	AL,0			;SET READ MODE ONLY
		INT	021H
	        JC	@@QUIT			;ON CY GIVE ERROR MESSAGE

		MOV	[CS:DHAND],AX
						;CLEAR
		MOV	ES,[CS:TEMPRAM]
		MOV	DI,0
		MOV	CX,8000H
		MOV	AX,1A1AH
		REP	STOSW

						;LOAD
		MOV	DS,[CS:TEMPRAM]
		MOV	DX,0

		MOV	CX,-1
		MOV	BX,[CS:DHAND]	
						 
		MOV	AH,03FH			  
		INT	021H			   
	        JC	@@QUIT			;ON CY GIVE ERROR MESSAGE
						;EXEC PROG
		CMP	[WORD CS:FILEEXEC],0
		JZ	@@CLOSE

		MOV	SI,0			;SET UP STREAM 0
		MOV	DS,[CS:TEMPRAM]

		MOV	AX,0	    		;MAKE CHANNEL 0 COMMAND LINE
		CALL	SET_REDIRECT

		MOV	AX,0			;REDIRECT TO CHANNEL 0
		CALL	REDIRECT

		MOV	BX,[CS:FILEEXEC]
		CALL	BX
						;** CLOSE FILE
@@CLOSE:	MOV	AH,03EH			;CLOSE INPUT FILE
		MOV	BX,[CS:DHAND]
		INT    	021H
	        JC	@@QUIT			;ON CY GIVE ERROR MESSAGE
		CLC
		RET

@@QUIT:		STC
		RET

;****************************************
;	      LOAD TEMPRAM
;****************************************

LOADADDR	DW	0
LOADLEN		DW	0

LOAD_TEMP:	MOV	DS,[CS:CODERAM]

		MOV	AH,03DH			;READ ONLY FILE INPUT
		MOV	AL,0			;SET READ MODE ONLY
		INT	021H
	        JC	@@QUIT			;ON CY GIVE ERROR MESSAGE

		MOV	[CS:DHAND],AX
						;CLEAR
		MOV	ES,[CS:TEMPRAM]
		MOV	DI,0
		MOV	CX,8000H
		MOV	AX,0000H
		REP	STOSW
						;LOAD
		MOV	DS,[CS:TEMPRAM]
		MOV	DX,0

		MOV	CX,[CS:LOADLEN]	
		MOV	BX,[CS:DHAND]	
						 
		MOV	AH,03FH			  
		INT	021H			   
		JC	@@QUIT

		MOV	[CS:LOADLEN],AX

		MOV	AH,03EH			;CLOSE INPUT FILE
		MOV	BX,[CS:DHAND]
		INT    	021H
		JC	@@QUIT

		CLC
		RET
						;** CLOSE FILE
@@QUIT:		MOV	AH,03EH			;CLOSE INPUT FILE
		MOV	BX,[CS:DHAND]
		INT    	021H

       		STC
		RET

;****************************************
;	      LOAD TEMPRAM
;****************************************

SAVE_TEMP:	MOV	DS,[CS:CODERAM]

		MOV	AH,03CH
		MOV	AL,0
		MOV	CX,0
		INT	021H
	        JC	@@QUIT			;ON CY GIVE ERROR MESSAGE

		MOV	[CS:DHAND],AX
						;LOAD
		MOV	DS,[CS:TEMPRAM]
		MOV	DX,0

		MOV	CX,[CS:LOADLEN]	
		MOV	BX,[CS:DHAND]	
						 
		MOV	AH,040H			  
		INT	021H			   
		JC	@@QUIT
						;** CLOSE FILE
@@CLOSE:	MOV	AH,03EH			;CLOSE INPUT FILE
		MOV	BX,[CS:DHAND]
		INT    	021H
		JC	@@QUIT

		CLC
		RET
						;** CLOSE FILE
@@QUIT:		MOV	AH,03EH			;CLOSE INPUT FILE
		MOV	BX,[CS:DHAND]
		INT    	021H

       		STC
		RET

;****************************************
;	      SKIP FILE LINE
;****************************************

SKIP_LINE:	CALL	GETCHR

		CMP	AL,1AH
		JZ	@@QUIT

		CMP	AL,13
		JZ	@@ENDLINE

		CALL	NEXTCHR
		JMP	SKIP_LINE
		
@@ENDLINE:	CALL	NEXTCHR		;SKIP 13,10
		CALL	NEXTCHR

@@QUIT:		RET

;****************************************
;	      MOVE BACK A LINE
;****************************************

BACK_LINE:	CALL	LASTCHR		;SKIP 10
		JC	@@QUIT

		CALL	LASTCHR		;SKIP 13
		JC	@@QUIT

@@LOOP:		CALL	GETCHR

		CMP	AL,10
		JZ	@@OK

		CALL	LASTCHR
		JNC	@@LOOP
@@QUIT:		RET

@@OK:		CALL	NEXTCHR
		RET
