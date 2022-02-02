;*****************************************************************************
;*               GAMEBOY EMULATOR INSTRUCTION TABLES
;*****************************************************************************
     
		IDEAL
		JUMPS
		DOSSEG
		MODEL	COMPACT
		STACK	512
			
		ASSUME	CS:CODESG
		SEGMENT	CODESG PARA PUBLIC

		P486N

DONGLE		= 0

TOPPRG:

;********************************
;	    VARIABLES
;********************************

TIME		DW	0
CODERAM		DW	0
TRACERAM	DW	0

OLD_KEY_IP	DW	0
OLD_KEY_CS	DW	0

OLDVMODE	DB	0		;OLD VIDEO MODE
		EVEN

FILE_ERROR	DW	0		;FILE ERROR FLAG

Z80_PC		DW	0		;Z80 REGS
Z80_HL		DW	0
Z80_DE		DW	0
Z80_BC		DW	0
Z80_SP		DW	0		;STACK
Z80_AF		DW	0
Z80_BANK	DW	0		;Z80 PAGED MEMORY

INTMASK		DW	0
INSTCNT		DW	0

Z80_SEG		DW	0		;MEMORY SEGMENTS
BANK_1		DW	0
BANK_2		DW	0
BANK_3		DW	0
BANK_4		DW	0
BANK_5		DW	0
BANK_6		DW	0
BANK_7		DW	0
BANK_8		DW	0
BANK_9		DW	0
BANK_A		DW	0
BANK_B		DW	0
BANK_C		DW	0
BANK_D		DW	0
BANK_E		DW	0
BANK_F		DW	0

INP_FILE_NAME	DB	128 DUP (?)
INP_FILE_HAND	DW	0

OUT_FILE_NAME	DB	"OP.TXT",0,0
OUT_FILE_HAND	DW	0

		EVEN

;********************************
;	 REGISTOR DEFINES
;********************************

_HL		EQU	BX	;HL = BX
_DE		EQU	DX
_BC		EQU	CX
_SP		EQU	[CS:Z80_SP]
_B 		EQU	CH
_C 		EQU	CL
_D 		EQU	DH
_E 		EQU	DL
_H 		EQU	BH
_L 		EQU	BL
_A 		EQU	AH
_F		EQU	AL
_NN		EQU	DI	;2 BYTE FOLLOWER
_W		EQU	DI	;2 BYTE FOLLOWER
_N		EQU	AL	;1 BYTE FOLLOWER

;********************************
;            MACRO'S
;********************************

		MACRO	KEY @1
		TEST	[CS:KEYTAB+@1],1
		ENDM

		MACRO	OPW	;DOES NOTHING EXCEPT MARK OUT
		INSTLEN = 3
		ENDM		;WORD LOCATIONS

		MACRO	OPB	;DOES NOTHING EXCEPT MARK OUT
		INSTLEN = 2
		ENDM		;BYTE LOCATIONS

		MACRO	SETNULL	;DOES NOTHING EXCEPT MARK OUT
		INSTLEN = 1
		RW = 1
		ENDM		;BYTE LOCATIONS

;********************************
;            MACRO'S
;********************************

		MACRO	RBC	;FLAGS INSTUCTION READS FROM BC
		CALL	BANK_BC	;USED SO EMU IS PRE WARNED ABOUT
		ENDM		;BANK ACCESS

		MACRO	RDE
		CALL	BANK_DE
		ENDM

	     	MACRO	RHL
		CALL	BANK_HL
		ENDM

;********************************
;            MACRO'S
;********************************

		MACRO	BADOP	;BAD OPCODE FLAG
		JMP	BOMBOUT
		ENDM

		MACRO	LD @1,@2
		MOV	@1,@2
		ENDM

;********************************
;            MACRO'S
;********************************

		MACRO	PAD @1	;DEFINE FIELD END & DISASS DATA
		
		PUSHF
		ADD	[CS:Z80_PC],INSTLEN
		POPF	

		RET

		DB	@1		;INCLUDE OPCODE DATA

		INSTLEN = 1		;RESET LEN FLAGS

		TABSTART = TABSTART + 32
		ORG	TABSTART
		ENDM

;*****************************************************************************
;
;*****************************************************************************

;****************************************
;*          CONTROL REGISTER
;****************************************

P1		=	0FF00H		;KEY PORT

SB		=	0FF01H		;SERIAL DATA
SC		=	0FF02H		;SERIAL CONTROL

TDIV		=	0FF04H		;DIVIDER
TIMA		=	0FF05H		;TIMER
TMA		=	0FF06H		;TIMER
TAC		=	0FF07H		;TIMER CONTROLL

I_F		=	0FF0FH		;INTERRUPT FLAG
I_E		=	0FFFFH		;INTERRUPT ENABLE FLAG

IME		=	0FEFFH		;IME FLAG

DONGLE_SEED	=	0FEFEH		;SOFT DONGLE SEED (GB COUNTER)
DONGLE_LAST	=	0FEFDH		;SOFT DONGLE SEED (PC COUNTER)

LCDC		=	0FF40H		;LCD CONTROLL

STAT		=	0FF41H		;LCDC STATUS

SCY		=	0FF42H		;SCROLL X
SCX		=	0FF43H		;SCROLL Y

LY		=	0FF44H		;LCDC Y
LYC		=	0FF45H		;LCDC Y COMPARE

DMA		=	0FF46H		;DMA CONTROL

BGP		=	0FF47H		;BAK PALET
OBP0		=	0FF48H		;OBJ 0 PALET
OBP1		=	0FF49H		;OBJ 1 PALET

WY		=	0FF4AH		;WINDOW X
WX		=	0FF4BH		;WINDOW Y

;		LCDC	   76543210
;			   ||||||||_________ BG        ON(1)/OFF
;			   |||||||__________ SPR       ON(1)/OFF
;			   ||||||___________ OBJ      8X8(0)/8X16
;			   |||||____________ BG MAP  9800(0)/9C00
;			   ||||_____________ BG CHR  8800(0)/8000
;			   |||______________ WIN       ON(1)/OFF
;			   ||_______________ WIN MAP 9800(0)/9C00
;			   |________________ CONTROL   ON(1)/OFF
;

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
;	     RETURN TO DOS
;*********************************
    
DOS_RET:	CALL	RESKEYINT

		MOV	AL,1
		MOV	AH,04CH			;NORMAL DOS RETURN
		INT	021H
		RET				;YES I KNOW I DON'T NEED

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

RESKEYINT:	CLI
		XOR	AX,AX
		MOV	DS,AX

		MOV	SI,OFFSET KEY_VEC

		MOV	AX,[CS:OLD_KEY_IP]
		MOV	[SI],AX

		MOV	AX,[CS:OLD_KEY_CS]
		MOV	[SI+2],AX

		STI
		RET

;********************************
;     KEY INTERRUPT SERVER
;********************************

KEYTAB		DB	128 DUP (0)		

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
;      WRITE BYTES TO DISK
;
;   DS:DX = ADDRESS OF BUFFER
;      CX = LENGTH OF BUFFER 
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
;      WRITE BYTES TO DISK
;
;      AL = ADDRESS OF BUFFER
;*********************************

		EVEN
WBYTE		DB	0
		
WRITE_BYTE:	MOV	[CS:WBYTE],AL

		MOV	AX,[CS:FILE_ERROR]
		AND	AX,AX
		JNZ	@@OUT

		MOV	DS,[CS:CODERAM]
		MOV	DX,OFFSET WBYTE
		MOV	CX,1
					       
		MOV	BX,[CS:OUT_FILE_HAND]	
						 
		MOV	AH,040H			  
		INT	021H			   
						    
		JNC	@@OUT			     
		MOV	[CS:FILE_ERROR],AX

@@OUT:		RET

;*********************************
;	   ERROR JUMPS
;*********************************

ERROR_OUT1:
		CALL	OLD_VMODE

		CALL	PRINT
		DB	"ERROR IN INPUT FILE ~",0

		CALL	PRINT_NAME

		CALL	PRINT
		DB	"~",13,10,0

		JMP	DOS_RET

ERROR_CLOSE:	CALL	FILE_IN_CLOSE
		CALL	OLD_VMODE

		CALL	PRINT
		DB	"ERROR CLOSE IN FILE ~",0

		CALL	PRINT_NAME

		CALL	PRINT
		DB	"~",13,10,0

		JMP	DOS_RET

ERROR_OUT2:	CALL	OLD_VMODE

		CALL	PRINT
		DB	"ERROR IN OUTPUT FILE !",13,10,0
	    
		JMP	DOS_RET

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

FILE_OUT_CLOSE:	MOV	BX,[CS:OUT_FILE_HAND]
		AND	BX,BX
		JZ	@@QUIT

		MOV	AH,03EH			;CLOSE INPUT FILE
		INT    	021H

@@QUIT:		RET

;*********************************
;    GET IN FILE LENGTH IN AX
;*********************************
	
GET_FILE_END:	XOR	CX,CX			;CLEAR CX & DX
		XOR	DX,DX
		MOV	BX,[CS:INP_FILE_HAND]	;GET FILE HANDLE
		MOV	AX,4202H		;SET UP DOS CALL
		INT	21H
		JC	ERROR_CLOSE		;IF FAILED GOTO ERROR CLOSE
		RET

;*********************************
;  GET A COMMAND TAIL PARAMETER
;
; SI:DS = POINTS TO COMMAND TAIL
;    DI:ES = PARAM POINTER  
;*********************************

GET_PARA:	MOV	CL,0

		CMP	[BYTE DS:SI],32
		JNZ	@@LOOP

		INC	SI

@@LOOP:		MOV	AL,[DS:SI]	;GET DATA FROM PSP COMMAND TAIL
	 	
		CMP	AL,32
		JZ	@@END

		CMP	AL,9
		JZ	@@END

		CMP	AL,";"
		JZ	@@END

		CMP	AL,0
		JZ	@@NOEND

		CMP	AL,13
		JZ	@@NOEND

		MOV	[CS:DI],AL
		MOV	[WORD CS:DI+1],0
		INC	SI
		INC	DI
		INC	CL
		JMP	@@LOOP

@@END:		INC	SI
		OR	CL,CL
		JZ	@@NOEND

		MOV	[BYTE CS:DI],0

@@NOEND:	RET

;*********************************
;	 PRINT INPUT NAME
;*********************************

PRINT_NAME:	MOV	SI,OFFSET INP_FILE_NAME
		MOV	CX,128

@@LOOP:		MOV	DL,[CS:SI]
		CMP	DL,0
		JZ	@@QUIT

		CMP	DL,13
		JZ	@@QUIT

		PUSH	SI
		PUSH	CX

		MOV	AH,02H
		INT	021H
	
		POP	CX
		POP	SI

		INC	SI

		LOOP	@@LOOP
@@QUIT:		RET

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
;      OPEN AN INPUT FILE
;*********************************

OPEN_OUT_FILE:	MOV	DS,[CS:CODERAM]

		MOV	AH,03CH			;READ ONLY FILE INPUT
		MOV	AL,0			;SET READ MODE ONLY
		MOV	DX,OFFSET OUT_FILE_NAME
		INT	021H
	        JC	ERROR_OUT1		;ON CY GIVE ERROR MESSAGE
		MOV	[CS:OUT_FILE_HAND],AX
		RET
			   
;*********************************
;          PRINT COMMAND
;*********************************
	
PRINT:		POP	BX		;GET STACK ADDRESS

@@LOOP:		MOV	AL,[CS:BX]	;GET BYTE FROM STRING
		AND	AL,AL
		JZ	@@END

		PUSH	BX
		PUSH	DX
		MOV	DL,AL
		MOV	AH,02H
		INT	021H
		POP	DX
		POP	BX

		INC	BX
		JMP	@@LOOP

@@END:		INC	BX
		PUSH	BX
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

NUM16:		PUSH	AX
		MOV	AL,"/"
		CALL	PR_AL
		POP	AX

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
;       WAIT FOR FRAME FLY
;*********************************

WAIT_FLY:	MOV	DX,3DAH

@@LOOP:		IN	AL,DX
		AND	AL,00001000B
		JZ	@@LOOP
		RET

;*********************************
;     WAIT FOR LOADS OF TIME
;*********************************

WAIT_KEY:	MOV	AH,08H		;WAIT FOR KEY
		INT	021H
		RET

;*********************************
;     SET TO VGA 320 x 200
;*********************************

SET_VGA:	MOV	AX,0013H		;MCGA 13H
		INT	010H
		RET

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

OLD_VMODE:	MOV	AH,0FH
		INT	010H

		CMP	AL,[CS:OLDVMODE]
		JZ	@@SAME

		MOV	AL,[CS:OLDVMODE]
		XOR	AH,AH
		INT	010H

@@SAME:		RET

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

@@NOMEM:	CALL	PRINT
		DB	"NOT ENOUGH MEMORY !",13,10
		DB	"REMOVE DEVICE DRIVER ETC.",13,10,0

		JMP	DOS_RET

;********************************
;    READ IN GAMEBOY PROGRAM
;********************************

BANKS		DW	0

READ_PRG:	MOV	[CS:BANKS],0

		MOV	BX,1000H
		CALL	GETMEM
		MOV	[CS:Z80_SEG],AX

		MOV	DX,0
		MOV	DS,[CS:Z80_SEG]
		MOV	CX,4000H
		CALL	READ_BYTES
		
		CMP	AX,4000H
		JNZ	@@EXIT

		INC	[CS:BANKS]

		MOV	AX,[CS:Z80_SEG]
		ADD	AX,400H
		MOV	[CS:BANK_1],AX

		MOV	DS,AX
		MOV	DX,0
		MOV	CX,4000H
		CALL	READ_BYTES
		
		CMP	AX,4000H
		JNZ	@@EXIT

		INC	[CS:BANKS]

		MOV	DI,OFFSET BANK_2
		MOV	CX,30			;BANK COUNT

@@LOOP:		PUSH	DI
		PUSH	CX

		MOV	BX,400H
		CALL	GETMEM

		MOV	[CS:DI],AX

		MOV	DX,0
		MOV	DS,[CS:DI]
		MOV	CX,4000H

		CALL	READ_BYTES

		POP	CX
		POP	DI

		CMP	AX,4000H
		JNZ	@@EXIT

		INC	[CS:BANKS]
		ADD	DI,2

		LOOP	@@LOOP

@@EXIT:		RET

;********************************
;	CHECK SUM BANKS
;********************************

CHKSUM		DW	0

SUMBANKS:
		XOR	AX,AX
		MOV	[CS:CHKSUM],AX

		MOV	DI,OFFSET Z80_SEG
		MOV	CX,[CS:BANKS]

@@LOOP:		PUSH	DI
		PUSH	CX

		MOV	AX,[CS:DI]
		MOV	DS,AX

		CALL	SUM_BANK

		POP	CX
		POP	DI

		ADD	DI,2
		LOOP	@@LOOP

		CALL	MAKE_COMP
		RET


;********************************
;      DO COMPILMENT CHECK
;********************************

MAKE_COMP:	PUSH	SI

		MOV	SI,134H
		MOV	DS,[CS:Z80_SEG]

		MOVZX	AX,[BYTE PTR DS:14EH]
		SUB	[WORD PTR CS:CHKSUM],AX

		MOVZX	AX,[BYTE PTR DS:14FH]
		SUB	[WORD PTR CS:CHKSUM],AX

		MOV	CX,25		;DO 25 BYTES
		MOV	AL,0

@@LOOP:		ADD	AL,[DS:SI]				
		INC	SI
		LOOP	@@LOOP

		ADD	AL,19H
		NEG	AL
		
		PUSH	AX

		CALL	PRINT
		DB	"COMPLEMENT VALUE = #",0
		POP	AX

		CALL	HEX_AL	       

		CALL	PRINT
		DB	10,13,0

		CALL	PRINT
		DB	"CURRENT CHECK SUM = #",0

		MOV	AX,[CS:CHKSUM]
		CALL	HEX_AX

		CALL	PRINT
		DB	10,13,0

		CALL	PRINT
		DB	"ROM CHECK SUM = #",0

		MOV	DS,[CS:Z80_SEG]
		MOV	AH,[DS:14EH]
		MOV	AL,[DS:14FH]
		CALL	HEX_AX

		CALL	PRINT
		DB	10,13,0



		POP	SI

		RET

;********************************
;     DO CHECK SUM
;********************************

SUM_BANK:
		MOV	DI,0
		MOV	SI,[CS:CHKSUM]
		MOV	CX,4000H	


@@LOOP:		MOVSX	AX,[BYTE PTR DS:DI]				
		ADD	SI,AX

		INC	DI

		LOOP	@@LOOP
		MOV	[CS:CHKSUM],SI
		RET
	

;********************************
;        START OF PROGRAM
;********************************

SCRTIME		= 2400			;600		;2400 REAL
INTTIME		= 100			;600
	
START:		MOV	[CS:CODERAM],CS

		MOV	AX,ES			;AX = PSP
	      	MOV	BX,SS
	      	SUB	BX,AX
	      	ADD	BX,020H
	      	MOV	AH,04AH			;SHRINK PROGRAM
	      	INT	021H

		MOV	SI,081H			;POINT SI TO COMMAND TAIL

		MOV	DI,OFFSET INP_FILE_NAME	;GET NAME OF INPUT FILE
		CALL	GET_PARA		;INTO BUFFER

		CALL	PRINT
		DB	"Nintendo Gameboy Emulator System V 1.2",13,10
		DB	"(C) A.R.Hartley 1993 Ideal Concepts",13,10
		DB	13,10
		DB	"Loading ....",13,10,0

		CALL	SETKEYINT
		CALL	GET_VMODE		;GET CURRENT VIDEO MODE

		CALL	OPEN_IN_FILE		;OPEN FILE
		CALL	READ_PRG		;READ GAMEBOY PRG
		CALL	FILE_IN_CLOSE		;CLOSE FILE

		CALL	SET_VGA
		CALL	SET_MONO
		CALL	CLS
		
		MOV	BX,1000H
		CALL	GETMEM
		MOV	[CS:DISPMEM],AX

		MOV	DS,[CS:Z80_SEG]

		MOV	AX,0
		MOV	[CS:Z80_BC],AX
		MOV	[CS:Z80_DE],AX
		MOV	[CS:Z80_HL],AX
		MOV	[CS:Z80_AF],AX

		MOV	[CS:DONGLE_ERROR],AX

		MOV	AX,0DFFFH
		MOV	[CS:Z80_SP],AX

		MOV	AX,100H			;RUN FROM 150H
		MOV	[CS:Z80_PC],AX

		MOV	AX,[CS:BANK_1]		;SET BANK POS
		MOV	[CS:Z80_BANK],AX

		MOV	AX,INTTIME
		MOV	[CS:INSTCNT],AX		;INC INT COUNT
		MOV	[CS:UPDATE],1		;DO UPDATE AT ONCE

		MOV	AL,0
		MOV	[BYTE STAT],0	
		MOV	[BYTE BGP],0FFH		;PALETTE BLACK

		MOV	[BYTE LY],0		;LCD Y AT 0
		MOV	[BYTE LYC],0		;LCD COMPARE AT 0

		MOV	[BYTE SCX],0
		MOV	[BYTE SCY],0

		MOV	[BYTE IME],0		;DISABLE INTS
		MOV	[BYTE I_F],0		;DISABLE INTS
		MOV	[BYTE I_E],0		;DISABLE INTS

		MOV	[BYTE DONGLE_LAST],0	;SET UP DONGLE
		MOV	[BYTE DONGLE_SEED],0

		MOV	[BYTE DMA],0		;DMA FLAG
		MOV	[BYTE TAC],0		;TIMER OFF

@@LOOP:		MOV	_HL,[CS:Z80_HL]
		MOV	_DE,[CS:Z80_DE]
		MOV	_BC,[CS:Z80_BC]

		CALL	RUN_ONE
		CALL	RUN_ONE

		CALL	UPDATE_KEYS
		CALL	UPDATE_LY

		CALL	RUN_ONE
		CALL	RUN_ONE

		CALL	UPDATE_KEYS
		CALL	UPDATE_LY

		CALL	RUN_ONE
		CALL	RUN_ONE

		CALL	UPDATE_KEYS
		CALL	UPDATE_LY

		CALL	RUN_ONE
		CALL	RUN_ONE

		CALL	UPDATE_KEYS
		CALL	UPDATE_LY

		CALL	RUN_ONE
		CALL	RUN_ONE

		CALL	UPDATE_KEYS
		CALL	UPDATE_LY

		MOV	[CS:Z80_BC],_BC
		MOV	[CS:Z80_DE],_DE
		MOV	[CS:Z80_HL],_HL

		;CALL	WRITE_INST

		CALL	UPDATE_DMA
		CALL	UPDATE_SCR
		CALL	UPDATE_SIO
		CALL	UPDATE_INT
		CALL	UPDATE_TMA
		CALL	UPDATE_LCD

		IF	DONGLE
		CALL	DONGLE_INT
		ENDIF	   

;		MOV	CX,1000
;@@DELAY:	NOP
;		LOOP	@@DELAY

		INC	[CS:TIME]

		KEY	ESC_KEY
		JZ	@@LOOP

@@STOP:		CALL	OLD_VMODE		;SET TO NORMAL VIDEO MODE

		CALL	SUMBANKS

		MOV	AX,[CS:Z80_PC]
		CALL	HEX_AX

		

       		JMP	DOS_RET

;*********************************
;	     GET KEYS
;      AL = ASC : AH = CODE
;*********************************

GETKEYS:	MOV	AH,1
		INT	16H
		JZ	@@NOKEY
		RET

@@NOKEY:	XOR	AL,AL
		XOR	AH,AH
		RET

;*********************************
;	     BREAKPOINT
;*********************************

BREAKPOINT:	CALL	OLD_VMODE		;SET TO NORMAL VIDEO MODE

		CALL	PRINT
		DB	"Breakpoint reached PC = #",0

		MOV	AX,[CS:Z80_PC]
		CALL	HEX_AX

		CALL	PR_REGS

       		JMP	DOS_RET

;*********************************
;	    NO DONGLE
;*********************************

NO_DONGLE:	CALL	OLD_VMODE		;SET TO NORMAL VIDEO MODE

		CALL	PRINT
		DB	"Dongle not detected !!",13,10,0

       		JMP	DOS_RET

;********************************
;	      BOMBOUT
;	      ~~~~~~~
;   IF A BAD OPCODE IS RUN THE
;	PROGRAM COMES HERE
;********************************

BOMBOUT:	CALL	OLD_VMODE		;SET TO NORMAL VIDEO MODE

		CALL	PRINT
		DB	"Bad opcode PC = #",0

		MOV	AX,[CS:Z80_PC]
		CALL	HEX_AX

		CALL	PR_REGS

       		JMP	DOS_RET

;*********************************
;	     BANK ERROR
;*********************************

SELBANK		DW	0
BANKPORT	DW	0

BANKERROR:	CALL	OLD_VMODE		;SET TO NORMAL VIDEO MODE

		CALL	PRINT
		DB	"Bank not loaded PC = #",0

		MOV	AX,[CS:Z80_PC]
		CALL	HEX_AX

		CALL	PRINT
		DB	13,10,"Bank selected = #",0

		MOV	AX,[CS:SELBANK]
		CALL	HEX_AX

		CALL	PRINT
		DB	13,10,"Port address = #",0

		MOV	AX,[CS:BANKPORT]
		CALL	HEX_AX

       		JMP	DOS_RET

;********************************
;	  PRINT REGISTORS
;********************************

PR_REGS:
		CALL	PRINT
		DB	13,10,"Regs:- HL = #",0
		MOV	AX,[CS:Z80_HL]
		CALL	HEX_AX

		CALL	PRINT
		DB	13,10,"       DE = #",0
		MOV	AX,[CS:Z80_DE]
		CALL	HEX_AX

		CALL	PRINT
		DB	13,10,"       BC = #",0
		MOV	AX,[CS:Z80_BC]
		CALL	HEX_AX

		CALL	PRINT
		DB	13,10,"       AF = #",0
		MOV	AX,[CS:Z80_AF]
		CALL	HEX_AX
							CALL	PRINT
		DB	13,10,"       SP = #",0
		MOV	AX,[CS:Z80_SP]
		CALL	HEX_AX
		RET

;*********************************
;	VBLANK SIMULATION
;*********************************

UPDATE		DW	0

UPDATE_SCR:	DEC	[CS:UPDATE]
		JZ	@@DISP
		RET

@@DISP:		MOV	[CS:UPDATE],SCRTIME

PRINT_SCR:

;		CALL	WAIT_FLY

		MOV	DS,[CS:Z80_SEG]
		CALL	SET_BGP_PAL
		CALL	SET_SPR0_PAL
		CALL	SET_SPR1_PAL

		CALL	DISPSCR
		CALL	DISPWIN
		CALL	DISPSPR

		CALL	WAIT_FLY
		CALL	PR_SCR
		RET

;*********************************
;	   LY SIMULATION
;*********************************

UPDATE_LY:	MOV	DS,[CS:Z80_SEG]

		AND	[BYTE STAT],11111011B		;CLR LYC

		MOV	AX,[CS:TIME]
		AND	AX,3
		JNZ	@@EXIT

		MOV	AL,[STAT]
		XOR	AL,2
		MOV	[STAT],AL

		INC	[BYTE LY]

		MOV	AL,[BYTE LYC]
		CMP	AL,[BYTE LY]
		JNZ	@@EXIT

		OR	[BYTE STAT],00000100B		;SET LYC

@@EXIT:		CMP	[CS:DONGLE_ERROR],10
		JZ	NO_DONGLE
		RET

;*********************************
;	   UPDATE KEYS
;*********************************

UPDATE_KEYS:	MOV	DS,[CS:Z80_SEG]

		MOV	AL,[P1]
		AND	AL,30H

		CMP	AL,20H
		JZ	GETJOY

		CMP	AL,10H
		JZ	GETPAD
		RET

;*********************************
;	   READ JOY KEYS
;*********************************

GETJOY:		MOV	DL,0

		KEY	RIGHTARROW_KEY
		JZ	@@NOT1

		OR	DL,1

@@NOT1:		KEY	LEFTARROW_KEY
		JZ	@@NOT2

		OR	DL,2

@@NOT2:		KEY	UPARROW_KEY
		JZ	@@NOT3

		OR	DL,4

@@NOT3:		KEY	DOWNARROW_KEY
		JZ	@@NOT4

		OR	DL,8

@@NOT4:		NOT	DL
		AND	DL,0FH		

		MOV	AL,[P1]
		AND	AL,0F0H
		OR	AL,DL
		MOV	[P1],AL

		JMP	KEYINT

;*********************************
;	   READ PAD KEYS
;*********************************

GETPAD:		MOV	DL,0

		KEY	A_KEY
		JZ	@@NOT1

		OR	DL,1

@@NOT1:		KEY	B_KEY
		JZ	@@NOT2

		OR	DL,2

@@NOT2:		KEY	F1_KEY
		JZ	@@NOT3

		OR	DL,4

@@NOT3:		KEY	F2_KEY
		JZ	@@NOT4

		OR	DL,8

@@NOT4:		NOT	DL
		AND	DL,0FH		

		MOV	AL,[P1]
		AND	AL,0F0H
		OR	AL,DL
		MOV	[P1],AL

		JMP	KEYINT

;********************************
;     P10-P13 KEY INTERRUPT
;********************************

KEYINT:		TEST	[BYTE I_E],00010000B
		JZ	@@NOPE
	
		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[CS:Z80_PC],60H		;MAKE THIS THE NEW PC ADDRESS
		MOV	[BYTE IME],0		;DO DI

@@NOPE:		RET

;********************************
;     LCDC STATUS INTERRUPT
;********************************

UPDATE_LCD:	MOV	AX,[CS:TIME]
		AND	AX,3FFH
		JNZ	@@NOPE

		TEST	[BYTE I_E],00000010B
		JZ	@@NOPE
	
		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		;MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		;CALL	PUSHDI

		;MOV	[CS:Z80_PC],48H		;MAKE THIS THE NEW PC ADDRESS
		;MOV	[BYTE IME],0		;DO DI

@@NOPE:		RET

;*********************************
;	UPDATE DMA SIMULATION
;*********************************

