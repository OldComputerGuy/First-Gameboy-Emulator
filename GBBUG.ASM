;*****************************************************************************
;* 			   GAME BOY MONITOR									     *
;*****************************************************************************
									    
		IDEAL
		JUMPS
		DOSSEG
		MODEL COMPACT
		STACK 512
		
		ASSUME	CS:CODESG

		SEGMENT	CODESG PARA PUBLIC
		P486N

TOPPRG:

SYMLEN		=	18		;12

INP_FILE_NAME	DB	128 DUP (?)
INP_FILE_HAND	DW	0

OUT_FILE_NAME	DB	128 DUP (?)
OUT_FILE_HAND	DW	0

READBUF		DB	258 DUP (?)

FILE_ERROR	DW	0
CODERAM		DW	0

ENTER_LINE	DB	255
ENTLEN		DB	0
ENTBUF		DB	257 DUP (0)

LABRAM		DW	0
OLDVMODE	DB	0

BYTEBUF		DB	256 DUP (0)

;*********************************
;	     PAD MACRO
;*********************************

;		MACRO	PAD @1
;		DB	@1
;		PADORG	= PADORG + 16
;		ORG	PADORG
;		ENDM	

;*********************************
;       SET UP READ BUFFER
;*********************************

READPTR		DW	0

SETREAD:	
		MOV	DS,[CS:CODERAM]
		MOV	DX,OFFSET READBUF

		MOV	ES,[CS:CODERAM]
		MOV	DI,DX
		MOV	AX,0
		MOV	CX,128
		REP	STOSW

		MOV	CX,256

		MOV	[CS:READPTR],0
		CALL	READ_BYTES

		RET

;*********************************
;  READ A BYTE FROM DISK BUFFER
;*********************************

GETBYTE:	PUSH	CX			;SAVE ALL
		PUSH	DX
		PUSH	BX
		PUSH	DI
		PUSH	SI
		PUSH	DS
		PUSH	ES

		CMP	[CS:READPTR],0100H	;HAVE WE GOT TO THE END OF
		JNZ	@@NOREAD		;THE BUFFER ? JUMP IF NOT
	 
		CALL	SETREAD			;READ IN NEXT CHUNK
	
@@NOREAD:	MOV	BX,OFFSET READBUF
		MOV	AX,[CS:READPTR]
		ADD	BX,AX
		MOV	AL,[CS:BX]
		INC	[CS:READPTR]

		POP	ES
		POP	DS
		POP	SI   			;RESTORE ALL
		POP	DI
		POP	BX
		POP	DX
		POP	CX
		RET
		

;*********************************
;      OPEN AN OUTPUT FILE
;*********************************

OPEN_OUT_FILE:	MOV	DS,[CS:CODERAM]

		MOV	AH,03CH			;CREATE OUTPUT FILE
		MOV	CX,0 			;MODE HIDDEN
		MOV	DX,OFFSET OUT_FILE_NAME
		INT	021H
	        JC	ERROR_CLOSE		;ON CY GIVE ERROR
						;AND CLOSES INPUT FILE.
		MOV	[CS:OUT_FILE_HAND],AX
		RET

;*********************************
;      OPEN AN INPUT FILE
;*********************************

OPEN_IN_FILE:	MOV	DS,[CS:CODERAM]

		MOV	AH,03DH			;READ ONLY FILE INPUT
		MOV	AL,0			;SET READ MODE ONLY
		MOV	DX,OFFSET INP_FILE_NAME
		INT	021H
	        JC	ERROR_OUT1		;ON CY GIVE ERROR MESSAGE
		MOV	[CS:INP_FILE_HAND],AX
		RET

;*********************************
;      READ BYTES FROM DISK
;
;   DS:DX = ADDRESS OF BUFFER
;      CX = LENGTH OF BUFFER 
;*********************************

READ_BYTES:	MOV	AX,[CS:FILE_ERROR]
		AND	AX,AX
		JNZ	@@OUT
					       
		MOV	BX,[CS:INP_FILE_HAND]	
						 
		MOV	AH,03FH			  
		INT	021H			   
						    
		JNC	@@OUT			     
		MOV	[CS:FILE_ERROR],AX

@@OUT:		RET

;*********************************
;       WRITE BYTE TO DISK
;DS:DX = ADDRESS OF BUFFER TO SAVE
;    CX = LENGTH OF BUFFER
;*********************************

WRITE_BYTES:	MOV	AX,[CS:FILE_ERROR]
		AND	AX,AX
		JNZ	@@OUT

		MOV	BX,[CS:OUT_FILE_HAND]
		MOV	AH,040H
		INT	021H

		JNC	@@OUT
		MOV	[CS:FILE_ERROR],AX

@@OUT:		RET

;*********************************
;	   ERROR JUMPS
;*********************************

ERROR_OUT1:	CALL	PRINT
		DB	"ERROR IN INPUT FILE !",13,10,0
		JMP	DOS_RET

ERROR_CLOSE:	CALL	FILE_IN_CLOSE

ERROR_OUT2:	CALL	PRINT
		DB	"ERROR IN OUTPUT FILE !",13,10,0
	    
DOS_RET:
		CALL	dealloc_EMS

		MOV	AX,04C00H		;NORMAL DOS RETURN
		INT	021H
		RET				;YES I KNOW I DON'T NEED
						;THIS, BUT IT FEELS SAFER
;*********************************
;       CLOSE INPUT FILE
;*********************************

FILE_IN_CLOSE:	MOV	AH,03EH			;CLOSE INPUT FILE
		MOV	BX,[CS:INP_FILE_HAND]
		INT    	021H
    		RET

;*********************************
;       CLOSE OUTPUT FILE
;*********************************

FILE_OUT_CLOSE:	MOV	AH,03EH			;CLOSE OUTPUT FILE
		MOV	BX,[CS:OUT_FILE_HAND]
		INT	021H
    		RET

;*********************************
;          GET 64K SEGMENT
;*********************************
			      
GETRAM:
		MOV	AH,048H			;SAVE 64K FOR INPUT DATA
		MOV	BX,01000H
	    INT	021H
		JC	@@NOMEM
		RET

@@NOMEM:
		CALL	PRINT
		DB	"NO MEMORY !",13,10,0
		JMP		ERROR_CLOSE

;********************************
;    GET MEM FOR PAGE MEMORY
;********************************
			      
GETMEM:		MOV	AH,048H
	      	INT	021H

		JC	@@NOMEM

		PUSH	AX

		PUSH	DI
		PUSH	ES
		PUSH	BX
		PUSH	CX
		
		ADD	BX,BX
		ADD	BX,BX
		ADD	BX,BX
		MOV	CX,BX

		MOV	ES,AX
		MOV	DI,0

		MOV	AX,0
		REP	STOSW

		POP	CX
		POP	BX
		POP	ES
		POP	DI

		POP	AX
		RET

@@NOMEM:
		CALL PRINT
		DB	"NOT ENOUGH MEMORY !",13,10
		DB	"REMOVE DEVICE DRIVER ETC.",13,10,0

		JMP		ERROR_CLOSE

;*********************************
;          PRINT COMMAND
;*********************************

OLDBX		DW	0
	
PRINT:		MOV	[CS:OLDBX],BX
		POP	BX		;GET STK ADDRESS

@@LOOP:		MOV	AL,[CS:BX]	;GET BYTE FROM STRING
		AND	AL,AL
		JZ	@@END

		CALL	PR_AL

		INC	BX
		JMP	@@LOOP

