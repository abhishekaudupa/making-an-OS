org 0x7c00
bits 16

%define	ENDL 0xa, 0xd
%define mfatDirEntSize 32
%define fatFileNameLen 11

%macro printString 1
	mov si, %1
	call print
%endmacro

; FAT16 Header

BS_jmpBoot:
	jmp main
	nop

BS_OEMName: 	DB "MSWIN4.1"
BPB_BytsPerSec:	DW 512
BPB_SecPerClus:	DB 4
BPB_RsvdSecCnt: DW 4
BPB_NumFATs: 	DB 2
BPB_RootEntCnt: DW 512			; 32 byte dir entries
BPB_TotSec16: 	DW 20480		; total sectors in the filesystem
BPB_Media: 	DB 0xf8			; refer FAT spec
BPB_FATSz16: 	DW 20			; in sectors
BPB_SecPerTrk: 	DW 63
BPB_NumHeads: 	DW 16
BPB_HiddSec: 	DD 0			; no partitions. Therefore no hidden sectors
BPB_TotSec32: 	DD 0

BS_DrvNum: 	DB 0x0			; this will be read in from register dl
BS_Reserved1: 	DB 0
BS_BootSig: 	DB 0x28
BS_VolID: 	DB 0x1, 0x2, 0x3, 0x4	; whatever you want
BS_VolLab: 	DB "PYRROS     " 	; 11 bytes
BS_FilSysType: 	DB "FAT16   " 		; 8 bytes

; FAT16 Header end

main:
	mov ax, 0x0			; set ds to segment 0
	mov ds, ax

	cli				; set stack segment to 0x70000
	mov ax, 0x7000
	mov ss, ax
	mov sp, 0x0
	sti

	printString msgStart

	mov [BS_DrvNum], dl		; save drive number

	call loadRootDir		; load root directory
	call searchBootLd2Entry		; search for the bootloader entry in root directory
	call loadStage2BootLoader	; load the 2nd stage bootloader

	call runStage2BootLoader

runStage2BootLoader:
	jmp 0x7e0:0000
	jmp $