UPDATE_DMA:	MOV	AX,[CS:Z80_SEG]

		MOV	DS,AX
		MOV	ES,AX

		MOV	AL,[DMA]		;IS DMA SET
		AND	AL,AL
		JZ	@@EXIT

		MOV	AH,AL
		MOV	AL,0

		PUSH	AX
		POP	SI
	
		MOV	DI,0FE00H
		MOV	CX,140

		REP	MOVSB
		
		MOV	[BYTE DMA],0		;RESET DMA


;** ARH 98
;		MOV	[CS:UPDATE],100		;RESET DMA
;**		

@@EXIT:		RET

;********************************
;      	   SET PC TO DI
;********************************

INTFLAG		DW	0

UPDATE_INT:	TEST	[BYTE I_E],00000001B
		JZ	@@NOPE
	
		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		DEC	[CS:INSTCNT]		;INC INT COUNT   
		JNZ	@@NOPE

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[CS:Z80_PC],40H		;MAKE THIS THE NEW PC ADDRESS

		MOV	[BYTE IME],0		;DO DI
		MOV	[BYTE CS:INTFLAG],1

		MOV	[CS:INSTCNT],INTTIME
		RET

@@NOPE:		MOV	[BYTE CS:INTFLAG],0
		RET

;********************************
;    SIMULATE SIO INTERRUPT
;********************************

SIOTIME		DW	0

UPDATE_SIO:	TEST	[BYTE I_E],00001000B
		JZ	@@NOPE

		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		MOV	AX,[CS:SIOTIME]
		AND	AX,AX
		JNZ	@@COUNT

		MOV	DS,[CS:Z80_SEG]
		MOV	AL,[SC]
		AND	AL,80H
		JZ	@@NOPE			;SEND FLAG SET JMP IF NOT

		MOV	[CS:SIOTIME],50
		RET

@@COUNT:	DEC	[CS:SIOTIME]
		JNZ	@@NOPE
				
		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[BYTE IME],0		;DISABLE INTERRUPTS
		MOV	[CS:Z80_PC],58H		;MAKE THIS THE NEW PC ADDRESS

@@NOPE:		RET

;********************************
;    SIMULATE TIMER INTERRUPT
;********************************

UPDATE_TMA:	TEST	[BYTE I_E],00000100B
		JZ	@@NOPE

		CMP	[BYTE IME],0		;1 IF NO INTS
		JZ	@@NOPE

		TEST	[BYTE TAC],00000100B
		JZ	@@NOPE		

		MOV	AL,[BYTE TMA]		;ADD TIMA=TIMA+TMA
		ADD	[BYTE TIMA],AL
		JNC	@@NOPE

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[BYTE IME],0		;DISABLE INTERRUPTS
		MOV	[CS:Z80_PC],50H		;MAKE THIS THE NEW PC ADDRESS

@@NOPE:		RET

;********************************
;     DO DONGLE INTERRUPT
;********************************

DONGLE_ERROR	DW	0

DONGLE_INT:	MOV	AX,[CS:TIME]
		AND	AX,3FFH
		JNZ	@@NOPE

		CMP	[BYTE IME],0FFH		;1 IF NO INTS
		JZ	@@NOPE

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		CALL	PUSHDI

		MOV	[CS:Z80_PC],38H		;MOVE PC TO DONGLE ADDRESS
		MOV	[BYTE IME],0		;DO DI

		MOV	AX,[DONGLE_LAST]
		CMP	AL,AH
		JZ	@@NOERROR

		INC	[CS:DONGLE_ERROR]
		RET

@@NOERROR:	MOV	AL,[DONGLE_LAST]	;RUN DONGLE CODE
		ADD	AL,AL
		ADD	AL,AL
		ADD	AL,AL
		ADD	AL,[DONGLE_LAST]
		ADD	AL,49
		MOV	[DONGLE_LAST],AL

@@NOPE:		RET

;*********************************
;	WRITE INSTUCTION
;*********************************

WRITE_INST:
		LD	BX,[CS:LASTINST]
		ADD	BX,31

		MOV	CX,31

@@LOOP:		CMP	[BYTE CS:BX],0C3H
		JZ	@@GOTIT
		DEC	BX
		LOOP	@@LOOP
		RET

@@GOTIT:	INC	BX
		MOV	AL,[CS:BX]
		CMP	AL,0
		JZ	@@OUT

		CMP	AL,"/"
		JZ	@@ENTER

		PUSH	BX
		CALL	WRITE_BYTE
		POP	BX		
		JMP	@@GOTIT

@@OUT:		MOV	AL,13
		CALL	WRITE_BYTE
		
@@EXIT:		RET

@@ENTER:	PUSH	BX
		MOV	AL,13
		CALL	WRITE_BYTE

		MOV	AL,10
		CALL	WRITE_BYTE
		POP	BX		
		JMP	@@GOTIT

;*********************************
;	WRITE INSTUCTION
;*********************************

TRACEBIT	DB	1,2,4,8,16,32,64,128

FIND_TRACE:	MOV	DL,AL
		AND	DL,7
		MOV	DH,0

		MOV	DI,OFFSET TRACEBIT
		ADD	DI,DX
		MOV	DL,[CS:DI]

		SHR	AX,1
		SHR	AX,1
		SHR	AX,1
		MOV	DI,AX

		MOV	ES,[CS:TRACERAM]
		RET

;*****************************************************************************
;			   DISPLAY PROGRAMS
;*****************************************************************************

DISPMEM		DW	0A000H

;*********************************
;       CLEAR VGA SCREEN
;*********************************

CLS:		MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,0 			;BASE OF SCREEN
		MOV	AX,8484H
		MOV	CX,8000H
		REP	STOSW
    		RET

;*********************************
;       PRINT BACK SCREEN
;*********************************

PR_SCR:		PUSH	DS

		MOV	AX,[CS:DISPMEM]		;MAKE DS = VGA SEGMENT
		MOV	DS,AX
		MOV	SI,320*8+8

		MOV	AX,0A000H
		MOV	ES,AX
		MOV	DI,320*24+72		;BASE OF SCREEN
       
		MOV	CX,144
@@LOOP:		
		REPT	40
		MOVSD
		ENDM

		ADD	DI,160
		ADD	SI,160

		LOOP	@@LOOP

		POP	DS
    	RET

;*********************************
;	     TEST CHR
;*********************************

DISPSCR:	MOV	DS,[CS:Z80_SEG]

		MOV	AL,[SCX]
		OR	AL,[SCY]
		JZ	STATIC_SCR

		MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,320*8+8

		MOV	AL,[SCX]
		AND	AL,7
		MOV	CL,AL
		MOV	CH,0
		SUB	DI,CX

		MOV	AL,[SCY]
		AND	AL,7
		MOV	AH,0
		MOV	CX,320
		MUL	CX
		SUB	DI,AX

		CALL	SELMAP

		MOV	AL,[SCY]
		SHR	AL,3
		CBW
		SHL	AX,5

		MOV	CL,[SCX]
		SHR	CL,3
		MOV	CH,0
		ADD	BX,CX
		ADD	BX,AX

		MOV	CX,19			;18

@@MAIN:		PUSH	CX
		PUSH	BX
		PUSH	DI

		MOV	CX,21			;20
@@LOOP:		PUSH	CX

		PUSH	BX

		MOV	BL,[BYTE DS:BX]
		MOV	BH,0

		CALL	PR_CHR
		POP	BX

		POP	CX

		MOV	AL,BL
		AND	AL,11100000B
		INC	BL
		AND	BL,00011111B
		OR	BL,AL

		ADD	SI,16
		ADD	DI,8

		LOOP	@@LOOP

		POP	DI
		POP	BX
		POP	CX

		MOV	AX,BX
		AND	AX,1111110000000000B
		ADD	BX,32
		AND	BX,0000001111111111B
		OR	BX,AX

		ADD	DI,8*320

		LOOP	@@MAIN
		RET

;*********************************
;	     TEST CHR
;*********************************

STATIC_SCR:	MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,320*8+8

		CALL	SELMAP

		MOV	CX,18			;18

@@MAIN:		PUSH	CX
		PUSH	BX
		PUSH	DI

		MOV	CX,20			;20
@@LOOP:		PUSH	CX

		PUSH	BX

		MOV	BL,[BYTE DS:BX]
		MOV	BH,0

		CALL	PR_CHR
		POP	BX

		POP	CX

		INC	BX

		ADD	SI,16
		ADD	DI,8

		LOOP	@@LOOP

		POP	DI
		POP	BX
		POP	CX

		ADD	BX,32
		ADD	DI,8*320

		LOOP	@@MAIN
		RET

;*********************************
;	     TEST CHR
;*********************************

WINXL		DW	0

DISPWIN:	MOV	DS,[CS:Z80_SEG]

		MOV	AL,[LCDC]		;IS WINDOW ON
		AND	AL,00100000B
		JZ	@@QUIT

		MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,0

		MOV	AL,[WX]
		MOV	AH,0
		ADD	DI,AX

		MOV	AL,[WY]
		MOV	AH,0
		ADD	AX,8
		MOV	CX,320
		MUL	CX
		ADD	DI,AX

		CALL	WINMAP

		MOV	AL,[WX]
		SHR	AL,3
		MOV	AH,0

		MOV	CX,21			;18
		SUB	CX,AX	
		JC	@@QUIT
		JZ	@@QUIT

		MOV	[CS:WINXL],CX

		MOV	AL,[WY]
		SHR	AL,3
		MOV	AH,0
		INC	AX
		MOV	CX,19			;18
		SUB	CX,AX	
		JC	@@QUIT
		JZ	@@QUIT

@@MAIN:		PUSH	CX
		PUSH	BX
		PUSH	DI

		MOV	CX,[CS:WINXL]			;20
@@LOOP:		PUSH	CX

		MOV	AL,[BYTE DS:BX]
		PUSH	BX

		MOV	BL,AL
		MOV	BH,0

		CALL	PR_CHR
		POP	BX

		POP	CX

		MOV	AL,BL
		AND	AL,11100000B
		INC	BL
		AND	BL,00011111B
		OR	BL,AL

		ADD	SI,16
		ADD	DI,8

		LOOP	@@LOOP

		POP	DI
		POP	BX
		POP	CX

		MOV	AX,BX
		AND	AX,1111110000000000B
		ADD	BX,32
		AND	BX,0000001111111111B
		OR	BX,AX

		ADD	DI,8*320

		LOOP	@@MAIN
@@QUIT:		RET

;*********************************
;   CLEAR SCREEN EDGE WITH BLUE
;*********************************

CLR_EDGES:	MOV	AX,[CS:DISPMEM]		;MAKE ES = VGA SEGMENT
		MOV	ES,AX
		MOV	DI,0

		MOV	CX,8
		MOV	AX,8585H

@@LOOP:		PUSH	CX
		PUSH	DI
		
		MOV	CX,22*4
		REP	STOSW

		POP	DI
		PUSH	DI

		ADD	DI,(19*8)*320

		MOV	CX,22*4
		REP	STOSW

		POP	DI
		POP	CX

		ADD	DI,320

		LOOP	@@LOOP

		MOV	DI,320*8
		MOV	CX,8*18+1

@@LOOP2:	MOV	[ES:DI+0],AX
		MOV	[ES:DI+2],AX
		MOV	[ES:DI+4],AX
		MOV	[ES:DI+6],AX

		MOV	[ES:DI+168],AX
		MOV	[ES:DI+170],AX
		MOV	[ES:DI+172],AX
		MOV	[ES:DI+174],AX

		ADD	DI,320
		LOOP	@@LOOP2
		RET

;*********************************
;	  SELECT MAP AREA
;*********************************

WINMAP:		TEST	[BYTE LCDC],01000000B
		JNZ	@@AREA1

		MOV	BX,9800H
		RET

@@AREA1:	MOV	BX,9C00H
		RET		

;*********************************
;	  SELECT MAP AREA
;*********************************

SELMAP:		TEST	[BYTE LCDC],00001000B
		JNZ	@@AREA1

		MOV	BX,9800H
		RET

@@AREA1:	MOV	BX,9C00H
		RET		

;*********************************
;	  SELECT CHR AREA
;*********************************

;		LCDC	   76543210
;			   ||||||||_________ BG        ON(1)/OFF
;			   |||||||__________ SPR       ON(1)/OFF
;			   ||||||___________ OBJ      8X8(0)/8X16
;			   |||||____________ BG MAP  9800(0)/9C00
;			   ||||_____________ BG CHR  8800(0)/8000
;			   |||______________ WIN       ON(1)/OFF
;			   ||_______________ WIN MAP 9800(0)/9C00
;			   |________________ CONTROL   ON(1)/OFF
;

SELCHR:		TEST	[BYTE LCDC],00010000B
		JNZ	@@AREA1

		XOR	BL,80H
		SHL	BX,4

		ADD	BX,8800H
		MOV	SI,BX
		RET

@@AREA1:	SHL	BX,4
		ADD	BX,8000H
		MOV	SI,BX
 		RET

;*********************************
;     PIXEL PRINTING MACROS
;*********************************

		MACRO	ONEPIX
		XOR	DL,DL
		RCL	AH,1
		ADC	DL,DH
		ADD	DL,DL
		RCL	AL,1
		ADC	DL,CH
		MOV	[ES:DI],DL
		INC	DI
		ENDM


		MACRO	TWOPIX
		XOR	AX,AX
		RCL	DH,1
		ADC	AL,CL
		ADD	AL,AL
		RCL	DL,1
		ADC	AL,CH
		RCL	DH,1
		ADC	AH,CL
		ADD	AH,AH
		RCL	DL,1
		ADC	AH,CH
		STOSW
		ENDM

;*********************************
;	    PRINT A CHR
;	      CX = XY
;        BX = CHR ADDRESS
;*********************************
     
		IF	0
	
PR_XY:		MOV	DL,CH
		MOV	DH,0
		MOV	AX,320
		MUL	DX
		MOV	CH,0
		ADD	AX,CX
		MOV	DI,AX
						;BX = CHR NUM
PR_CHR:		CALL	SELCHR
						;DS:SI = VRAM CHR
						;ES:DI = SCR ADDR
GB_CHR:		MOV	CH,128
		MOV	CL,0

		MOV	DH,0

