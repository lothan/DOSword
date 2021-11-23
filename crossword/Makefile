all: build

ASM := crossword.asm
OUT := crossword.img
PUZ := input.puz

build:
	python3 prebuild.py ${PUZ} ${ASM}
	nasm -f bin ${ASM} -l ${ASM}.list -o ${OUT}.intermediate
	@python3 -c 'print("Crossword code is " + str(len(open("${OUT}.intermediate", "rb").read()[:-2].rstrip(b"\x00"))) + " bytes long")' # echo "Code length: "$(shell du -b ${OUT}.intermediate)
	cat ${PUZ} ${OUT}.intermediate > ${OUT}

test:
	qemu-system-i386 -fda ${OUT}