loadStage2BootLoader:
	pusha
	push es

	mov ax, [BPB_NumFATs]		; get the root directory LBA/sector in register ax
	mul word [BPB_FATSz16]
	add ax, [BPB_RsvdSecCnt]
	push ax				; save the root directory LBA/sector on stack

	mov ax, [BPB_RootEntCnt]	; get the root directory size in sectors
	mul word [fatDirEntSize]
	div word [BPB_BytsPerSec]

	pop bx				; retreive the root directory sector to bx
	add ax, bx			; add it to the root directory sector size in ax to obtain data sector

	call lbaToCHS
	
	mov bx, 0x7e0			; read into buffer 0x7e00:0000 (yes, we're overwriting the previous data from disk)
	mov es, bx
	mov bx, 0

	push cx
	push dx
	xor dx, dx
	mov ax, [stage2BLSize]		; load the size, in bytes, of stage 2 bootloader file into ax
	div word [BPB_BytsPerSec]	; divide by bytes per sector to get the number of sectors to read
	cmp dx, 0
	jz .loadBS2cont
	inc ax				; increment ax if there is a reminder. We now have number of sectors to read in al

.loadBS2cont:
	pop dx
	pop cx
	call readDisk

	pop es
	popa
	ret

searchBootLd2Entry:
	push ax
	push bx
	push cx
	push ds
	push si
	push es
	push di

	mov bx, 0x7e00			; location to start reading from

	mov ax, 0			; prepare es and ds for string comparison
	mov ds, ax
	mov es, ax

	mov ax, [BPB_RootEntCnt]	; get the size of root directory in bytes in ax
	mul word [fatDirEntSize]
	add ax, bx			; set its value to the byte after the root directory bytes in disk

.searchLoop:
	mov si, stage2BootLdName	; load si with stage 2 bl's filename
	mov di, bx			; point di to bx which holds the directory entry's name
	mov cx, fatFileNameLen		; cx holds the length of the filename string
	repe cmpsb			; compare filename byte by byte 
	cmp cx, 0			; comparison succeeded if cx is zero
	jz .searchSuccess
	
	add bx, mfatDirEntSize		; set bx to read the next directory
	cmp bx, ax			; end search if root directory ends
	jae .searchFailure
	
	jmp .searchLoop			; read the next entry

.searchSuccess:
	mov ax, [bx + 26]		; cluster number of file data is in offset 26. Save it.
	mov [stage2BLStartCluster], ax
	mov ax, [bx + 28]		; file size, in bytes, is in offset 28. Save it.
	mov [stage2BLSize], ax

	pop di
	pop es
	pop si
	pop ds
	pop bx
	pop cx
	pop ax
	ret

.searchFailure:
	printString msgBootLd2NotFound
	jmp $	

; search in root directory which comes immediately after reserved sectors and FAT.
; Root directory sector = BPB_RsvdSecCnt + (BPB_NumFATs * BPB_FATSz16)
loadRootDir:
	pusha
	push es

	mov ax, [BPB_NumFATs]		; get the root directory LBA/sector in register ax
	mul word [BPB_FATSz16]
	add ax, [BPB_RsvdSecCnt]

	call lbaToCHS			; convert the LBA to CHS to supply to BIOS int 0x13

	mov bx, 0x7e0			; read into buffer 0x7e00:0000
	mov es, bx
	mov bx, 0
	
	mov ax, [BPB_RootEntCnt]	; calculate number of sectors to read
	mul word [fatDirEntSize]
	div word [BPB_BytsPerSec]

	call readDisk

	pop es
	popa
	ret

; Read the disk
; Input: 	As specified by BIOS int 0x13 requirements
;		al -> number of sectors to read
;		dh -> head number
;		ch -> cylinder
;		cl -> sector
;		es:bx -> read buffer
; Output:	Disk contents in es:bx

readDisk:
	push di
	mov di, 3			; 3 retries in case of read failures

.readDiskLoop:
	push ax				; save input
	push bx
	push cx
	push dx
	push es

	stc
	mov dl, [BS_DrvNum]		; set drive number
	mov ah, 0x2			; int 0x13, ah=2: read sectors
	int 0x13			; issue the BIOS interrupt
	jc .readDiskRetry		; carry flag set => disk read failed

	pop es				; read succeeded
	pop dx
	pop cx
	pop bx
	pop ax
	pop di
	ret

.readDiskRetry:
	dec di				; decrement retry count
	jz .readDiskFail		; all attempts exhausted

	pop es				; restore input
	pop dx
	pop cx
	pop bx
	pop ax
	jmp .readDiskLoop

	ret

.readDiskFail:
	printString msgDiskReadFailure
	jmp $
	
; Convert the given LBA to CHS and save it in registers required by BIOS int0x13.
; cyl	= (LBA / BPB_SecPerTrk) / BPB_NumHeads
; hd 	= (LBA / BPB_SecPerTrk) mod BPB_NumHeads
; sec 	= (LBA mod BPB_SecPerTrk) + 1
; 
; sec 	-> register cx[0:5]
; cyl 	-> c[0:7] in register cx[8:15], c[8:9] in register cx[6:7]
; hd 	-> register dh
lbaToCHS:
	push ax
	push dx

	xor dx, dx			; zero out dx
	div word [BPB_SecPerTrk]	; quotient in ax
	inc dx				; increment remainder
	mov cx, dx			; store sector in cx

	xor dx, dx			; zero out dx
	div word [BPB_NumHeads]		; quotient in ax
	mov dh, dl			; store head in dh

	mov ch, al			; cyl[0:7] in cx[8:15]
	shl ah, 6			; shift cyl[8:9] to pos ah[8:9] (ax[15:16])
	or cl, ah			; set cx[6:7] to cyl[8:9]

	pop ax
	mov dl, al
	pop ax
	ret

%include "print.asm"

msgStart:
	DB "Stage 1 bootloader started", ENDL, 0x0

msgDiskReadFailure:
	DB "Disk read failed", ENDL, 0x0

msgBootLd2NotFound:
	DB "Stage 2 Bootloader not found", ENDL, 0x0

fatDirEntSize:
	DW mfatDirEntSize

stage2BootLdName:
	DB "BOOTLD2 BIN"

stage2BLStartCluster:
	DW 0

stage2BLSize:
	DD 0

times 510-($-$$) DB 0
DW 0xaa55
