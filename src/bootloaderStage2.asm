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

extern kernel_main
extern interrupt_handler

start:
	push cs
	pop ds
	mov ax, 0
	mov es, ax
	
	printString msgStart
	hd 0, 1506

	;call loadGDT
	;call initVideoMode
	;call enterProtectedMode
	;call setupInterrupts

	;call 0x8:start_kernel

	jmp $

initVideoMode:
	push ax
	push cx

	mov ah, 0x0
    	mov al, 0x3
    	int 0x10
    
    	mov ah, 0x1
    	mov cx, 0x2000
    	int 0x10

	pop cx
	pop ax
	ret

loadGDT:
	cli
	lgdt [gdtr - start]
	ret

enterProtectedMode:
	push eax
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	pop eax
	ret

setupInterrupts:
	call initPIC
	call loadIDT
	ret

%define PICMCommPort 0x20
%define PICMDataPort 0x21
%define PICSCommPort 0xa0
%define PICSDataPort 0xa1

initPIC:
	push ax

	mov al, 0x11			; send init cmd to master and slave PIC
	out PICMCommPort, al
	out PICSCommPort, al

	mov al, 32			; master PIC IRQs start at intr 32
	out PICMDataPort, al

	mov al, 40			; slave PIC IRQs start at intr 40
	out PICSDataPort, al

	mov al, 0x4			; setup cascading
	out PICMDataPort, al
	mov al, 0x2
	out PICSDataPort, al

	mov al, 0x1
	out PICMDataPort, al
	out PICSDataPort, al

	mov al, 0x0			; enable all interrupts
	out PICMDataPort, al
	out PICSDataPort, al

	pop ax
	ret

loadIDT:
	lidt [idtr - start]
	ret

%include "print.asm"
%include "hexdump.asm"

msgStart:
	DB "Stage 2 bootloader started", ENDL, 0x0

bits 32
start_kernel:
	mov eax, 0x10
	mov ds, eax
	mov ss, eax

	mov eax, 0
	mov es, eax
	mov fs, eax
	mov gs, eax
	sti
	call kernel_main

%include "gdt.asm"
%include "idt.asm"
