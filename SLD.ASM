;*****************************************************************************
;	             SIMPLE FILE VIEWER FOR SLD SYSTEM
;*****************************************************************************

SLDFILE		DB	128 DUP (0)		;FILE NAME
SLDHAND		DW	0

SLDLINE		DW	0   			;LINE NUMBER
SLDADDR		DW	0			;LINE ADDRESS
LASTSLDFILE	DW	0			;LAST FILE READ ADDRESS
SLDSEARCHTYPE	DW	0			;SEARCH TYPE
SLDFOUND	DW	0			;FOUND FLAG

;*****************************************************************************
;		    GET SLD FROM FILE 'SYM.TAB'
;*****************************************************************************

;****************************************
;	     OPEN SYMBOL FILE
;       TEMPORARLY USE SCEEN RAM
;****************************************

LOAD_SLD:	MOV	DX,OFFSET SYMNAME
		MOV	BX,0			;NO EXEC
		JMP	LOAD_STREAM

;****************************************
;	      READ IN SYMBOLS
;****************************************

FIND_SLD_LINE:
	    	MOV	[WORD CS:SLDSEARCHTYPE],0

		MOV	[WORD CS:SLDFOUND],0
		MOV	[WORD CS:LASTSLDFILE],-1

		MOV	SI,0			;SET UP STREAM 0
		MOV	DS,[CS:TEMPRAM]

		MOV	AX,0	    		;MAKE CHANNEL 0 COMMAND LINE
		CALL	SET_REDIRECT

		MOV	AX,0			;REDIRECT TO CHANNEL 0
		CALL	REDIRECT

@@LOOP:		CALL	GETCHR

		CMP	AL,1AH			;EOF ?
		JZ	@@QUIT

		CALL	LOOK_SLD	
		JC	@@FOUND			;FOUND ?

@@SKIP:		CALL	SKIP_LINE
		JMP	@@LOOP

@@FOUND:	MOV	[WORD CS:SLDFOUND],1
@@QUIT:		RET

;****************************************
;	     FIND NEAR SYMBOLS
;	     ~~~~~~~~~~~~~~~~~
;NOTE. YOU MUST RUN FIND_SLD_LINE BEFORE
;      RUNNING THIS PROGRAM.
;****************************************

FIND_SLD_NEAR:
	    	MOV	[WORD CS:SLDSEARCHTYPE],1
		MOV	[WORD CS:SLDFOUND],0

		;MOV	[WORD CS:LASTSLDFILE],-1

		MOV	SI,0			;SET UP STREAM 0
		MOV	DS,[CS:TEMPRAM]

		MOV	AX,0	    		;MAKE CHANNEL 0 COMMAND LINE
		CALL	SET_REDIRECT

		MOV	AX,0			;REDIRECT TO CHANNEL 0
		CALL	REDIRECT

		CALL	SKIP_LINE		;SKIP FILE LINE

@@LOOP:		CALL	GETCHR

		CMP	AL,1AH			;EOF ?
		JZ	@@QUIT

		CMP	AL,">"			;IF ANOTHER FILE QUIT
		JZ	@@QUIT

		CALL	LOOK_SLD	
		JC	@@FOUND			;FOUND ?

@@SKIP:		CALL	SKIP_LINE
		JMP	@@LOOP

@@FOUND:	MOV	[WORD CS:SLDFOUND],1
@@QUIT:		RET

;****************************************
;	      BUILD TABLE
;	      ~~~~~~~~~~~
;NOTE. YOU MUST RUN FIND_SLD_LINE BEFORE
;      RUNNING THIS PROGRAM.
;****************************************

SLDTOP		DW	0			;TOP LINE OF SLD FILE

TOPLINE		DW	0			;TOP SLD LINE
BOTLINE		DW	0			;BOT SLD LINE + 1
SLDTAB		DW	128 DUP (-1)

BUILD_SLD_TABLE:
		MOV	DI,OFFSET SLDTAB	;CLEAR OUT SLD TABLE
		MOV	ES,[CS:CODERAM]
		MOV	CX,128
		MOV	AX,-1
		REP	STOSW

	    	MOV	[WORD CS:SLDSEARCHTYPE],2	;TYPE BUILD TABLE
		MOV	[WORD CS:FOUNDDISCUR],0		;NOT FOUND DISCUR

		MOV	SI,0			;SET UP STREAM 0
		MOV	DS,[CS:TEMPRAM]

		MOV	AX,0	    		;MAKE CHANNEL 0 COMMAND LINE
		CALL	SET_REDIRECT

		MOV	AX,0			;REDIRECT TO CHANNEL 0
		CALL	REDIRECT

		CALL	SKIP_LINE		;SKIP FILE LINE

