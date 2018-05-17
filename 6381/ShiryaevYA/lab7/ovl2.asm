OVL2 segment
	ASSUME CS:OVL2, DS:nothing, SS:nothing, ES:nothing

MAIN 	PROC 	FAR
	push 	AX
	push 	BX
	push 	DS
	push 	DI
	push 	DX
	
	mov 	DS, AX
	mov 	DX, OFFSET OVL_MESSAGE	
	call 	WRITE_LINE	
	
	mov 	BX, OFFSET SEG_ADRESS
	add 	BX, 20			
	mov 	DI, BX		
	mov 	AX, CS			
	call 	WRD_TO_HEX
	
	mov 	DX, OFFSET SEG_ADRESS	
	call 	WRITE_LINE	
	
	mov 	DX, OFFSET END_LINE	
	call 	WRITE_LINE	
	
	pop 	DX
	pop 	DI
	pop 	DS
	pop 	BX
	pop 	AX
	retf
MAIN 	ENDP

; функция вывода сообщения на экран
WRITE_LINE	PROC
	push	AX
	mov		AH,09H
	int		21H
	pop		AX
	ret
WRITE_LINE	ENDP

TETR_TO_HEX PROC near
	and 	AL, 0Fh 
	cmp 	AL, 09 
	jbe 	NEXT 
	add 	AL, 07 
NEXT: 
	add 	AL,30h 
	ret 
TETR_TO_HEX ENDP 
;-------------------------------------------------------------------------
BYTE_TO_HEX PROC near 
	push 	CX 
	mov 	AH,AL 
	call 	TETR_TO_HEX 
	xchg 	AL,AH 
	mov 	CL,4 
	shr 	AL,CL 
	call 	TETR_TO_HEX 
	pop 	CX 
	ret 
BYTE_TO_HEX ENDP 
;-------------------------------------------------------------------------
;перевод в 16с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near 
	push 	BX 
	mov 	BH,AH 
	call 	BYTE_TO_HEX 
	mov 	[DI],AH 
	dec 	DI 
	mov 	[DI],AL 
	dec 	DI 
	mov 	AL,BH 
	call 	BYTE_TO_HEX 
	mov 	[DI],AH 
	dec 	DI 
	mov 	[DI],AL 
	pop 	BX 
	ret 
WRD_TO_HEX ENDP 

OVL_MESSAGE 	db 	0dh, 0ah, 'Second overlay.', 0dh, 0ah, '$'
SEG_ADRESS 		db 	'Segment adress:     ', 0dh, 0ah, '$'
END_LINE		db	0DH,0AH,'$'	

OVL2 ENDS
END MAIN