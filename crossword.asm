	;; Play a (mini) crossword puzzle in DOS
	
bits 16
cpu 8086
	
%if	com
	org 0x0100
%else 
	org 0x7c00
%endif
	
;; changed by prebuild.py to load puzzle data as immediates 
puz_len:    equ 380
width:      equ 4
height:     equ 4

;; other immediates
col_width:	equ 25
indent:		equ 4

;; where the .puz file starts
%if com
	puz_off:	equ 0x100
%else
	puz_off:	equ 0x7c00
%endif

;; various fields in the .puz specification
across_msg:	equ puz_off + 0x2 
down_msg:	equ puz_off + 0x9
solution:	equ puz_off + 0x34
grid:		equ puz_off + 0x34 + (width*height)
clues:		equ grid + (width*height) + 3 ; after the grid and 3 null bytes

;; Locations for variable memory  
;; saved over the damn checksums
next_aloc:	equ puz_off + 0x10
next_dloc:	equ puz_off + 0x12 	; line with
next_clue:	equ puz_off + 0x14	; pointer to the next clue's text
cur_clue:	equ puz_off + 0x16	; the current clue number when initializing

	
start:
	mov ax, 0x0002				; Set Video mode 80x25 with color
	int 0x10					
	
	mov ax, 0xb800				; Load text video segment
	mov es, ax					; in ES for stosw instructions using DI

	call init_clues

print_puzzle:
	
	xor ax, ax					; Zero out AX and DI 
	xor bx, bx					; 
	xor cx, cx					; 
	xor dx, dx					; dl is x value, dh is y value

	xor di, di					; ES:DI points to beginning of video memory
	
p1:	call print_line_row			; print the row with lines (e.g. +-+-+-+)
	call print_text_row			; prints the row with text (e.g. | | | |)

	xor dl, dl
	inc dh
	cmp dh, height				; check if end of crossword
	jnz p1
	
	call print_line_row

	;; initialize cursor location to the first empty cell
	;; jmps to update_cursor, which jmps to main
premain:
	mov dx, 0
	mov bx, grid
n1:	cmp byte [bx], 0x2e 		; if it's a black square, go to the next cell
	jne update_cursor
	add dl, 1
	call load_grid_pos
	jmp n1

	;; prints the rows with lines (e.g. +-+-+-+)
print_line_row:
	mov byte cl, width
p2:	call handle_clue			; returns "+" or current clue number
	stosw
	mov al, 0x2d				; "-" for inbetween cells (i.e 3-+-+)
	stosw
	
	inc dl						; end of the row? break out of loop
	cmp dl, width
	jz p3

	jmp p2
	
