TESTPC	   SEGMENT
	   ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	   ORG	   100H
START:	   JMP	   BEGIN

; ДАННЫЕ:
; дополнительные данные
EOF	EQU '$'	; определение символьной константы
; данные IBM PC
_type 	db 'Тип IMB PC ',EOF
_PC 		db 'PC',0DH,0AH,EOF
_PC_XT 	db 'PC/XT',0DH,0AH,EOF
_AT 		db 'AT',0DH,0AH,EOF
_PS2_30 	db 'PS2 модель 30',0DH,0AH,EOF
_PS2_50_60 	db 'PS2 модель 50 или 60',0DH,0AH,EOF
_PS2_80 	db 'PS2 модель 80',0DH,0AH,EOF
_PCjr 	db 'PCjr',0DH,0AH,EOF
_PC_Conv db 'PC Convertible',0DH,0AH,EOF
; данные MS DOS
_ver		db 'Номер версии MS DOS:  .    ',0DH,0AH,EOF
_oem		db 'Серийный номер OEM:    ',0DH,0AH,EOF
_user	db 'Серийный номер пользователя:      ',0DH,0AH,EOF

; ПРОЦЕДУРЫ:
TETR_TO_HEX PROC near

	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
;байт AL переводится в два символа шестн. числа в AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  ;в AL - старшая, в AH - младшая
	pop CX
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
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

BYTE_TO_DEC PROC near
;перевод в 10с/с, SI - адрес поля младшей цифры
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
end_l:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

; функция определения типа IMB PC
TYPE_IMB_PC PROC NEAR
  push ds
	mov ax, 0F000h
	mov ds, ax
	sub bx, bx
	mov bh, [0FFFEh]
  pop ds
	ret
TYPE_IMB_PC ENDp

; функция определения версии MS DOS (al)
VERS_DOS PROC NEAR
	push ax
	push si

	mov si, offset _ver
	add si, 15h
	call BYTE_TO_DEC

	mov si, offset _ver
	add si, 17h
	mov al, ah
	call BYTE_TO_DEC
	pop si
	pop ax
	ret
VERS_DOS ENDP

; функция опеделения серийного номера OEM (bh)
OEM_DOS PROC NEAR
	push ax
	push bx
	push si

	mov si, offset _oem
	add si, 16h
	mov al, bh
	call BYTE_TO_DEC

	pop si
	pop bx
	pop ax
	ret
OEM_DOS ENDP

; функция определения серийного номера пользователя (bl:cx)
USER_DOS PROC NEAR
	push bx
	push cx
	push di
	push ax

	mov di, offset _user
	add di, 22h
	mov ax, cx
	call WRD_TO_HEX

	mov al, bl
	call BYTE_TO_HEX
	mov di, offset _user
	add di, 1Dh
	mov [di], ax

	pop ax
	pop di
	pop cx
	pop bx
  ret
USER_DOS ENDP

; функция вывода на экран
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

; КОД
BEGIN:
	; вызываем функцию определения типа IBM PC
	call TYPE_IMB_PC

	; вывод поясняющей строки
	mov dx, offset _type
	call PRINT

	; определяем по предпоследнему биту ROM BIOS тип IBM PC
	; предварительно загружаем смещения определённого типа
	; и в случае успеха - выводим тип на экран
	mov dx, offset _PC
	cmp bh, 0FFh
	je	to_print

	mov dx, offset _PC_XT
	cmp bh, 0FEh
	je	to_print

  mov dx, offset _PC_XT
  cmp bh, 0FBh
  je	to_print

	mov dx, offset _AT
	cmp bh, 0FCh
	je	to_print

	mov dx, offset _PS2_30
	cmp bh, 0FAh
	je	to_print

	mov dx, offset _PS2_50_60
	cmp bh, 0FCh
	je	to_print

	mov dx, offset _PS2_80
	cmp bh, 0F8h
	je	to_print

	mov dx, offset _PCjr
	cmp bh, 0FDh
	je	to_print

	mov dx, offset _PC_Conv
	cmp bh, 0F9h
	je	to_print

 	mov al, bh
 	call BYTE_TO_HEX
	mov dx, ax

	; вызываем функцию вывода на экран
to_print:
	call PRINT

	; вызываем функцию определения версии MS DOS
	mov ah, 30h
  int 21h

	; сохраняем полученные значения
	call VERS_DOS
	call OEM_DOS
  call USER_DOS

	; выводим полученные значения
	mov dx, offset _ver
	call PRINT
	mov dx, offset _oem
	call PRINT
	mov dx, offset _user
	call PRINT
; выход в DOS
	xor al, al
	mov ah, 4ch
	int 21h
  TESTPC     ENDS
		END START	; конец модуля
