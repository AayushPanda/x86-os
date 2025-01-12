ASM=nasm

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_img kernel bootloader clean ${BUILD_DIR}

floppy_img: ${BUILD_DIR}/main_floppy.img

${BUILD_DIR}/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=${BUILD_DIR}/main_floppy.img bs=512 count=2880 # blank floppy with 1.44MB = 2880 sectors * 512 bytes
	mkfs.fat -F 12 -n "TSOS" ${BUILD_DIR}/main_floppy.img # format floppy as FAT12
	dd if=${BUILD_DIR}/bootloader.bin of=${BUILD_DIR}/main_floppy.img conv=notrunc # write bootloader to floppy first sector
	mcopy -i ${BUILD_DIR}/main_floppy.img ${BUILD_DIR}/kernel.bin "::kernel.bin" # copy kernel to floppy root directory (:: is the root directory)

bootloader: ${BUILD_DIR}/bootloader.bin

${BUILD_DIR}/bootloader.bin: ${BUILD_DIR}
	${ASM} ${SRC_DIR}/bootloader/boot.asm -f bin -o ${BUILD_DIR}/bootloader.bin


kernel: ${BUILD_DIR}/kernel.bin

${BUILD_DIR}/kernel.bin: ${BUILD_DIR}
	${ASM} ${SRC_DIR}/kernel/main.asm -f bin -o ${BUILD_DIR}/kernel.bin

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}

clean:
	rm -rf ${BUILD_DIR}