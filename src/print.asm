bits 16

print:
	push ax
	push bx
	push si

.printLoop:
	lodsb
	cmp al, 0
	jz .printDone
	mov ah, 0xe
	mov bh, 0x0
	int 0x10
	jmp .printLoop

.printDone:
	pop si
	pop bx
	pop ax
	ret

printchar:
	push ax
	push bx
	mov ah, 0xe
	mov bh, 0x0
	int 0x10
	pop bx
	pop ax
	ret
