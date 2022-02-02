;*****************************************************************************
;			KEY TABLES AND ROUTINES
;*****************************************************************************

OLD_KEY_IP	DW	-1
OLD_KEY_CS	DW	-1

;********************************
;	KEY EQUATE TABLES
;********************************

KEY_PORT	=	60H	
SYSTEM_CONTROL	=	61H
INT_CONTROL	=	20H

ESC_KEY		=	01H
ONE_KEY		=	02H
TWO_KEY		=	03H
THREE_KEY	=    	04H
FOUR_KEY	=	05H
FIVE_KEY	=	06H
SIX_KEY		=	07H
SEVE_KEY	=	08H
EIGHT_KEY	=	09H
NINE_KEY	=	0AH
ZERO_KEY	=	0BH
BACKSPACE_KEY	=	0EH
TAB_KEY		=	0FH	
Q_KEY		=	10H
W_KEY		=	11H
E_KEY		=	12H
R_KEY		=	13H
T_KEY		=	14H
Y_KEY		=	15H
U_KEY		=	16H
I_KEY		=	17H
O_KEY		=	18H
P_KEY		=	19H
ENTER_KEY	=	1CH
CTRL_KEY	=	1DH
A_KEY		=	1EH
S_KEY		=	1FH
D_KEY		=	20H
F_KEY		=	21H
G_KEY		=	22H
H_KEY		=	23H
J_KEY		=	24H
K_KEU		=	25H
L_KEY		=	26H
LEFTSHIFT_KEY	=	2AH
Z_KEY		=	2CH
X_KEY		=	2DH
C_KEY		=	2EH
V_KEY		=	2FH
B_KEY		=	30H
N_KEY		=	31H
M_KEY		=	32H
RIGHTSHIFT_KEY	=	36H
ALT_KEY		=	38H
SPACEBAR_KEY	=	39H
CAPSLOCK_KEY	=	3AH
F1_KEY		=	3BH
F2_KEY		=	3CH
F3_KEY		=	3DH
F4_KEY		=	3EH
F5_KEY		=	3FH
F6_KEY		=	40H
F7_KEY		=	41H
F8_KEY		=	42H
F9_KEY		=	43H
F10_KEY		=	44H
NUMLOCK_KEY	=	45H
SCROLLOCK_KEY	=	46H
HOME_KEY	=	47H
UPARROW_KEY	=	48H
PGUP_KEY	=	49H
LEFTARROW_KEY	=	4BH
RIGHTARROW_KEY	=	4DH
END_KEY		=	4FH
DOWNARROW_KEY	=	50H
PGDN_KEY	=	51H
INS_KEY		=	52H
DEL_KEY		=	53H      

;*********************************
;	KEY DECODE TABLE
;*********************************

KEYTAB		DB	128 DUP (0)	;INTERRUPT KEY TABLE

KEY_DECODE:
		DB	0  ,0  ,-1	;00	
		DB	27 ,27 ,-1	;01	ESC_KEY				
		DB	"1","!",-1	;02	ONE_KEY		
		DB	"2",34 ,"@"	;03	TWO_KEY		
		DB	"3","#","ú"	;04	THREE_KEY	
		DB	"4", 0,"$"	;05	FOUR_KEY	
		DB	"5","%",-1	;06	FIVE_KEY	
		DB	"6","&",-1	;07	SIX_KEY		
		DB	"7","/","{"	;08	SEVE_KEY	
		DB	"8","(","["	;09	EIGHT_KEY	
		DB	"9",")","]"	;0A	NINE_KEY	
		DB	"0","=","}"	;0B	ZERO_KEY
		DB	"+","?","\"	;0C	+ KEY
		DB	"'","*",-1	;0D	' KEY
		DB	8  ,8  ,-1	;0E	BACKSPACE_KEY	
		DB	9  ,9  ,-1	;0F	TAB_KEY		

		DB	"Q","q",-1	;10	Q_KEY		
		DB	"W","w",-1	;11	W_KEY		
		DB	"E","e",-1	;12	E_KEY		
		DB	"R","r",-1	;13	R_KEY		
		DB	"T","t",-1	;14	T_KEY		
		DB	"Y","y",-1	;15	Y_KEY		
		DB	"U","u",-1	;16	U_KEY		
		DB	"I","i",-1	;17	I_KEY		
		DB	"O","o",-1	;18	O_KEY		
		DB	"P","p",-1	;19	P_KEY
		DB	"è",0  ,-1	;1A	è KEY
		DB	"^",0  ,-1	;1B	^ KEY
		DB	13 ,0  ,-1	;1C	ENTER_KEY	
		DB	0  ,0  ,-1	;1D	CTRL_KEY	
		DB	"A","a",-1	;1E	A_KEY		
		DB	"S","s",-1	;1F	S_KEY		

		DB	"D","d",-1	;20	D_KEY		
		DB	"F","f",-1	;21	F_KEY		
		DB	"G","g",-1	;22	G_KEY		
		DB	"H","h",-1	;23	H_KEY		
		DB	"J","j",-1	;24	J_KEY		
		DB	"K","k",-1	;25	K_KEU		
		DB	"L","l",-1	;26	L_KEY		
		DB	0,0    ,-1	;27	î_KEY
		DB	0,0    ,-1	;28	Ñ_KEY
		DB	"\","#",-1	;29	´_KEY

		DB	0  ,0  ,-1	;2A	LEFTSHIFT_KEY	
		DB	"'","*",-1	;2B	*_KEY
		DB	"Z","z",-1	;2C	Z_KEY		
		DB	"X","x",-1	;2D	X_KEY		
		DB	"C","c",-1	;2E	C_KEY		
		DB	"V","v",-1	;2F	V_KEY		

		DB	"B","b",-1	;30	B_KEY		
		DB	"N","n",-1	;31	N_KEY		
		DB	"M","m",-1	;32	M_KEY		
		DB	",",";",-1	;33	,_KEY
		DB	".",":",-1	;34	._KEY
		DB	"-","_",-1	;35	-_KEY
		DB	0  ,0  ,-1	;36	RIGHTSHIFT_KEY	
		DB	"*","*",-1	;37	KEYPAD *
		DB	0  ,0  ,-1	;38	ALT_KEY		
		DB	32 ,32 ,-1	;39	SPACEBAR_KEY	
		DB	0  ,0  ,-1	;3A	CAPSLOCK_KEY	

		DB	3 ,0   ,-1	;3B	F1_KEY		
		DB	4 ,0   ,-1	;3C	F2_KEY		
		DB	5 ,0   ,-1	;3D	F3_KEY		
		DB	6 ,0   ,-1	;3E	F4_KEY		
		DB	7 ,0   ,-1	;3F	F5_KEY		
		DB	8 ,0   ,-1	;40	F6_KEY		
		DB	9 ,0   ,-1	;41	F7_KEY		
		DB	10,0   ,-1	;42	F8_KEY		
		DB	11,0   ,-1	;43	F9_KEY		
		DB	12,0   ,-1	;44	F10_KEY		

		DB	0  ,0  ,-1	;45	NUMLOCK_KEY	
		DB	0  ,0  ,-1	;46	SCROLLOCK_KEY	
		DB	26 ,0  ,-1	;47	HOME_KEY	
		DB	"",0  ,-1	;48	UPARROW_KEY	
		DB	1  ,0  ,-1	;49	PGUP_KEY	
		DB	"-",0  ,-1	;4A	KEYPAD_-
		DB	"",0  ,-1	;4B	LEFTARROW_KEY	
		DB	"5","5",-1	;4C	KEYPAD 5
		DB	"",0  ,-1	;4D	RIGHTARROW_KEY	
		DB	"+","+",-1	;4E	KEYPAD_+
		DB	25 ,0  ,-1	;4F	END_KEY		

		DB	"",0  ,-1	;50	DOWNARROW_KEY	
		DB	2  ,0  ,-1	;51	PGDN_KEY	
		DB	15 ,0 ,0	;52	INS_KEY		
		DB	14 ,0  ,0	;53	DEL_KEY		

		DB	0  ,0  ,-1	;54	UNUSED
		DB	0  ,0  ,-1	;55	UNUSED
		DB	"<",">","|"	;56	UNUSED

		DB	0  ,0  ,-1	;57	F11
		DB	0  ,0  ,-1	;58	F12

LAST_KEY	=	58H

		DB	256 DUP (0)

;********************************
;    SET UP KEYBOARD INTERRUPT
;********************************

KEY_VEC		EQU	24H			

SETKEYINT:	CLI
		
		XOR	AX,AX
		MOV	DS,AX

		MOV	SI,OFFSET KEY_VEC

		MOV	AX,[SI]
		MOV	[CS:OLD_KEY_IP],AX

		MOV	AX,[SI+2]
		MOV	[CS:OLD_KEY_CS],AX

		MOV	AX,OFFSET KEY_INT
		MOV	[SI],AX
		MOV	AX,CS
		MOV	[SI+2],AX
	
		STI
		RET

;********************************
;    RESTORE SYSTEM INTERRUPT
;********************************

RESKEYINT:	CMP	[WORD CS:OLD_KEY_CS],-1
		JZ	@@NOKEY

		CLI
		XOR	AX,AX
		MOV	DS,AX

		MOV	SI,OFFSET KEY_VEC

		MOV	AX,[CS:OLD_KEY_IP]
		MOV	[SI],AX

		MOV	AX,[CS:OLD_KEY_CS]
		MOV	[SI+2],AX

		STI
@@NOKEY:	RET

;********************************
;     KEY INTERRUPT SERVER
;********************************

KEY_INT:	PUSH 	AX				
		PUSH	BX				

		XOR	AH,AH				

		IN 	AL,KEY_PORT			
		AND	AL,AL				
		JS	@@KEY_RELEASED		    	

@@KEY_PRESSED:	MOV	BX,OFFSET KEYTAB
		ADD	BX,AX

		MOV	[BYTE CS:BX],1			
		JMP	@@ENDKEY