@@END:		INC	BX
		PUSH	BX

		MOV	BX,[CS:OLDBX]
		RET

;*********************************
;        PRINT CHAR IN AL
;*********************************

PR_AL:		PUSH	DX
		PUSH	BX
		PUSH	AX

		MOV	DL,AL
		MOV	AH,02H
		INT	021H
	
		POP	AX
		POP	BX
		POP	DX
		RET

;*********************************
;     PRINT HEX NUM IN AL
;*********************************

HEXTAB		DB	"0123456789ABCDEF"

HEX_AX:		PUSH	AX

		MOV	AL,AH
		CALL	HEX_AL
		
		POP	AX

HEX_AL:		PUSH	DX
		PUSH	BX
		PUSH	SI
		PUSH	DI

		MOV	AH,0
		PUSH	AX

		AND	AL,0F0H
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		MOV	BX,OFFSET HEXTAB
		ADD	BX,AX
		MOV	DL,[BYTE CS:BX]

		MOV	AH,02H
		INT	021H

		POP	AX
		AND	AL,0FH
		MOV	BX,OFFSET HEXTAB
		ADD	BX,AX
		MOV	DL,[BYTE CS:BX]

		MOV	AH,02H
		INT	021H
	
		POP	DI
		POP	SI
		POP	BX
		POP	DX
		RET

;*********************************
;       NUMBER PRINTER IN AX
;*********************************

DEC_AL:		PUSH	AX
		PUSH	DX
		PUSH	CX

		XOR	AH,AH
		JMP	DEC8

DEC_AX:		PUSH	AX
		PUSH	DX
		PUSH	CX

		MOV	DX,-10000
		CALL	PDIGIT

		MOV	DX,-1000
		CALL	PDIGIT

DEC8:		MOV	DX,-100
		CALL	PDIGIT

		MOV	DX,-10
    		CALL	PDIGIT

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
		ADD	AX,DX
		JC	DIG1

		SBB	AX,DX
		DEC	CL

PRDIG:		ADD	CL,48
		PUSH	AX
		MOV	AL,CL
		CALL	PR_AL
		POP	AX
		RET

;*********************************
;        PRINT BINARY NUM
;*********************************

BIN_AX:		MOV	DL,AL
		MOV	AL,AH
		CALL	BIN_AL

		MOV	CL,AL

		MOV	AL,"-"
		CALL	PR_AL

		MOV	AL,DL
		JMP	BIN_AL

;*********************************
;       PRINT 8 BIT BINARY
;*********************************

BIN_AL:		PUSH	AX
		PUSH	CX

		MOV	CH,AL
		MOV	CL,8

@@LOOP:		MOV	AL,"0"

		ROL	CH,1
		JNC	@@ZERO

		MOV	AL,"1"

@@ZERO:		CALL	PR_AL

		DEC	CL
		JNZ	@@LOOP

		POP	CX
		POP	AX
		RET

;*********************************
;     WAIT FOR LOADS OF TIME
;*********************************

WAIT_KEY:	MOV	AH,08H		;WAIT FOR KEY
		INT	021H
		RET

;*********************************
;  GET A COMMAND TAIL PARAMETER
;
; SI:DS = POINTS TO COMMAND TAIL
;    DI:ES = PARAM POINTER  
;*********************************

GET_PARA:	MOV	CL,0

@@LOOP:		MOV	AL,[DS:SI]	;GET DATA FROM PSP COMMAND TAIL
	 	
		CMP	AL,32
		JZ	@@END

		CMP	AL,0
		JZ	@@NOEND

		CMP	AL,13
		JZ	@@NOEND

		MOV	[CS:DI],AL
		INC	SI
		INC	DI
		INC	CL
		JMP	@@LOOP

@@END:		INC	SI
		OR	CL,CL
		JZ	@@NOEND

		MOV	[BYTE CS:DI],0

@@NOEND:	RET

;****************************************
;           EVALUATE EXPRESSION
;          SI POINTS TO EQUATION
;              * BX = VALUE
;****************************************

EVAL_ERROR	DW	0
OLDSP		DW	0

STKCNT		DW	0
NSTK		DB	128 DUP (?)

EVAL:		MOV	[CS:EVAL_ERROR],0

		CALL	DO_EVAL

		CMP	[CS:STKCNT],0
		JNZ	@@ERROR

		CMP	[CS:EVAL_ERROR],1
		JZ	@@ERROR

		CLC
		RET

@@ERROR:	STC
		RET

;****************************************
;		DO EVAL
;****************************************

DO_EVAL:	MOV	[CS:OLDSP],SP

		MOV	DI,OFFSET NSTK	;SET UP NUMBER STK
		MOV	[CS:STKCNT],0

		MOV	BX,OFFSET UNSTK
		PUSH	BX

		MOV	AL,[CS:SI]

		CMP	AL,32
		JZ	SETCY

		CMP	AL,","
		JZ	SETCY

RECURSE:	XOR	AL,AL		;PUT A ZERO ON THE STK
		PUSH	AX

;****************************************
;	RPNC MAIN LOOP
;****************************************

RPLOOP1:	CALL	STKNUM
		
		MOV	AL,[CS:SI]

		CMP	AL,32		;FOUND A SPACE UNRECURSE
		JZ	DROP1

		CMP	AL,13  		;FOUND END OF LINE UNRECURSE OR STOP
		JZ	DROP1

		CMP	AL,","		;FOUND DIVIDER UNRECURSE
		JZ	DROP1

		CMP	AL,")"		;FOUND END BRACKET UNRECURSE
		JZ	DROP1

		CMP	AL,"("		;FOUND A LEFT BRACKET
		JZ	BRACKL		;RECURSE PARSE

		CALL	PRIORTY		;GET CURRENT SIGNS PRIORITY IN CL
		MOV	CH,CL		;STORE NEW FOUND SIGNS PRIOR IN CH

PRIORLP1:	POP	AX		;GET TOP ENTRY
		PUSH	AX

		CMP	AL,0		;IS IT THE LAST ONE
		JZ	PRIOR1		;JUMP IF LAST ENTRY

		CALL	PRIORTY		;GET SIGN A TOP OF STK PROIR IN CL
		
		CMP	CL,CH		;WHICH SIGN IS GREATER
		JC	PRIOR1

		POP	AX 		;UNSTK A SIGN
		
		CALL	DOSIGN		;DO THIS SIGN : SAVE CX
		JMP	PRIORLP1

PRIOR1:		MOV	AL,[CS:SI]	;GET NEXT SIGN ON THE STK
		PUSH	AX

		INC	SI		;GET NEXT CHR
		JMP	RPLOOP1		;GET NEXT NUMBER

DROP1:		INC	SI		;FOUND A BRACKET OR DIVIDOR
					;DROP ALL SIGNS AND EXIT

@@DROP2:	POP	AX		;IS THIS THE END OF THE STK

		CMP	AL,0
		JZ	@@EXIT		;IF IT IS THEN END

		CALL	DOSIGN		;ELSE, PERFORM IT'S FUNCTION
		JMP	@@DROP2

@@EXIT:		RET

;****************************************
;	  BRACKET LEFT FOUND
;         SO RECURSE EVALUATOR
;****************************************

BRACKL:		INC	SI		;GO TO NEXT CHR
		CALL	RECURSE		;EVALUATE TILL BRACKET RIGHT
		JMP	RPLOOP1		;RETURN TO LOOP

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

DIGIT:		MOV	AL,[CS:SI]

