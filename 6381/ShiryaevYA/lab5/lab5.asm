MYSTACK SEGMENT STACK
	dw 100h dup (?)
MYSTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
; ПРОЦЕДУРЫ
;---------------------------------------
; Процедура обработчика прерывания
INTERRUPT PROC FAR
	jmp INTERRUPT_CODE
	_TEST db 'BBBC'
	_IP DW 0
	_CS DW 0 ; Переменные для хранения CS и IP старого обработчика
	_PSP DW 0 ; Переменная для хранения адреса PSP у пользовательского обработчика
	_SS DW 0
	_SP DW 0
	_AX DW 0
	INTERRUPT_CODE:
	
	mov CS:_AX, ax
	mov CS:_SS, ss
	mov CS:_SP, sp
	mov ax, MYSTACK
	mov ss, ax
	mov sp, 100h
	push dx
	push ds
	push es
	
			; Статья 28 Рудаков
	; Проверяем пришедший scan-код
		in al,60h
		cmp al,17h ; 17h - клавиша i
		jne INTERRUPT_STNDRD ; Если пришел другой скан-код, идём в стандартный обработчик
	; Проверяем, нажат ли левый Alt(12 бит состояния)
		mov ax,0040h
		mov es,ax
		mov al,es:[18h]
		and al,00000010b
		jz INTERRUPT_STNDRD ; Если не нажат, идем в стандартный обработчик
	jmp INTERRUPT_USER

	
	INTERRUPT_STNDRD:
	; Переходим в стандартный обработчик прерывания:
		pop es
		pop ds
		pop dx
		mov ax, CS:_AX
		mov sp, CS:_SP
		mov ss, CS:_SS
		jmp dword ptr CS:_IP
		; jmp INTERRUPT_END
	
	INTERRUPT_USER:
	; Пользовательский обработчик:
	push ax
	;следующий код необходим для отработки аппаратного прерывания
		in al, 61h   ;взять значение порта управления клавиатурой
		mov ah, al     ; сохранить его
		or al, 80h    ;установить бит разрешения для клавиатуры
		out 61h, al    ; и вывести его в управляющий порт
		xchg ah, al    ;извлечь исходное значение порта
		out 61h, al    ;и записать его обратно
		mov al, 20h     ;послать сигнал "конец прерывания"
		out 20h, al     ; контроллеру прерываний 8259
	pop ax

	INTERRUPT_PUSH_TO_BUFF:
	; Запись символа в буфер клавиатуры:
		mov ah,05h
		mov cl,'E'
		mov ch,00h
		int 16h
		or al,al
		jz INTERRUPT_END ; Проверяем переполнение буфера клавиатуры
		; Очищаем буфер клавиатуры:
			CLI
			mov ax,es:[1Ah]
			mov es:[1Ch],ax ; Помещаем адрес начала буфера в адрес конца
			STI
			jmp INTERRUPT_PUSH_TO_BUFF
		
	INTERRUPT_END:
	pop es
	pop ds
	pop dx
	mov ax, CS:_AX
	mov al,20h
	out 20h,al
	mov sp, CS:_SP
	mov ss, CS:_SS
	iret
INTERRUPT ENDP
	LAST:
;---------------------------------------
; Вызывает прерывание, печатающее строку.
PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
;
CHECK_INTERRUPT PROC
	; Проверка, установлено ли пользовательский обработчик прерывания с вектором 09h
		mov ah,35h
		mov al,09h
		int 21h ; Получаем в es сегмент прерывания, а в bx - смещение
	
	mov si, offset _TEST
	sub si, offset INTERRUPT ; В si хранится смещение сигнатуры относительно начала функции INTERRUPT
	
	; Проверка сигнатуры ('BBBC'):
	; ES - сегмент функции прерывания
	; BX - смещение функции прерывания
	; SI - смещение сигнатуры относительно начала функции прерывания
		mov ax,'BB'
		cmp ax,es:[bx+si]
		jne MARKNOTLOAD
		mov ax,'CB'
		cmp ax,es:[bx+si+2]
		jne MARKNOTLOAD
		jmp MARKISLOAD
	
	MARKNOTLOAD:
	; Установка пользовательской функции прерывания
		mov dx,offset STRLOAD
		call PRINT
		call SET_INTERRUPT ; Установили пользовательское прерывание
		; Вычисление необходимого количества памяти для резидентной программы:
			mov dx,offset LAST ; Кладём в dx размер части сегмента CODE
							   ; содержащей пользовательское прерывание и необходимые код и данные для него
			mov cl,4
			shr dx,cl
			inc dx	; Перевели его в параграфы
			add dx,CODE ; Прибавляем адрес сегмента CODE
			sub dx,CS:_PSP ; Вычитаем адрес сегмента PSP, сохраненного в _PSP
		xor al,al
		mov ah,31h
		int 21h ; Оставляем нужное количество памяти(dx - кол-во параграфов) и выходим в DOS
				; оставляя программу в памяти резидентно
		
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
		je DDELETE ; Если есть, значит идем удалять наш обработчик
		DONTDELETE:
		pop bx
		pop es
	
	mov dx,offset STRALRLOAD
	call PRINT
	ret
	
	; Убираем пользовательский обработчик прерывания
		DDELETE:
		pop bx
		pop es
		; ES - сегмент функции прерывания
		; BX - смещение функции прерывания
		; SI - смещение сигнатуры относительно начала функции прерывания
		call DEL_INTERRUPT
		mov dx,offset STRUNLOAD
		call PRINT
		ret
CHECK_INTERRUPT ENDP
;---------------------------------------
; Установка пользовательского обработчика прерывания INTERRUPT
SET_INTERRUPT PROC
	push ds
	mov ah,35h; Сохраняем старый обработчик
	mov al,09h
	int 21h
	mov CS:_IP,bx
	mov CS:_CS,es
	
	mov dx,offset INTERRUPT ; Устанавливаем новый
	mov ax,seg INTERRUPT
	mov ds,ax
	mov ah,25h
	mov al,09h
	int 21h
	pop ds
	ret
SET_INTERRUPT ENDP 
;---------------------------------------
; Удаление пользовательского обработчика прерывания INTERRUPT
DEL_INTERRUPT PROC
	push ds
	; Восстанавливаем стандартный вектор прерывания:
		CLI
		mov dx,ES:[BX+SI+4] ; IP
		mov ax,ES:[BX+SI+6] ; CS
		mov ds,ax
		
		mov ax,2509h
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
BEGIN:
	mov ax,data
	mov ds,ax
	mov CS:_PSP,es
	
	call CHECK_INTERRUPT
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

DATA SEGMENT
	STRALRLOAD DB 'already loaded',0DH,0AH,'$'
	STRUNLOAD DB 'unloaded',0DH,0AH,'$'
	STRLOAD DB 'loaded',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS

STACK SEGMENT STACK
	dw 50 dup (?)
STACK ENDS
 END START