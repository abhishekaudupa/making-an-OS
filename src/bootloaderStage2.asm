bits 16

%define	ENDL 0xa, 0xd

%macro printString 1
	mov si, %1
	call print
%endmacro

%macro hd 2
	mov di, %1
	mov cx, %2
	call hexdump
%endmacro

start:
	push cs
	pop ds
	mov ax, 0
	mov es, ax

	call loadGDT

	jmp $

loadGDT:
	lgdt [gdtr - start]
	ret

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

msgStart:
	DB "Stage 2 bootloader started", ENDL, 0x0

sixteen:
	DW 16

hexNums:
	DB "0123456789abcdef"

gdt:
	null_descriptor:	DQ 0x0
	kernel_code_seg:	DQ 0x0
	kernel_data_seg:	DQ 0x0
	user_code_seg:		DQ 0x0
	user_data_seg:		DQ 0x0

gdtr:
	gdt_size: 		DW (8 * 5)
	gdt_offset:		DD gdt
