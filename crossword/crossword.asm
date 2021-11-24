	;; Crossword puzzle bootloader

bits 16
org 0x7c00
cpu 8086

;; changed by prebuild.py to load puzzle data as immediates 
puz_len:    equ 232
width:      equ 4
height:     equ 4

;; other immediates
col_width:	equ 25
indent:		equ 4

	
puz_off:	equ 0x7c00
across_msg:	equ puz_off + 0x2 	; In .puz specification
down_msg:	equ puz_off + 0x9
solution:	equ puz_off + 0x34

	;; no longer needed - using these as immediates
	;; puz_width:	equ puz_off + 0x2c
	;; puz_height:	equ puz_off + 0x2d

	;; Not in .puz specification - used as storage over those dumb checksums
next_aclue:	equ puz_off + 0x10
next_dclue:	equ puz_off + 0x12
	
start:
	mov ax, 0x0002				; Set Video mode 80x25 with color
	int 0x10					
	
	mov ax, 0xb800				; Load text video segment
	mov es, ax					; in ES for stosw instructions using DI
	
print_puzzle:
	xor ax, ax					; Zero out AX and DI 
	xor bx, bx					; BL=x value BH=y value
	xor cx, cx					; 
	xor dx, dx					; clue count

	call init_clues

	xor di, di					; ES:DI points to beginning of video memory
	
p1:	call print_line_row			; print the row with lines (e.g. +-+-+-+)
	call print_text_row			; prints the row with text (e.g. | | | |)

	xor bl, bl
	inc bh
	cmp bh, height				; check if end of crossword
	jnz p1
	
	call print_line_row
	
	jmp main

print_line_row:
	mov byte cl, width
p2:	call handle_clue
	stosw
	mov ax, 0x0f2d
	stosw

	
	inc bl
	cmp bl, width
	jz p3

	jmp p2
	
p3:	mov ax, 0x0f2b				; adds the final "+" and then goes to the next
	stosw						; line, calculated using 2 bytes per char and
	add di, 0xa0-(4*width+2)	; 2 chars per cell with the extra +
	ret

	
print_text_row:
	mov cl, width+1
	;; lodsb 						; load byte of solution from DS:SI to AL
p4:	mov ax, 0x0f7c
	stosw
	mov ax, 0x0f20				; White on black background color
	stosw						; store AX in ES:DI
	loop p4						; loop it
	
	add di, 0xa0-(4*width+4)	; next line
	ret
	
	;; main logic function for printing clues and numbering cells correctly
handle_clue:	
	mov ax, 0x0F2B
	ret
	
init_clues:	
	mov di, (col_width+indent)*2 ; print ACROSS at the top of col 2
	mov si, across_msg
	mov cl, 6
i1: lodsb
	mov ah, 0x0f
	stosw
	loop i1

	mov [next_aclue], 0xa0+col_width*2 ; next across clue goes under ACROSS
	
	mov di, col_width*4 + indent*2 ;print DOWN at the top of col 3
	mov si, down_msg
	mov cl, 4
i2:	lodsb
	mov ah, 0x0f
	stosw
	loop i2

	mov [next_dclue], 0xa0+col_width*4 ; next down clue goes right under DOWNx
	
	ret

	
main:							; main loop
	jmp main

	
	;; Pad the rest of the file with null bytes and add
	;; 0x55AA to the end to make the puzzle and code bootable 
times (510-puz_len)-($-$$) db 0
dw 0xAA55