DIGIT_AL:	CALL	TESTCASE

		CMP	[CS:BASE],10
		JZ	DIG_09

		CMP	[CS:BASE],2
		JZ	DIG_01

DIG_0F:		CMP	AL,"A"
		JC	DIG_09

		CMP	AL,"G"
		CMC
		JC	@@EXIT

		SUB	AL,55
@@EXIT:		RET

DIG_09:		CMP	AL,":"
		CMC
		JC	@@EXIT

		CMP	AL,"0"
		JC	@@EXIT

		SUB	AL,48
@@EXIT:		RET

DIG_01:		CMP	AL,"2"
		CMC
		JC	@@EXIT

		CMP	AL,"0"
		JC	@@EXIT

		SUB	AL,48
@@EXIT:		RET

;****************************************
;          MULTIPLY BY BASE
;           BETWEEN 2,10,16
;         C = OVERFLOW DETECT
;****************************************

MULBASE:	ADD	BX,BX

		CMP	[CS:BASE],2
		JZ	@@EXIT

		MOV	DX,BX

		ADD	BX,BX
		ADD	BX,BX
		ADD	BX,DX

		CMP	[CS:BASE],10
		JZ	@@EXIT

		ADD	BX,DX
		ADD	BX,DX
		ADD	BX,DX

@@EXIT:		RET

;****************************************
;	    TEST NUMBERS BASE
;****************************************

GETBASE:	MOV	AL,[CS:SI]		;GETCHR

		CMP	AL,"-"
		JZ	@@UNARY

		CMP	AL,"%"			;TEST BINARY
		JZ	@@SETBIN 		;JUMP IF NOT BIN

		CMP	AL,"#"
		JZ	@@SETHEX

		CALL	DIG_09
		JNC	@@SETDEC

		MOV	[CS:BASE],0FFFFH	;SIGNIFY LABEL
		RET

@@UNARY:	MOV	[CS:NEGFLAG],1
		INC	SI
		JMP	GETBASE

@@SETDEC:	MOV	[CS:BASE],10		;SAY DECIMAL
		RET

@@SETBIN:	MOV	[CS:BASE],2		;SAY BINARY
		INC	SI
		RET

@@SETHEX:	MOV	[CS:BASE],16		;SAY HEX
		INC	SI
		RET

;****************************************
;      GET A NUMBER OFF SCREEN
;****************************************

NEGFLAG		DW	0
BASE		DW	10

GETNUM:		MOV	[CS:NEGFLAG],0

		CALL	GETBASE

		CMP	[CS:BASE],0FFFFH
		JZ	GETLABEL

		MOV	BX,0

@@LOOP:		CALL	MULBASE

		CALL	DIGIT
		JC	@@EXIT

		XOR	AH,AH
		ADD	BX,AX

		INC	SI

		CALL	DIGIT
		JNC	@@LOOP

@@EXIT:		CMP	[CS:NEGFLAG],1
		JNZ	@@QUIT		

		NEG	BX
@@QUIT:		RET

;****************************************
;           PROCESS LABELS
;****************************************

GETLABEL:	PUSH	DI
		CALL	FINDLABEL
		POP	DI
		JC	@@ERROR

		CMP	[CS:NEGFLAG],1
		JNZ	@@QUIT		

		NEG	BX
@@QUIT:		RET

@@ERROR:	CALL	PRINT
		DB	"LABEL NOT FOUND !",10,13,0

	    	JMP	EXP_ERROR

;****************************************
;	       STK NUMBER
;****************************************

STKNUM:		MOV	AL,[CS:SI]
	
		CALL	VALIDTEST
		JC	@@EXIT

		CALL	GETNUM
		CALL	STK

		CLC
@@EXIT:		RET

;****************************************
;  TEST FOR LABELS,DECIMAL,HEX,BINARY
;    CYSET IF NOT IN THIS CATAGORY
;****************************************

VALIDCHR	DB	"1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		DB	"abcdefghijklmnopqrstuvwxyz$&_[]{}#%-"
		DB	255

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

;****************************************
;  TEST FOR LABELS,DECIMAL,HEX,BINARY
;    CYSET IF NOT IN THIS CATAGORY
;****************************************

VALID2		DB	"1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		DB	"abcdefghijklmnopqrstuvwxyz$&_"
		DB	255

VALIDLAB:	PUSH	BX

		MOV	BX,OFFSET VALID2

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


;****************************************
;	     STK A NUMBER
;****************************************

STK:		MOV	[CS:DI],BX
		ADD	DI,2
		INC	[CS:STKCNT]
		RET

;****************************************
;	   UNSTK A NUMBER
;****************************************

UNSTK:		SUB	DI,2
		MOV	BX,[CS:DI]
		DEC	[CS:STKCNT]
		RET

UNSTK_AX: 	SUB	DI,2
		MOV	AX,[CS:DI]
		DEC	[CS:STKCNT]
SETCY:		RET

;****************************************
;	    GET PRIORTY
;****************************************

PRIORTAB:	;DB	"!",1
		;DB	"&",2
		;DB	"<",3
		;DB	">",3
		;DB	"=",3

		DB	"+",4
		DB	"-",4
		DB	"*",5
		DB	"/",5
		DB	255

PRIORTY:	PUSH	BX

		MOV	CL,AL
		MOV	BX,OFFSET PRIORTAB
		
PRILP:		MOV	AL,[CS:BX]
		CMP	AL,CL
		JZ	GETPRI
		
		CMP	AL,255	
		JZ	OUTPRI

		ADD	BX,2
		JMP	PRILP	

GETPRI:		INC	BX
		MOV	CL,[CS:BX]

		POP	BX
		RET

OUTPRI:		POP	BX

		CALL	PRINT
		DB	"SIGN IS INVALID !",10,13,0

		JMP	EXP_ERROR

;****************************************
;	     DO SIGNS PRG
;****************************************

DOSIGN:		CMP	AL,"*"
		JZ	MULM

		CMP	AL,"/"
		JZ	DIVM

		CMP	AL,"+"
		JZ	ADDSP

		CMP	AL,"-"
		JZ	SUBSP

		CALL	PRINT
		DB	"SIGN IS INVALID !",10,13,0

		JMP	EXP_ERROR

;****************************************
;   INVALID SIGN EXIT EXPRESSION EVAL
;****************************************

EXP_ERROR:	MOV	SP,[CS:OLDSP]		;RETRIEVE ENTRY STACK
		MOV	[EVAL_ERROR],1
		RET
		
;****************************************
;	     ADD TOP STK
;****************************************

ADDSP:		CALL	UNSTK
		MOV	DX,BX
		CALL	UNSTK
		ADD	BX,DX
		JMP	STK

;****************************************
;	     SUB TOP STK
;****************************************

SUBSP:		CALL	UNSTK
		MOV	DX,BX
		CALL	UNSTK
		SUB	BX,DX
		JMP	STK

;****************************************
;	     MULT TOP STK
;****************************************

MULM:		CALL	UNSTK
		CALL	UNSTK_AX

		MUL	BX
		MOV	BX,AX
		JMP	STK

;****************************************
;	    DIVIDE TOP STK
;****************************************

DIVM:		CALL	UNSTK
		CALL	UNSTK_AX
		DIV	BX
		MOV	BX,AX
		JMP	STK

;*********************************
;        PRINT WHATS THIS?
;            CX = X POS
;*********************************
	
WHATTHIS:	INC	CL
		INC	CL