@@LOOP:		CALL	GETCHR

		CMP	AL,1AH			;EOF ?
		JZ	@@QUIT

		CMP	AL,">"			;IF ANOTHER FILE QUIT
		JZ	@@QUIT

		CALL	LOOK_SLD	
		JC	@@QUIT			;FINISHED ?

@@SKIP:		CALL	SKIP_LINE
		JMP	@@LOOP

@@QUIT:		RET

;****************************************
;	      READ IN SLD
;
;  SEARCH TYPE 0 = SEARCH FOR ADDRESS
;  SEARCH TYPE 1 = SEARCH FOR LINE
;****************************************

LOOK_SLD:	CALL	NEXTCHR			;GET WHATEVER

		CMP	AL,"$"			;LINE NUM
		JZ	@@NUM

		CMP	AL,">"			;MUST BE A SYM
		JZ	@@FILE

		JMP	@@EXIT			;MUST BE CRAP

;----------------------------------------------
;	       GET SLD FILE NAME
;----------------------------------------------

@@FILE:		CALL	GET_FILE_NAME		;GET THE FILE NAME

		MOV	SI,OFFSET SLDFILE	;PUT FILENAME IN FILENAME
		CALL	LABEL_TO_FILE

		MOV	AX,[CS:CHANPTR]		;SAVE LAST FILE POS
		MOV	[CS:LASTSLDFILE],AX

		JMP	@@EXIT			;SAY NOT FOUND

;----------------------------------------------
;	     GET LINE NUMBER INFO
;----------------------------------------------

@@NUM:		MOV	[CS:BASE],16		;SAY GET HEX
		CALL	GETNUM			;NUM IN EBX

		CALL	SKIP_EXP		;SKIP SHITE

		CALL	GETCHR			;QUIT IF SYMBOL
		CMP	AL,"*"			;IS NOT A LINE NUM
		JNZ	@@EXIT

		CALL	NEXTCHR			;SKIP '*'
		CALL	SKIP_EXP		;SKIP SHITE

		PUSH	EBX			;SAVE ADDRESS
		CALL	GETNUM			;LINE NUM IN EBX
		POP	EDX			;GET ADDRESS OF THIS LINE		

;----------------------------------------------
;      TEST FOR DIFFERENT SEARCH TYPES
;----------------------------------------------

	    	CMP	[WORD CS:SLDSEARCHTYPE],0
		JZ	@@ADDR

	    	CMP	[WORD CS:SLDSEARCHTYPE],2
		JZ	@@TABLE

;----------------------------------------------
;	     LINE NUMBER SEARCH
;
;	      BX = LINE NUMBER
;	      DX = LINE ADDRESS
;----------------------------------------------

		CMP	BX,[CS:SLDLINE]		;IS IT THE RIGHT LINE
		JNZ	@@EXIT

		MOV	[CS:SLDADDR],DX		;SAVE LINE NUMBER
		STC
		RET

;----------------------------------------------
;	        ADDRESS SEARCH
;
;	      BX = LINE NUMBER
;	      DX = LINE ADDRESS
;----------------------------------------------

@@ADDR:		CMP	DX,[CS:SLDADDR]		;IS IT THE RIGHT ADDRESS	
		JNZ	@@EXIT

		MOV	[CS:SLDLINE],BX		;SAVE LINE NUMBER
		STC
		RET

;----------------------------------------------
;	       BUILD SLD TABLE
;
;	      BX = LINE NUMBER
;	      DX = LINE ADDRESS
;----------------------------------------------

@@TABLE:	CMP	BX,[CS:BOTLINE]		;IS IT HIGHER
		JNC	@@FINISHED		;FINISHED

		SUB	BX,[CS:TOPLINE]		;IS IT LOWER
		JC	@@EXIT

		SHL	BX,1				;BX * 2
		MOV	[CS:BX + OFFSET SLDTAB],DX	;PUT IN ENTRY

		CMP	[CS:DISCUR],DX		;HAVE WE FOUND THE CURSOR
		JNZ	@@NOCUR			;JUMP IF NOT

		MOV	[WORD CS:FOUNDDISCUR],1	;SAY FOUND CURSOR

@@NOCUR:	CLC				;SAY NOT FINISHED
		RET

@@FINISHED:	STC
		RET

;----------------------------------------------
;		EXIT NOT FOUND
;----------------------------------------------

@@EXIT:		CLC
		RET		

;*****************************************************************************
;		    	     PRINT SLD FILE
;*****************************************************************************

