
Z80_SEG		DW	0		;MEMORY SEGMENTS

;********************************
;    READ IN GAMEBOY PROGRAM
;********************************

ROM_NAME	DB	"ROM.GB",0,0,0,0

BANKS		DW	0

READ_PRG:
		MOV	DS,[CS:CODERAM]

		MOV	AH,03DH			;READ ONLY FILE INPUT
		MOV	AL,0			;SET READ MODE ONLY
		MOV	DX,OFFSET ROM_NAME
		INT	021H

	   	JNC	@@ROMOK

		CALL	PRINT
		DB	"No rom file loaded !",13,10,13,10,0
		RET

@@ROMOK:

		MOV		[CS:INP_FILE_HAND],AX
		MOV		[CS:BANKS],0

		MOV		BX,1000H
		CALL	GETMEM
		MOV		[CS:Z80_SEG],AX

		MOV		DX,0
		MOV		DS,[CS:Z80_SEG]
		MOV		CX,4000H
		CALL	READ_BYTES
		
		CMP		AX,4000H
		JNZ		@@EXIT

		INC		[CS:BANKS]

		MOV		CX,63				;BANK COUNT

@@LOOP:
		PUSH	CX

		mov		ax,[cs:BANKS]
		call	BankEmm

		mov		ds,[cs:emm_seg]

		MOV		DX,0
		MOV		CX,4000H

		CALL	READ_BYTES

		POP	CX

		CMP		AX,4000H
		JNZ		@@EXIT

		INC		[CS:BANKS]

		LOOP	@@LOOP

@@EXIT:
		CALL	FILE_IN_CLOSE		;CLOSE FILE
		RET

;***************************
;BX = mem
;ret: al = byte
;***************************

GET_MEMORY_AL:

		PUSH	DS
 		MOV		DS,[CS:Z80_SEG]
 		
 		CMP		BX,04000H
 		JC		@@NOBANK

		CMP		BX,08000H
		JNC		@@NOBANK

 		MOV		DS,[CS:Z80_BANK]

		
@@NOBANK:
		MOV		AL,[BYTE DS:BX]
		POP		DS

		RET

PUT_MEMORY_AL:

		PUSH	DS
 		MOV		DS,[CS:Z80_SEG]
 		
 		CMP		BX,04000H
 		JC		@@NOBANK

		CMP		BX,08000H
		JNC		@@NOBANK

 		MOV		DS,[CS:Z80_BANK]

@@NOBANK:
		MOV		[BYTE DS:BX],AL
		POP		DS

		RET
