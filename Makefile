# Programs
# # Locations of various programs
VBoxManage = "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"  # 'VBoxManage' if VirtualBox is installed on Linux
NASM = nasm
AS = as
LD = ld
GCC = gcc-10


# # Parameters
ASPARAMS = --64
NASMPARAMS = -f elf64
GCCPARAMS = -m64 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore
LDPARAMS = -m elf_x86_64
VMNAME = rOS
VMDISKNAME = rOS.vmdk

# # Dependencies
objects = bootloader.o


# #########################################
# #      Raw Binary
# #########################################
bootloader.o: bootloader.asm bootloader.gdt.asm
	@echo -----------------------
	@echo Compiling Bootloader
	@$(NASM) $(NASMPARAMS) $< -o $@

%.o: %.asm
	@$(AS) $(ASPARAMS) $< -o $@
	
%.o: %.cpp
	@$(GCC) $(GCCPARAMS) -c $< -o $@

rOS.bin: linker.ld $(objects)
	@echo -----------------------
	@echo Linking Objects
	@$(LD) $(LDPARAMS) -T $< $(objects) -o $@


# #########################################
# #      VMDK // VHD
# #########################################
# Use: VBoxManage convertfromraw $< $@ --format VDI|VMDK|VHD
# Use: qemu-img convert -f raw -O qcow2|qed|vdi|vpc|vmdk $< $@
# Use: mkisofs  -o $@ -b $< ./
rOS.vmdk: rOS.bin
	@echo -----------------------
	@echo Creating VMDK
	@$(VBoxManage) convertfromraw $< $@ --format VMDK
	 



# #########################################
# #      Virtual Machine
# #########################################
VMSetup: rOS.vmdk createVM addDisk

createVM:
	@echo -----------------------
	@echo Creating VM
	@$(VBoxManage) createvm --name $(VMNAME) --register
	@$(VBoxManage) modifyvm $(VMNAME) --memory 4 --longmode on
	@$(VBoxManage) storagectl $(VMNAME) --name "SATA Controller" --add sata \
		--controller IntelAHCI --portcount 1 --bootable on

addDisk:
	@echo -----------------------
	@echo Adding disk to VM
	@$(VBoxManage) storageattach $(VMNAME) --storagectl "SATA Controller" --device 0 \
		--port 0 --type hdd --medium $(VMDISKNAME)

rmDisk:
	@echo -----------------------
	@echo Removing disk from VM
	@($(VBoxManage) storageattach $(VMNAME) --storagectl "SATA Controller" --device 0 \
		--port 0 --type hdd --medium none)
	@($(VBoxManage) closemedium disk $(VMNAME) --delete)

deleteVM:
	@echo -----------------------
	@echo Deleting VM
	@($(VBoxManage) unregistervm  $(VMNAME) --delete) || true

startVM:
	@echo -----------------------
	@echo Starting VM
	@$(VBoxManage) startvm $(VMNAME)


# #########################################
# #      Cleanup
# #########################################
clean: deleteVM
	@echo -----------------------
	@echo Cleaning up
	@rm *.o rOS.bin $(VMDISKNAME) 