;************************************
;	PRINT SLD INFO ON SCREEN
;************************************

DISPLAY_SLD:
		CALL	LOAD_SLD		;LOAD SLD INFO
		CALL	MAKE_SLD_TABLE

		CMP	[WORD CS:FOUNDDISCUR],0
		JZ	@@NOTFOUND

		CALL	SHOW_SLD_FILE

		STC
		RET

@@NOTFOUND:	CLC
		RET

;************************************
;	MAKE LINE ADDRESS TABLE
;************************************

FOUNDDISCUR	DW	0

MAKE_SLD_TABLE:

;----------------------------------------------
;	         SLD SYSTEM
;----------------------------------------------

		MOV	AX,[CS:SLDTOP]		;GET TOP OF WINDOW
		MOV	[CS:SLDADDR],AX

		CALL	FIND_SLD_LINE		;FIND THE LINE NUM

	    	CMP	[WORD CS:SLDFOUND],0	;NO FILE NAME
		JZ	@@NOTOP

		MOV	AX,[CS:SLDLINE]		;SAVE TOP LINE NUMBER
		MOV	[CS:TOPLINE],AX

		MOVZX	CX,[BYTE CS:SLDDEPTH]	;GET DEPTH OF WINDOW
		ADD	AX,CX
		MOV	[CS:BOTLINE],AX		;SAVE BOTTOM LINE IF WINDOW

;----------------------------------------------
;		BUILD SLD TABLE
;----------------------------------------------

		CALL	BUILD_SLD_TABLE		;BUILD SLD TABLE

		CMP	[WORD CS:FOUNDDISCUR],1	;SAY FOUND CURSOR
		JZ	@@EXIT

;----------------------------------------------
;     COULD NOT FIND SLD TOP LINE NUMBER
;	SO REPLACE IT WITH CURSOR POS
;----------------------------------------------

@@NOTOP:	MOV	AX,[CS:DISCUR]
		CMP	[CS:SLDTOP],AX
		JZ	@@EXIT

		MOV	[CS:SLDTOP],AX
		JMP	MAKE_SLD_TABLE

@@EXIT:		RET

;************************************
;        SET UP SLD VIEWER
;      AX = ADDRESS OF CURSOR
;************************************

SETUP_SLD:
		RET			;DONT NEED THIS

		SUB	AX,4*8
		JNC	@@NOT8

		MOV	[CS:SLDTOP],AX
		RET

@@NOT8:		ADD	AX,4*8
		MOV	[CS:SLDTOP],AX
		RET

;************************************
;	SET UP SLD WINDOW SIZE
;	~~~~~~~~~~~~~~~~~~~~~~
;	   AL = XPOS
;	   AH = YPOS
;          BL = LAST X POS
;          BH = WINDOW DEPTH
;************************************

SET_SLD_WINDOW:
		MOV	[WORD CS:SLDX],AX
		MOV	[WORD CS:SLDLASTX],BX
		RET

;************************************
;	    SAVE SLD WINDOW
;************************************

SAVE_SLD:	POP	BX
		PUSH	[WORD CS:SLDX]
		PUSH	[WORD CS:SLDLASTX]
		JMP	BX

;************************************
;	   RESTORE SLD WINDOW
;************************************

RESTORE_SLD:	POP	BX
		POP	[WORD CS:SLDLASTX]
		POP	[WORD CS:SLDX]
		JMP	BX

;*****************************************************************************
;			   GENERIC SLD DISPLAY
;*****************************************************************************

SLDX		DB	1	;1		;X POS OF WINDOW
SLDY		DB	6	;6		;Y POS OF WINDOW

SLDLASTX	DB	79	;79		;WIDTH OF SLD
SLDDEPTH	DB	24	;24		;HIGHT OF SLD

;****************************************
;	     OPEN SYMBOL FILE
;       TEMPORARLY USE SCEEN RAM
;****************************************

SHOW_SLD_FILE:
		MOV	DX,OFFSET SLDFILE
		MOV	BX,OFFSET SHOW_SLD
		JMP	LOAD_STREAM

;****************************************
;
;****************************************

SHOW_SLD:
		MOV	DX,[CS:TOPLINE]
		CALL	SEARCH_LINE

		MOVZX	CX,[CS:SLDDEPTH]		;GET DEPTH
		MOV	DX,[WORD CS:SLDX]		;GET XY START
		MOV	SI,OFFSET SLDTAB

