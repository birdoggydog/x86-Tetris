assume	cs:code,  ds:code
code  segment
start:
	cli
	mov  	ax, code
	mov  	ds, ax
	push 	ds
	call	initialize ;; draws the blank board, blah blah blah
	pop	ds
mainloop:
	call 	incpiece
	mov	si,offset piecenumber
	mov	ax,[si]
	mov	ah,0
	mov	cx,8
	mul	cx	
	add	ax,offset piecex_line
	mov	si,ax
	call	setcurrentpiece
	call	showcurrentpiece
	mov	dl,0
	mov	dh,0
	call	canmovedown
	cmp	al,0
	jz	quit
	
movedownloop:	
	in	al,64h
	and	al,1
	jnz	waskey
movedownret:
	mov	dl,1
	mov	dh,0
	call	canmovedown
	cmp	al,0
	jz	wrapmove		
	call	showcurrentpiece
	call	incpiecerow
	call	showcurrentpiece
	call	wastesometime
	jmp	movedownloop
;	jmp	mainloop
wrapmove:
	call	clearfulls
	jmp	mainloop
waskey:
	
	in	al,60h ; get it
	cmp	al,4bh	;left
	jz	keyleft
	cmp	al,4dh ;right
	jz	keyright 
	cmp	al,39h	;space?
	jz	space
	call	clearkeybuffer
	jmp	movedownret
quit: 
	mov 	ah, 0
	int 	21h
clearkeybuffer:
	in	al,60h	;read from buffer
	in	al,64h	;read from command
	and	al,1	
	jnz	clearkeybuffer
	ret

space:
	call	clearkeybuffer
	push	dx
	;call	canrotate
	;cmp	al,1
	;jnz	endspace
	call	showcurrentpiece
	call	rotate
	call	showcurrentpiece
endspace:
	pop	dx	
	jmp	movedownret
keyleft:
	call	clearkeybuffer
	push	dx
	mov	dl,0
	mov	dh,2
	call	canmovedown
	cmp	al,0
	jz	endleft	
	call	showcurrentpiece
	mov	dl,0
	call	incpiececol
	call	showcurrentpiece
endleft:
	pop	dx
	jmp	movedownret
keyright:

	call	clearkeybuffer
	push	dx
	mov	dl,0
	mov	dh,1
	call	canmovedown
	cmp	al,0
	jz	endright
	call	showcurrentpiece
	mov	dl,1
	call	incpiececol
	call	showcurrentpiece
endright:
	pop	dx
	jmp	movedownret
wastesometime:
	push	cx
	mov 	cx,0
wasteloop:
	add	cx,1
	cmp	cx,10000
	jnz	wasteloop	
	pop	cx
	ret
canmovedown:
	push	si
	push	cx
	push	bx
	push	dx
	call 	showcurrentpiece
	mov	si,offset currentpiecex
	mov	cx, 0
canmovedownloop:
	mov	bl,[si+4]
	pop	dx
	add	bl,dl
	mov	bh,[si]
	cmp	dh,2
	jz	decrementbh	
	add	bh,dh
continuecanmove:
	push	dx	
	call	getpixel
	cmp	al,7
	jz	faildown
	add	si,1
	add	cx,1
	cmp	cx,4
	jnz 	canmovedownloop
	jmp	successdown
faildown:
	mov	al,0
	jmp	finishdowncheck
successdown:
	mov 	al,1
	jmp	finishdowncheck
finishdowncheck:
	call	showcurrentpiece
	pop	dx
	pop	bx
	pop	cx
	pop	si
	ret
decrementbh:
	dec	bh
	jmp	continuecanmove
incpiececol:
	push	si
	push	cx
	push	bx
	mov	si,offset currentpiecex
	mov	cx,0
	mov	bx,0
inccolloop:
	mov	bh,[si]
	cmp	dl,0
	jz	colleft
	inc	bh
	jmp 	contcolinc
colleft:
	dec	bh	
contcolinc:
	mov	[si],bh
	add	si,1
	add	cx,1
	cmp	cx,4
	jnz	inccolloop
	
	pop	bx
	pop	cx
	pop	si
	ret
incpiecerow:
	push	si
	push	cx
	push	bx
	mov	si,offset currentpiecex
	add	si,4
	mov	cx,0
	mov	bx,0
incrowloop:
	mov	bh,[si]
	add	bh,1
	mov	[si],bh
	add	si,1
	add	cx,1
	cmp	cx,4
	jnz	incrowloop
	
	pop	bx
	pop	cx
	pop	si
	ret
incpiece:
	push	ax
	push	si
	
	mov	si,offset rotatenumber
	mov	ax,0
	mov	[si],ax	
	mov	si,offset piecenumber
	mov	ax,[si]
	add	ax,1
	mov	ah,0
	cmp	ax,7
	jz 	reset
	jmp	set
reset:	
mov	ax,0
set:
	mov	si,offset piecenumber
	mov	[si],ax
	pop	si
	pop	ax
	ret
