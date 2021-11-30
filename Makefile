all: crossword.com # crossword.img

SRC := crossword.asm
IMG := crossword.img
COM := crossword.com
PUZ := input.puz

crossword.img: ${SRC} ${PUZ}
	python3 prebuild.py ${PUZ} ${SRC}
	nasm -f bin ${SRC} -l ${IMG}.list -Dcom=0 -o ${IMG}.intermediate
	@python3 -c 'print("Crossword MBR code is " + str(len(open("${IMG}.intermediate", "rb").read()[:-2].rstrip(b"\x00"))) + " bytes long")'
	cat ${PUZ} ${IMG}.intermediate > ${IMG}

crossword.com: ${SRC} ${PUZ}
	python3 prebuild.py ${PUZ} ${SRC}
	nasm -f bin ${SRC} -l ${COM}.list -Dcom=1 -o ${COM}.intermediate
	@python3 -c 'print("Crossword COM code is " + str(len(open("${COM}.intermediate", "rb").read()[:-2].rstrip(b"\x00"))) + " bytes long")'
	cat ${PUZ} ${COM}.intermediate > ${COM}

test-mbr:
	qemu-system-i386 -fda ${IMG}

test-com:
	dosbox -c "MOUNT C ." -c "C:\CROSSW~1.com"
