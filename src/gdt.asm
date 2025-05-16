gdt:
	null_descriptor:	DQ 0x0000000000000000
	kernel_code_seg:	DQ 0x00cf9a000000ffff
	kernel_data_seg:	DQ 0x00cf92000000ffff
	;user_code_seg:		DQ 0x0
	;user_data_seg:		DQ 0x0

gdtr:
	gdt_size: 		DW gdtr - gdt
	gdt_offset:		DD gdt