@@LOOP:		REPT	8

		LODSW
		MOV	DX,AX

		TWOPIX
		TWOPIX
		TWOPIX
		TWOPIX

		ADD	DI,320-8
		ENDM

		SUB	DI,320*8
		RET

		ENDIF

;*********************************
;	    PRINT A CHR
;	      CX = XY
;        BX = CHR ADDRESS
;*********************************

		MACRO	PIX4

		RCL	DH,1
		SETC	AL
		ADD	AL,AL
		RCL	DL,1
		ADC	AL,CH

		RCL	DH,1
		SETC	AH
		ADD	AH,AH
		RCL	DL,1
		ADC	AH,CH

		BSWAP	EAX

		RCL	DH,1
		SETC	AH
		ADD	AH,AH
		RCL	DL,1
		ADC	AH,CH

		RCL	DH,1
		SETC	AL
		ADD	AL,AL
		RCL	DL,1
		ADC	AL,CH

		BSWAP	EAX
		STOSD
		ENDM

	
PR_XY:		MOV	DL,CH
		MOV	DH,0
		MOV	AX,320
		MUL	DX
		MOV	CH,0
		ADD	AX,CX
		MOV	DI,AX
						;BX = CHR NUM
PR_CHR:		CALL	SELCHR
						;DS:SI = VRAM CHR
						;ES:DI = SCR ADDR
GB_CHR:		MOV	CH,128
		MOV	CL,0

		EVEN

@@LOOP:		REPT	8

		LODSW
		MOV	DX,AX

		PIX4
		PIX4

		ADD	DI,320-8
		ENDM

		SUB	DI,320*8
		RET

;*********************************
;	    PRINT A SPR
;	      CX = XY
;        BX = CHR ADDRESS
;*********************************

A_SPR:		
		MOV	AX,[CS:DISPMEM]
		MOV	ES,AX

		MOV	CH,[BX+0]
		SUB	CH,8

		MOV	CL,[BX+1]

		MOV	BX,[BX+2]
		MOV	[CS:SPRATTR],BH

		MOV	BH,0

		CMP	CH,8*18			;DO SOME CLIPPING
		JNC	@@EXIT

		CMP	CL,8*21
		JNC	@@EXIT

		CALL	SPR_XY
@@EXIT:		RET

;*********************************
;	    PRINT A SPR
;	      CX = XY
;        BX = CHR ADDRESS
;*********************************

SPR_XY:		MOV	DL,CH
		MOV	DH,0
		MOV	AX,320
		MUL	DX
		MOV	CH,0
		ADD	AX,CX
		MOV	DI,AX

		ADD	BX,BX
		ADD	BX,BX
		ADD	BX,BX
		ADD	BX,BX
		ADD	BX,8000H
		MOV	SI,BX

		MOV	CX,8

		TEST	[BYTE LCDC],00000100B
		JZ	@@8X8

		MOV	CX,16

@@8X8:		TEST	[BYTE CS:SPRATTR],00100000B	
		JNZ	@@MIRROR

		EVEN

@@LOOP:		LODSW

       		CALL	PIXEL
		INC	DI       
		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL
		INC	DI       
       		CALL	PIXEL

		ADD	DI,320-7
		LOOP	@@LOOP
		RET

@@MIRROR:	ADD	DI,8

		EVEN

@@L2:		LODSW

       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL
		DEC	DI
       		CALL	PIXEL

		ADD	DI,320+7
		LOOP	@@L2
		RET

;*********************************
;	    PRINT 1 PIXEL
;*********************************

PIXEL:		CMP	[BYTE ES:DI],85H
		JZ	@@EXIT

		MOV	DL,0
		RCL	AH,1
		ADC	DL,0
		ADD	DL,DL
		RCL	AL,1
		ADC	DL,0
		ADD	DL,124

		CMP	DL,124
		JZ	@@EXIT

		MOV	[ES:DI],DL

@@EXIT:		RET

;*********************************
;	  DISPLAY SPRITES
;*********************************

SPRATTR		DB	0

DISPSPR:	MOV	DS,[CS:Z80_SEG]

		MOV	BX,0FE00H
		MOV	CX,40

@@LOOP:		PUSH	CX
		PUSH	BX

		CALL	A_SPR

		POP	BX
		POP	CX

		ADD	BX,4
		LOOP	@@LOOP     
		RET

;*********************************
;          SET UP COLORS
;*********************************

SET_COLORS:	;MOV	SI,OFFSET COLOR_BUF
		MOV	CX,256
		MOV	BX,0
		JMP	SETCOL

;*********************************
;	     SET COLORS
;	     ~~~~~~~~~~
;	   SI = COLOR TAB
;	   CX = AMOUNT
;          BX = START COLOR
;*********************************

TEMPC		DB	0,0,0

SETCOL:		PUSH	CX

		MOV	AL,[CS:SI]
		SHR	AL,1
		SHR	AL,1
		MOV	[CS:TEMPC],AL

		MOV	AL,[CS:SI+1]
		SHR	AL,1
		SHR	AL,1
		MOV	[CS:TEMPC+1],AL

		MOV	AL,[CS:SI+2]
		SHR	AL,1
		SHR	AL,1
		MOV	[CS:TEMPC+2],AL

		MOV	DX,OFFSET TEMPC
		MOV	ES,[CS:CODERAM]
		MOV	CX,1

		MOV	AX,1012H		;SET RGB REG
		INT	10H

		POP	CX

		INC	BX
		ADD	SI,3

		LOOP	SETCOL
		RET

;*********************************
;   SET COLORS 0 - 3 AS GAMEBOY
;    VGA COLS START 128 - 131
;*********************************

MONO_COLS:

COL0:		DB	000H,000H,000H		;BLACK
COL1:		DB	03FH,03FH,03FH		;GREY #7F OR #3F
COL2:		DB	07FH,07FH,07FH		;GREY #7F OR #3F
COL3:		DB	0BFH,0BFH,0BFH		;WHITE

		DB	01FH,01FH,01FH		;BLACK ISH
		DB	000H,000H,080H		;BLACK ISH

SET_MONO:	MOV	SI,OFFSET MONO_COLS
		MOV	CX,6
		MOV	BX,128
		JMP	SETCOL

;*********************************
;
;*********************************

OLD_BGP			DB	0
OLD_OBP0		DB	0
OLD_OBP1		DB	0

SET_BGP_PAL:	MOV	BX,131

		MOV	AL,[DS:BGP]
		CMP	AL,[CS:OLD_BGP]
		JZ	@@NOSET

		MOV	[CS:OLD_BGP],AL
				
		AND	AL,3
		CALL	GET_GB_PAL

		MOV	AL,[DS:BGP]
		SHR	AL,1
		SHR	AL,1
		AND	AL,3
       		CALL	GET_GB_PAL

		MOV	AL,[DS:BGP]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		AND	AL,3
		CALL	GET_GB_PAL

		MOV	AL,[DS:BGP]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

@@NOSET:
		RET

;*********************************
;	  SPR PAL 0 AT 124
;*********************************

SET_SPR0_PAL:	
		MOV	BX,126

		MOV	AL,[DS:OBP0]
		CMP	AL,[CS:OLD_OBP0]
		JZ	@@NOSET

		MOV	[CS:OLD_OBP0],AL

		CALL	GET_GB_PAL

		MOV	BX,127
		MOV	AL,[DS:OBP0]
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

		MOV	BX,124
		MOV	AL,[DS:OBP0]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

		MOV	BX,125
		MOV	AL,[DS:OBP0]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

@@NOSET:
		RET

;*********************************
;	  SPR PAL 1 AT 124
;*********************************

SET_SPR1_PAL:	
		MOV	BX,116

		MOV	AL,[DS:OBP1]
		CMP	AL,[CS:OLD_OBP1]
		JZ	@@NOSET

		MOV	[CS:OLD_OBP1],AL

		CALL	GET_GB_PAL

		MOV	BX,117
		MOV	AL,[DS:OBP1]
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

		MOV	BX,114
		MOV	AL,[DS:OBP1]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

		MOV	BX,115
		MOV	AL,[DS:OBP1]
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		SHR	AL,1
		CALL	GET_GB_PAL

@@NOSET:
		RET

;*********************************
;
;*********************************

GET_GB_PAL:	PUSH	BX

		MOV	SI,OFFSET COL0

		AND	AL,3
		JZ	@@OK

		MOV	SI,OFFSET COL1

		CMP	AL,1
		JZ	@@OK

		MOV	SI,OFFSET COL2

		CMP	AL,2
		JZ	@@OK

		MOV	SI,OFFSET COL3

@@OK:		MOV	CX,1
		CALL	SETCOL

		POP	BX

		DEC	BX
		RET

;*****************************************************************************
;		      EMULATION PROCESS ROUTINES
;*****************************************************************************


LAST_PC		DW	0
LASTINST	DW	0

FLAGS		DB	0

;********************************
;      RUN ONE INSTRUCTION
;********************************

		EVEN

RUN_ONE: 	MOV	DS,[CS:Z80_SEG]
		MOV	SI,[CS:Z80_PC]
		MOV	[CS:LAST_PC],SI

		MOV	DI,SI
		AND	DI,1100000000000000B
		CMP	DI,0100000000000000B
		JNZ	@@NOTBANK

		MOV	DS,[CS:Z80_BANK]	;SWITCH TO BANK

@@NOTBANK:	CMP	[BYTE SI],0CBH		;TEST FOR AFTER CB
		JZ	AFTER_CB

		PUSH	OFFSET Z80_RETURN

		MOV	AL,[SI]
		XOR	AH,AH
		ADD	AX,AX
		MOV	DI,AX
		PUSH	[WORD CS:DI+OFFSET TABLES]

		MOV	AH,[CS:FLAGS]
		SAHF

		MOV	AH,[BYTE CS:Z80_AF+1]

		MOV	AL,[SI+1]		;GET AL READY
		MOV	DI,[SI+1]		;GET DI READY

	 	MOV	DS,[CS:Z80_SEG]
		RET				;DO IT

Z80_RETURN:	MOV	[BYTE CS:Z80_AF+1],AH

		LAHF
		MOV	[CS:FLAGS],AH
		RET

;********************************
;      	      RUN ONE
;     AFTER CB INSTRUCTIONS
;********************************

		EVEN

AFTER_CB:	INC	SI
		MOV	[CS:Z80_PC],SI

		PUSH	OFFSET CB_RETURN

		MOV	AL,[SI]
		XOR	AH,AH
		ADD	AX,AX
		MOV	DI,AX
		PUSH	[WORD CS:DI+OFFSET (TABLES+512)]
	
		MOV	AH,[CS:FLAGS]
		SAHF

		MOV	AH,[BYTE CS:Z80_AF+1]

 		MOV	DS,[CS:Z80_SEG]
		RET				;DO IT

CB_RETURN:	MOV	[BYTE CS:Z80_AF+1],AH

		LAHF
		MOV	[CS:FLAGS],AH
		RET

;*****************************************************************************
;			EXTRA EMULATION ROUTINES
;*****************************************************************************

LDZ_Z_A:	PUSHF
		PUSH _BC		;SAVE BC
		LD   _B,0FFH		;B  = FF
		LD   _C,_N		;C  = N
		MOV  DI,_BC		;DI = CX
		MOV  [DI],_A		;AL => [DI]
		POP  _BC		;RESTORE BC
		POPF
		RET	

;********************************

LD_C_A:		PUSHF
		MOV _N,_B		;SAVE B
		MOV _B,0FFH		;B  = FF
		MOV DI,_BC		;DI = FFCC
		MOV [DI],_A		;AL => [DI]
		MOV _B,_N		;RESTORE B
		POPF
		RET

;********************************

LD_A_C:		PUSHF
		MOV _N,_B		;SAVE B
		MOV _B,0FFH		;B  = FF
		MOV DI,_BC		;DI = FFCC
		MOV _A,[DI]		;AL => [DI]
		MOV _B,_N		;RESTORE B
		POPF
		RET

;********************************

LDZ_A_Z:	PUSHF
		PUSH _BC
		LD   _C,_N		;PUT BYTE IN AL
		LD   _B,0FFH		;AH = FF
		LD   DI,_BC		;DI = FFXX
		LD   _A,[DI]		;AL = (DI)
		POP  _BC
		POPF
		RET

;********************************

LDHL_SP_N:	LD   _HL,[CS:Z80_SP]	;MAKE HL=SP

		PUSH AX			;SAVE AL
		LD   AL,_N		;AL = AH
		CBW			;SIGN EXTEND AL => AX
		ADD  _HL,AX		;BX = BX + AX
		POP  AX			;RETRIEVE OLD AL

		MOV _N,1
		JC   @@CYSET

		AND _N,_N
		RET

@@CYSET:	AND _N,_N
		STC
		RET

;********************************

ADD_SP_N:	PUSH AX			;SAVE AL
		LD   AL,_N		;AL = AH
		CBW			;SIGN EXTEND AL => AX
		ADD  [CS:Z80_SP],AX	;BX = BX + AX
		POP  AX			;RETRIEVE OLD AL

		MOV _N,1		;CLR ZF
		AND _N,_N
		RET

;********************************

BANK_HL:	PUSHF

		TEST	_H,10000000B
		JNZ	@@OUT

		TEST	_H,01000000B
		JZ	@@OUT

		MOV	DS,[CS:Z80_BANK]

@@OUT:		POPF
		RET
;********************************

BANK_DE:	PUSHF

		TEST	_D,10000000B
		JNZ	@@OUT

		TEST	_D,01000000B
		JZ	@@OUT

		MOV	DS,[CS:Z80_BANK]

@@OUT:		POPF
		RET

;********************************

BANK_BC:	PUSHF

		TEST	_B,10000000B
		JNZ	@@OUT

		TEST	_B,01000000B
		JZ	@@OUT

		MOV	DS,[CS:Z80_BANK]

@@OUT:		POPF
		RET

;********************************

REPDATA		DW	0
RDATA		DB	0

