import puz
import sys

if len(sys.argv) != 3:
    print("Usage: python3 " + sys.argv[0] + " <puz> <asm>")
    exit(1)

p = puz.read(sys.argv[1])
    
with open(sys.argv[2]) as f:
    asm = f.readlines()
    
if "puz_len:    equ " + str(len(p.tobytes())) + "\n" in asm and \
   p.tobytes()[:2] == b'\xeb\x1e':
    print("Puzzle and ASM look like they match.")
    print("Skipping prebuild...")
    exit(0)

# PUZ prebuild edits

# strip author, title, copyright, and notes to save space
p.author = ""
p.title = ""
p.copyright = ""
p.notes = ""

puz_len = len(p.tobytes()) + 9 # 9 is the length of the added p.notes below
# TODO check to see if there's enough space for mbr here:

# set up second, three-byte (long) jump, in unused .puz header space
# to skip instruction after the puzzle data
p.unk2 = b'\xe9' + (puz_len - 0x23).to_bytes(2, "little") + b'\x00'*9

# stupid brute force to get our desired two-byte (short) jump instruction
# to jump to the long jump at offset 0x20
# at offset 0, where the main checksum is, by editing the unused notes section
# easier with itertools but want to keep dependencies down
# even easier to calculate directly but idc, I just want a basic build system up
valid_jumps = False
for i in range(1,256): 
    for j in range(1,256):
        p.notes = bytes([i] + [0x41]*7 + [j]).decode("ISO8859")
        if p.tobytes()[:2] == b'\xeb\x1e':
            valid_jumps = True
            break
    if valid_jumps:
        break  

p.save(sys.argv[1])

# ASM prebuild edits

# edit the defines for the asm to match the puzzle info
puz_len_line = next(x[0] for x in enumerate(asm) if x[1].startswith("puz_len"))
asm[puz_len_line] = 'puz_len:    equ ' + str(puz_len) + '\n'
width_line = next(x[0] for x in enumerate(asm) if x[1].startswith("width"))
asm[width_line] = 'width:      equ ' + str(p.width) + '\n'
height_line = next(x[0] for x in enumerate(asm) if x[1].startswith("height"))
asm[height_line] = 'height:     equ ' + str(p.height) + '\n'

with open(sys.argv[2], "w") as f:
    f.writelines(asm)