@@LOOP:		MOV	AL,32
		CALL	PR_AL
		LOOP	@@LOOP

		CALL	PRINT
		DB	"^ What's this ?",13,10,13,10,0
		RET

;*********************************
;        INPUT NEXT COMMAND
;*********************************
	
INPUT:		MOV	ES,[CS:CODERAM]
		MOV	DI,OFFSET ENTBUF
		MOV	CX,128
		MOV	AX,0
		REP	STOSW

		CALL	TARGSTATE

		MOV	AL,">"
		CALL	PR_AL

		MOV	DS,[CS:CODERAM]
		MOV	DX,OFFSET ENTER_LINE
		MOV	AH,0AH
		INT	21H

		INC	[BYTE CS:ENTLEN]

		CALL	PRINT
		DB	13,10,0
      		RET

;*********************************
;     GET COMMAND LINE BYTE
;*********************************

GETCHR:		MOV	AL,[CS:SI]		;MAKE THIS UPPER CASE
		AND	AL,11011111B
      		RET

NEXTCHR:	INC	SI
		RET

SKIPGARB:	CALL	GETCHR
		CMP	AL,0DH
		JZ	@@QUIT

		CMP	AL,32
		JG	@@EXIT

		CALL	NEXTCHR
		JMP	SKIPGARB

@@EXIT:		CLC
		RET

@@QUIT:		STC
		RET

;*********************************
;   GET TARGET CONNECTION STATE
;*********************************

TARGSTATE:	MOV	AX,[CS:MONFLAGS]
		AND	AX,0001H
		JNZ	@@NOPROMPT

		MOV	DL,55H		;TEST #55
		MOV	AL,4 		;ECHO
;		INT	82H

		MOV	DL,AL

		MOV	AL,"+"

		CMP	DL,55H
		JZ	@@CON

		MOV	AL,"-"

@@CON:		CALL	PR_AL
		RET

@@NOPROMPT:	RET


;*********************************
;      TEST CONNECTION STATE
;*********************************

TESTCON:	MOV	DL,55H		;TEST #55
		MOV	AL,4 		;ECHO
;		INT	82H
		CMP	AL,55H
		JZ	@@CON
		STC
      		RET

@@CON:		CLC
		RET

;*********************************
;     CLEAR OUT LABEL TABLE
;*********************************

CLR_LAB_TAB:	MOV	AX,2020H		;FILL WITH SPACES
		MOV	CX,8000H		;FILL #4000 WORDS
		MOV	ES,[CS:LABRAM]		;AT LABTAB SEGMENT
		MOV	DI,0
		REP	STOSW
		RET

;*********************************
;       SET UP LABEL TABLE
;*********************************
	
LABS_NAME	DB	"SYM.TAB",0,0,0,0

SET_LAB_TAB:	MOV	DS,[CS:CODERAM]

		MOV	AH,03DH			;READ ONLY FILE INPUT
		MOV	AL,0			;SET READ MODE ONLY
		MOV	DX,OFFSET LABS_NAME
		INT	021H

	        JNC	@@LABOK

		CALL	PRINT
		DB	"No symbol table loaded !",13,10,13,10,0
		RET

@@LABOK:	MOV	[CS:INP_FILE_HAND],AX

		CALL	COPY_LABS

		CALL	FILE_IN_CLOSE
		RET

;*********************************
;  COPY LABELS INTO LABEL SPACE
;*********************************
   
COPY_LABS:	CALL	SETREAD			;SET UP READING BUFFERS

		MOV	ES,[CS:LABRAM]		;ES:DI = LABEL AREA
		MOV	DI,0

@@LOOP:		CALL	GETBYTE			;TEST FIRST BYTE
		CMP	AL,26			;test for eof
		JZ	@@LASTSYM
		CMP	AL,0
		JZ	@@LASTSYM

		CALL	GETNAME			;GET ALL DATA

		CALL	GETBYTE			;SKIP CR
		CALL	GETBYTE			;SKIP LF

		JMP	@@LOOP
@@LASTSYM:	RET

;*********************************
;    EXTRACT LABEL AND ADDRESS
;AND PLACE THIS IN THE LABEL TABLE
;*********************************

GETNAME:	PUSH	DI			;STORE LABEL ADDRESS

		STOSB				;PUT FIRST PART OF LABEL

		MOV	CX,SYMLEN-3		;DO A MAX OF 10 CHRS
	
@@LOOP:		CALL	GETBYTE			;ONE BYTE

		CMP	AL,9			;
	    	JZ	@@END

		CMP	AL,32
		JZ	@@END

		STOSB				;STORE LABEL BYTE IN ES:DI
		LOOP	@@LOOP			;

@@END:		POP	DI			;GET OLD DI
		ADD	DI,SYMLEN-2		;ADD OVER LABEL AREA

@@LOOP2:	CALL	GETBYTE			;GET BYTE FROM FILE
		CMP	AL,"$"			;LOOK FOR "$" SIGN
		JNZ	@@LOOP2
			
		MOV	[CS:BASE],16		;SET TO BASE 16
		MOV	BX,0			;COUNT = 0

		CALL	GETBYTE			;EXTRACT NUMBER ASCII			
		CALL	DIGIT_AL		;CONVERT TO REAL NUMBER
		XOR	AH,AH			;ADD THIS TO COUNTER
		ADD	BX,AX

		CALL	MULBASE			;MULTIPLY NUMBER BY 16
		CALL	GETBYTE			;EXTRACT NUMBER ASCII			
		CALL	DIGIT_AL		;CONVERT TO REAL NUMBER
		XOR	AH,AH			;ADD THIS TO COUNTER
		ADD	BX,AX

		CALL	MULBASE			;MULTIPLY NUMBER BY 16
		CALL	GETBYTE			;SO ON FOR 4 DIGITS
		CALL	DIGIT_AL
		XOR	AH,AH
		ADD	BX,AX

		CALL	MULBASE
		CALL	GETBYTE			
		CALL	DIGIT_AL
		XOR	AH,AH
		ADD	BX,AX

		CALL	MULBASE
		CALL	GETBYTE			
		CALL	DIGIT_AL
		XOR	AH,AH
		ADD	BX,AX

		MOV	AX,BX			;GET NUMBER IN AX
		STOSW				;STORE IT TO ES:DI
		RET

;*********************************
;            FIND LABEL
;      CS:SI POINTS TO LABEL
;*********************************

LABBUF:		DB	64 DUP (0)

FINDLABEL:	MOV	DI,OFFSET LABBUF	;CLEAR OUT LABEL BUFFER
		MOV	CX,SYMLEN-2
		
@@LOOP:		MOV	[BYTE CS:DI],32
		INC	DI
		LOOP	@@LOOP
	
		MOV	DI,OFFSET LABBUF	;SET UP LABEL BUFFER
		MOV	CX,SYMLEN-2

@@LAB1:		MOV	AL,[CS:SI]		;PUT LABEL IN LABEL BUFFER 
		CALL	VALIDLAB
		JC	@@END

		MOV	[CS:DI],AL
		INC	DI
		INC	SI
		LOOP	@@LAB1

@@END:		PUSH	SI			;SAVE COMMAND LINE POS

		MOV	DS,[CS:LABRAM] 		;POINT DS:SI TO BASE OF
		MOV	SI,0			;LABEL TABLE

		MOV	CX,2047 
		
@@TESTLOOP:	PUSH	CX
		PUSH	SI
		CALL	COMPARE
		POP	SI
		POP	CX

		JC	@@FOUND

		ADD	SI,SYMLEN
		LOOP	@@TESTLOOP

		POP	SI

		MOV	BX,0			;COULD NOT FIND LABEL
		STC
		RET		