TESTBANK: 	PUSHF

		CMP	DI,3000H					;4000H
		JNC	@@OUT

		CMP	DI,2000H
		JC	@@NOWRITE

     	PUSH	AX
		PUSH	DI

		MOV	AH,[DI]
		MOV	[CS:RDATA],AH

		MOV	AL,_N
		MOV	AH,0

		MOV	[CS:BANKPORT],DI
		MOV	[CS:SELBANK],AX

		ADD	AX,AX

		ADD	AX,OFFSET Z80_SEG
		MOV	DI,AX

		MOV	AX,[CS:DI]

		AND	AX,AX
		JZ	BANKERROR

		SUB	AX,400H			;MAKE SEGMENT START AT #4000
		MOV	[CS:Z80_BANK],AX

		MOV	[CS:REPDATA],1

		POP	DI
		POP	AX
		POPF
		RET

@@OUT:		POPF
		RET

@@NOWRITE:	MOV	_N,[DI]
		MOV	[CS:RDATA],_N
		MOV	[CS:REPDATA],1

		POPF
		RET

;********************************

PUTBACK:	PUSHF
		CMP	[CS:REPDATA],1
		JNZ	@@QUIT

		MOV	_N,[CS:RDATA]
		MOV	[DI],_N

		MOV	[CS:REPDATA],0

@@QUIT:		POPF
       		RET

;********************************

TESTBIT_0:	JC	@@CYSET
		TEST	_N,1
		CLC
		RET

@@CYSET:	TEST	_N,1
		STC
		RET

;********************************

TESTBIT_1:	JC	@@CYSET
		TEST	_N,2
		CLC
		RET
@@CYSET:	TEST	_N,2
		STC
		RET

;********************************

TESTBIT_2:	JC	@@CYSET
		TEST	_N,4
		CLC
		RET
@@CYSET:	TEST	_N,4
		STC
		RET

;********************************


TESTBIT_3:	JC	@@CYSET
		TEST	_N,8
		CLC
		RET
@@CYSET:	TEST	_N,8
		STC
		RET

;********************************

TESTBIT_4:	JC	@@CYSET
		TEST	_N,16
		CLC
		RET
@@CYSET:	TEST	_N,16
		STC
		RET

;********************************

TESTBIT_5:	JC	@@CYSET
		TEST	_N,32
		CLC
		RET
@@CYSET:	TEST	_N,32
		STC
		RET

;********************************

TESTBIT_6:	JC	@@CYSET
		TEST	_N,64
		CLC
		RET
@@CYSET:	TEST	_N,64
		STC
		RET

;********************************

TESTBIT_7:	JC	@@CYSET
		TEST	_N,128
		CLC
		RET
@@CYSET:	TEST	_N,128
		STC
		RET

;********************************

CLRZERO:	LD	_N,1
		AND	_N,_N
		RET

;********************************

TESTZERO:	JC	@@CYSET
		AND	_N,_N
		CLC
		RET		
@@CYSET:	AND	_N,_N
		STC
		RET		


;********************************
;	 RUN HALT OR STOP
;********************************

DO_HALT:
		MOV	[CS:INSTCNT],1
		MOV	[CS:UPDATE],1
		RET

;********************************
;      	   SET PC TO DI
;********************************

SET_PC:		MOV	[CS:Z80_PC],DI		;MAKE THIS THE NEW PC ADDRESS
		RET

;********************************
;      SET UP A CALL TO DI
;********************************

CALL_DI:	PUSHF
		PUSH	DI			;SAVE TRAIL DATA

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		ADD	DI,3			;SKIP CALL
		CALL	PUSHDI

		POP	DI	       		;RETRIEVE TRAIL DATA
		MOV	[CS:Z80_PC],DI		;MAKE THIS THE NEW PC ADDRESS
		POPF
		RET

;********************************
;      SET UP A RST TO DI
;********************************

RST_DI:		PUSHF
		PUSH	DI			;SAVE TRAIL DATA

		MOV	DI,[CS:Z80_PC]		;PUSH Z80 RETURN ADDRESS
		INC	DI
		CALL	PUSHDI

		POP	DI	       		;RETRIEVE TRAIL DATA

		MOV	[CS:Z80_PC],DI		;MAKE THIS THE NEW PC ADDRESS
		POPF
		RET

;********************************
;	   DO A RETURN
;         AND JUMP TO DI 
;********************************

RETURN:		CALL	POPDI
		MOV	[CS:Z80_PC],DI
		RET

;********************************
;	 PUSH DI ON STACK
;********************************

PUSHDI:		PUSHF
		MOV	SI,[CS:Z80_SP]
		MOV	[SI-2],DI
		SUB	[CS:Z80_SP],2
		POPF
		RET

;********************************
;	 POP DI OFF STACK
;********************************

POPDI:		PUSHF
		MOV	SI,[CS:Z80_SP]
		MOV	DI,[SI]
		ADD	[CS:Z80_SP],2
		POPF
		RET

;********************************
;	   RELATIVE JUMP
; ADDRESS RULE = ADDR + 2 + DISP
;********************************

REL_JUMP_N:	PUSHF
		PUSH	AX
		MOV	AL,_N
		CBW
		ADD	[CS:Z80_PC],AX
		POP	AX
		POPF
		RET

;********************************
;GET FLAGS AND ARRANGE THEN IN AL
;********************************

GET_FLAGS_AL:	JC	@@CARRY
		JZ	@@ZERO

		MOV	AL,0
		RET

@@CARRY:	JZ	@@BOTH

		MOV	AL,10H
		RET

@@BOTH:		MOV	AL,90H
		RET

@@ZERO:		MOV	AL,80H
		RET

;********************************
;	 SET FLAG REGISTOR
;********************************

SET_FLAGS_AL:	CMP	AL,10H
		JZ	@@CARRY

		CMP	AL,80H
		JZ	@@ZERO

		CMP	AL,90H
		JZ	@@BOTH
					;CLEAR CY AND ZERO
		CLC
		RET

@@CARRY:	CMP	AL,0FFH		;SET NZ
		STC
		RET

@@ZERO:		CLC
		RET

@@BOTH:		STC
		RET

;********************************
;	 SWAP INSTRUCTION
;********************************

SWAP:		ROL	_N,1
		ROL	_N,1
		ROL	_N,1
		ROL	_N,1

		AND	_N,_N
		CLC
		RET

;*****************************************************************************
;			     EQUAL REGS
;        BX=HL:CX=BC:DX=DE:SI=SP:CH=B:CL=C:BH=H:BL=L:DH=D:DL=E:AH=A
;
;			   DS = Z80 SPACE	
;	     ON ENTRY DI = 2 FOLLOWERS : AL = 1 FOLLOWER
;*****************************************************************************

		NOJUMPS

TABSTART	= 8000H

		ORG	TABSTART

;********************************
;	  EMULATION TABLES
;********************************

EMU_TAB:	SETNULL			;ZERO OUT RW AND INSTRLEN

		NOP
		PAD  "NOP"

;********************************

		OPW
		LD   _BC,_W
		PAD  "LD BC,w"

;********************************
	
		MOV DI,_BC
		MOV _N,_A
		CALL TESTBANK

		MOV [DI],_A

		CALL PUTBACK
		PAD  "LD (BC),A"

;********************************

		PUSHF
		INC _BC
		POPF
		PAD  "INC BC"

;********************************

		INC _B
		PAD  "INC B"

;********************************

		DEC _B
		PAD  "DEC B"

;********************************

		OPB
		LD  _B,_N
		PAD  "LD B,n"

;********************************

		CALL CLRZERO
		ROL _A,1
		PAD  "RLCA"

;********************************

		OPW
		MOV [Z80_SP],DI 		;CUNT THIS IS LD (W),SP
		PAD  "LD (W),SP"		;THIS WAS DB #08

;********************************

		ADD _HL,_BC
		PAD  "ADD HL,BC"

;********************************

		RBC
		MOV DI,_BC
		MOV _A,[DI]
		PAD  "LD A,(BC)"

;********************************

		PUSHF
		DEC _BC
		POPF
		PAD  "DEC BC"

;********************************

		INC _C
		PAD  "INC C"

;********************************

		DEC _C
		PAD  "DEC C"

;********************************

		OPB
		MOV _C,_N
		PAD  "LD C,n"

;********************************

		CALL CLRZERO
		ROR _A,1
		PAD  "RRCA"

;********************************

		CALL DO_HALT		;???
		PAD  "STOP"

;********************************

		OPW
		MOV _DE,_W
		PAD  "LD DE,w"

;********************************

		MOV _N,_A		
		MOV DI,_DE
		CALL TESTBANK

		MOV [DI],_A

		CALL PUTBACK
		PAD  "LD (DE),A"

;********************************

		PUSHF
		INC _DE
		POPF
		PAD  "INC DE"

;********************************

		INC _D
		PAD  "INC D"

;********************************

		DEC _D
		PAD  "DEC D"

;********************************

		OPB
		MOV _D,_N
		PAD  "LD D,n"

;********************************

		CALL CLRZERO
		RCL _A,1
		PAD  "RLA"

;********************************

		OPB
		CALL REL_JUMP_N
		PAD "JR d"

;********************************

		ADD _HL,_DE
		PAD "ADD HL,DE"

;********************************

		RDE
		MOV DI,_DE
		MOV _A,[DI]
		PAD  "LD A,(DE)"

;********************************

		PUSHF
		DEC _DE
		POPF
		PAD  "DEC DE"

;********************************

		INC _E
		PAD  "INC E"

;********************************

		DEC _E
		PAD  "DEC E"

;********************************

		OPB
		MOV _E,_N
		PAD  "LD E,n"

;********************************

		CALL CLRZERO
		RCR _A,1
		PAD  "RRA"

;********************************

		OPB
		JZ  JRNZ
		CALL REL_JUMP_N
JRNZ:		PAD  "JR NZ,d"

;********************************

		OPW
		MOV _HL,_W
		PAD  "LD HL,w"

;********************************

		PUSHF

		MOV DI,_HL
		MOV _N,_A
		CALL TESTBANK

		MOV [_HL],_A
		INC _HL

		CALL PUTBACK
		POPF
		PAD  "LD (HLI),A"

;********************************

		PUSHF
		INC _HL
		POPF
		PAD  "INC HL"

;********************************

		INC _H
		PAD  "INC H"

;********************************

		DEC _H
		PAD  "DEC H"

;********************************

		OPB
		MOV _H,_N
		PAD  "LD H,n"

;********************************

		MOV AL,_A
		DAA
		MOV _A,AL
		PAD  "DAA"

;********************************

		OPB
		JNZ  JRZ
		CALL REL_JUMP_N
JRZ:		PAD  "JR Z,d"

;********************************

		ADD _HL,_HL
		PAD  "ADD HL,HL"

;********************************

		RHL
		PUSHF
		MOV _A,[_HL]
		INC _HL
		POPF
		PAD  "LD A,(HLI)"

;********************************

		PUSHF
		DEC _HL
		POPF
		PAD  "DEC HL"

;********************************

		INC _L
		PAD  "INC L"

;********************************

		DEC _L
		PAD  "DEC L"

;********************************

		OPB
		MOV _L,_N
		PAD  "LD L,n"

;********************************

		NOT _A
		PAD  "CPL"

;********************************

		OPB
		JC   JRNC
		CALL REL_JUMP_N
JRNC:		PAD  "JR NC,d"

;********************************

		OPW
		MOV [CS:Z80_SP],_W
		PAD  "LD SP,w"

;********************************

		PUSHF

		MOV  DI,_HL
		MOV  _N,_A
		CALL TESTBANK

		MOV [_HL],_A
		DEC _HL

		CALL PUTBACK
		POPF

		PAD  "LD (HLD),A"

;********************************
		     
		PUSHF
		INC [CS:Z80_SP]
		POPF
		PAD  "INC SP"

;********************************

		RHL
		INC [BYTE _HL]

		PAD  "INC (HL)"

;********************************

		RHL

		DEC [BYTE _HL]
		PAD  "DEC (HL)"

;********************************

		OPB
		MOV [BYTE _HL],_N
		PAD  "LD (HL),n"

;********************************

		STC
		PAD  "SCF"

;********************************

		OPB
		JNC  JRC
		CALL REL_JUMP_N
JRC:		PAD  "JR C,d"

;********************************

		ADD _HL,[CS:Z80_SP]
		PAD  "ADD HL,SP"

;********************************

		RHL
		PUSHF
		MOV _A,[_HL]
		DEC _HL
		POPF
		PAD  "LD A,(HLD)"

;********************************

		PUSHF
		DEC [CS:Z80_SP]
		POPF
		PAD  "DEC SP"

;********************************

		INC _A
		PAD  "INC A"

;********************************

		DEC _A
		PAD  "DEC A"

;********************************

		OPB
		MOV _A,_N
		PAD  "LD A,n"

;********************************

		CMC
		PAD  "CCF"

;********************************

		LD  _B,_B
		PAD  "LD B,B"

;********************************

		LD  _B,_C
		PAD  "LD B,C"

;********************************

		LD  _B,_D
		PAD  "LD B,D"

;********************************

		LD  _B,_E
		PAD  "LD B,E"

;********************************

		LD  _B,_H
		PAD  "LD B,H"

;********************************

		LD  _B,_L
		PAD  "LD B,L"

;********************************

		RHL
		LD  _B,[_HL]
		PAD  "LD B,(HL)"

;********************************

		LD  _B,_A
		PAD  "LD B,A"

;********************************

		LD  _C,_B
		PAD  "LD C,B"

;********************************

		LD  _C,_C
		PAD  "LD C,C"

;********************************

		LD  _C,_D
		PAD  "LD C,D"

;********************************

		LD  _C,_E
		PAD  "LD C,E"

;********************************

		LD  _C,_H
		PAD  "LD C,H"

;********************************

		LD  _C,_L
		PAD  "LD C,L"

;********************************

		RHL
		LD  _C,[_HL]
		PAD  "LD C,(HL)"

;********************************

		LD  _C,_A
		PAD  "LD C,A"

;********************************

		LD  _D,_B
		PAD  "LD D,B"

;********************************

		LD  _D,_C
		PAD  "LD D,C"

;********************************

		LD  _D,_D
		PAD  "LD D,D"

;********************************

		LD  _D,_E
		PAD  "LD D,E"

;********************************

		LD  _D,_H
		PAD  "LD D,H"

;********************************

		LD  _D,_L
		PAD  "LD D,L"

