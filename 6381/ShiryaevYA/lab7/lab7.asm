EOL 	EQU 	'$'
AStack	SEGMENT  STACK
        DW 512 DUP(?)			
AStack  ENDS
;-------------------------------------------------------------------------
CODE	SEGMENT
        ASSUME CS:CODE, DS:DATA, SS:AStack
;-------------------------------------------------------------------------
DATA	SEGMENT
    err_4Ah_code_7  			db 	0dh, 0ah,'Code 7 of 4Ah error: memory control block destroyed', 0dh, 0ah, '$'
    err_4Ah_code_8				db 	0dh, 0ah,'Code 8 of 4Ah error: not enought memory for function execution', 0dh, 0ah, '$'
    err_4Ah_code_9				db 	0dh, 0ah,'Code 9 of 4Ah error: invalid adress of the memory block', 0dh, 0ah, '$'	
					
	called_program_err_code_1	db 	0dh, 0ah,'Overlay program was not loaded!(Code 1): function doesnt exist', 0dh, 0ah, '$'   
	called_program_err_code_2  	db 	0dh, 0ah,'Overlay program was not loaded!(Code 2): file not found', 0dh, 0ah, '$'
	called_program_err_code_3  	db 	0dh, 0ah,'Overlay program was not loaded!(Code 3): route not found', 0dh, 0ah, '$'
	called_program_err_code_4  	db 	0dh, 0ah,'Overlay program was not loaded!(Code 4): too many open files', 0dh, 0ah, '$'
	called_program_err_code_5  	db 	0dh, 0ah,'Overlay program was not loaded!(Code 5): no acsess', 0dh, 0ah, '$'					
	called_program_err_code_8  	db 	0dh, 0ah,'Overlay program was not loaded!(Code 8): not enought memory', 0dh, 0ah, '$'					
	called_program_err_code_10 	db 	0dh, 0ah,'Overlay program was not loaded!(Code 10): wrong environment', 0dh, 0ah, '$'

	err_4Eh_code_2	    		db 	0dh, 0ah,'Code 2 of 4Eh error. Cant calc the size of overlay: File not found', 0dh, 0ah, '$'
	err_4Eh_code_3     			db 	0dh, 0ah,'Code 3 of 4Eh error. Cant calc the size of overlay: Way not found', 0dh, 0ah, '$'
	
	OVERLAY_ADDR 				dd 	0
	DTA 						db 	43 dup (0), '$'
	KEEP_PSP 					dw 	0
	OVERLAY_ADDRESS 			dw 	0
	DTA_prgh 					db	256	dup (0), '$'
	
	OVL1_NM						db 	'ovl1.ovl', 0
	OVL2_NM 					db 	'ovl2.ovl', 0
DATA 	ENDS
;-------------------------------------------------------------------------
PRINT	PROC	NEAR
		push	AX
		mov		AH,09H
		int		21H
		pop		AX
		ret
PRINT	ENDP
;-------------------------------------------------------------------------
;поиск ошибки в случае невозможности выполнения 4Ah
DEF_4Ah_ERROR 	PROC

		cmp 	AX, 7
		mov 	DX,	OFFSET err_4Ah_code_7
		je 		IF_4Ah_ERROR
		cmp 	AX,	8
		mov 	DX,	OFFSET err_4Ah_code_8
		je 		IF_4Ah_ERROR
		cmp 	AX,	9
		mov 	DX,	OFFSET err_4Ah_code_9
		
IF_4Ah_ERROR:
		call 	PRINT
		ret
DEF_4Ah_ERROR ENDP
;-------------------------------------------------------------------------
;поиск ошибки в случае, если вызываемая программа не была загружена
DEF_PROGRAMLAUNCH_ERROR 	PROC
		
		cmp 	AX, 1
		mov 	DX, OFFSET called_program_err_code_1
		je 		IF_NO_PROGRAM_LAUNCH
		cmp 	AX, 2
		mov 	DX, OFFSET called_program_err_code_2
		je 		IF_NO_PROGRAM_LAUNCH
		cmp 	AX, 3
		mov 	DX, OFFSET called_program_err_code_3
		je 		IF_NO_PROGRAM_LAUNCH
		cmp 	AX, 4
		mov 	DX, OFFSET called_program_err_code_4
		je 		IF_NO_PROGRAM_LAUNCH
		cmp 	AX, 5
		mov 	DX, OFFSET called_program_err_code_5
		je 		IF_NO_PROGRAM_LAUNCH
		cmp 	AX, 8
		mov 	DX, OFFSET called_program_err_code_8
		je 		IF_NO_PROGRAM_LAUNCH
		cmp 	AX, 10
		mov 	DX, OFFSET called_program_err_code_10
		je 		IF_NO_PROGRAM_LAUNCH
		
IF_NO_PROGRAM_LAUNCH:
		call 	PRINT	
		ret
DEF_PROGRAMLAUNCH_ERROR ENDP
;-------------------------------------------------------------------------
;Нахождение пути до вызываемого файла (в bp - имя файла)
PathSearch	PROC
		push 	AX
		push 	BX
		push 	CX
		push 	DX
		push 	SI
		push 	DI
		push 	ES
	
		mov 	ES, KEEP_PSP
		mov 	AX, ES:[2Ch]
		mov 	ES, AX
		mov 	BX, 0
		mov 	CX, 2
		
path_locate_loop:
		inc 	CX
		mov 	AL, ES:[BX]
		inc 	BX
		cmp 	AL, 0
		jz 		path_locate
		loop 	path_locate_loop
		
path_locate:
		cmp 	byte PTR ES:[BX], 0
		jnz 	path_locate_loop
		add 	BX, 3
		mov 	SI, OFFSET DTA_prgh
		
