TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:
	JMP BEGIN
	
INACCESSMEMADDR db 'Segment address of the first byte of inaccessible memory: $'
INACCESSMEMADDREM db '    $'
ENVADDR db 'Segmental environment address: $'
ENVADDREM db '    $'
TAIL_M db 'Tail:$'
TAILEM db 50h DUP(' '),'$'
NOTAIL db 'There is no tail$'
CONTENV db 'Contents of the environment area:',0DH,0AH,'$'
PATH db 'Path:',0DH,0AH,'$'
ENDL db 0DH,0AH,'$'

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

INACCESS_M PROC near
	mov ax,ss:[2]
	mov es,ax
	mov di,offset INACCESSMEMADDREM+3
	call WRD_TO_HEX
	mov dx,offset INACCESSMEMADDR
	call PRINT
	mov dx,offset INACCESSMEMADDREM
	call PRINT
	mov dx,offset ENDL
	call PRINT
	;mov ax,01000h 
	;mov es:[0h],ax ; works in dos
	ret
INACCESS_M ENDP
;---------------------------------------
; Чтение из PSP сегментного адреса среды, передаваемой программе и его вывод в консоль
ENV_ADDR PROC near
	mov ax,ss:[2Ch]
	mov di,offset ENVADDREM+3
	call WRD_TO_HEX
	mov dx,offset ENVADDR
	call PRINT
	mov dx,offset ENVADDREM
	call PRINT
	mov dx,offset ENDL
	call PRINT
	ret
ENV_ADDR ENDP

TAIL PROC near
	xor ch,ch
	mov cl,ss:[80h]
	
	cmp cl,0
	jne notnil
		mov dx,offset NOTAIL
		call PRINT
		mov dx,offset ENDL
		call PRINT
		ret
	notnil:
	
	mov dx,offset TAIL_M
	call PRINT
	
	mov bp,offset TAILEM
	T_cycle:
		mov di,cx
		mov bl,ss:[di+80h]
		mov ss:[bp+di-1],bl
	loop T_cycle
	
	mov dx,offset TAILEM
	call PRINT
	ret
TAIL ENDP

ENV PROC near
	mov dx, offset ENDL
	call PRINT
	mov dx, offset CONTENV
	call PRINT

	mov ax,ds:[2ch]
	mov es,ax
	
	xor bp,bp
	E_cycle:
		cmp word ptr es:[bp],0001h
		je E_exit
		cmp byte ptr es:[bp],00h
		jne E_noendl
			mov dx,offset ENDL
			call PRINT
			inc bp
		E_noendl:
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp E_cycle
	E_exit:
	add bp,2
	
	mov dx, offset ENDL
	call PRINT
	mov dx, offset PATH
	call PRINT
	
	E_cycle1:
		cmp byte ptr es:[bp],00h
		je E_exit1
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp E_cycle1
	E_exit1:
	
	ret
ENV ENDP

BEGIN:
	call INACCESS_M
	call ENV_ADDR
	call TAIL
	call ENV
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START 