;********************************

		RHL
		LD  _D,[_HL]
		PAD  "LD D,(HL)"

;********************************

		LD  _D,_A
		PAD  "LD D,A"

;********************************

		LD  _E,_B
		PAD  "LD E,B"

;********************************

		LD  _E,_C
		PAD  "LD E,C"

;********************************

		LD  _E,_D
		PAD  "LD E,D"

;********************************

		LD  _E,_E
		PAD  "LD E,E"

;********************************

		LD  _E,_H
		PAD  "LD E,H"

;********************************

		LD  _E,_L
		PAD  "LD E,L"

;********************************

		RHL
		LD  _E,[_HL]
		PAD  "LD E,(HL)"

;********************************

		LD  _E,_A
		PAD  "LD E,A"

;********************************

		LD  _H,_B
		PAD  "LD H,B"

;********************************

		LD  _H,_C
		PAD  "LD H,C"

;********************************

		LD  _H,_D
		PAD  "LD H,D"

;********************************

		LD  _H,_E
		PAD  "LD H,E"

;********************************

		LD  _H,_H
		PAD  "LD H,H"

;********************************

		LD  _H,_L
		PAD  "LD H,L"

;********************************

		RHL
		LD  _H,[_HL]
		PAD  "LD H,(HL)"

;********************************

		LD  _H,_A
		PAD  "LD H,A"

;********************************

		LD  _L,_B
		PAD  "LD L,B"

;********************************

		LD  _L,_C
		PAD  "LD L,C"

;********************************

		LD  _L,_D
		PAD  "LD L,D"

;********************************

		LD  _L,_E
		PAD  "LD L,E"

;********************************

		LD  _L,_H
		PAD  "LD L,H"

;********************************

		LD  _L,_L
		PAD  "LD L,L"

;********************************

		RHL
		LD  _L,[_HL]
		PAD  "LD L,(HL)"

;********************************

		LD  _L,_A
		PAD  "LD L,A"

;********************************

		MOV DI,_HL
		MOV _N,_B
		CALL TESTBANK

		LD  [_HL],_B

		CALL PUTBACK
		PAD  "LD (HL),B"

;********************************

		MOV DI,_HL
		MOV _N,_C
		CALL TESTBANK

		LD  [_HL],_C

		CALL PUTBACK
		PAD  "LD (HL),C"

;********************************

		MOV DI,_HL
		MOV _N,_D
		CALL TESTBANK

		LD  [_HL],_D

		CALL PUTBACK
		PAD  "LD (HL),D"

;********************************

		MOV DI,_HL
		MOV _N,_E
		CALL TESTBANK

		LD  [_HL],_E

		CALL PUTBACK
		PAD  "LD (HL),E"

;********************************

		MOV DI,_HL
		MOV _N,_H
		CALL TESTBANK

		LD  [_HL],_H

		CALL PUTBACK
		PAD  "LD (HL),H"

;********************************

		MOV DI,_HL
		MOV _N,_L
		CALL TESTBANK

		LD  [_HL],_L

		CALL PUTBACK
		PAD  "LD (HL),L"

;********************************

		CALL DO_HALT
		PAD  "HALT"

;********************************

		MOV DI,_HL
		MOV _N,_A
		CALL TESTBANK

		LD  [_HL],_A

		CALL PUTBACK
		PAD  "LD (HL),A"

;********************************

		LD  _A,_B
		PAD  "LD A,B"

;********************************

		LD  _A,_C
		PAD  "LD A,C"

;********************************

		LD  _A,_D
		PAD  "LD A,D"

;********************************

		LD  _A,_E
		PAD  "LD A,E"

;********************************

		LD  _A,_H
		PAD  "LD A,H"

;********************************

		LD  _A,_L
		PAD  "LD A,L"

;********************************

		RHL
		LD  _A,[_HL]
		PAD  "LD A,(HL)"

;********************************

		LD  _A,_A
		PAD  "LD A,A"

;********************************

		ADD _A,_B
		PAD  "ADD A,B"

;********************************

		ADD _A,_C
		PAD  "ADD A,C"

;********************************

		ADD _A,_D
		PAD  "ADD A,D"

;********************************

		ADD _A,_E
		PAD  "ADD A,E"

;********************************

		ADD _A,_H
		PAD  "ADD A,H"

;********************************

		ADD _A,_L
		PAD  "ADD A,L"

;********************************

		RHL
		ADD _A,[_HL]
		PAD  "ADD A,(HL)"

;********************************

		ADD _A,_A
		PAD  "ADD A,A"

;********************************

		ADC _A,_B
		PAD  "ADC A,B"

;********************************

		ADC _A,_C
		PAD  "ADC A,C"

;********************************

		ADC _A,_D
		PAD  "ADC A,D"

;********************************

		ADC _A,_E
		PAD  "ADC A,E"

;********************************

		ADC _A,_H
		PAD  "ADC A,H"

;********************************

		ADC _A,_L
		PAD  "ADC A,L"

;********************************

		RHL
		ADC _A,[_HL]
		PAD  "ADC A,(HL)"

;********************************

		ADC _A,_A
		PAD  "ADC A,A"

;********************************

		SUB _A,_B
		PAD  "SUB B"

;********************************

		SUB _A,_C
		PAD  "SUB C"

;********************************

		SUB _A,_D
		PAD  "SUB D"

;********************************

		SUB _A,_E
		PAD  "SUB E"

;********************************

		SUB _A,_H
		PAD  "SUB H"

;********************************

		SUB _A,_L
		PAD  "SUB L"

;********************************

		RHL
		SUB _A,[_HL]
		PAD  "SUB (HL)"

;********************************

		SUB _A,_A
		PAD  "SUB A"

;********************************

		SBB _A,_B
		PAD  "SBC A,B"

;********************************

		SBB _A,_C
		PAD  "SBC A,C"

;********************************

		SBB _A,_D
		PAD  "SBC A,D"

;********************************

		SBB _A,_E
		PAD  "SBC A,E"

;********************************

		SBB _A,_H
		PAD  "SBC A,H"

;********************************

		SBB _A,_L
		PAD  "SBC A,L"

;********************************

		RHL
		SBB _A,[_HL]
		PAD  "SBC A,(HL)"

;********************************

		SBB _A,_A
		PAD  "SBC A,A"

;********************************

		AND _A,_B
		PAD  "AND B"

;********************************

		AND _A,_C
		PAD  "AND C"

;********************************

		AND _A,_D
		PAD  "AND D"

;********************************

		AND _A,_E
		PAD  "AND E"

;********************************

		AND _A,_H
		PAD  "AND H"

;********************************

		AND _A,_L
		PAD  "AND L"

;********************************

		RHL
		AND _A,[_HL]
		PAD  "AND (HL)"

;********************************

		AND _A,_A
		PAD  "AND A"

;********************************

		XOR _A,_B
		PAD  "XOR B"

;********************************

		XOR _A,_C
		PAD  "XOR C"

;********************************

		XOR _A,_D
		PAD  "XOR D"

;********************************

		XOR _A,_E
		PAD  "XOR E"

;********************************

		XOR _A,_H
		PAD  "XOR H"

;********************************

		XOR _A,_L
		PAD  "XOR L"

;********************************

		RHL
		XOR _A,[_HL]
		PAD  "XOR (HL)"

;********************************

		XOR _A,_A
		PAD  "XOR A"

;********************************

		OR _A,_B
		PAD  "OR B"

;********************************

		OR _A,_C
		PAD  "OR C"

;********************************

		OR _A,_D
		PAD  "OR D"

;********************************

		OR _A,_E
		PAD  "OR E"

;********************************

		OR _A,_H
		PAD  "OR H"

;********************************

		OR _A,_L
		PAD  "OR L"

;********************************

		RHL
		OR _A,[_HL]
		PAD  "OR (HL)"

;********************************

		OR _A,_A
		PAD  "OR A"

;********************************

		CMP _A,_B
		PAD  "CP B"

;********************************

		CMP _A,_C
		PAD  "CP C"

;********************************

		CMP _A,_D
		PAD  "CP D"

;********************************

		CMP _A,_E
		PAD  "CP E"

;********************************

		CMP _A,_H
		PAD  "CP H"

;********************************

		CMP _A,_L
		PAD  "CP L"

;********************************

		RHL
		CMP _A,[_HL]
		PAD  "CP (HL)"

;********************************

		CMP _A,_A
		PAD  "CP A"

;********************************

		JZ   RNZ
		JMP  RETURN
RNZ:		PAD  "RET NZ"

;********************************

		CALL POPDI
		MOV  _BC,DI
		PAD  "POP BC"

;********************************

		OPW
		JZ   XJNZ
		JMP  SET_PC
XJNZ:		PAD  "JP NZ,w/"

;********************************

		OPW
		JMP SET_PC
		PAD  "JP w/"

;********************************

		OPW
		JZ   NC4
		JMP CALL_DI
NC4:		PAD  "CALL NZ,w"

;********************************

		MOV  DI,_BC
		CALL PUSHDI
		PAD  "PUSH BC"

;********************************

		OPB
		ADD _A,_N
		PAD  "ADD A,n"

;********************************

		MOV  DI,00H
		JMP  RST_DI			;DON'T ADD PC
		PAD  "RST 00H"

;********************************

		JNZ  RZ
		JMP  RETURN
RZ:		PAD  "RET Z"

;********************************

		JMP  RETURN
		PAD  "RET/"

;********************************

JJPZ:		OPW
		JNZ  XJZ
		JMP  SET_PC
XJZ:		PAD  "JP Z,w"

;********************************

		BADOP
		PAD  "DB #CB"

;********************************

		OPW
		JNZ  NC3
		JMP  CALL_DI
NC3:		PAD  "CALL Z,w"

;********************************

		OPW
		JMP  CALL_DI
		PAD  "CALL w/"

;********************************

		OPB
		ADC _A,_N
		PAD  "ADC A,n"

;********************************

		MOV  DI,08H
		JMP  RST_DI
		PAD  "RST 08H"

;********************************

		JC   RNC
		JMP  RETURN
RNC:		PAD  "RET NC"

;********************************

		CALL POPDI
		MOV  _DE,DI
		PAD  "POP DE"

;********************************

		OPW
		JC   XJNC
		JMP  SET_PC
XJNC:		PAD  "JP NC,w"

;********************************

		BADOP
		PAD  "DB #D3"

;********************************

		OPW
		JC   NC2
		JMP  CALL_DI
NC2:		PAD  "CALL NC,w"

;********************************

		MOV  DI,_DE
		CALL PUSHDI
		PAD  "PUSH DE"

;********************************

		OPB
		SUB _A,_N
		PAD  "SUB n"

;********************************

		MOV  DI,10H
		JMP  RST_DI
		PAD  "RST 10H"

;********************************

		JNC  RC
		JMP  RETURN
RC:		PAD  "RET C"

;********************************

		MOV  [BYTE IME],1		;EI
		JMP  RETURN
		PAD  "RETI"

;********************************

		OPW
		JNC  XJC
		JMP  SET_PC
XJC:		PAD  "JP C,w"

;********************************

		BADOP
		PAD  "DB #DB"

;********************************

		OPW
		JNC  NC1
		JMP  CALL_DI
NC1:		PAD  "CALL C,w"

;********************************

		BADOP
		PAD  "DB #DD"

;********************************

		OPB
		SBB _A,_N
		PAD  "SBC A,n"

;********************************

		MOV  DI,18H
		JMP  RST_DI
		PAD  "RST 18H"

;********************************

		OPB
		CALL LDZ_Z_A
		PAD  "LDZ (z),A"

;********************************

		CALL POPDI
		MOV  _HL,DI
		PAD  "POP HL"

;********************************
 
		CALL  LD_C_A
		PAD  "LD (C),A"

;********************************

		BADOP
		PAD  "DB #E3"

;********************************

		BADOP
		PAD  "DB #E4"

;********************************

		MOV  DI,_HL
		CALL PUSHDI
		PAD  "PUSH HL"

;********************************

		OPB
		AND _A,_N
		PAD  "AND n"

;********************************

		MOV  DI,20H
		JMP  RST_DI
		PAD  "RST 20H"

;********************************

		OPB
		CALL ADD_SP_N
		PAD  "ADD SP,n"

;********************************

		MOV  DI,_HL
		JMP  SET_PC
		PAD  "JP (HL)"

;********************************

		OPW

		MOV  _N,_A
		CALL TESTBANK

		MOV [_W],_A

		CALL PUTBACK
		PAD  "LD (w),A"

;********************************

		BADOP
		PAD  "DB #EB"

;********************************

		BADOP
		PAD  "DB #EC"

;********************************

		BADOP
		PAD  "DB #ED"

;********************************

		OPB
		XOR _A,_N
		PAD  "XOR n"

;********************************

		MOV  DI,28H
		JMP  RST_DI
		PAD  "RST 28H"

;********************************
		
		OPB
		CALL  LDZ_A_Z
		PAD  "LDZ A,(z)"

;********************************

		CALL POPDI		;POP DI
		MOV  AX,DI		;MAKE AX = DI
		CALL SET_FLAGS_AL
		PAD  "POP AF"

;********************************

		CALL  LD_A_C
		PAD  "LD A,(C)"

;********************************

		MOV  [BYTE IME],0
		PAD  "DI"

;********************************

		BADOP
		PAD  "DB #F4"

;********************************

		CALL GET_FLAGS_AL	;GET FLAGS IN AH
		MOV  DI,AX 		;SAVE AX AS AF
		CALL PUSHDI
		PAD  "PUSH AF"

;********************************

		OPB
		OR   _A,_N
		PAD  "OR n"

;********************************

		MOV  DI,30H
		JMP  RST_DI
		PAD  "RST 30H"

;********************************

		OPB
		CALL  LDHL_SP_N
		PAD  "LDHL SP,n"

;********************************

		MOV [CS:Z80_SP],_HL
		PAD  "LD SP,HL"

;********************************

		OPW
		PUSH _HL
		MOV  _HL,_W
		RHL
		MOV _A,[_HL]
		POP  _HL
		PAD  "LD A,(w)"

;********************************

		MOV  [BYTE IME],1
		PAD  "EI"

;********************************

		BADOP
		PAD  "DB #FC"

;********************************

		BADOP
		PAD  "DB #FD"