@@FOUND:       	MOV	BX,[SI+(SYMLEN-2)]
		POP	SI

		CLC
		RET
	
;*********************************
;          COMPARE LABELS
;*********************************

COMPARE:	MOV	DI,OFFSET LABBUF
		MOV	CX,SYMLEN-2

@@LOOP:		LODSB
		CMP	AL,[CS:DI]
		JZ	@@OK

		CLC
		RET

@@OK:		INC	DI	
		LOOP	@@LOOP

		STC
		RET

;*********************************
;         SET VIDEO MODE
;*********************************

SETVMODE:
		MOV	AH,0
		INT	10H
		RET

;*********************************
;     SET TO VGA 320 x 200
;*********************************

SET_VGA:
		MOV	AX,0013H		;MCGA 13H
		INT	010H

		MOV		[CS:DISP_ON],1
		RET

;*********************************
;       SET TEXT VIDEO MODE
;*********************************

SET_TEXT_MODE:
		MOV	AX,0002H
		INT	10H

		XOR	BL,BL			;SET 80 50 MODE
		MOV	AX,1112H
		INT	10H

;crt_rows	equ	84h

		mov	ax,40h			;bios data segment
		mov	ds,ax

		mov	al,10
		mov	[byte ds:84h],al	;must be rows-1

		MOV		[CS:DISP_ON],0
		RET

;*********************************
;           MAIN ENTRY
;*********************************

START:		CLD
		MOV	[CS:CODERAM],CS

		MOV	AX,0002H
		INT	10H

		MOV	AX,ES			;AX = PSP
	      	MOV	BX,SS
	      	SUB	BX,AX
	      	ADD	BX,020H
	      	MOV	AH,04AH			;SHRINK PROGRAM
	      	INT	021H

		CALL	TEST_EMS
		CALL	Enough_EMS
		CALL	Alloc_EMS

		MOV	SI,082H			;POINT SI TO COMMAND TAIL
		MOV	DI,OFFSET INP_FILE_NAME	;GET NAME OF INPUT FILE
		CALL	GET_PARA		;INTO BUFFER

		CALL	GET_VMODE

		CALL	SET_TEXT_MODE
		
		CALL	GETRAM
		MOV	[CS:LABRAM],AX

		MOV		BX,1000H
		CALL	GETMEM
		MOV		[CS:DISPMEM],AX

		CALL	CLR_LAB_TAB
		CALL	SET_LAB_TAB		;SET UP LABEL TABLE

		CALL	READ_PRG
		CALL	RESET_CPU
		
		CALL	UPDATE_MON
		CALL	DIS_WINDOW
		
MAIN:	CALL	INPUT
		CALL	FUNCTIONS
       	JMP	MAIN

;*********************************
;        COMMAND FUNCTIONS
;*********************************

FUNCTIONS:	MOV	SI,OFFSET ENTBUF
		MOV	AL,[CS:SI]

		CMP	AL,13
		JZ	@@QUIT
			 
		CMP	AL,"Q"
		JZ	QUIT

		CMP	AL,"q"
		JZ	QUIT

		CMP	AL,"x"
		JZ	GETEXP

		CMP	AL,"m"
		JZ	DUMP

		CMP	AL,"d"
		JZ	DUMPCODE

		CMP	AL,"c"
		JZ	DUMPCHR

		CMP	AL,"w"
		JZ	SETWORD

		CMP	AL,"W"
		JZ	SETWIDE

		CMP	AL,"D"
		JZ	SETDEPTH

		CMP	AL,"b"
		JZ	SETBYTE

		CMP	AL,"r"		;radix
		JZ	SETBASE

		CMP	AL,"z"
		JZ	SET_BANK

		CMP	AL,"g"
		JZ	GOTOADDR

		CMP	AL,"l"
		JZ	LABELS

;		CMP	AL,"N"
;		JZ	SEND_DATA

;		CMP	AL,"I"
;		JZ	REC_DATA

;		CMP	AL,"R"
;		JZ	SET_RATE

;		CMP	AL,"r"
;		JZ	SEND_LOTS

;		CMP	AL,"F"
;		JZ	SET_FLAGS

		CMP	AL,"v"
		JZ	NEAR_LABEL

		;CMP	AL,"?"
		;JZ	HELP

		CMP	AL,"C"
		JZ	CLS

;		CMP	AL,"i"
;		JZ	BugInfo

;		CMP	AL,"n"
;		JZ	Next

		CMP	AL,"t"
		JZ	TRACE

		MOV	CX,0
		CALL	WHATTHIS

@@QUIT:		RET

;*********************************
;	    QUIT GBMON
;*********************************

QUIT:	CALL	PRINT
		DB	27,"[2J",0

		CALL	OLD_VMODE

		mov		ax,[cs:banks]
		call	HEX_AX


		mov		ax,[cs:emm_Seg]
		call	HEX_AX

		JMP		DOS_RET

;*********************************
;     GET CURRENT VIDEO MODE
;*********************************

GET_VMODE:	MOV	AH,0FH
		INT	010H
		MOV	[CS:OLDVMODE],AL
		RET

;*********************************
;     SET TO OLD VIDEO MODE
;*********************************

OLD_VMODE:	;MOV	AH,0FH
		;INT	010H

		;CMP	AL,[CS:OLDVMODE]
		;JZ	@@SAME

		MOV	AL,[CS:OLDVMODE]
		XOR	AH,AH
		INT	010H

@@SAME:		RET

;*********************************
;        NEAREST LABEL
;*********************************

NEAR_LABEL:	INC	SI
		INC	SI
    		CALL	EVAL

		PUSH	BX

		CALL	PRINT
		DB	13,10
		DB	"Nearest label(s)",13,10
		DB	"~~~~~~~~~~~~~~~~",13,10,0

		POP	AX

		MOV	ES,[CS:LABRAM]		;ES:DI = LABEL AREA
		MOV	DI,0

@@LOOP:		CMP	[BYTE ES:DI],32
		JZ	@@QUIT

		MOV	SI,AX
		SUB	SI,[WORD ES:DI+(SYMLEN-2)]
		JNC	@@FOUND

@@NOTNEAR:	ADD	DI,SYMLEN
		JMP	@@LOOP

@@FOUND:	AND	SI,SI
		JNZ	@@NEAR

		PUSH	DI
		PUSH	AX

		CALL	PR_LAB

		CALL	PRINT
		DB	"*",13,10,0

		POP	AX
		POP	DI
		JMP	@@NOTNEAR		

@@NEAR:		CMP	SI,8
		JNC	@@NOTNEAR

		PUSH	DI
		PUSH	AX
       
		CALL	PR_LAB
		
		MOV	AL,"+"
		CALL	PR_AL

		MOV	AL,"#"
		CALL	PR_AL
		
		MOV	AX,SI
		CALL	HEX_AL
	
		CALL	PRINT
		DB	13,10,0

		POP	AX
		POP	DI
		JMP	@@NOTNEAR		

@@QUIT:		CALL	PRINT
		DB	13,10,0
		RET

;*********************************
;        SCAN FOR LABELS
;*********************************

SLEN		DW	0

LABELS:		INC	SI

		CMP	[BYTE CS:SI],13
		JZ	@@HERE

		INC	SI			;SI POINTS TO LABEL

@@HERE:		PUSH	SI			;GET STRING LENGTH
		MOV	CX,0			;COUNTER FOR LEN