path_loop:
		mov 	AL, ES:[BX]
		mov 	[SI], AL
		inc 	SI
		inc 	BX
		cmp 	AL, 0
		jz 		end_path_loop
		jmp 	path_loop
	
end_path_loop:	
		sub 	SI, 9
		mov 	DI, BP
		
change_loop:
		mov 	AH, [DI]
		mov 	[SI], AH
		cmp 	AH, 0
		jz 		end_change_loop
		inc 	DI
		inc 	SI
		jmp 	change_loop
	
end_change_loop:
		pop 	ES
		pop 	DI
		pop 	SI
		pop 	DX
		pop 	CX
		pop 	BX
		pop 	AX
		ret
PathSearch	ENDP
;-------------------------------------------------------------------------
;Определение размера оверлея при помощи функции 4Eh прерывания 21h
OverlayFileSize	 	PROC
		push 	ES
		push 	BX
		push 	SI
	
		push 	DS
		push 	DX
		mov 	DX, SEG DTA
		mov 	DS, DX
		mov 	DX, OFFSET DTA	
		mov 	AX, 1A00h		
		int 	21h
		pop 	DX
		pop 	DS
		
		push 	DS
		push 	DX
		mov 	CX, 0			
		mov 	DX, SEG DTA_prgh	
		mov 	DS, DX
		mov 	DX, OFFSET DTA_prgh	
		mov 	AX, 4E00h
		int 	21h
		pop 	DX
		pop 	DS
			
		jnc 	get_size 
		
	;смотрим на код ошибки		
		cmp 	AX, 2
		je 		err_4Eh_2_mark
			
		cmp 	AX, 3
		je 		err_4Eh_3_mark
			
err_4Eh_2_mark:
		mov 	DX, OFFSET err_4Eh_code_2
		call 	PRINT
		jmp 	exit
		
err_4Eh_3_mark:
		mov 	DX, OFFSET err_4Eh_code_3
		call 	PRINT
		jmp 	exit
		
get_size:
		push 	ES
		push 	BX
		push 	SI
		mov 	SI, OFFSET DTA
		add 	SI, 1Ch		
		mov 	BX, [SI]
		
		sub 	SI, 2	
		mov 	BX, [SI]	
		push 	CX
		mov 	CL, 4
		shr 	BX, CL 
		pop 	CX
		mov 	AX, [SI+2] 
		push 	CX
		mov 	CL, 12
		sal 	AX, CL	
		pop 	CX
		add 	BX, AX	
		inc 	BX
		inc 	BX
			
		mov 	AX, 4800h	
		int 	21h			
		mov 	OVERLAY_ADDRESS, AX	
		pop 	SI
		pop 	BX
		pop 	ES

exit:
		pop 	SI
		pop 	BX
		pop 	ES
		ret
OverlayFileSize  ENDP
;-------------------------------------------------------------------------
;Вызов оверлейной программы
OvlProcess  	PROC
		push 	AX
		push 	BX
		push 	CX
		push 	DX
		push 	BP
			
		mov 	BX, SEG OVERLAY_ADDRESS
		mov 	ES, BX
		mov 	BX, OFFSET OVERLAY_ADDRESS	;в ES:BX - указатель на блок параметров
			
		mov 	DX, SEG DTA_prgh
		mov 	DS, DX	
		mov 	DX, OFFSET DTA_prgh			;в DS:DX - указатель на путь к оверлею
			
		push 	SS
		push 	SP
			
		mov 	AX, 4B03h	
		int 	21h
		jnc 	no_err
		
		call 	DEF_PROGRAMLAUNCH_ERROR
		jmp		err

no_err:
		mov 	AX, SEG DATA
		mov 	DS, AX	
		mov 	AX, OVERLAY_ADDRESS
		mov 	WORD PTR OVERLAY_ADDR+2, AX
		call 	OVERLAY_ADDR
		mov 	AX, OVERLAY_ADDRESS
		mov 	ES, AX
		mov 	AX, 4900h
		int 	21h
		mov 	AX, SEG DATA
		mov 	DS, AX
		
err:
		pop 	SP
		pop 	SS
		mov 	ES, KEEP_PSP
		pop 	BP
		pop 	DX
		pop 	CX
		pop 	BX
		pop 	AX	
		ret
OvlProcess  	ENDP	
;-------------------------------------------------------------------------
Main	PROC  	FAR
		mov 	AX, seg DATA
		mov 	DS, AX
		mov 	KEEP_PSP, ES
		
		;вычисляем в BX необходимое количество памяти в параграфах
		mov 	AX, END_BYTE	
		mov 	AX, ES			
		sub 	BX, AX	
		
		;перевод в параграфы
		mov 	CL, 4h		
		shr 	BX, CL			
		
		;попытка освободить лишнюю память
		mov 	AH, 4Ah		
		int 	21h		
		jnc 	SUCCESSFULLY_COMPLITED_4Ah
	
		call	DEF_4Ah_ERROR
		jmp 	Exit_to_DOS
		
SUCCESSFULLY_COMPLITED_4Ah:	
		mov 	bp, OFFSET OVL1_NM
		call 	PathSearch
		call 	OverlayFileSize
		call 	OvlProcess
		
		mov 	bp, OFFSET OVL2_NM
		call 	PathSearch
		call 	OverlayFileSize
		call 	OvlProcess
		

Exit_to_DOS:
		xor 	AL, AL
		mov 	AH, 4Ch
		int 	21H 
		ret

Main    		ENDP
CODE			ENDS

END_BYTE	SEGMENT	
END_BYTE  ENDS	

END Main