;********************************

		OPB
		CMP _A,_N
		PAD  "CP n"

;********************************

		MOV  DI,38H
		JMP  RST_DI
		PAD  "RST 38H"

;********************************

;AFTER CB STUFF

CB_TAB:		ROL _B,1
		MOV _N,_B

		CALL TESTZERO
		PAD  "RLC B"

;********************************

		ROL _C,1
		MOV _N,_C

		CALL TESTZERO
		PAD  "RLC C"

;********************************

		ROL _D,1
		MOV _N,_D

		CALL TESTZERO
		PAD  "RLC D"

;********************************

		ROL _E,1
		MOV _N,_E

		CALL TESTZERO
		PAD  "RLC E"

;********************************

		ROL _H,1
		MOV _N,_H

		CALL TESTZERO
		PAD  "RLC H"

;********************************

		ROL _L,1
		MOV _N,_L

		CALL TESTZERO
		PAD  "RLC L"

;********************************

		RHL
		ROL [BYTE _HL],1
		MOV _N,[_HL]
		CALL TESTZERO
		PAD  "RLC (HL)"

;********************************

		ROL _A,1
		MOV _N,_A
		CALL TESTZERO
		PAD  "RLC A"

;********************************

		ROR _B,1
		MOV _N,_B

		CALL TESTZERO
		PAD  "RRC B"

;********************************

		ROR _C,1
		MOV _N,_C

		CALL TESTZERO
		PAD  "RRC C"

;********************************

		ROR _D,1
		MOV _N,_D

		CALL TESTZERO
		PAD  "RRC D"

;********************************

		ROR _E,1
		MOV _N,_E

		CALL TESTZERO
		PAD  "RRC E"

;********************************

		ROR _H,1
		MOV _N,_H

		CALL TESTZERO
		PAD  "RRC H"

;********************************

		ROR _L,1
		MOV _N,_L

		CALL TESTZERO
		PAD  "RRC L"

;********************************

		RHL
		ROR [BYTE _HL],1
		MOV _N,[_HL]

		CALL TESTZERO
		PAD  "RRC (HL)"

;********************************

		ROR _A,1
		MOV _N,_A

		CALL TESTZERO
		PAD  "RRC A"

;********************************

		RCL _B,1
		MOV _N,_B

		CALL TESTZERO
		PAD  "RL B"

;********************************

		RCL _C,1
		MOV _N,_C

		CALL TESTZERO
		PAD  "RL C"

;********************************

		RCL _D,1
		MOV _N,_D

		CALL TESTZERO
		PAD  "RL D"

;********************************

		RCL _E,1
		MOV _N,_E

		CALL TESTZERO
		PAD  "RL E"

;********************************

		RCL _H,1
		MOV _N,_H

		CALL TESTZERO
		PAD  "RL H"

;********************************

		RCL _L,1
		MOV _N,_L

		CALL TESTZERO
		PAD  "RL L"

;********************************

		RHL
		RCL [BYTE _HL],1
		MOV _N,[_HL]

		CALL TESTZERO
		PAD  "RL (HL)"

;********************************

		RCL _A,1
		MOV _N,_A

		CALL TESTZERO
		PAD  "RL A"

;********************************

		RCR _B,1
		MOV _N,_B

		CALL TESTZERO
		PAD  "RR B"

;********************************

		RCR _C,1
		MOV _N,_C

		CALL TESTZERO
		PAD  "RR C"

;********************************

		RCR _D,1
		MOV _N,_D

		CALL TESTZERO
		PAD  "RR D"

;********************************

		RCR _E,1
		MOV _N,_E

		CALL TESTZERO
		PAD  "RR E"

;********************************

		RCR _H,1
		MOV _N,_H

		CALL TESTZERO
		PAD  "RR H"

;********************************

		RCR _L,1
		MOV _N,_L

		CALL TESTZERO
		PAD  "RR L"

;********************************

		RHL
		RCR [BYTE _HL],1
		MOV _N,[_HL]

		CALL TESTZERO
		PAD  "RR (HL)"

;********************************

		RCR _A,1
		MOV _N,_A

		CALL TESTZERO
		PAD  "RR A"

;********************************

		SHL _B,1
		MOV _N,_B

		CALL TESTZERO
		PAD  "SLA B"

;********************************

		SHL _C,1
		MOV _N,_C

		CALL TESTZERO
		PAD  "SLA C"

;********************************

		SHL _D,1
		MOV _N,_D

		CALL TESTZERO
		PAD  "SLA D"

;********************************

		SHL _E,1
		MOV _N,_E

		CALL TESTZERO
		PAD  "SLA E"

;********************************

		SHL _H,1
		MOV _N,_H

		CALL TESTZERO
		PAD  "SLA H"

;********************************

		SHL _L,1
		MOV _N,_L

		CALL TESTZERO
		PAD  "SLA L"

;********************************

		RHL
		SHL [BYTE _HL],1
		MOV _N,[_HL]

		CALL TESTZERO
		PAD  "SLA (HL)"

;********************************

		SHL _A,1
		MOV _N,_A

		CALL TESTZERO
		PAD  "SLA A"

;********************************

		SAR _B,1
		MOV _N,_B

		CALL TESTZERO
		PAD  "SRA B"

;********************************

		SAR _C,1
		MOV _N,_C

		CALL TESTZERO
		PAD  "SRA C"

;********************************

		SAR _D,1
		MOV _N,_D

		CALL TESTZERO
		PAD  "SRA D"

;********************************

		SAR _E,1
		MOV _N,_E

		CALL TESTZERO
		PAD  "SRA E"

;********************************

		SAR _H,1
		MOV _N,_H

		CALL TESTZERO
		PAD  "SRA H"

;********************************

		SAR _L,1
		MOV _N,_L

		CALL TESTZERO
		PAD  "SRA L"

;********************************

		RHL
		SAR [BYTE _HL],1
		MOV _N,[_HL]

		CALL TESTZERO
		PAD  "SRA (HL)"

;********************************

		SAR _A,1
		MOV _N,_A

		CALL TESTZERO
		PAD  "SRA A"

;********************************

		MOV _N,_B
		CALL SWAP
		MOV _B,_N
		PAD  "SWAP B"

;********************************

		MOV _N,_C
		CALL SWAP
		MOV _C,_N
		PAD  "SWAP C"

;********************************

		MOV _N,_D
		CALL SWAP
		MOV _D,_N
		PAD  "SWAP D"

;********************************

		MOV _N,_E
		CALL SWAP
		MOV _E,_N
		PAD  "SWAP E"

;********************************

		MOV _N,_H
		CALL SWAP
		MOV _H,_N
		PAD  "SWAP H"

;********************************

		MOV _N,_L
		CALL SWAP
		MOV _L,_N
		PAD  "SWAP L"

;********************************

		MOV _N,[_HL]
		CALL SWAP
		MOV [_HL],_N
		PAD  "SWAP (HL)"

;********************************

		MOV _N,_A
		CALL SWAP
		MOV _A,_N
		PAD  "SWAP A"

;********************************

		SHR _B,1
		MOV _N,_B

		CALL TESTZERO
		PAD  "SRL B"

;********************************

		SHR _C,1
		MOV _N,_C

		CALL TESTZERO
		PAD  "SRL C"

;********************************

		SHR _D,1
		MOV _N,_D

		CALL TESTZERO
		PAD  "SRL D"

;********************************

		SHR _E,1
		MOV _N,_E

		CALL TESTZERO
		PAD  "SRL E"

;********************************

		SHR _H,1
		MOV _N,_H

		CALL TESTZERO
		PAD  "SRL H"

;********************************

		SHR _L,1
		MOV _N,_L

		CALL TESTZERO
		PAD  "SRL L"

;********************************

		RHL
		SHR [BYTE _HL],1
		MOV _N,[_HL]

		CALL TESTZERO
		PAD  "SRL (HL)"

;********************************

		SHR _A,1
		MOV _N,_A

		CALL TESTZERO
		PAD  "SRL A"

;********************************

		MOV  _N,_B
		CALL TESTBIT_0
		PAD  "BIT 0,B"

;********************************

		MOV  _N,_C
		CALL TESTBIT_0
		PAD  "BIT 0,C"

;********************************

		MOV  _N,_D
		CALL TESTBIT_0
		PAD  "BIT 0,D"

;********************************

		MOV  _N,_E
		CALL TESTBIT_0
		PAD  "BIT 0,E"

;********************************

		MOV  _N,_H
		CALL TESTBIT_0
		PAD  "BIT 0,H"

;********************************

		MOV  _N,_L
		CALL TESTBIT_0
		PAD  "BIT 0,L"

;********************************

		RHL
		MOV  _N,[BYTE _HL]
		CALL TESTBIT_0
		PAD  "BIT 0,(HL)"

;********************************

		MOV  _N,_A
		CALL TESTBIT_0
		PAD  "BIT 0,A"

;********************************

		MOV  _N,_B
		CALL TESTBIT_1
		PAD  "BIT 1,B"

;********************************

		MOV  _N,_C
		CALL TESTBIT_1
		PAD  "BIT 1,C"

;********************************

		MOV  _N,_D
		CALL TESTBIT_1
		PAD  "BIT 1,D"

;********************************

		MOV  _N,_E
		CALL TESTBIT_1
		PAD  "BIT 1,E"

;********************************

		MOV  _N,_H
		CALL TESTBIT_1
		PAD  "BIT 1,H"

;********************************

		MOV  _N,_L
		CALL TESTBIT_1
		PAD  "BIT 1,L"

;********************************

		RHL
		MOV  _N,[BYTE _HL]
		CALL TESTBIT_1
		PAD  "BIT 1,(HL)"

;********************************

		MOV  _N,_A
		CALL TESTBIT_1
		PAD  "BIT 1,A"

;********************************

		MOV  _N,_B
		CALL TESTBIT_2
		PAD  "BIT 2,B"

;********************************

		MOV  _N,_C
		CALL TESTBIT_2
		PAD  "BIT 2,C"

;********************************

		MOV  _N,_D
		CALL TESTBIT_2
		PAD  "BIT 2,D"

;********************************

		MOV  _N,_E
		CALL TESTBIT_2
		PAD  "BIT 2,E"

;********************************

		MOV  _N,_H
		CALL TESTBIT_2
		PAD  "BIT 2,H"

;********************************

		MOV  _N,_L
		CALL TESTBIT_2
		PAD  "BIT 2,L"

;********************************

		RHL
		MOV  _N,[BYTE _HL]
		CALL TESTBIT_2
		PAD  "BIT 2,(HL)"

;********************************

		MOV  _N,_A
		CALL TESTBIT_2
		PAD  "BIT 2,A"

;********************************

		MOV  _N,_B
		CALL TESTBIT_3
		PAD  "BIT 3,B"

;********************************

		MOV  _N,_C
		CALL TESTBIT_3
		PAD  "BIT 3,C"

;********************************

		MOV  _N,_D
		CALL TESTBIT_3
		PAD  "BIT 3,D"

;********************************

		MOV  _N,_E
		CALL TESTBIT_3
		PAD  "BIT 3,E"

;********************************

		MOV  _N,_H
		CALL TESTBIT_3
		PAD  "BIT 3,H"

;********************************

		MOV  _N,_L
		CALL TESTBIT_3
		PAD  "BIT 3,L"

;********************************

		RHL
		MOV  _N,[BYTE _HL]
		CALL TESTBIT_3
		PAD  "BIT 3,(HL)"

;********************************

		MOV  _N,_A
		CALL TESTBIT_3
		PAD  "BIT 3,A"

;********************************

		MOV  _N,_B
		CALL TESTBIT_4
		PAD  "BIT 4,B"

;********************************

		MOV  _N,_C
		CALL TESTBIT_4
		PAD  "BIT 4,C"

;********************************

		MOV  _N,_D
		CALL TESTBIT_4
		PAD  "BIT 4,D"

;********************************

		MOV  _N,_E
		CALL TESTBIT_4
		PAD  "BIT 4,E"

;********************************

		MOV  _N,_H
		CALL TESTBIT_4
		PAD  "BIT 4,H"

;********************************

		MOV  _N,_L
		CALL TESTBIT_4
		PAD  "BIT 4,L"

;********************************

		RHL
		MOV  _N,[BYTE _HL]
		CALL TESTBIT_4
		PAD  "BIT 4,(HL)"

;********************************

		MOV  _N,_A
		CALL TESTBIT_4
		PAD  "BIT 4,A"

;********************************

		MOV  _N,_B
		CALL TESTBIT_5
		PAD  "BIT 5,B"

;********************************

		MOV  _N,_C
		CALL TESTBIT_5
		PAD  "BIT 5,C"

;********************************

		MOV  _N,_D
		CALL TESTBIT_5
		PAD  "BIT 5,D"

;********************************

		MOV  _N,_E
		CALL TESTBIT_5
		PAD  "BIT 5,E"

;********************************

		MOV  _N,_H
		CALL TESTBIT_5
		PAD  "BIT 5,H"

;********************************

		MOV  _N,_L
		CALL TESTBIT_5
		PAD  "BIT 5,L"

;********************************

		RHL
		MOV  _N,[BYTE _HL]
		CALL TESTBIT_5
		PAD  "BIT 5,(HL)"

;********************************

		MOV  _N,_A
		CALL TESTBIT_5
		PAD  "BIT 5,A"

;********************************

		MOV  _N,_B
		CALL TESTBIT_6
		PAD  "BIT 6,B"

;********************************

		MOV  _N,_C
		CALL TESTBIT_6
		PAD  "BIT 6,C"

;********************************

		MOV  _N,_D
		CALL TESTBIT_6
		PAD  "BIT 6,D"

;********************************

		MOV  _N,_E
		CALL TESTBIT_6
		PAD  "BIT 6,E"

;********************************

		MOV  _N,_H
		CALL TESTBIT_6
		PAD  "BIT 6,H"

;********************************

		MOV  _N,_L
		CALL TESTBIT_6
		PAD  "BIT 6,L"

;********************************

		RHL
		MOV  _N,[BYTE _HL]
		CALL TESTBIT_6
		PAD  "BIT 6,(HL)"

;********************************

		MOV  _N,_A
		CALL TESTBIT_6
		PAD  "BIT 6,A"