@@LOOP:		PUSH	CX
		PUSH	DX
		PUSH	SI

		MOV	[CS:ATTR],0000111B

		MOV	CX,DX				;SET SCREEN POS
		CALL	SETPOS_REAL

		MOV	SI,[CS:SI]			;GET ADDRESS

		CALL	SWITCH_CACHE
		CALL	SWITCH_CUR
		CALL	SWITCH_BP

		MOV	AL,32
		CALL	DCHAR
		INC	[WORD CS:SLDXPOS]

		CALL	SWITCH_BP
		CALL	SWITCH_CUR

		CALL	PRINT_LINE

		POP	SI
		POP	DX
		POP	CX

		ADD	SI,2				;NEXT LINE
		INC	DH				;INC Y POS

		LOOP	@@LOOP		
		RET

;****************************************
;	      FIND LAST LINE
;	      CX = LAST LINE
;****************************************

SEARCH_LAST:	MOV	DX,0

;----------------------------------------
;	     SEARCH FOR LINE NO
;	   DX = LINE NUM TO FIND
;----------------------------------------

SEARCH_LINE:	CMP	DX,1
		JZ	@@OK

		MOV	CX,1

@@LOOP:		CMP	AL,1AH			;EOF ?
		JZ	@@QUIT

		CALL	SKIP_LINE
		INC	CX			;NEXT LINE

		CMP	CX,DX
		JNZ	@@LOOP

@@OK:		STC
		RET

@@QUIT:		CLC
		RET

;****************************************
;	 DISPLAY TEXT FILE LINE
;****************************************

VIEWOFFSET	DW	0
SLDXPOS		DW	0

PRINT_LINE:
		MOV	[WORD CS:SLDXPOS],0

PRLINELP:	MOV	AL,[CS:SLDLASTX]
		CMP	[BYTE CS:LASTXY],AL
		JNC	@@QUITSKIP

		CALL	GETCHR

		CMP	AL,1AH
		JZ	@@QUITSKIP

		CMP	AL,13
		JZ	@@ENDLINE
	
		CMP	AL,9
		JZ	@@TAB

		CALL	SLDCHAR
		CALL	NEXTCHR

		JMP	PRLINELP

;****************************************
;
;****************************************

@@ENDLINE:	CALL	NEXTCHR		;SKIP 13,10
		CALL	NEXTCHR
		CALL	SLDENDLINE
		RET

;****************************************
;
;****************************************

@@QUITSKIP:	CALL	SKIP_LINE
		CALL	SLDENDLINE
		RET

;****************************************
;
;****************************************

@@TAB:		CALL	NEXTCHR

		MOV	AX,11

@@LOOP:		CMP	AX,512
		JNC	PRLINELP

		CMP	[WORD CS:SLDXPOS],AX
		JC	@@TABLOOP

		ADD	AX,8
		JMP	@@LOOP

@@TABLOOP:	
		CALL	SLDSPACES
		JMP	PRLINELP

;---------- OLD SHIT -------------

IF 0

@@TAB:		CALL	NEXTCHR

		MOV	AX,[CS:SLDXPOS]
		MOV	BX,OFFSET TABDATA

@@LOOP:		CMP	[WORD CS:BX],0
		JZ	PRLINELP

		CMP	AX,[CS:BX]
		JC	@@TABLOOP

		ADD	BX,2
		JMP	@@LOOP

@@TABLOOP:	MOV	AX,[CS:BX]
		CALL	SLDSPACES

		JMP	PRLINELP

TABDATA		DW	11,19,27,35,43,51,59,67,75,83,91,99,107,115,223,0

ENDIF

;****************************************
;
;****************************************

SLDCHAR:	PUSH	BX

		MOV	BL,[BYTE CS:SLDXPOS]
		CMP	BL,[BYTE CS:VIEWOFFSET]
		JC	@@EXIT

		MOV	BL,[CS:SLDLASTX]
		CMP	[BYTE CS:LASTXY],BL
		JNC	@@EXIT

		CALL	DCHAR

@@EXIT:		INC	[WORD CS:SLDXPOS]
		POP	BX
		RET

;****************************************
;
;****************************************

SLDSPACES:
		CMP	AX,250			;CHECK FOR ERRORS
		JC	@@LOOP			;JUMP IF OK

		MOV	AX,249			;SET TO LIMIT
     		
@@LOOP:
		CMP	[CS:SLDXPOS],AX
		JNC	@@OK


		PUSH	AX
		MOV	AL,32
		CALL	SLDCHAR
		POP	AX

		JMP	@@LOOP
@@OK:	   	RET	

;****************************************
;
;****************************************

SLDENDLINE:
		MOV	AL,[CS:SLDLASTX]
		CALL	SPACES
		RET     		