initialize:	
	mov 	bx, 0h
rowloop:	
	push 	bx
	mov	bx, 0h
columnloop:		pop 	ax
	push 	ax
	push 	bx
	mov 	bx, 80
	mul	bx
	pop 	bx
	add	ax, bx
	shl 	ax, 1
	mov	si, ax
	cmp	si,3360
	jg	blank
	cmp	si, 3200
	jge	floor
	;push ds here?
	cmp 	bx, 0
	jz	wall
	cmp 	bx,11
	jz	wall
blank:
	mov	cl, '*'
	mov	[si],cl
	mov	cl,0
	mov	[si+1],cl
	jmp contloop
wall:
	mov 	cl,'|'
	mov	[si],cl
	mov	cl,7
	mov	[si+1],cl
	jmp	contloop
floor:
	cmp	si, 3221
	jg	blank
	mov	cl,'-'
	mov	[si],cl
	mov	cl,7
	mov	[si+1],cl
contloop:
	call 	draw
	add 	bx, 1
	cmp	bx, 80
	jnz	columnloop
	pop 	bx
	add 	bx, 1
	cmp 	bx, 25
	jnz	rowloop
	mov	bx, 0
draw:
	mov	ax,0b800h
	mov	ds,ax	;es is vram
	ret
getpixel:
	push	si
	push	ds
	push	cx
	push	ax
	call	draw
	mov	ax,80
	mul	bl
	mov	cx, 0
	mov	cl,bh
	add	ax, cx
	mov 	cx,2
	mul	cx
	mov	si,ax
	pop	ax
	mov	al,[si+1]
	pop	cx
	pop	ds
	pop	si
	ret
setpixel:
	push	si
	push 	ds
	push	ax
	push 	cx
	call	draw
	mov	ax,80
	mul	bl
	mov	cx, 0
	mov	cl,bh
	add	ax, cx
	mov 	cx,2
	mul	cx
	mov	si,ax
	pop 	cx
	pop	ax
	mov	[si+1],al
	pop 	ds
	pop	si
endset:
	ret
showcurrentpiece:
	push	si
	push	ax
	push	cx	
	push	bx
	mov	si, offset currentpiecex
	mov	bl,[si+4]
	mov	bh,[si]
	call	getpixel
	cmp	al,7
	jz	turnblack
	mov	ax,7
	jmp	show
turnblack:
	mov	ax,0
show:
	mov	cx, 0
	mov	si,offset currentpiecex	
showloop:
	mov	bl,[si+4]
	mov	bh,[si]
	call	setpixel
	add	cx,1
	add	si, 1
	cmp	cx,4
	jnz	showloop
	pop	bx
	pop	cx
	pop 	ax
	pop	si
	ret

setcurrentpiece:
	push	ds
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ax,0
	mov	dx,0
storeloop:	
	mov	dl,[si]
	push	dx
	add	si,1
	add	ax,1
	cmp	ax,8
	jnz	storeloop
	mov	si,offset currentpiecex
	add	si,7
	mov	ax,0
restoreloop:
	pop	dx
	mov	[si],dl
	sub	si,1
	add	ax,1
	cmp	ax,8
	jnz	restoreloop
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	ds
	ret
clearfulls:
	push	si
	push	dx
	push	ax
	push	cx
	push	bx
	mov	bl,19
	mov	bh,1
clearrowloop:
	push	bx
	call	getpixel
	pop	bx
	cmp	al,7
	jnz	failrow	
	add	bh,1
	cmp	bh,11
	jnz	clearrowloop
	jmp	sucrow
failrow:
	
	mov	bh,1
	dec	bl
	cmp	bl,0
	jnz	clearrowloop
	jmp	endclearfulls
	
sucrow:
	push	bx
sucloop:
	mov	bh,10
	call	copyabovebelow
	dec	bl
	cmp	bl,0
	jnz	sucloop
	pop	bx
	mov	bh,1
	mov	bl,19
	jmp	clearrowloop
endclearfulls:
	pop	bx
	pop	cx
	pop	ax	
	pop	dx
	pop	si
	ret	
copyabovebelow:
	push	bx
	dec	bl
	call	getpixel
	inc	bl
	call	setpixel
	pop	bx	
	dec	bh
	cmp	bh,0
	jnz	copyabovebelow
	ret

rotate:
	push	ds
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ax,1234h
	mov	cx,0
	mov	ax,offset currentpiecex
	mov	si,ax
	mov	ax,0
	mov	dx,0
rotstoreloop:	
	mov	dl,[si]
	push	dx
	add	si,1
	add	ax,1
	cmp	ax,8
	jnz	rotstoreloop
	
	mov	si,offset piecenumber
	mov	ch,0
	mov	cl,[si]
	mov	ax,32
	mul	cx
	mov	bx,ax ; piece offset

	mov	si,offset rotatenumber
	mov	al,[si]
	mov	ah,0
	mov	ch,0
	mov	cl,8
	mul	cx ;rotation offset
	
	add	ax,bx ; add them to locate matrix location
	mov	bx,offset linerotations
	add	ax,bx
	
	add	ax,7
	mov	bx,ax
	mov	si,offset currentpiecex
	add	si,7
	mov	ax,0