;********************************

		MOV  _N,_B
		CALL TESTBIT_7
		PAD  "BIT 7,B"

;********************************

		MOV  _N,_C
		CALL TESTBIT_7
		PAD  "BIT 7,C"

;********************************

		MOV  _N,_D
		CALL TESTBIT_7
		PAD  "BIT 7,D"

;********************************

		MOV  _N,_E
		CALL TESTBIT_7
		PAD  "BIT 7,E"

;********************************

		MOV  _N,_H
		CALL TESTBIT_7
		PAD  "BIT 7,H"

;********************************

		MOV  _N,_L
		CALL TESTBIT_7
		PAD  "BIT 7,L"

;********************************

		RHL
		MOV  _N,[BYTE _HL]
		CALL TESTBIT_7
		PAD  "BIT 7,(HL)"

;********************************

		MOV  _N,_A
		CALL TESTBIT_7
		PAD  "BIT 7,A"

;********************************

		PUSHF
		AND _B,11111110B
		POPF
		PAD  "RES 0,B"

;********************************

		PUSHF
		AND _C,11111110B
		POPF
		PAD  "RES 0,C"

;********************************

		PUSHF
		AND _D,11111110B
		POPF
		PAD  "RES 0,D"

;********************************

		PUSHF
		AND _E,11111110B
		POPF
		PAD  "RES 0,E"

;********************************

		PUSHF
		AND _H,11111110B
		POPF
		PAD  "RES 0,H"

;********************************

		PUSHF
		AND _L,11111110B
		POPF
		PAD  "RES 0,L"

;********************************

		PUSHF
		AND [BYTE _HL],11111110B
		POPF
		PAD  "RES 0,(HL)"

;********************************

		PUSHF
		AND _A,11111110B
		POPF
		PAD  "RES 0,A"

;********************************

		PUSHF
		AND _B,11111101B
		POPF
		PAD  "RES 1,B"

;********************************

		PUSHF
		AND _C,11111101B
		POPF
		PAD  "RES 1,C"

;********************************

		PUSHF
		AND _D,11111101B
		POPF
		PAD  "RES 1,D"

;********************************

		PUSHF
		AND _E,11111101B
		POPF
		PAD  "RES 1,E"

;********************************

		PUSHF
		AND _H,11111101B
		POPF
		PAD  "RES 1,H"

;********************************

		PUSHF
		AND _L,11111101B
		POPF
		PAD  "RES 1,L"

;********************************

		PUSHF
		AND [BYTE _HL],11111101B
		POPF
		PAD  "RES 1,(HL)"

;********************************

		PUSHF
		AND _A,11111101B
		POPF
		PAD  "RES 1,A"

;********************************

		PUSHF
		AND _B,11111011B
		POPF
		PAD  "RES 2,B"

;********************************

		PUSHF
		AND _C,11111011B
		POPF
		PAD  "RES 2,C"

;********************************

		PUSHF
		AND _D,11111011B
		POPF
		PAD  "RES 2,D"

;********************************

		PUSHF
		AND _E,11111011B
		POPF
		PAD  "RES 2,E"

;********************************

		PUSHF
		AND _H,11111011B
		POPF
		PAD  "RES 2,H"

;********************************

		PUSHF
		AND _L,11111011B
		POPF
		PAD  "RES 2,L"

;********************************

		PUSHF
		AND [BYTE _HL],11111011B
		POPF
		PAD  "RES 2,(HL)"

;********************************

		PUSHF
		AND _A,11111011B
		POPF
		PAD  "RES 2,A"

;********************************

		PUSHF
		AND _B,11110111B
		POPF
		PAD  "RES 3,B"

;********************************

		PUSHF
		AND _C,11110111B
		POPF
		PAD  "RES 3,C"

;********************************

		PUSHF
		AND _D,11110111B
		POPF
		PAD  "RES 3,D"

;********************************

		PUSHF
		AND _E,11110111B
		POPF
		PAD  "RES 3,E"

;********************************

		PUSHF
		AND _H,11110111B
		POPF
		PAD  "RES 3,H"

;********************************

		PUSHF
		AND _L,11110111B
		POPF
		PAD  "RES 3,L"

;********************************

		PUSHF
		AND [BYTE _HL],11110111B
		POPF
		PAD  "RES 3,(HL)"

;********************************

		PUSHF
		AND _A,11110111B
		POPF
		PAD  "RES 3,A"

;********************************

		PUSHF
		AND _B,11101111B
		POPF
		PAD  "RES 4,B"

;********************************

		PUSHF
		AND _C,11101111B
		POPF
		PAD  "RES 4,C"

;********************************

		PUSHF
		AND _D,11101111B
		POPF
		PAD  "RES 4,D"

;********************************

		PUSHF
		AND _E,11101111B
		POPF
		PAD  "RES 4,E"

;********************************

		PUSHF
		AND _H,11101111B
		POPF
		PAD  "RES 4,H"

;********************************

		PUSHF
		AND _L,11101111B
		POPF
		PAD  "RES 4,L"

;********************************

		PUSHF
		AND [BYTE _HL],11101111B
		POPF
		PAD  "RES 4,(HL)"

;********************************

		PUSHF
		AND _A,11101111B
		POPF
		PAD  "RES 4,A"

;********************************

		PUSHF
		AND _B,11011111B
		POPF
		PAD  "RES 5,B"

;********************************

		PUSHF
		AND _C,11011111B
		POPF
		PAD  "RES 5,C"

;********************************

		PUSHF
		AND _D,11011111B
		POPF
		PAD  "RES 5,D"

;********************************

		PUSHF
		AND _E,11011111B
		POPF
		PAD  "RES 5,E"

;********************************

		PUSHF
		AND _H,11011111B
		POPF
		PAD  "RES 5,H"

;********************************

		PUSHF
		AND _L,11011111B
		POPF
		PAD  "RES 5,L"

;********************************

		PUSHF
		AND [BYTE _HL],11011111B
		POPF
		PAD  "RES 5,(HL)"

;********************************

		PUSHF
		AND _A,11011111B
		POPF
		PAD  "RES 5,A"

;********************************

		PUSHF
		AND _B,10111111B
		POPF
		PAD  "RES 6,B"

;********************************

		PUSHF
		AND _C,10111111B
		POPF
		PAD  "RES 6,C"

;********************************

		PUSHF
		AND _D,10111111B
		POPF
		PAD  "RES 6,D"

;********************************

		PUSHF
		AND _E,10111111B
		POPF
		PAD  "RES 6,E"

;********************************

		PUSHF
		AND _H,10111111B
		POPF
		PAD  "RES 6,H"

;********************************

		PUSHF
		AND _L,10111111B
		POPF
		PAD  "RES 6,L"

;********************************

		PUSHF
		AND [BYTE _HL],10111111B
		POPF
		PAD  "RES 6,(HL)"

;********************************

		PUSHF
		AND _A,10111111B
		POPF
		PAD  "RES 6,A"

;********************************

		PUSHF
		AND _B,01111111B
		POPF
		PAD  "RES 7,B"

;********************************

		PUSHF
		AND _C,01111111B
		POPF
		PAD  "RES 7,C"

;********************************

		PUSHF
		AND _D,01111111B
		POPF
		PAD  "RES 7,D"

;********************************

		PUSHF
		AND _E,01111111B
		POPF
		PAD  "RES 7,E"

;********************************

		PUSHF
		AND _H,01111111B
		POPF
		PAD  "RES 7,H"

;********************************

		PUSHF
		AND _L,01111111B
		POPF
		PAD  "RES 7,L"

;********************************

		PUSHF
		AND [BYTE _HL],01111111B
		POPF
		PAD  "RES 7,(HL)"

;********************************

		PUSHF
		AND _A,01111111B
		POPF
		PAD  "RES 7,A"

;********************************

		PUSHF
		OR _B,1
		POPF
		PAD  "SET 0,B"

;********************************

		PUSHF
		OR _C,1
		POPF
		PAD  "SET 0,C"

;********************************

		PUSHF		
		OR _D,1
		POPF
		PAD  "SET 0,D"

;********************************

		PUSHF
		OR _E,1
		POPF
		PAD  "SET 0,E"

;********************************

		PUSHF
		OR _H,1
		POPF
		PAD  "SET 0,H"

;********************************

		PUSHF
		OR _L,1
		POPF
		PAD  "SET 0,L"

;********************************

		PUSHF
		OR [BYTE _HL],1
		POPF
		PAD  "SET 0,(HL)"

;********************************

		PUSHF
		OR _A,1
		POPF
		PAD  "SET 0,A"

;********************************

		PUSHF
		OR _B,2
		POPF
		PAD  "SET 1,B"

;********************************

		PUSHF
		OR _C,2
		POPF
		PAD  "SET 1,C"

;********************************

		PUSHF
		OR _D,2
		POPF
		PAD  "SET 1,D"

;********************************

		PUSHF
		OR _E,2
		POPF
		PAD  "SET 1,E"

;********************************

		PUSHF
		OR _H,2
		POPF
		PAD  "SET 1,H"

;********************************

		PUSHF
		OR _L,2
		POPF
		PAD  "SET 1,L"

;********************************

		PUSHF
		OR [BYTE _HL],2
		POPF
		PAD  "SET 1,(HL)"

;********************************

		PUSHF
		OR _A,2
		POPF
		PAD  "SET 1,A"

;********************************

		PUSHF
		OR _B,4
		POPF
		PAD  "SET 2,B"

;********************************

		PUSHF
		OR _C,4
		POPF
		PAD  "SET 2,C"

;********************************

		PUSHF
		OR _D,4
		POPF
		PAD  "SET 2,D"

;********************************

		PUSHF
		OR _E,4
		POPF
		PAD  "SET 2,E"

;********************************

		PUSHF
		OR _H,4
		POPF
		PAD  "SET 2,H"

;********************************

		PUSHF
		OR _L,4
		POPF
		PAD  "SET 2,L"

;********************************

		PUSHF
		OR [BYTE _HL],4
		POPF
		PAD  "SET 2,(HL)"

;********************************

		PUSHF
		OR _A,4
		POPF
		PAD  "SET 2,A"

;********************************

		PUSHF
		OR _B,8
		POPF
		PAD  "SET 3,B"

;********************************

		PUSHF
		OR _C,8
		POPF
		PAD  "SET 3,C"

;********************************

		PUSHF
		OR _D,8
		POPF
		PAD  "SET 3,D"

;********************************

		PUSHF
		OR _E,8
		POPF
		PAD  "SET 3,E"

;********************************

		PUSHF
		OR _H,8
		POPF
		PAD  "SET 3,H"

;********************************

		PUSHF
		OR _L,8
		POPF
		PAD  "SET 3,L"

;********************************

		PUSHF
		OR [BYTE _HL],8
		POPF
		PAD  "SET 3,(HL)"

;********************************

		PUSHF
		OR _A,8
		POPF
		PAD  "SET 3,A"

;********************************

		PUSHF
		OR _B,16
		POPF
		PAD  "SET 4,B"

;********************************

		PUSHF
		OR _C,16
		POPF
		PAD  "SET 4,C"

;********************************

		PUSHF
		OR _D,16
		POPF
		PAD  "SET 4,D"

;********************************

		PUSHF
		OR _E,16
		POPF
		PAD  "SET 4,E"

;********************************

		PUSHF
		OR _H,16
		POPF
		PAD  "SET 4,H"

;********************************

		PUSHF
		OR _L,16
		POPF
		PAD  "SET 4,L"

;********************************

		PUSHF
		OR [BYTE _HL],16
		POPF
		PAD  "SET 4,(HL)"

;********************************

		PUSHF
		OR _A,16
		POPF
		PAD  "SET 4,A"

;********************************

		PUSHF
		OR _B,32
		POPF
		PAD  "SET 5,B"

;********************************

		PUSHF
		OR _C,32
		POPF
		PAD  "SET 5,C"

;********************************

		PUSHF
		OR _D,32
		POPF
		PAD  "SET 5,D"

;********************************

		PUSHF
		OR _E,32
		POPF
		PAD  "SET 5,E"

;********************************

		PUSHF
		OR _H,32
		POPF
		PAD  "SET 5,H"

;********************************

		PUSHF
		OR _L,32
		POPF
		PAD  "SET 5,L"

;********************************

		PUSHF
		OR [BYTE _HL],32
		POPF
		PAD  "SET 5,(HL)"

;********************************

		PUSHF
		OR _A,32
		POPF
		PAD  "SET 5,A"

;********************************

		PUSHF
		OR _B,64
		POPF
		PAD  "SET 6,B"

;********************************

		PUSHF
		OR _C,64
		POPF
		PAD  "SET 6,C"

;********************************

		PUSHF
		OR _D,64
		POPF
		PAD  "SET 6,D"

;********************************

		PUSHF
		OR _E,64
		POPF
		PAD  "SET 6,E"

;********************************

		PUSHF
		OR _H,64
		POPF
		PAD  "SET 6,H"

;********************************

		PUSHF
		OR _L,64
		POPF
		PAD  "SET 6,L"

;********************************

		PUSHF
		OR [BYTE _HL],64
		POPF
		PAD  "SET 6,(HL)"

;********************************

		PUSHF
		OR _A,64
		POPF
		PAD  "SET 6,A"

;********************************

		PUSHF
		OR _B,128
		POPF
		PAD  "SET 7,B"

;********************************

		PUSHF
		OR _C,128
		POPF
		PAD  "SET 7,C"

;********************************

		PUSHF
		OR _D,128
		POPF
		PAD  "SET 7,D"

;********************************

		PUSHF
		OR _E,128
		POPF
		PAD  "SET 7,E"

;********************************

		PUSHF
		OR _H,128
		POPF
		PAD  "SET 7,H"

;********************************

		PUSHF
		OR _L,128
		POPF
		PAD  "SET 7,L"

;********************************

		PUSHF
		OR [BYTE _HL],128
		POPF
		PAD  "SET 7,(HL)"

;********************************

		PUSHF
		OR _A,128
		POPF
		PAD  "SET 7,A"

;********************************

		EVEN

EMTAB		= 8000H

TABLES:
		REPT	512
		DW	EMTAB
EMTAB		= EMTAB + 32
		ENDM

		ENDS
		END	START
