%define	ENDL 0xa, 0xd

%macro printString 1
	mov si, %1
	call print
%endmacro

hexdump:
	push ax
	push bx
	push cx
	push di

	mov bx, 16

.hexdump_loop:
	cmp bx, 0
	jnz .hexdump_inner
	printString nextline
	mov bx, 16

.hexdump_inner:
	call printByte
	dec bx
	dec cx
	cmp cx, 0
	jz .hexdump_done
	mov al, " "
	call printchar
	inc di
	jmp .hexdump_loop

.hexdump_done:
	printString nextline
	pop di
	pop cx
	pop bx
	pop ax
	ret

printByte:
	push ax
	push dx

	xor dx, dx
	mov al, [di]
	div word [sixteen]
	call printNibble
	mov al, dl
	call printNibble

	pop dx
	pop ax
	ret

printNibble:
	push ax
	push di

	mov di, hexNums
	add di, ax
	mov ax, [di]
	call printchar

	pop di
	pop ax
	ret

nextline:
	DB ENDL, 0x0

sixteen:
	DW 16

hexNums:
	DB "0123456789abcdef"
