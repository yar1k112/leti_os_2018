CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
	 ORG 100H
START: JMP BEGIN

; данные
DOS_V	db	'DOS VER: '
DOS_F	db	' .'
END_DOS_V DB ' ', 0AH, 0DH,'$'
OEM	db	'OEM:  '
ENDOEM DB ' ', 0AH, 0DH,'$'
USERN	db	'USER NUMBER:      '
USERNEND DB ' ', 0AH, 0DH,'$'

; процедуры
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
	NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;в AL старшая цифра
	pop CX ;в AH младшая
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near ;перевод в 16 с/с 16-ти разрядного числа
	push BX          ; в AX - число, DI - адрес последнего символа
	mov BH,AH        ;  now it aclually converts byte to string, last sybmol adress is di
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near ; перевод байта в 10с/с, SI - адрес поля младшей цифры
	push	AX        ; AL содержит исходный байт
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
	loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
	end_l: pop DX
	pop CX
	pop	AX
	ret
BYTE_TO_DEC ENDP


GET_PC_CODE PROC NEAR ; код типа пк - в регистре al
	push	BX
	push	ES
	mov	BX,0F000H
	mov	ES,BX
	mov	AL,ES:[0FFFEH]
	pop	ES
	pop	BX
	ret
GET_PC_CODE	ENDP

PRINT_PC_TYPE PROC NEAR
	jmp print_pc_type_begin
		TYPE_PC db 'PC type: PC', 0AH, 0DH,'$'
		TYPE_PC_XT db 'PC type: PC/XT', 0AH, 0DH,'$'
		TYPE_AT db 'PC type: AT', 0AH, 0DH,'$'
		TYPE_PS2_M30 db 'PC type: model 30', 0AH, 0DH,'$'
		TYPE_PS2_M50 db 'PC type: model 50 or 60', 0AH, 0DH,'$'
		TYPE_PS2_M80 db 'PC type: model 80', 0AH, 0DH,'$'
		TYPE_PSjr db 'PC type: PCjr', 0AH, 0DH,'$'
		TYPE_PC_CONV db 'PC type: PC Convertible', 0AH, 0DH,'$'
		TYPE_UNKNOWN db 'PC type code: '
		TYPE_CODE db '  ', 0AH, 0DH, '$'
	print_pc_type_begin:
		push ax
		push dx
		push di
		
		n0: cmp al, 0FFh
		jne n1
		mov dx, offset TYPE_PC;
		jmp print
		
		n1: cmp al, 0FEh
		jne n2
		mov dx, offset TYPE_PC_XT;
		jmp print
		
		n2: cmp al, 0FBh
		jne n3
		mov dx, offset TYPE_PC_XT;
		jmp print
		
		n3: cmp al, 0FCh
		jne n4
		mov dx, offset TYPE_AT;
		jmp print
		
		n4: cmp al, 0FAh
		jne n5
		mov dx, offset TYPE_PS2_M30;
		jmp print
		
		n5: cmp al, 0FCh
		jne n6
		mov dx, offset TYPE_PS2_M50;
		jmp print
		
		n6: cmp al, 0F8h
		jne n7
		mov dx, offset TYPE_PS2_M80;
		jmp print
		
		n7: cmp al, 0FDh
		jne n8
		mov dx, offset TYPE_PSjr
		jmp print
		
		n8: cmp al, 0F9h
		jne n9
		mov dx, offset TYPE_PC_CONV
		jmp print
		
		n9: 
		call BYTE_TO_HEX
		mov di, OFFSET TYPE_CODE
		mov [di], ax
		mov dx, offset TYPE_UNKNOWN;
		
		print:
		mov  ah,9                          
		int  21h
		pop di
		pop dx
		pop ax
	ret
PRINT_PC_TYPE ENDP

BEGIN:
	push DS 
	sub AX,AX 
	push AX 

	; pc type
	call GET_PC_CODE
	call PRINT_PC_TYPE
	
	
	mov	AH,30H
	INT	21H
	
	; DOS TYPE
	push ax
	mov si, offset DOS_F
	call BYTE_TO_DEC
	pop ax
	mov al,ah
	mov si, offset END_DOS_V
	call BYTE_TO_DEC
	mov dx, offset  DOS_V;
	mov  ah,9                          
	int  21h

	; oem
	mov al,bh
	call BYTE_TO_HEX
	mov di, offset ENDOEM
	mov [di-1], ax
	mov dx, offset OEM;
	mov  ah,9                          
	int  21h

	; user number
	mov ax,cx
	mov di, offset USERNEND
	call WRD_TO_HEX
	mov al,bl
	call BYTE_TO_HEX
	mov [di-2], ax

	mov dx, offset USERN
	mov  ah,9                          
	int  21h

	; end of program
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
END START