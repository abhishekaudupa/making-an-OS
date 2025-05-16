SRC 		= src
BUILD 		= build
LINKER_SRC	= linker.ld
BOOTLD1_SRC 	= bootloaderStage1.asm
ABOOTLD2_SRC 	= bootloaderStage2.asm
CBOOTLD2_SRC	= cbootld2.c
ABOOTLD2_OBJ 	= abootldr2.o
CBOOTLD2_OBJ	= cbootldr2.o
BOOTLD2_OBJ	= bootldr2.o
BOOTLD1_TGT 	= bootldr1.bin
BOOTLD2_TGT	= bootldr2.bin
DISK_IMAGE 	= disk.img
PRJ_NAME 	= PYRROS

CC		= gcc
ASM 		= nasm
LD		= ld
LDFLAGS		= -melf_i386 -T$(SRC)/$(LINKER_SRC)
ASMFLAGS 	= -f bin -i$(SRC)
ASMELFLAGS	= -f elf32 -i$(SRC)
CFLAGS		= -Wall -m32 -c -ffreestanding -fno-asynchronous-unwind-tables -fno-pie

EMU		= qemu-system-i386
EMUFLAGS	= -hda

all: $(BUILD)/$(DISK_IMAGE)

$(BUILD)/$(DISK_IMAGE): $(BUILD)/$(BOOTLD1_TGT) $(BUILD)/$(BOOTLD2_TGT) | $(BUILD)
	dd if=/dev/zero of=$@ bs=1024 count=10240
	mkfs.vfat -F 16 $@ -n $(PRJ_NAME)
	dd if=$< of=$@ bs=512 count=1 conv=notrunc
	mcopy -i $@ $(BUILD)/$(BOOTLD2_TGT) "::bootld2.bin"

$(BUILD)/$(BOOTLD1_TGT): $(SRC)/$(BOOTLD1_SRC) | $(BUILD)
	$(ASM) $(ASMFLAGS) $< -o $@

$(BUILD)/$(ABOOTLD2_OBJ): $(SRC)/$(ABOOTLD2_SRC) | $(BUILD)
	$(ASM) $(ASMELFLAGS) $< -o $@

$(BUILD)/$(CBOOTLD2_OBJ): $(SRC)/$(CBOOTLD2_SRC) | $(BUILD)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/$(BOOTLD2_TGT): $(BUILD)/$(ABOOTLD2_OBJ) $(BUILD)/$(CBOOTLD2_OBJ) | $(BUILD)
	$(LD) $(LDFLAGS) $^ -o $(BUILD)/$(BOOTLD2_OBJ)
	objcopy -O binary $(BUILD)/$(BOOTLD2_OBJ) $@
	chmod ugo-x $@ $(BUILD)/$(BOOTLD2_OBJ)

flash: $(BUILD)/$(DISK_IMAGE)
	sudo dd if=$< of=/dev/sd$(dev) conv=nocreat
	sudo hd /dev/sd$(dev) -n 10485760

run: $(BUILD)/$(DISK_IMAGE)
	$(EMU) $(EMUFLAGS) $<

rundbg: $(BUILD)/$(DISK_IMAGE) $(BUILD)/$(BOOTLD1_TGT)
	objdump -b binary -D $(BUILD)/$(BOOTLD1_TGT) -mi8086 -Mintel --adjust-vma=0x7c00
	$(EMU) $(EMUFLAGS) $< -s -S

$(BUILD): 
	@mkdir -p $@

clean:
	@rm -rf $(BUILD) *.out

checkbl1:
	objdump -b binary -D $(BUILD)/$(BOOTLD1_TGT) -mi8086 -Mintel --adjust-vma=0x7c00

checkbl2:
	objdump -D $(BUILD)/$(BOOTLD2_OBJ) -mi8086  | less

dd: $(BUILD)/$(DISK_IMAGE)
	hd $<

.PHONY: all clean run rundbg checkbl1 checkbl2