p3:	mov al, 0x2b				; adds the final "+" and then goes to the next
	stosw						; line, calculated using 2 bytes per char and
	add di, 0xa0-(4*width+2)	; 2 chars per cell with the extra +
	ret

	;; prints the row that should contain user inputted text (i.e. "| | | |)
print_text_row:
	mov cx, width+1
p4:	mov al, 0x7c				; prints "| " width+1 times
	stosw
	add di, 2					; jump over a character 
	loop p4				
	
	add di, 0xa0-(4*width+4)	
	ret

	;; main logic function for printing clues and numbering cells correctly
	;; dx must be preserved - has (y,x) cords
	;; bx is used for grid positioning checks
	;; cl never used
handle_clue:
	mov ax, width	  			; (a '.' or 0x2e in the grid), then return a '+'
	mul dh
	add al, dl
	add ax, grid
	mov bx, ax
	cmp byte [bx], 0x2e
	je	h5
	cmp dh, height				; if its the last row, don't handle across clue
	je h6
	xor ax, ax
	
	;; if dl=0 or the cell to the left is '.', handle across clue
	dec bx						; ax is pointing at the current grid location
	cmp dl, 0					; so a simple dec bx should check the cell to the left
	je h1						
	cmp byte [bx], 0x2e
	jne h2

h1:	push bx
	mov bx, next_aloc
	call print_clue
	pop bx
	mov al, 1
	
	;; if dh=0 or the cell above is '.', handle down clue
h2:	cmp dh, 0
	je 	h3
	sub bx, width-1				; check the above row
	cmp byte [bx], 0x2e			; accounting for previous dec
	jne h4
	
h3:	push bx
	mov bx, next_dloc
	call print_clue
	pop bx
	mov al, 1

h4:	cmp al, 1					; dh contains whether a clue number exists
	jne h6						; in this cell. If not, return just a "+"
	
	mov word bx, [cur_clue]		; return and increment a printable clue number
	mov ax, bx
	inc bl				 		; note: only works for clue numbers less than 10
	mov word [cur_clue], bx
	ret


	;; print a black square in the square down and to the right of current di
h5:	push di
	add di, 0xa0+2
	mov ax, 0x0fdb
	stosw
	pop di

h6:	mov ax, 0x0F2B				; return a simple "+" for the cross
	ret

	;; prints both the across and down clues in the right column
	;; reads the next clue in the .puz file from next_clue
	;; and uses the number stored in cur_clue
	;; and writes to bx
print_clue:
	push ax
	push di
	push si

	mov word di, [bx]			; load location for next clue
	
	mov word ax, [cur_clue]
	stosw						; this is inefficient as hell to print ("1.  "
	mov ax, 0x0f2e
	stosw
	mov ax, 0x0f20
	stosw
	mov ax, 0x0f20
	stosw
	mov word si, [next_clue]
	
a1:	mov ax, [bx]				; [bx] stores the start of the column 
	add ax, col_width*2-4		; where the clue is printed. If it is 
	cmp ax, di					; col_width away from di (current clue
	jne a2						; printing location) print "\" and
	mov ax, 0x0f5c
	stosw
	mov di, [bx] 				; go to the next line
	add di, 0xa0
	mov [bx], di
	add di, indent*2

a2:	lodsb
	cld
	cmp byte al, 0				; if we get a null byte, leave loop
	je a3
	mov ah, 0x0f
	stosw
	jmp a1
	
a3:	mov word [next_clue], si
	
	mov di, [bx]
	add di, 0xa0
	mov [bx], di
	pop si
	pop di
	pop ax
	ret
	
handle_dclue:	
	ret
	
	;; Just prints "ACROSS" and "DOWN" and sets values
	;; for the variables next_aloc, nextdloc, cur_clue, and next_clue
init_clues:	
	mov di, (col_width+indent)*2 ; print ACROSS at the top of col 2
	mov si, across_msg
	mov cl, 6
i1: lodsb
	mov ah, 0x0f
	stosw
	loop i1

	mov word [next_aloc], 0xa0+col_width*2	; next across clue goes under ACROSS
	
	mov di, col_width*4 + indent*2 ;print DOWN at the top of col 3
	mov si, down_msg
	mov cl, 4
i2:	lodsb
	mov ah, 0x0f
	stosw
	loop i2

	mov word [next_dloc], 0xa0+col_width*4 ; next down clue goes right under DOWNx
	
	mov word [cur_clue], 0x0f31
	mov word [next_clue], clues	
	ret

	;; Main interactive code run after printing the puzzle
	;; BX stores pointer to current grid location in puz file
	;; DX stores location of cursor DL=xpos DH=ypos
	;; insane that I picked dl and dh like that, and it turns out to be
	;; the same values the system interupts use for updating the cursor
main:
	mov ah, 0
	int 0x16					; Read input

	cmp al, 0x1b				; Escape key
	je handle_escape

	;; no idea where these numbers came from, windows doc was different
	;; Got these from here:
	;; https://stackoverflow.com/questions/16939449/how-to-detect-arrow-keys-in-16-bit-dos-code
	cmp ah, 0x4B				; Left arrow
	je handle_left
	cmp ah, 0x48				; Up arrow
	je handle_up
	cmp ah, 0x4d				; Right arrow
	je handle_right
	cmp ah, 0x50				; Down arrow
 	je handle_down

	sub al, 0x41				; I thought this was a clever way to check
	cmp al, 26					; 0x41 < al < 0x5a but it doesn't work -
	ja handle_letter 			; everything else is a letter
								; looking back, this is about where I gave up
	
	jmp main					; infinite main loop 

handle_escape:
	mov di, 0					; clear screen
	mov cx, 0xfa0
	mov ax, 0x0f00
e1: stosw
	loop e1
	
	int 0x20					; and quit
	
	;; move one square to the left, skipping over black squares
	;; and wrapping around to the previous row if dh=0
	;; I think I can do this with much fewer instructions
	;; if I knew how flags worked (dec first, ask questions later)
handle_left:
	cmp word dx, 0 				; if in the top left, go to bottom right
	jne l1					
	mov dh, height-1
	mov dl, width
	jmp l2
l1:	cmp dl, 0					; if furthest left col (x=0)
	jne l2
	mov dl, width				; go to end of previous line
	dec dh
l2:	dec dl						; actually go left
	call load_grid_pos
	cmp byte [bx], 0x2e			; if there is a black square
	je handle_left				; go left once more
	jmp update_cursor

	;; move one square up, skipping and wrapping over edges and black squares
handle_up:
	cmp word dx, 0				; if in the top left, 
	jne u1
	mov dh, height				; go to the bottom right
	mov dl, width-1
	jmp u2
u1:	cmp dh, 0 					; if top row (y=0)
	jne u2
	mov dh, height				; go to the bottom
	dec dl						; of the previous row
u2:	dec dh
	call load_grid_pos
	cmp byte [bx], 0x2e
	je handle_up
	jmp update_cursor

	;; move one square right, skipping and wrapping over edges and black squares
handle_right:
	cmp dl, width-1				; if furthest right col, go to start of line
	jne r2					
	mov dl, 0
	cmp dh, height-1			; if furthest bottom row 
	jne r1
	mov dh, 0					; go to the first row
	jmp r3
r1:	inc dh						; there is an easier way to write this I'm sure
	jmp r3						; but this works and I'm not drawing a flow chart
r2:	inc dl						; for a crappy asm game coded over break
r3:	call load_grid_pos
	cmp byte [bx], 0x2e			; if there is a black square
	je handle_right				; go right once more
	jmp update_cursor	

	;; move one square down, skipping and wrapping over edges and black squares
handle_down:
	cmp dh, height-1			; if furthest bottom row, go to the top row
	jne d2					
	mov dh, 0
	cmp dl, width-1				; if furthest right col 
	jne d1
	mov dl, 0					; go to the top left
	jmp d3
d1:	inc dl					
	jmp d3				
d2:	inc dh			
d3:	call load_grid_pos
	cmp byte [bx], 0x2e			; if there is a black square
	je handle_down				; go down once more
	jmp update_cursor	


	;; displays letter at cursor position
	;; and saves letter to grid in memory
handle_letter:
	;; Write character to cursor position 
	add al, 0x21 				; change offset to capital letters
	mov ah, 0x09
	mov bh, 0
	mov bl, 0x0f
	mov cx, 1
	int 0x10

	;; add to grid in memory
	push ax
	call load_grid_pos
	pop ax
	mov byte [bx], al			; moves character to memory position

	;; checks the solution to see if puzzle is complete
	mov cx, width*height
	mov bx, solution
	mov si, grid
s1:	lodsb
	cmp byte al, [bx]
	jne s2
	inc bx
	loop s1

	jmp handle_win

s2:	jmp handle_right

	;; prints "YOU WIN!" and 
handle_win:	
	mov cx, 9
	mov si, win_msg+puz_len
	mov di, 0xa0*(height+1)*2
	mov ah, 0x0f
w1:	lodsb
	stosw
	loop w1

	mov ah, 0
	int 0x16
	jmp handle_escape
	

win_msg: db "YOU WIN!!", 0
	
	;; reads position from dx (DL=xpos DH=ypos)
	;; and points the current grid position
load_grid_pos:
	mov al, dh
	cbw
	mov cl, width
	mul cl
	add al, dl
	mov bx, grid
	add bx, ax
	ret

	;; updates the cursor location to the current locaiton at dx
	;; jmped to after every keyboard interupt, so jmps to main after
update_cursor:
	push dx						; save dx with logical position
	push bx
	add dh, dh					; calculate video position
	add dl, dl
	inc dh
	inc dl
	mov ah, 2
	mov bh, 0
	int 0x10					; display interupt
	pop bx
	pop dx
	jmp main
	
	;; Pad the rest of the file with null bytes and add
	;; 0x55AA to the end to make the puzzle and code bootable
	;; not really neaded anymore because this is no longer an mbr
%if com=0
	times (510-puz_len)-($-$$) db 0
	dw 0xAA55
%endif