@@SLEN:		CMP	[BYTE CS:SI],13 		;LOOK FOR CR
		JZ	@@ENDS
		INC	SI
		INC	CX
		JMP	@@SLEN

@@ENDS:		POP	SI

		MOV	[CS:SLEN],CX

		MOV	DI,0			;DI = POINTS TO LABEL TABLE
		MOV	ES,[CS:LABRAM]		;ES = LABEL MEM

@@LOOP:		MOV	AL,[ES:DI]
		CMP	AL,20H
		JZ	@@LAST

		PUSH	SI
		PUSH	DI
		PUSH	CX
		CALL	TESTLAB
		POP	CX
		POP	DI
		POP	SI
		JNC	@@NOPRINT

		PUSH	DI
		PUSH	SI
		CALL	PRNAME
		POP	SI
		POP	DI

@@NOPRINT:	ADD	DI,SYMLEN
		JMP	@@LOOP

@@LAST:		RET

;*********************************
;	PRINT LABLE NAME
;*********************************

PRNAME:		MOV	CX,SYMLEN-2

@@PRLP:		MOV	AL,[ES:DI]
		INC	DI
		CALL	PR_AL
		LOOP	@@PRLP		

		MOV	BX,[ES:DI]

		CALL	DNUM_BX
		RET

;*********************************
;          COMPARE LABELS
;*********************************

TESTLAB:	MOV	CX,[CS:SLEN]
		AND	CX,CX
		JZ	@@STCY

@@LOOP:		MOV	AL,[CS:SI]
		CMP	AL,[ES:DI]
		JZ	@@OK

		CLC
		RET

@@OK:		INC	DI 
		INC	SI	
		LOOP	@@LOOP

@@STCY:		STC
		RET

;*********************************
;          CLS COMMAND
;*********************************
	
CLS:		INC	SI
		MOV	AL,[CS:SI]
		CMP	AL,"L"
		JNZ	@@EXIT

    		INC	SI
		MOV	AL,[CS:SI]
		CMP	AL,"S"
		JNZ	@@EXIT

		MOV	AX,0002H
		INT	10H



;		CALL	PRINT
;		DB	27,"[2J",0
		RET

@@EXIT:		RET

;*********************************
;         GET EXPRESSION
;*********************************

GETEXP:		INC	SI
		INC	SI
    		CALL	EVAL
		JNC	DNUM_BX

		RET

DNUM_BX:	CALL	PRINT
		DB	"Hex #",0

		MOV	AX,BX
		CALL	HEX_AX

		CALL	PRINT
		DB	" , Dec ",0

		MOV	AX,BX
		CALL	DEC_AX

		CALL	PRINT
		DB	" , Bin ",0

		MOV	AX,BX
		CALL	BIN_AX

		CALL	PRINT
		DB	" , Chr ",0

		MOV	AL,BH
		CALL	CHRCODE

		MOV	AL,BL
		CALL	CHRCODE

		CALL	PRINT
		DB	13,10,0
		RET

;*********************************
;         SET DUMP BASE 
;*********************************

MBASE		DB	"H"

SETBASE:	INC	SI
		INC	SI
		MOV	AL,[CS:SI]
		AND	AL,11011111B

		CMP	AL,"B"
		JNZ	@@1
		MOV	[CS:MBASE],AL
		JMP	@@EXIT

@@1:		CMP	AL,"H"
		JNZ	@@2
		MOV	[CS:MBASE],AL
		JMP	@@EXIT

@@2:		CMP	AL,"D"
		JNZ	@@3
		MOV	[CS:MBASE],AL
		JMP	@@EXIT

@@3:		CALL	PRINT
		DB	"Settings are (D)ecimal (B)inary (H)ex",13,10
		DB	"current setting is (",0

		MOV	AL,[CS:MBASE]
		CALL	PR_AL

		CALL	PRINT
		DB	")",10,13,0
		RET

@@EXIT:		RET

;*********************************
;             SET BANK
;*********************************

SET_BANK:
		INC	SI
		INC	SI

		CALL	EVAL
		JC		EXIT

		MOV	DL,BL
;		MOV	AX,3
;		INT	82H

		mov		al,bl
		call	BankEmm
		RET

;*********************************
;	 an Instraction
;*********************************
 
TRACE:
		CALL	DIS_WINDOW
		RET

;*********************************
;     SET UPLOAD DOWNLOAD RATE
;*********************************

SET_RATE:	INC	SI
		INC	SI
		CALL	EVAL
		JC	EXIT

		PUSH	BX		;BX HOLDS RATE

		MOV	AX,8		;SET RATE HERE
;		INT	82H

		CALL	PRINT
		DB	"UPLOAD DOWNLOAD RATE (DEFAULT 700) = ",0

		POP	AX
		CALL	DEC_AX

		CALL	PRINT
		DB	13,10,0
		RET

;*********************************
;          SET MONFLAGS
;*********************************

MONFLAGS	DW	0

SET_FLAGS:	CMP	[CS:ENTLEN],2
		JNZ	@@NOPE

		MOV	BX,[CS:MONFLAGS]
		JMP	@@OK

@@NOPE:		INC	SI
		INC	SI
		CALL	EVAL
		JC	EXIT

@@OK:		PUSH	BX		;BX HOLDS RATE

		MOV	[CS:MONFLAGS],BX

		CALL	PRINT
		DB	"MONITOR FLAGS = ",0

		POP	AX
		CALL	BIN_AX

		CALL	PRINT
		DB	13,10
		DB	0
		RET


;*********************************
;         SEND RAW DATA
;*********************************

SEND_DATA:	INC	SI
		INC	SI

@@ANOTHER:	CALL	EVAL
		JC	EXIT

		MOV	AL,BL			;SEND BYTE DIRECT
;		INT	80H

		DEC	SI
		CMP	[BYTE CS:SI],","
		JNZ	EXIT

		INC	SI
		JMP	@@ANOTHER

;*********************************
;         RECEIVE RAW DATA
;*********************************

SEND_LOTS:	MOV	CX,1

		CMP	[CS:ENTLEN],2
		JZ	@@LOOP

		INC	SI
		INC	SI

@@ANOTHER:	CALL	EVAL
		JC	EXIT

		MOV	CX,BX
		MOV	CH,0

@@LOOP:		PUSH	CX

		MOV	AL,CL			;SEND BYTE DIRECT
;		INT	80H

		POP	CX
		LOOP	@@LOOP

		RET		

;*********************************
;         RECEIVE RAW DATA
;*********************************

REC_DATA:	MOV	CX,1

		CMP	[CS:ENTLEN],2
		JZ	@@LOOP

		INC	SI
		INC	SI

@@ANOTHER:	CALL	EVAL
		JC	EXIT

		MOV	CX,BX
		MOV	CH,0

@@LOOP:		PUSH	CX
;		INT	81H			;RECEIVE DATA

		CALL	HEX_AL

		CALL	PRINT
		DB	" ",0

		POP	CX
		LOOP	@@LOOP

		CALL	PRINT
		DB	13,10,0

		RET		

;*********************************
;         GOTO ADDRESS
;*********************************

GOTOADDR:
		INC	SI
		INC	SI
		CALL	EVAL
		JC	EXIT

		MOV		[WORD CS:DISCUR],BX
		MOV		[WORD CS:DIS_ADDR],BX

		CALL	CHECK_CUR
		RET

;*********************************
;       READ OR SET A BYTE 
;*********************************

