.MODEL SMALL
.STACK 200h
.DATA

;ДАННЫЕ
IBMType 			db  'IMB PC type:        ', '$' ;тип PC и название модели 
VersionOfPC			db	'Version of PC:	     .   ', 0dh, 0ah,'$' ;номер основной версии системы
OEMSerialNumber		db	'OEM serial number:       ', 0dh, 0ah, '$' ;серийный номер OEM 
UserSerialNumber 	db	'User serial number:        ', 0dh, 0ah, '$' ;серийный номер пользователя

;таблица соответствия кода и типа IBM PC
TypePC 				db 'PC', 0dh, 0ah,'$'
TypePCXT 			db 'PC/XT', 0dh, 0ah,'$'
TypeAT 				db 'AT', 0dh, 0ah,'$'
TypePS2_30 			db 'PS2 model 30', 0dh, 0ah,'$'
TypePS2_50_60 		db 'PS2 model 50 or 60', 0dh, 0ah,'$'
TypePS2_80 			db 'PS2 model 80', 0dh, 0ah,'$'
TypePCjr 			db 'PCjr', 0dh, 0ah,'$'
TypePC_Convertible 	db 'PC Convertible', 0dh, 0ah,'$'

.CODE
START: JMP	BEGIN
;ПРОЦЕДУРЫ
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC near ;половина байт AL переводится в символ шестнадцатиричного числа в AL
		and		al, 0Fh ;and 00001111 - оставляем только вторую половину al
		cmp		al, 09 ;если больше 9, то надо переводить в букву
		jbe		NEXT ;выполняет короткий переход, если первый операнд МЕНЬШЕ или РАВЕН второму операнду
		add		al, 07 ;дополняем код до буквы
	NEXT:	add		al, 30h ;16-ричный код буквы или цифры в al
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near ;байт AL переводится в два символа шестнадцатиричного числа в AX
		push	cx
		mov		ah, al ;копируем al в ah
		call	TETR_TO_HEX ;переводим al в символ 16-рич.
		xchg	al, ah ;меняем местами al и  ah
		mov		cl, 4 
		shr		al, cl ;cдвиг всех битов al вправо на 4
		call	TETR_TO_HEX ;переводим al в символ 16-рич.
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------------------------------------------------------------
WRD_TO_HEX		PROC	near ;регистр AX переводится в шестнадцатеричную систему, DI - адрес последнего символа
		push	bx
		mov		bh, ah ;копируем ah в bh, т.к. ah испортится при переводе
		call	BYTE_TO_HEX ;переводим al в два символа шестнадцатиричного числа в AX
		mov		[di], ah ;пересылка содержимого регистра ah по адресу, лежащему в регистре DI
		dec		di 
		mov		[di], al ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		dec		di
		mov		al, bh ;копируем bh в al, восстанавливаем значение ah
		xor		ah, ah ;очищаем ah
		call	BYTE_TO_HEX ;переводим al в два символа шестнадцатиричного числа в AX
		mov		[di], ah ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		dec		di
		mov		[di], al ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		pop		bx
		ret
WRD_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_DEC		PROC	near ;байт AL переводится в десятичную систему, SI - адрес поля младшей цифры
		push	cx
		push	dx
		push	ax
		xor		ah, ah ;очищаем ah
		xor		dx, dx ;очищаем dx
		mov		cx, 10 
	loop_bd:div		cx ;делим ax на 10
		or 		dl, 30h ;логическое или 00110000
		mov 	[si], dl ;пересылка содержимого регистра dl по адресу, лежащему в регистре si
		dec 	si
		xor		dx, dx ;очищаем dx
		cmp		ax, 10 ;сравниваем содержимое ax с 10
		jae		loop_bd ;перейти, если больше или равно 10
		cmp		ax, 00h ;сравниваем ax и 0
		jbe		end_l ;Перейти, если меньше или равно 0
		or		al, 30h ;логическое или 00110000
		mov		[si], al ;пересылка содержимого регистра dl по адресу, лежащему в регистре si
	end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP	
;--------------------------------------------------------------------------------
;ПРОЦЕДУРЫ ДЛЯ ОПРЕДЕЛЕНИЯ ДАННЫХ
;--------------------------------------------------------------------------------
FindIBMType  PROC NEAR ;определение типа PC
	push es
	mov ax, 0F000h		
	mov es, ax			
	sub bx, bx
	mov bh, es:[0FFFEh]
	pop es
	ret
FindIBMType ENDP
;--------------------------------------------------------------------------------
FindVersion PROC NEAR ;AL – номер основной версии. Если 0, то <2.0;
	push ax					
	push si					
	mov si, offset VersionOfPC		
	add si, 13h			
	call BYTE_TO_DEC			
	pop si					
	pop ax					
	ret
FindVersion ENDP
;--------------------------------------------------------------------------------
FindModification PROC NEAR ;AH – номер модификации;
	push ax					
	push si					
	mov si, offset VersionOfPC		
	add si, 15h	
	mov al, ah
	call BYTE_TO_DEC		
	pop si					
	pop ax					
	ret
FindModification ENDP
;--------------------------------------------------------------------------------
FindOEM PROC NEAR ;BH – серийный номер OEM (Original Equipment Manufacturer);
	push ax					
	push bx					
	push si					
	mov si, offset OEMSerialNumber		
	add si, 16h 		
	mov al, bh
	call BYTE_TO_DEC		
	pop si					
	pop bx					
	pop ax					
	ret
FindOEM ENDP
;--------------------------------------------------------------------------------
FindUserNumber PROC NEAR ;BL:CX – 24-битовый серийный номер пользователя;
	push bx					
	push cx					
	push di
	push ax	
	mov di, offset UserSerialNumber
	add di, 17h 
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	mov di, offset UserSerialNumber
	add di, 18h
	mov [di], ax
	pop ax
	pop di					
	pop cx					
	pop bx	
	ret	
FindUserNumber ENDP
;--------------------------------------------------------------------------------
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
;КОД
BEGIN:
	mov ax, @data
	mov ds, ax
	mov bx, ds
	
	;определение типа PC
	call FindIBMType
	mov dx, offset IBMType
	call PRINT

	;выводим тип на экран
	mov dx, offset TypePC
	cmp bh, 0FFh
	je	PrintType
	
	mov dx, offset TypePCXT
	cmp bh, 0FEh
	je	PrintType
	
	mov dx, offset TypeAT
	cmp bh, 0FCh
	je	PrintType
	
	mov dx, offset TypePS2_30
	cmp bh, 0FAh
	je	PrintType

	mov dx, offset TypePS2_50_60 
	cmp bh, 0FCh
	je	PrintType
	
	mov dx, offset TypePS2_80
	cmp bh, 0F8h
	je	PrintType
	
	mov dx, offset TypePCjr
	cmp bh, 0FDh
	je	PrintType
	
	mov dx, offset TypePC_Convertible
	cmp bh, 0F9h
	je	PrintType
	
	mov al, bh
	call BYTE_TO_HEX
	mov dx, ax
	
	;вывод на экран тип
PrintType:
	call PRINT

	;определяем версию MS DOS
	mov ah, 30h
	int 21h
	
	;заносим найденные значения в строки 
	call FindVersion
	call FindModification
	call FindOEM
	call FindUserNumber
	
	;выводим полученные значения
	mov dx, offset VersionOfPC	
	call PRINT
	mov dx, offset OEMSerialNumber
	call PRINT
	mov dx, offset UserSerialNumber
	call PRINT			
	
; выход в DOS
	xor al, al
	mov ah, 4ch
	int 21h
	
END START	; конец модуля
