; Шаблон текста программы для модуля типа .COM
TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN
; ДАННЫЕ
_TYPE db 'OS TYPE: $'
_PC db 'PC',0DH,0AH,'$'
_PCXT db 'PC/XT',0DH,0AH,'$'
_AT db 'AT',0DH,0AH,'$'
_PS2_30 db 'PS2 model 30',0DH,0AH,'$'
;_PS2_50_60 db 'PS2 модель 50/60',0DH,0AH,'$'
_PS2_80 db 'PS2 model 80',0DH,0AH,'$'
_PCJR db 'PCjr',0DH,0AH,'$'
_PC_CONV db 'PC Convertible',0DH,0AH,'$'
_VER db 'OS version:   .  ',0DH,0AH,'$'
_OEM db 'OEM:    ',0DH,0AH,'$' ; additional 3 bytes for digits
_USSERN db 'User serial number: ','$'
_HEX db '    $'
_ENDL db 0DH,0AH,'$'
; ПРОЦЕДУРЫ
;---------------------------------------
PRINT PROC near
	mov AH,09h
	int 21h
	ret
PRINT ENDP

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP
;---------------------------------------
; перевод в 16с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
	push BX
	mov BH,AH
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
;---------------------------------------
; перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
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
	ret
BYTE_TO_DEC ENDP

;вывод типа системы
_TYPE_OS PROC near
	mov ax,0F000h
	mov es,ax
	mov ax,es:0FFFEh
	
	mov dx, offset _TYPE 
	call PRINT
	
	cmp ah,0FEh
	je P_PC
	
	cmp ah, 0FDh
	je P_PCJR
	
	cmp ah, 0FCh
	je P_AT
	
	cmp ah, 0FBh
	je P_PCXT
	
	cmp ah, 0FAh
	je P_30
	
	cmp ah, 0F9h
	je P_CONV
	
	cmp ah, 0F8h
	je P_80
	
	P_PC:
		mov dx, offset _PC
		jmp _PRINT
	P_PCJR:
		mov dx, offset _PCJR
		jmp _PRINT
	P_AT:
		mov dx, offset _AT
		jmp _PRINT
	P_PCXT:
		mov dx, offset _PCXT
		jmp _PRINT
	P_30:
		mov dx, offset _PS2_30
		jmp _PRINT
	P_CONV:
		mov dx, offset _PC_CONV
		jmp _PRINT
	P_80:
		mov dx, offset _PS2_80
		jmp _PRINT
	
	
	_PRINT:
		call PRINT
		ret
	
_TYPE_OS ENDP

;вывод версии MS DOS
_W_OS PROC near
	mov si,offset _VER
	add si,13
	push ax
	call BYTE_TO_DEC 
	pop ax
	mov al,ah
	add si,3
	cmp al,10
	jl _TR
	inc si
	_TR:
	call BYTE_TO_DEC 
	mov dx,offset _VER 
	call PRINT
	ret
_W_OS ENDP

;Вывод серийного номера ОЕМ
_W_OEM PROC near 
	mov si,offset _OEM
	add si,7
	mov al,bh
	call BYTE_TO_DEC
	
	mov dx,offset _OEM
	call PRINT
	ret
_W_OEM ENDP

;Вывод серийного номера пользователя
_W_SERN PROC near
	mov dx,offset _USSERN
	call PRINT
	
	mov  al,bl
	call BYTE_TO_HEX
	mov bx,ax
	mov dl,bl
	mov ah,02h
	int 21h
	mov dl,bh
	int 21h
	
	mov di,offset _HEX
	add di,3
	mov ax,cx
	call WRD_TO_HEX
	mov dx,offset _HEX
	call PRINT
	mov dx,offset _ENDL
	call PRINT
	
	ret
_W_SERN ENDP

;---------------------------------------
BEGIN:
	call _TYPE_OS
	
	xor ax,ax
	mov ah,30h
	int 21h
	
	call _W_OS
	call _W_OEM
	call _W_SERN
	
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
	END START