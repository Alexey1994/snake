org 0x7C00

	mov AX, CS
	mov SS, AX
	mov DS, AX

	mov SP, 0x7C00 - (2 * 80 * 50)
	mov BP, SP

	cli

	mov word[8 * 4], int_08
	mov word[8 * 4 + 2], AX

	mov word[9 * 4], int_09
	mov word[9 * 4 + 2], AX

	mov AL, 0x34
	out 0x43, AL
	mov AL, 0
	out 0x40, AL
	mov AL, 128
	out 0x40, AL

	sti

	mov AX, 0xB800
	mov ES, AX

	;set 8x8 font
	mov AH, 0x11
	mov AL, 0x12
	xor BX, BX
	int 0x10

	;clean screen
	xor DI, DI
	xor AX, AX
	mov CX, 2 * 80 * 50
	cld
	rep stosw

	;snake head
	mov word[BP], 0

	call new_apple

handler:
	mov AX, [number_of_ticks]
	and AX, 0x3
	cmp AX, 0
	jz move_snake
	jmp skip_move

move_snake:
	inc word[number_of_ticks]

move_head:
	;SI points to snake head
	mov SI, [snake_head]

	;copy prev head to next head
	mov AX, [BP + SI]
	mov [BP + SI + 2], AX
	mov AX, [BP + SI + 1]
	mov [BP + SI + 2 + 1], AX

	add word[snake_head], 2
	mov SI, [snake_head]

	;add head
	mov AL, [snake_vector_x]
	add [BP + SI], AL
	mov AL, [snake_vector_y]
	add [BP + SI + 1], AL

	;check head borders
	cmp byte[BP + SI], -1
	jnz skip_maximazing_player_x
	mov byte[BP + SI], 79
skip_maximazing_player_x:

	cmp byte[BP + SI], 80
	jnz skip_zeroing_player_x
	mov byte[BP + SI], 0
skip_zeroing_player_x:

	cmp byte[BP + SI + 1], -1
	jnz skip_maximazing_player_y
	mov byte[BP + SI+ 1], 49
skip_maximazing_player_y:

	cmp byte[BP + SI + 1], 50
	jnz skip_zeroing_player_y
	mov byte[BP + SI + 1], 0
skip_zeroing_player_y:

	;test screen character
	mov CL, [BP + SI]
	mov CH, [BP + SI + 1]
	call set_pixel_position
	cmp word ES:[DI], 0
	jz no_eat

	call new_apple

	jmp draw_head

no_eat:
	;clean tail
	mov CL, [BP]
	mov CH, [BP + 1]
	call set_pixel_position
	mov AX, 0
	cld
	stosw

	;shift array right
	push ES
	mov AX, CS
	mov ES, AX
	mov DI, BP
	mov SI, BP
	add SI, 2
	mov CX, [snake_head]
	cld
	rep movsw
	pop ES

	sub word[snake_head], 2


draw_head:
	mov SI, [snake_head]
	mov CL, [BP + SI]
	mov CH, [BP + SI + 1]
	call set_pixel_position
	mov AX, 0 + 8 * 256 * 4
	cld
	stosw

skip_move:
	hlt
	jmp handler


snake_vector_x:
	db 1

snake_vector_y:
	db 0

snake_head:
	dw 0


;in  CL    - x
;in  CH    - y
;out ES:DI - video memory pos
set_pixel_position:
		xor AX, AX
		mov AL, CH
		mov DX, 80
		mul DX
		xor DX, DX
		mov DL, CL
		add AX, DX
		mov DI, AX
		shl DI, 1

		ret


;out  AX - random number
random:
		mov AX, [previous_random_number]
		mov CX, 60611
		mul CX
		add AX, [number_of_ticks]
		mov [previous_random_number], AX
		ret

previous_random_number:
	dw 1


new_apple:
	repeat_apple_pos_generation:
		call random
		xor DX, DX
		mov BX, 80
		div BX
		mov CL, DL

		push CX
		call random
		xor DX, DX
		mov BX, 50
		div BX
		pop CX
		mov CH, DL

		call set_pixel_position

		cmp word ES:[DI], 0
		jnz repeat_apple_pos_generation

		mov AX, 3 + 12 * 256
		cld
		stosw

		ret


align 2
int_08:
		push AX

		inc word[number_of_ticks]

		mov AL, 0x20
		out 0x20, AL
		
		pop AX

		iret

number_of_ticks:
	dw 0

align 2
int_09:
		push AX

		in AL, 0x60
		cmp AL, 0xE0
		jnz test_up_key
		jmp end_key_handler
		test AL, 0x80
		jz test_up_key
		jmp end_key_handler

	test_up_key:
			cmp AL, 72
			jnz test_down_key

			cmp byte[snake_vector_x], 0
			jnz accept_test_up_key
			cmp byte[snake_vector_y], 1
			jnz accept_test_up_key
			jmp end_key_handler

		accept_test_up_key:
			mov byte[snake_vector_x], 0
			mov byte[snake_vector_y], -1
			jmp end_key_handler

	test_down_key:
			cmp AL, 80
			jnz test_left_key

			cmp byte[snake_vector_x], 0
			jnz accept_test_down_key
			cmp byte[snake_vector_y], -1
			jnz accept_test_down_key
			jmp end_key_handler

		accept_test_down_key:
			mov byte[snake_vector_x], 0
			mov byte[snake_vector_y], 1

			jmp end_key_handler

	test_left_key:
			cmp AL, 75
			jnz test_right_key

			cmp byte[snake_vector_x], 1
			jnz accept_test_left_key
			cmp byte[snake_vector_y], 0
			jnz accept_test_left_key
			jmp end_key_handler

		accept_test_left_key:
			mov byte[snake_vector_x], -1
			mov byte[snake_vector_y], 0
			jmp end_key_handler

	test_right_key:
			cmp AL, 77
			jnz end_key_handler

			cmp byte[snake_vector_x], -1
			jnz accept_test_right_key
			cmp byte[snake_vector_y], 0
			jnz accept_test_right_key
			jmp end_key_handler

		accept_test_right_key:
			mov byte[snake_vector_x], 1
			mov byte[snake_vector_y], 0
			jmp end_key_handler

	end_key_handler:

		mov AL, 0x20
		out 0x20, AL

		pop AX

		iret


align 0x7C00 + 510
db 0x55, 0xAA