SETBYTE:	INC	SI
		INC	SI
		CALL	EVAL
		JC	EXIT

		DEC	SI
		CMP	[BYTE CS:SI],","
		JZ	@@POKE

		MOV	CX,1
		CALL	GET_BYTES

		MOV	BL,[CS:BYTEBUF]
		XOR	BH,BH
		JMP	DNUM_BX

@@POKE:		INC	SI
		PUSH	BX

		CALL	EVAL
		MOV	DX,BX

		POP	BX
		JC	EXIT

		MOV	[CS:BYTEBUF],DL

		MOV	ES,[CS:CODERAM]
		MOV	DI,OFFSET BYTEBUF
		MOV	CX,1
		MOV	AX,0
;		INT	82H
		RET

;*********************************
;       READ OR SET A WORD 
;*********************************

SETWORD:	INC	SI
		INC	SI
		CALL	EVAL
		JC	EXIT
		
		DEC	SI
		CMP	[BYTE CS:SI],","
		JZ	@@POKE

		MOV	CX,2
		CALL	GET_BYTES

		MOV	BX,[WORD CS:BYTEBUF]
		JMP	DNUM_BX

@@POKE:		INC	SI
		PUSH	BX

		CALL	EVAL
		MOV	DX,BX

		POP	BX
		JC	EXIT

		MOV	[WORD CS:BYTEBUF],DX

		MOV	ES,[CS:CODERAM]
		MOV	DI,OFFSET BYTEBUF
		MOV	CX,2
		MOV	AX,0
;		INT	82H
		RET

;*********************************
;      SET DUMP WITDH SIZE 
;*********************************

SETWIDE:	INC	SI
		INC	SI
		CALL	EVAL
		JC	EXIT

		CMP	BX,0
		JZ	EXIT

		CMP	BX,255
		JA	EXIT

		MOV	[CS:WIDE],BX

		CALL	PRINT
		DB	"Width set",13,10,0

EXIT:		RET

;*********************************
;      SET DUMP DEPTH SIZE 
;*********************************

SETDEPTH:	INC	SI
		INC	SI
		CALL	EVAL
		JC	EXIT

		CMP	BX,0
		JZ	EXIT

		CMP	BX,255
		JA	EXIT

		MOV	[CS:DEPTH],BX

		CALL	PRINT
		DB	"Depth set",13,10,0

		RET

;*********************************
;          DUMP MEMORY
;*********************************
          
DEPTH		DW	4
WIDE		DW	16
MONADD		DW	0

DUMP:		CMP	[CS:ENTLEN],2
		JNZ	@@NOPE

		MOV	BX,[CS:MONADD]
		JMP	@@DUMP	

@@NOPE:		INC	SI
		INC	SI
		CALL	EVAL

@@DUMP:		MOV	DL,[BYTE CS:DEPTH]

@@LOOP1:
		MOV	AX,BX
		CALL	HEX_AX

 		MOV	AL,32
		CALL	PR_AL

		MOV	CX,[CS:WIDE]

		CALL	GET_BYTES 		;GET BYTES AT BX LEN CX
						;INTO BYTEBUF
		MOV	DI,OFFSET BYTEBUF

@@LOOP2:	MOV	AL,[CS:DI]
		CALL	BASE_AL

		MOV	AL,32
		CALL	PR_AL

		INC	DI
		LOOP	@@LOOP2

		MOV	AL,13
		CALL	PR_AL

		MOV	AL,10
		CALL	PR_AL

		ADD	BX,[CS:WIDE]

		DEC	DL
		JNZ	@@LOOP1

		MOV	[CS:MONADD],BX
		RET

;*********************************
;           DUMP CHAR
;*********************************
          
CHRADD		DW	0

DUMPCHR:	CMP	[CS:ENTLEN],2
		JNZ	@@NOPE

		MOV	BX,[CS:CHRADD]
		JMP	@@DUMP	

@@NOPE:		INC	SI
		INC	SI
		CALL	EVAL

@@DUMP:		MOV	DL,[BYTE CS:DEPTH]

@@LOOP1:	MOV	AX,BX
		CALL	HEX_AX

 		MOV	AL,32
		CALL	PR_AL

		MOV	CX,[CS:WIDE]

		CALL	GET_BYTES 		;GET BYTES AT BX LEN CX
						;INTO BYTEBUF
		MOV	DI,OFFSET BYTEBUF

@@LOOP2:	MOV	AL,[CS:DI]

		CALL	CHRCODE

		INC	DI
		LOOP	@@LOOP2

		MOV	AL,13
		CALL	PR_AL

		MOV	AL,10
		CALL	PR_AL

		ADD	BX,[CS:WIDE]

		DEC	DL
		JNZ	@@LOOP1

		MOV	[CS:CHRADD],BX
		RET

;*********************************
;	    PRINT BASE
;*********************************

BASE_AL:	CMP	[CS:MBASE],"H"
		JZ	HEX_AL

		CMP	[CS:MBASE],"D"
		JZ	DEC_AL

		CMP	[CS:MBASE],"B"
		JZ	BIN_AL
		RET

;*********************************
;          PRINT CHRCODE
;*********************************

CHRCODE:	CMP	AL,32
		JA	@@OK

     		MOV	AL,"."

@@OK:		CMP	AL,255
		JNZ	@@OK2

		DEC	AL

@@OK2:		CALL	PR_AL
		RET

;*********************************
;    GET DATA INTO BYTE BUF
;	 GET BYTES AT BX LEN CX
;*********************************

GET_BYTES:	PUSH	BX		;SAVE UPLOAD ADDRESS
		PUSH	CX		;SAVE COUNT
		PUSH	DX
		PUSH	SI
		PUSH	DI
		
		MOV	DI,OFFSET BYTEBUF
		MOV	ES,[CS:CODERAM]

@@LOOP:
		CALL	GET_MEMORY_AL
		MOV		[ES:DI],AL
		INC		DI
		INC		BX
		LOOP	@@LOOP	

		POP	DI
		POP	SI
		POP	DX
		POP	CX
		POP	BX
		RET		

;*********************************
;          DUMP CODE
;*********************************
          
CODEADD		DW	0
INSTLEN		DW	0
INSTPOS		DW	0

DUMPCODE:	CMP	[CS:ENTLEN],2
		JNZ	@@NOPE

		MOV	BX,[CS:CODEADD]
		JMP	@@DUMP	

@@NOPE:		INC	SI
		INC	SI
		CALL	EVAL

@@DUMP:		MOV	DL,[BYTE CS:DEPTH]

@@LOOP1:	MOV	CX,3
		CALL	GET_BYTES 		;GET BYTES AT BX LEN CX
		CALL	GET_INST_LEN

		MOV	AX,BX
		CALL	HEX_AX

 		MOV	AL,32
		CALL	PR_AL

		MOV	DI,OFFSET BYTEBUF
		MOV	CX,[CS:INSTLEN]

@@LOOP2:	MOV	AL,[CS:DI]
		CALL	BASE_AL

		MOV	AL,32
		CALL	PR_AL

		INC	DI
		LOOP	@@LOOP2

		MOV	AL,9			;TAB
		CALL	PR_AL

		MOV	AL,9			;TAB
		CALL	PR_AL

		CALL	PRINTINST

		MOV	AL,13
		CALL	PR_AL

		MOV	AL,10
		CALL	PR_AL

		ADD	BX,[CS:INSTLEN]

		DEC	DL
		JNZ	@@LOOP1

		MOV	[CS:CODEADD],BX
		RET

