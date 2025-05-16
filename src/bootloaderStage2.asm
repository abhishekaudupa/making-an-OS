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
	
	printString msgStart
	call loadGDT
	call initVideoMode
	call enterProtectedMode
	call setupInterrupts

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

isr_0:
	cli
	push 0
	jmp isr_basic

isr_1:
	cli
	push 1
	jmp isr_basic

isr_2:
	cli
	push 2
	jmp isr_basic

isr_3:
	cli
	push 3
	jmp isr_basic

isr_4:
	cli
	push 4
	jmp isr_basic

isr_5:
	cli
	push 5
	jmp isr_basic

isr_6:
	cli
	push 6
	jmp isr_basic

isr_7:
	cli
	push 7
	jmp isr_basic

isr_8:
	cli
	push 8
	jmp isr_basic

isr_9:
	cli
	push 9
	jmp isr_basic

isr_10:
	cli
	push 10
	jmp isr_basic

isr_11:
	cli
	push 11
	jmp isr_basic

isr_12:
	cli
	push 12
	jmp isr_basic

isr_13:
	cli
	push 13
	jmp isr_basic

isr_14:
	cli
	push 14
	jmp isr_basic

isr_15:
	cli
	push 15
	jmp isr_basic

isr_16:
	cli
	push 16
	jmp isr_basic

isr_17:
	cli
	push 17
	jmp isr_basic

isr_18:
	cli
	push 18
	jmp isr_basic

isr_19:
	cli
	push 19
	jmp isr_basic

isr_20:
	cli
	push 20
	jmp isr_basic

isr_21:
	cli
	push 21
	jmp isr_basic

isr_22:
	cli
	push 22
	jmp isr_basic

isr_23:
	cli
	push 23
	jmp isr_basic

isr_24:
	cli
	push 24
	jmp isr_basic

isr_25:
	cli
	push 25
	jmp isr_basic

isr_26:
	cli
	push 26
	jmp isr_basic

isr_27:
	cli
	push 27
	jmp isr_basic

isr_28:
	cli
	push 28
	jmp isr_basic

isr_29:
	cli
	push 29
	jmp isr_basic

isr_30:
	cli
	push 30
	jmp isr_basic

isr_31:
	cli
	push 31
	jmp isr_basic

isr_32:
	cli
	push 32
	jmp irq_basic

isr_33:
	cli
	push 33
	jmp irq_basic

isr_34:
	cli
	push 34
	jmp irq_basic

isr_35:
	cli
	push 35
	jmp irq_basic

isr_36:
	cli
	push 36
	jmp irq_basic

isr_37:
	cli
	push 37
	jmp irq_basic

isr_38:
	cli
	push 38
	jmp irq_basic

isr_39:
	cli
	push 39
	jmp irq_basic

isr_40:
	cli
	push 40
	jmp irq_basic

isr_41:
	cli
	push 41
	jmp irq_basic

isr_42:
	cli
	push 42
	jmp irq_basic

isr_43:
	cli
	push 43
	jmp irq_basic

isr_44:
	cli
	push 44
	jmp irq_basic

isr_45:
	cli
	push 45
	jmp irq_basic

isr_46:
	cli
	push 46
	jmp irq_basic

isr_47:
	cli
	push 47
	jmp irq_basic

isr_basic:
	call interrupt_handler
	pop eax
	sti
	iret

interrupt_handler:
	ret

irq_basic:

loadIDT:
	lidt [idtr - start]
	ret

%include "print.asm"

msgStart:
	DB "Stage 2 bootloader started", ENDL, 0x0

gdt:
	null_descriptor:	DQ 0x0000000000000000
	kernel_code_seg:	DQ 0x00cf9a000000ffff
	kernel_data_seg:	DQ 0x00cf92000000ffff
	;user_code_seg:		DQ 0x0
	;user_data_seg:		DQ 0x0

gdtr:
	gdt_size: 		DW (8 * 3)
	gdt_offset:		DD gdt

idt:

idtr:
