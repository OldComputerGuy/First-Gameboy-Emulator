;*****************************************************************************
;			 Extended memory handlers for gameboy debugger
;*****************************************************************************

emm_handle	dw	0				;EMM handle
emm_Page	dw	-1				;Current Page
emm_Seg		dw	0				;Current Emm Page frame

EMM_device	DB 'EMMXXXX0' ; ASCII EMM device name string			
DeviceLen	EQU 8

;********************************
;		 Test for ems
;********************************

Test_EMS:	
			MOV   AH,35h                  ; AH = DOS get interrupt vector
			                        	    ; function
			MOV   AL,67h                  ; AL = EMM interrupt vector number
			INT   21h
			MOV   DI,0Ah                  ; ES:DI points to where device     
			                            ; name should be
			mov   SI,offset EMM_device      ; DS:SI points to ASCII string     
			mov	  ax,cs
			mov	  ds,ax
			                            ; containing EMM device name
			
			MOV   CX,DeviceLen   ; set up loop counter for string op
			CLD                           ; set up direction flag for forward
			REPE  CMPSB                   ; Compare the strings
	
	
			JZ   RET_ok

			CALL	PRINT
			DB		"Error, NO EMS !",13,10,0
			JMP		DOS_RET

RET_ok:		ret

;********************************
;  Make sure theres enough EMS
;********************************

Enough_EMS:
			ret
			
			MOV   AH,41h                  ;    AH = EMM get unallocated page
			                            ;    count function code
			INT   67h

			cmp		ah,64				  ;64 emu pages
			jnc		RET_ok

			CALL	PRINT
			DB		"Error, Not enough EMS !",13,10,0
			JMP		DOS_RET

;********************************
;		 Allocate EMS
;********************************

Alloc_EMS:
					
			MOV   AH,43h                  ;    AH = EMM allocate pages
			MOV   BX,256                   ;    BX = number of pages needed
			INT   67h
			OR    AH,AH                   ; Check EMM status
			JNZ   @@error       		  ; IF error THEN goto error handler
			                              ; ELSE
			MOV   [cs:emm_handle],DX           ;    save EMM handle

			call	Get_Pageframe
			ret			

@@error:
			CALL	PRINT
			DB		"Error, Could'nt alloc EMS !",13,10,0
			JMP		DOS_RET


;********************************
;
;********************************

Get_Pageframe:

			
			MOV   AH,41h                  ; AH = EMM get page frame base
			                            ; address function
			INT   67h
			OR    AH,AH                   ; Check EMM status
			JNZ   @@error       		; IF error THEN goto error handler

			MOV   	[cs:emm_Seg],BX              ; ELSE save pf_addr
			sub		bx,400h
			mov	 	[cs:z80_bank],bx
			
			ret

@@error:
			CALL	PRINT
			DB		"Error, Could'nt alloc EMS !",13,10,0
			JMP		DOS_RET

;********************************
;		 Bank in EMS
;		  AL = PAGE
;********************************

BankEmm:
			cmp		al,[byte cs:emm_Page]
			jz		@@same

			mov		[byte cs:emm_Page],al	;save this page num

			push	dx
			push	bx
			
			MOV   AH,44h                  ; AH = EMM map pages function
			MOV   DX,[cs:emm_handle]      ; DX = application's handle
				
			mov	  bl,al					  ; the ems page number
			mov	  bh,0					  ; bx is logical page

			MOV   AL,0                    ; AL = physical page 0 (page frame offset)
			INT   67h

			pop		bx
			pop		dx

			OR    AH,AH                   ; Check EMM status
			JNZ   @@error       ; If error THEN goto error handler

@@same:
			ret

@@error:
			CALL	PRINT
			DB		"Error, Could'nt bank EMS !",13,10,0
			JMP		DOS_RET

;********************************
;
;********************************
			
dealloc_EMS:

			cmp	  [word cs:emm_handle],0
			jz	  @@noems
			
			MOV   AH,45h                  ; AH = EMM deallocate pages        
			                            ; function
			MOV   DX,[cs:emm_handle]
			INT   67h                     ; return handle's pages to EMM
;			OR    AH,AH                   ; Check EMM status
;			JNZ   @@error       		  ; IF error THEN goto error handler

@@noems:
			ret

;********************************

write_to_expanded_memory:     ; Write zeros to memory mapped at
			                            ; physical page 0
			MOV   AX,[cs:emm_seg]
			MOV   ES,AX                   ; ES points to physical page 0
			MOV   DI,0                    ; DI indexes into physical page 0
			MOV   AL,0                    ; Initialize AL for string STOSB
			MOV   CX,4000h                ; Initialize loop counter to length 
			                            ; of expanded memory page size
			CLD                           ; set up direction flag for forward
			REP   STOSB
			ret
			