rotrestoreloop:
	push	si
	mov	si,bx
	mov	cl,[si]
	pop	si
	pop	dx
	cmp	cl,5
	jz	sub1
	cmp	cl,6
	jz	sub2
	cmp	cl,7
	jz	sub3
	jmp	addem
retfromsub:
	mov	[si],dl
	sub	si,1
	sub	bx,1
	add	ax,1
	cmp	ax,8
	jnz	rotrestoreloop
	call	incrotate
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	ds
	ret
addem:
	add	dl,cl
	jmp	retfromsub
sub1:
	dec	dl
	jmp	retfromsub
sub2:
	sub	dl,2
	jmp	retfromsub
sub3:
	sub	dl,3
	jmp	retfromsub
incrotate:
	push	si
	push	ax
	mov	ax,offset rotatenumber
	mov	si,ax
	mov	ax,[si]
	inc	ax
	cmp	ax,4
	jz	zeroize
zeroized:
	mov	[si],al
	pop	si
	pop	ax
	ret			
zeroize:
	mov	ax,0
	jmp	zeroized
	
piecex_line	db      5,5,5,5
piecey_line	db      0,1,2,3
piecex_l	db      5,6,7,5
piecey_l	db      0,0,0,1
piecex_r	db      5,6,7,7
piecey_r	db      0,0,0,1
piecex_s	db      5,6,6,7
piecey_s	db      1,1,0,0
piecex_z	db      5,6,6,7
piecey_z	db      0,0,1,1
piecex_t	db      5,6,7,6
piecey_t	db      0,0,0,1
piecex_box	db      5,6,5,6
piecey_box	db      0,0,1,1

linerotations:piecelinx_rot_1 db	5,0,1,2
pieceliny_rot_1y db      0,5,6,7
piecelinx_rot_2 db	1,0,5,6
pieceliny_rot_2y db	0,1,2,3
piecelinx_rot_3 db	5,0,1,2
pieceliny_rot_3y db      0,5,6,7
piecelinx_rot_4 db	1,0,5,6
pieceliny_rot_4y db	0,1,2,3
piece_l_rot_1 db	1,0,5,0
piece_l__rot_1y db	0,1,2,5
piece_l_rot_2 db	1,0,5,2
piece_l_rot_2y db	1,0,5,0
piece_l_rot_3 db	6,5,0,5
piece_l_rot_3y db	1,0,5,2
piece_l_rot_4 db	0,1,2,5
piece_l_rot_4y db	6,5,0,5
piece_r_rot_1 db	1,0,5,6
piece_r__rot_1y db	0,1,2,1
piece_r_rot_2 db	1,0,5,0
piece_r_rot_2y db	1,0,5,6
piece_r_rot_3 db	6,5,0,1
piece_r_rot_3y db	1,0,5,0
piece_r_rot_4 db	0,1,2,1
piece_r_rot_4y db	6,5,0,1
piece_s_rot_1 db	0,5,0,5
piece_s_rot_1y db	5,0,1,2
piece_s_rot_2 db	0,1,0,1
piece_s_rot_2y db	1,0,5,6
piece_s_rot_3 db	0,5,0,5
piece_s_rot_3y db	5,0,1,2
piece_s_rot_4 db	0,1,0,1
piece_s_rot_4y db	1,0,5,6
piece_z_rot_1 db	1,0,5,6
piece_z_rot_1y db	0,1,0,1
piece_z_rot_2 db	5,0,1,2
piece_z_rot_2y db	0,5,0,5
piece_z_rot_3 db	1,0,5,6
piece_z_rot_3y db	0,1,0,1
piece_z_rot_4 db	5,0,1,2
piece_z_rot_4y db	0,5,0,5
piece_t_rot_1   db	1,0,5,5
piece_t_rot_1y   db	0,1,2,0
piece_t_rot_2   db	1,0,5,1
piece_t_rot_2y   db	1,0,5,5
piece_t_rot_3   db	6,5,0,0
piece_t_rot_3y   db	1,0,5,1
piece_t_rot_4   db	0,1,2,0
piece_t_rot_4y   db	6,5,0,0
piece_sq_rot_1 db	0,0,0,0
piece_sq_rot_1y db	0,0,0,0
piece_sq_rot_2 db	0,0,0,0
piece_sq_rot_2y db	0,0,0,0
piece_sq_rot_3 db	0,0,0,0
piece_sq_rot_3y db	0,0,0,0
piece_sq_rot_4 db	0,0,0,0
piece_sq_rot_4y db	0,0,0,0

piecenumber db       0
rotatenumber db    0
currentpiecex db      0,0,0,0
currentpiecey db      0,0,0,0
placeholderx db      0,0,0,0
placeholdery db      0,0,0,0
code ends
	end start