;********************************
;        PRINT INSTRUCTION
;********************************

PRINTINST:	MOV	DI,[CS:INSTPOS]
		MOV	CX,16
		
@@LOOP:		MOV	AL,[CS:DI]
		AND	AL,AL
		JZ	@@QUIT

		PUSH	DI
		PUSH	CX
		CALL	PRINT_DATA
		POP	CX
		POP	DI
		INC	DI
		LOOP	@@LOOP

@@QUIT:		RET

;********************************
;        PRINT INSTRUCTION
;********************************

PRINT_DATA:
		CMP	AL,"d"
		JZ	@@DISP

		CMP	AL,"n"
		JZ	@@NUM

		CMP	AL,"w"
		JZ	@@WORD

		CMP	AL,"z"
		JZ	@@ZPAGE

		CMP	AL,"/"
		JZ	@@CR

		CMP	AL," "
		JZ	@@TAB

		JMP	DCHAR

;********************************

@@CR:
;		MOV	AL,13
;		CALL	DCHAR
;		MOV	AL,10
;		CALL	DCHAR
		RET

;********************************

@@TAB:
		MOV		AL,35
		CALL	SPACES

;		MOV	AL,9
;		CALL	DCHAR
		RET

;********************************

@@NUM:		MOV	AL,"#"
		CALL	DCHAR
		
		MOV	BL,[BYTE CS:BYTEBUF+1]
		JMP	SHOW_BYTE_HEX
		
;********************************

@@DISP:		MOV	AL,[BYTE CS:BYTEBUF+1]
		CBW
		PUSH	BX
		ADD	BX,AX
		ADD	BX,2
		MOV	AX,BX
		POP	BX

		CALL	HUNT
		RET

		MOV		BL,[BYTE CS:BYTEBUF+1]
		CALL	SHOW_BYTE_HEX
		RET

;********************************

@@WORD:		MOV	AX,[WORD CS:BYTEBUF+1]
		CALL	HUNT
		RET

;********************************

@@ZPAGE:	MOV	AL,[BYTE CS:BYTEBUF+1]
		MOV	AH,0FFH
		CALL	HUNT
		RET

;********************************

HUNT:	TEST	[CS:MONFLAGS],2
		JZ	HUNT_LAB

		PUSH	AX
		MOV	AL,"#"
		CALL	DCHAR
		POP		BX

		CALL	SHOW_WORD_HEX
		RET

;********************************
; HUNT THE SYMBOLIC REFERANCE
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	  AX = ADDRESS
;
;	 CYSET IF FOUND 
;	DI = LABEL NAME
;********************************

CLOSEST		DW	0

HUNT_LAB:	MOV	SI,-1

			MOV	ES,[CS:LABRAM]		;ES:DI = LABEL AREA
			MOV	DI,0

@@LOOP:		CMP	[BYTE ES:DI],32
			JZ	@@NOTFOUND

			CMP	[WORD ES:DI+(SYMLEN-2)],AX
			JZ	@@FOUND

			MOV	CX,AX
			SUB	CX,[WORD ES:DI+(SYMLEN-2)]
		
			CMP	CX,SI
			JNC	@@NOTNEAR

			MOV	[CS:CLOSEST],DI
			MOV	SI,CX

@@NOTNEAR:	ADD	DI,SYMLEN
			JMP	@@LOOP

@@FOUND:	CALL	PR_LAB
			STC
			RET

@@NOTFOUND:	CMP	SI,32
			JC	@@NEARADD

@@DATA:		PUSH	AX
			MOV	AL,"#"
			CALL	DCHAR
			POP	AX

			CALL	SHOW_WORD_HEX
			CLC
			RET

@@NEARADD:	MOV	DI,[CS:CLOSEST]
			CALL	PR_LAB

			MOV	AL,"+"
			CALL	DCHAR

			MOV	AL,"#"
			CALL	DCHAR

			MOV	AX,SI
			CALL	SHOW_BYTE_HEX

			CLC
			RET

;********************************
; HUNT THE SYMBOLIC REFERANCE
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	  AX = ADDRESS
;
;	 CYSET IF FOUND 
;	DI = LABEL NAME
;********************************

HUNT_ADD:
			MOV	ES,[CS:LABRAM]		;ES:DI = LABEL AREA
			MOV	DI,0

@@LOOP:
			CMP	[BYTE ES:DI],32
			JZ	@@NOTFOUND

			CMP	[WORD ES:DI+(SYMLEN-2)],AX
			JZ	@@FOUND
		
			ADD	DI,SYMLEN
			JMP	@@LOOP

@@FOUND:
			CALL	PR_LAB
			STC
			RET

@@NOTFOUND:
			CLC
			RET


;********************************
;	  PRINT OUT LABEL
;	    DI = LABEL
;********************************

PR_LAB:		MOV	CX,12			;SYMLEN-2

@@PRLP:		MOV	AL,[ES:DI]
			CMP	AL,32
			JZ	@@QUIT

			CALL	DCHAR
			
			INC	DI
			LOOP	@@PRLP
@@QUIT:		RET

;********************************
;    GET INSTRUCTION LENGTH
;      INSTRUCTION AT BX
;********************************

BADINSTR	DB	"** BAD OP **",0

GET_INST_LEN:
		MOV	DI,OFFSET EMU_TAB

		CALL	GET_MEMORY_AL
		MOV		[CS:BYTEBUF+0],AL
		INC		BX
		
		CALL	GET_MEMORY_AL
		MOV		[CS:BYTEBUF+1],AL
		INC		BX

		CALL	GET_MEMORY_AL
		MOV		[CS:BYTEBUF+2],AL

		MOV		AL,[CS:BYTEBUF]
		CMP		AL,0CBH
		JNZ		@@ACB

		MOV		DI,OFFSET CB_TAB
		MOV		AL,[CS:BYTEBUF+1]

@@ACB:
		XOR	AH,AH			;FIND TABLE INDEX
		ADD	AX,AX
		ADD	AX,AX
		ADD	AX,AX
		ADD	AX,AX
		ADD	AX,AX			;*32
		ADD	AX,31			;end of the field
		ADD	DI,AX		

		mov	cx,31

@@FIND:
		CMP		[BYTE CS:DI],0C3h
		JZ		@@FOUND
		DEC		DI
		LOOP	@@FIND

		MOV	DI,OFFSET BADINSTR
		DEC	DI

@@FOUND:

		INC	DI

		MOV	[CS:INSTPOS],DI

		MOV	AL,[CS:BYTEBUF]
		CMP	AL,0CBH
		JZ	@@TWO

		MOV	CX,16

@@LOOP:
		MOV	AL,[CS:DI]	
		CMP	AL,"d"
		JZ	@@TWO

		CMP	AL,"n"
		JZ	@@TWO

		CMP	AL,"z"
		JZ	@@TWO

		CMP	AL,"w"
		JZ	@@THREE

		CMP	AL,0
		JZ	@@ONE

		INC	DI
		LOOP	@@LOOP

@@ONE:
 		MOV	[CS:INSTLEN],1
		RET

@@TWO:
	 	MOV	[CS:INSTLEN],2
		RET

@@THREE:
		MOV	[CS:INSTLEN],3
		RET

		include "Keys.asm"
		include "Print.asm"
		include "Number.asm"
		include "Disas.asm"
		include "Banks.asm"
		include "GBDisp.asm"
		include "gb80emu.asm"
		include "emmhand.asm"

		ENDS	CODESG
		END	START
	
