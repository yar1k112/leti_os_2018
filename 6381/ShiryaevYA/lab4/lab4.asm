; Шаблон текста программы для модуля типа .COM
MYSTACK SEGMENT STACK
	dw 100h dup (?)
MYSTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
; ПРОЦЕДУРЫ
;---------------------------------------
; Вызывает прерывание, печатающее строку.
PRINT PROC near
	push ax
	mov al,00h
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP

;---------------------------------------
; Установка позиции курсора
setCarriage PROC
	push ax
	push bx
	push dx
	push cx
	mov ah,02h
	mov bh,0
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
setCarriage ENDP
;---------------------------------------
; Получение позиции курсора
getCarriage PROC
	push ax
	push bx
	;push dx
	push cx
	mov ah,03h
	mov bh,0
	int 10h
	pop cx
	;pop dx
	pop bx
	pop ax
	ret
getCarriage ENDP

;---------------------------------------
; вывод символа из AL
outputAL PROC
	push ax
	push bx
	push cx
	mov ah,09h   
	mov bh,0     
	mov bl,07h
	mov cx,1     
	int 10h      
	pop cx
	pop bx
	pop ax
	ret
outputAL ENDP
;---------------------------------------
; Процедура обработчика прерывания
INTERRUPT PROC FAR
	jmp INTERRUPT_CODE
	_TEST db 'BBBB'
	_IP DW 0
	_CS DW 0
	_PSP DW 0
	MUST_BE_REMOVED DB 0
	COUNT DB 0
	_SS DW 0
	_SP DW 0
	_AX DW 0
	INTERRUPT_CODE:
	; Меняем стек, сохраняем регистры
	mov _AX, ax
	mov CS:_SS, ss
	mov CS:_SP, sp
	mov ax, MYSTACK
	mov ss, ax
	mov sp, 100h
	push dx
	push ds
	push es
	
	; Устанавливаем курсор
	call getCarriage
	push dx
	mov dx,0013h
	call setCarriage
	
	; Печатаем цифру
	cmp COUNT,0AH
	jl skip
	mov COUNT,0h
	skip:
	mov al,COUNT
	or al,30h
	call outputAL
	
	; Возвращаем курсор
	pop dx
	call setCarriage
	inc COUNT

	; Возвращаем стек, восстанавливаем регистры
	pop es
	pop ds
	pop dx
	mov ax, _AX
	mov al,20h
	out 20h,al
	mov sp, _SP
	mov ss, _SS
	
	iret
INTERRUPT ENDP
LAST:
;---------------------------------------
;
CHECK_INTERRUPT PROC
	; Проверка, установлено ли пользовательское прерывание с вектором 1ch
		mov ah,35h
		mov al,1ch
		int 21h ; Получаем в es сегмент прерывания, а в bx - смещение
	
	mov si, offset _TEST
	sub si, offset INTERRUPT ; В si хранится смещение сигнатуры относительно начала функции INTERRUPT
	
	; Проверка сигнатуры ('BBBB'):
	; ES - сегмент функции прерывания
	; BX - смещение функции прерывания
	; SI - смещение сигнатуры относительно начала функции прерывания
		mov ax,'BB'
		cmp ax,es:[bx+si]
		jne MARKNOTLOAD
		cmp ax,es:[bx+si+2]
		jne MARKNOTLOAD
		jmp MARKISLOAD 
	
	MARKNOTLOAD:
	; Установка пользовательской функции прерывания
		lea dx, STRLOAD
		call PRINT
		call SET_INTERRUPT
		; Вычисление необходимого количества памяти для резидентной программы:
			mov dx,offset LAST ; Кладём в dx размер части сегмента CODE с обработчиком прерывания
			mov cl,4
			shr dx,cl
			inc dx	; Перевели его в параграфы
			add dx,CODE ; Прибавляем адрес сегмента CODE
			sub dx,_PSP ; Вычитаем адрес сегмента PSP
		xor al,al
		mov ah,31h
		int 21h ; Оставляем нужное количество памяти(dx - кол-во параграфов) 
		;и выходим в DOS, оставляя программу в памяти резидентно
		
	MARKISLOAD:
	; Смотрим, есть ли в хвосте /un
		push es
		push bx
		mov bx,_PSP
		mov es,bx
		cmp byte ptr es:[82h],'/'
		jne DONTDELETE
		cmp byte ptr es:[83h],'u'
		jne DONTDELETE
		cmp byte ptr es:[84h],'n'
		je DDELETE
		DONTDELETE:
		pop bx
		pop es
	
	mov dx,offset STRALRLOAD
	call PRINT
	ret
	
	; Убираем пользовательское прерывание
		DDELETE:
		pop bx
		pop es
		; mov byte ptr es:[bx+si+10],1
		call DEL_INTERRUPT
		mov dx,offset STRUNLOAD
		call PRINT
		ret
CHECK_INTERRUPT ENDP
;---------------------------------------
; Удаление написанного прерывания INTERRUPT
DEL_INTERRUPT PROC
		push ds
	; Восстанавливаем стандартный вектор прерывания:
		CLI
		mov dx,ES:[BX+SI+4] ; IP
		mov ax,ES:[BX+SI+6] ; CS
		mov ds,ax
		mov ax,251ch
		int 21h 
	; Освобождаем память:
		push es
		mov ax,ES:[BX+SI+8] ; PSP
		mov es,ax 
		mov es,es:[2Ch] ; Блока переменных среды
		mov ah,49h         
		int 21h
		pop es
		mov es,ES:[BX+SI+8] ; PSP ; Блока резидентной программы
		mov ah, 49h
		int 21h	
		STI
	pop ds
	ret
DEL_INTERRUPT ENDP
;---------------------------------------
; Установка написанного прерывания INTERRUPT
SET_INTERRUPT PROC
	push ds
	mov ah,35h; Сохраняем старое прерывание
	mov al,1ch
	int 21h
	mov _IP,bx
	mov _CS,es

	mov dx,offset INTERRUPT ; Устанавливаем новое
	mov ax,seg INTERRUPT
	mov ds,ax
	mov ah,25h
	mov al,1ch
	int 21h
	pop ds
	ret
SET_INTERRUPT ENDP 
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	mov _PSP,es
	
	call CHECK_INTERRUPT
	
	xor AL,AL
	mov AH,4Ch
	int 21H
	
CODE ENDS

STACK SEGMENT STACK
	dw 100h dup (?)
STACK ENDS

DATA SEGMENT
	STRALRLOAD DB 'already loaded',0DH,0AH,'$'
	STRUNLOAD DB 'unloaded',0DH,0AH,'$'
	STRLOAD DB 'loaded',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS
 END START