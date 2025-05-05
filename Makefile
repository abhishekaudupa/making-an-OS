SRC 		= src
BUILD 		= build
BOOTLD1_SRC 	= bootloaderStage1.asm
BOOTLD2_SRC 	= bootloaderStage2.asm
BOOTLD1_TGT 	= bootldr1.bin
BOOTLD2_TGT 	= bootldr2.bin
DISK_IMAGE 	= disk.img
PRJ_NAME 	= PYRROS

ASM 		= nasm
ASMFLAGS 	= -f bin

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

$(BUILD)/$(BOOTLD2_TGT): $(SRC)/$(BOOTLD2_SRC) | $(BUILD)
	$(ASM) $(ASMFLAGS) $< -o $@

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
	objdump -b binary -D $(BUILD)/$(BOOTLD2_TGT) -mi8086 -Mintel --adjust-vma=0x7e00

dd: $(BUILD)/$(DISK_IMAGE)
	hd $<

.PHONY: all clean run rundbg checkbl1 checkbl2