@@KEY_RELEASED:	AND	AL,7FH
	
		MOV	BX,OFFSET KEYTAB
		ADD	BX,AX
		MOV	[CS:BX],AH				

@@ENDKEY:	IN	AL,SYSTEM_CONTROL		
		OR 	AL,80H				
		OUT 	SYSTEM_CONTROL,AL		

		AND 	AL,7FH				
		OUT 	SYSTEM_CONTROL,AL		

		MOV 	AL,020H
		OUT	INT_CONTROL,AL

		POP	BX				
		POP 	AX				
		IRET

;********************************
;	   GET ASCII KEY
;********************************

INKEY		DB	0
LASTKEYTAB	DW	0
DEBUGKEY	DW	0
DUMMY		DW	0

GET_KEY:	MOV	DI,OFFSET KEYTAB
		MOV	CX,LAST_KEY		;*2
		MOV	BX,OFFSET KEY_DECODE

;---------------------------------	       
;	TEST THE SHIFT KEY
;---------------------------------

		KEY	RIGHTSHIFT_KEY
		JNZ	@@INC

		KEY	LEFTSHIFT_KEY
		JZ	@@TESTALT

@@INC:		INC	BX
		JMP	@@LOOP

;---------------------------------
;	 TEST THE ALT KEY
;---------------------------------

@@TESTALT:	KEY	ALT_KEY
		JZ	@@LOOP

@@ALT:		ADD	BX,2

;---------------------------------
;	LOOP THROUGH DECODE
;---------------------------------

@@LOOP:		CMP	[BYTE CS:DI],0
		JZ	@@NOKEY

		MOV	AX,DI
		SUB	AX,OFFSET KEYTAB
		MOV	[CS:DEBUGKEY],AX

		MOV	AL,[BYTE CS:BX]

		AND	AL,AL
		JZ	@@NOKEY

		CMP	AL,-1
		JNZ	@@NOALT

		MOV	AL,[BYTE CS:BX-2]

@@NOALT:	MOV	[CS:LASTKEYTAB],DI
		MOV	[BYTE CS:INKEY],AL
		RET

@@NOKEY:	INC	DI
		ADD	BX,3
		LOOP	@@LOOP

		XOR	AL,AL
		MOV	[BYTE CS:INKEY],AL
		MOV	[CS:LASTKEYTAB],OFFSET DUMMY
		RET

;*********************************
;	   WAIT FOR A KEY
;*********************************

WAITKEY:	CALL	WAIT_FLY
		CALL	GET_KEY
		AND	AL,AL
		JZ	WAITKEY
		RET

;*****************************************************************************
;			KEYBOARD DECODING LOADING
;*****************************************************************************

;****************************************
;	     OPEN KEY FILE
;****************************************

KEYNAME		DB	"EMU.KEY",0

GET_KEY_FILE:	MOV	BX,OFFSET READ_KEYFILE
		MOV	DX,OFFSET KEYNAME
		JMP	LOAD_STREAM

;****************************************
;	      READ IN SYMBOLS
;****************************************

READ_KEYFILE:

@@LOOP:		CALL	GETCHR

		CMP	AL,1AH			;EOF ?
		JZ	@@QUIT

		CMP	AL,"."			;KEY ?
		JZ	@@QUIT

		CMP	AL,"/"			;KEY ?
		JNZ	@@SKIP

		CALL	TRY_GET_KEY	

@@SKIP:		CALL	SKIP_LINE
		JMP	@@LOOP

@@QUIT:		RET

;****************************************
;	      READ IN KEYS
;****************************************

KEYADD		DW	0

TRY_GET_KEY:
		CALL	NEXTCHR			;SKIP '/'
		CALL	SKIP_EXP

		CALL	INTERNAL_EXP		;GET KEY NUMBER

		MOV	DX,BX			;STORE X1

		ADD	BX,BX			;TABLE X2
		ADD	BX,DX			;TABLE X3
		ADD	BX,OFFSET KEY_DECODE
		MOV	[CS:KEYADD],BX

@@LOOP:		CALL	GETCHR
		CMP	AL,","
		JNZ	@@QUIT

		CALL	NEXTCHR			;SKIP ','
		CALL	SKIP_EXP		;SKIP SHITE

		CALL	INTERNAL_EXP		;GET KEY NUMBER
		
		MOV	DI,[CS:KEYADD]
		MOV	[CS:DI],BL		;PLOT FIRST KEY
		INC	[CS:KEYADD]		;NEXT ADD

		JMP	@@LOOP

@@QUIT:		RET

;*********************************
;	  SHOW DUBUG KEY
;*********************************

SHOW_DEBUG_KEY:
		CALL	PRINT
		DB	COL,0011110B
		DB	AT,0,1
		DB	"DEBUGKEY ",SHOW16
		DW	OFFSET DEBUGKEY,OFFSET DEBUGKEY

		DB	" : INKEY ",SHOW8
		DW	OFFSET INKEY,OFFSET INKEY

		DB	STOP
		RET



