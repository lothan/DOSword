	;; Crossword puzzle bootloader

bits 16
org 0x7c00
cpu 8086

;; changed by prebuild.py to load puzzle data as immediates 
puz_len:    equ 232
width:      equ 4
height:     equ 4
;; -----------------

puz_off:	equ 0x7c00
acrossmsg:	equ puz_off + 0x2 	; In .puz specification
downmsg:	equ puz_off + 0xa
	;; puz_width:	equ puz_off + 0x2c
	;; puz_height:	equ puz_off + 0x2d
solution:	equ puz_off + 0x34
	
num_cells:	equ puz_off + 0x30	; user defined
cur_clue:	equ puz_off + 0x2f
	
start:
	mov ax, 0x0002				; Set Video mode 80x25 with color
	int 0x10					
	
	mov ax, 0xb800				; Load text video segment
	mov es, ax					; in ES for stosw instructions using DI
	xor ax, ax
	
	;; Clear screen - is this necessary?
	;; seems like setting the video mode above does this
	;; 	xor ax, ax					; Zero out AX
	;; 	mov ch, 8					; Set count to 0x800
	;; 	rep stosw					; set video segment to null

	;; Not necessary anymore with prebuild and using immediates
	;;	mov cl, width			    ; Calculate total number of cells
	;; 	mov al, height
	;; 	mul cx
	;; 	mov [num_cells], ax			; save the result in num_cells

	;; just prints the solution in a simple grid for now
print_puzzle:
	xor di, di
	
	mov bl, height
	
	mov si, solution			; load solution
p1:	mov cl, width
p2:	lodsb 						; load byte of solution from DS:SI to AL
	mov ah, 0x78
	stosw						; store AX in ES:DI
	loop p2						; loop it
	
	sub byte bl, 1				; check if end of crossword
	jz main
	
	add di, 0xa0-(width*2) 				; go to the next line
	;; 	sub di, [puz_width]
		
	jmp p1
	
main:							; main loop
	jmp main

	
	;; Pad the rest of the file with null bytes and add
	;; 0x55AA to the end to make the puzzle and code bootable 
times (510-puz_len)-($-$$) db 0
dw 0xAA55
