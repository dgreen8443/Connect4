;; CS1022 Introduction to Computing II 2018/2019
; Mid-Term Assignment - Connect 4 - SOLUTION
;
; get, put and puts subroutines provided by jones@scss.tcd.ie
;
;;;; TO DO 
; droppped index into checks instead of loops
; pass into drop doesn't need to store value ( if computer player)
; loop through ech check's R5 
; best check = move for comp
; ALLOW for comp player (can still have 2p)
; print row and column numbers

PINSEL0	EQU	0xE002C000
U0RBR	EQU	0xE000C000
U0THR	EQU	0xE000C000
U0LCR	EQU	0xE000C00C
U0LSR	EQU	0xE000C014

	AREA globals,DATA, READWRITE

BOARD	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0

DROPPED_INDEX
	DCB 0
	
BEST_COLUMN
	DCB 0

BEST_SCORE
	DCB 0
	
COMP_BOOL
	DCB 0
	
PLAYER_COUNT
	DCB 0

PLAYING_COMPUTER
    DCB 0
	
	AREA	RESET, CODE, READONLY
	ENTRY

	; initialise SP to top of RAM
1	LDR	R13, =0x40010000	; initialse SP
	; initialise the console
	BL	inithw

	;
	; your program goes here
	;
init_loop_start
	LDR R0, =BOARD
	MOV R1, #0
	LDR R2, =0x30
	
init_loop
	STRB R2, [R0,R1]
	ADD R1, R1, #1
	CMP R1, #42
	BLT init_loop
	LDR R6, =BOARD1
	MOV R9, #0
;init_test
;	LDRB R8, [R6, R9]      ;code for allowing me to create pre set tables to easily test conditions
;	STRB R8, [R0, R9]
;	ADD R9, R9, #1
;	CMP R9, #41
;	BLE init_test
	LDR R2, =0x00
	LDR R1, =DROPPED_INDEX
	STRB R2, [R1] 			; initialising the globals
	LDR R1, =BEST_SCORE
	STRB R2, [R1]
	LDR R1, =BEST_COLUMN
	STRB R2, [R1]
	BL disp_brd
	LDR R0,=str_go			; check for VS. CPU or 2P
	BL puts
	LDR R0,=str_play_computer
	BL puts
	BL get
	BL put 
	LDR R1, =PLAYING_COMPUTER
	STRB R0, [R1]
	
	LDR R1, =PLAYER_COUNT
	MOV R12, #1 ; player count
	STRB R12, [R1]
	
main
	MOV R3, #0
	CMP R12, #41
	BGE game_over_win			; check for full board
	BL player_div
	CMP R0, #0				; check which player
	BGT pick_p1
	LDR R1, =PLAYING_COMPUTER	;
	LDRB R0, [R1]
	CMP R0, #0x79
	BEQ comp_ask_move
	LDR R0, =str_player2
	B ask_move
	
pick_p1
	LDR R0, =str_player1
	
ask_move

	BL	puts
	BL get
	BL put 
	CMP R0, #0x71				; check for 'q' for a restart request
	BEQ init_loop_start
	SUB R0, R0, #0x30			; get the non-hex value of imput
	CMP R0, #7					
	BGT bad_move
	BL drop
	LDR R7, =DROPPED_INDEX
	LDRB R8, [R7]
	CMP R8, #50					; checks for legit placement
	BEQ ask_move
	BL 	vert_check
	CMP R3, #1
	BEQ game_over_win
	BL horiz_check
	CMP R3, #1
	BEQ game_over_win
	BL diag_left_check
	CMP R3, #1
	BEQ game_over_win
	BL diag_right_check
	CMP R3, #1
	BEQ game_over_win			; checking for a win
	ADD R12, R12, #1
	LDR R11, =PLAYER_COUNT		
	STRB R12, [R11]	
	B	main
	
	
comp_ask_move	
	BL 	comp_move
	
	BL 	vert_check
	CMP R3, #1
	BEQ game_over_win
	BL horiz_check
	CMP R3, #1
	BEQ game_over_win
	BL diag_left_check
	CMP R3, #1
	BEQ game_over_win
	BL diag_right_check
	CMP R3, #1
	BEQ game_over_win				; check for win
	ADD R12, R12, #1
	LDR R11, =PLAYER_COUNT
	STRB R12, [R11]
	B	main
	
bad_move
	LDR R0,=str_Bad_mov
	BL	puts
	BL disp_brd
	B	main
	
game_over_win
	BL game_win
stop	B	stop


;
; your subroutines go here
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Outputs the board
; does not take parameters
; does not return anything

disp_brd
		 PUSH {R4, lr}
		 LDR R0, =str_board
		 BL puts					; load the board and put out
         LDR R3, =BOARD				; every 7th char, put new line
		 LDR R2, =0
new_line LDR R0, str_newl
		 BL put
		 LDR R4, =0
R_loop 	 ADD R4, R4, #1
disp_chr LDRB R0, [ R3, R2]

show 	 BL  put
         ADD R2,R2,#1
		 CMP R2, #42
		 BGE disp_leave
		 CMP R4, #7
		 BEQ new_line
		 BLT R_loop
disp_leave
		 LDR R0, =str_newl
		 BL puts
		 POP {R4, pc}
		 BX  lr
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; R0 is parameter of the user input for column
; returns nothing
; calls disp_brd for moves
drop
		STMFD SP!, {R4-R8,LR}
		MOV R5, R0
		MOV R0, R12
		BL player_div
		CMP R0, #0
		BGT drop_p1
		LDR R4, =0x52 ;; put R
		B	drop_cont
drop_p1
		LDR R4, =0x59 ;; put Y
drop_cont 	
		LDR R1, =BOARD
		MOV R0, R5
		SUB R0, R0, #1
		LDRB R2, [R1, R0]
		CMP R2, #0x30
		BNE not_val					;finds lowest point on board not occupied in column to make move
		MOV R3, R0
		ADD R3, R3, #7
drop_loop
	
		CMP R3, #42
		BGE store_value
		LDRB R2, [R1, R3 ]
		CMP R2, #0x30
		BEQ next_row
store_value 
		LDR R7, =DROPPED_INDEX
		STRB R0, [R7]
		
character_place
		LDR R1, =BOARD
		STRB R4 , [R1, R0]; Get player's value
		BL 	disp_brd
		B	drop_leave
		
next_row
		ADD R3, R3, #7
		ADD R0, R0, #7
		B	drop_loop
		
not_val
		LDR R0, =str_Bad_mov
		LDR R7, =DROPPED_INDEX
		MOV R8, #50					; if col full don't allow drop
		STRB R8, [R7]			;	for comp_move's check
		BL 	puts
		
drop_leave 
		MOV R0, R5
		LDMFD SP!, {R4-R8,PC}
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; decides which player to control

; R0 passed in as player count
; R0 returned as mod ; returned 0 = player 1, returns 1 = player 2

player_div
		STMFD SP!, {R4-R6,LR}
		LDR R4, =PLAYER_COUNT
		LDRB R0, [R4]	
		MOV R1, #2
div_loop 
        CMP R0,R1
		BLT	div_leave
		SUB R0, R0, R1
		B	div_loop

div_leave
		LDMFD SP!, {R4-R6,PC}
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; Checks for a winner
; checks for first non-0 chr
; compares to following non-zeros
; if four of same before first non-zero -> player wins
; stop vert_loop if R7 > 42
; returns R3 as game win state
vert_check
		STMFD SP!, {R4-R8,LR}
		MOV R5, #0
		MOV R6, R0 ; stores R0 value of column to be returned
		MOV R3, #0
		MOV R7, #7
		LDR R1, =BOARD


		LDR R8, =DROPPED_INDEX		;uses data passed by drop to find entered position
		LDRB R0, [R8]
		LDRB R2, [R1, R0]
set_value
		CMP R0, #21					; if highest counter is less than 21 then a victory cannot happen
		BGT vert_exit
		MOV R4, R2 ; set check
		
set_loop
		ADD R5, #1
		LDRB R2, [R1, R0]
		CMP R2, R4
		BNE vert_exit
		ADD R0, R0, R7
		CMP R5, #4
		BEQ vert_win			;if 4 of the same char appear in a row without interuptions, game_win
		B	set_loop
		
vert_win
		MOV R3, #1
		
vert_exit
		MOV R0, R6 ; returns R0 value
		MOV R1, R5
		LDMFD SP!, {R4-R8,PC}
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; checks for a horiztontal winning move
; 
; Parameters: R0 = column or position, depending on player / computer
; Returns R3 for game win state
horiz_check
		STMFD SP!, {R4-R10,LR}
		MOV R6, R0	; stores R0 value to be returned
		MOV R5, #1 ; check counter
		MOV R3, #0
		SUB R0, R0, #1
		LDR R10, =BOARD
		
horiz_loop
		
		LDRB R2, [R10, R0]			; finds dropped position
		CMP R2, #0x30
		BNE horiz_set_value
		ADD R0, R0, #7
		B	horiz_loop

	
horiz_set_value
		MOV R8, R2 ; set character to check against
		BL pos_div		
		MOV R4, R0	;uses R0 as an anchor and r4 as a moving feeler
		
horiz_left
		CMP R4, R1			; how far from left col is pos?
		BEQ right			; moves left  and counts how many in a row
		SUB R4, R4, #1
		LDRB R9, [R10, R4]
		CMP R9, R8
		BNE right
		ADD R5, R5, #1
		CMP R5, #4
		BGE horiz_win
		B	horiz_left
		
right
		MOV R4, R0			; moves back to anchor point

horiz_right
		CMP R4,R2
		BEQ horiz_leave		; does as before but to the right
		ADD R4, R4, #1
		LDRB R9, [R10, R4]
		CMP R9, R8
		BNE horiz_leave
		ADD R5, R5, #1
		CMP R5, #4
		BGE horiz_win
		B	horiz_right

horiz_win
		MOV R3, #1
		
horiz_leave
		MOV R0, R6
		MOV R1, R5
		LDMFD SP!, {R4-R10,PC}

		
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; pos_div finds the first and last position of the current row
; pass R0 as position
; return R1 as first pos and R2 as second pos 

pos_div 
		
		STMFD SP!, {R4-R6,LR}
		MOV R1, #0
		
pos_div_loop 
		ADD R2, R1, #6			; finds the first and final position value of the row that is dropped to
		CMP R0, R2
		BLE	pos_div_leave
		ADD R1, R1, #7
		B	pos_div_loop

pos_div_leave
		LDMFD SP!, {R4-R6,PC}
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;game_win
	
game_win
		STMFD SP!, {R4,LR}
		CMP R12, #41			; checks for full board 
		BGE no_win
		
		BL player_div
		CMP R0, #0				; if game_win passed, finds the player who won
		BGT win_pl1
		LDR R0, =str_pl2
		BL puts
		B	win_out
		
win_pl1
		LDR R0, = str_pl1
		BL puts

win_out
		LDR R0, =str_win
		BL puts
		MOV R3, #1
		B 	win_leave
		
no_win
		LDR R0, =str_no_win
		BL puts
		
win_leave
		
		LDMFD SP!, {R4,PC}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Diagonal win
; R0 is passed in as column or position depending on comp or player
; R3 is returned with 1 = game win / 0 = no game win

diag_left_check
	
		STMFD SP!, {R4-R10,LR}
		MOV R6, R0	; stores R0 value to be returned
		MOV R5, #1 ; check counter
		MOV R3, #0
		SUB R0, R0, #1
		LDR R10, =BOARD

diag_left_loop
		LDRB R2, [R10, R0]
		CMP R2, #0x30
		BNE diag_left_set_value
		ADD R0, R0, #7					; finds dropped position
		B	diag_left_loop

	
diag_left_set_value
		MOV R8, R2 ; set check
		BL pos_div		
		; R1 = 1st pos on row
		; R2 = last pos on row
		SUB R1, R0, R1   ; count how far from left column
		SUB R2, R2, R0		; count how far from right column
		MOV R4, R0
		
diag_left_down
		CMP R1, #0
		BEQ diag_left_up
		ADD R4, R4, #6
		CMP R4, #42
		BGE diag_left_up
		LDRB R9, [R10, R4]
		CMP R9, R8
		BNE diag_left_up
		ADD R5, R5, #1					; same idea from horiz, but moves by 6 to move in a bottom left to top right motion /
		CMP R5, #4
		BEQ diag_left_win
		SUB R1, R1, #1
		B 	diag_left_down
		
		
diag_left_up
		MOV R4, R0
		
left_up
		CMP R2, #0
		BEQ diag_left_leave
		SUB R4, R4, #6
		CMP R4, #0
		BLT	diag_left_leave
		LDRB R9, [R10, R4]
		CMP R8, R9
		BNE diag_left_leave
		ADD R5, R5, #1
		CMP R5, #4
		BEQ diag_left_win
		SUB R2, R2, #1
		B	left_up
		
diag_left_win
		MOV R3, #1
		
diag_left_leave
		MOV R0, R6
		MOV R1, R5
		LDMFD SP!, {R4-R10,PC}
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
; Parameters: R0 = column or position, depending on player / computer
; Returns R3 for game win state
diag_right_check
		STMFD SP!, {R4-R10,LR}
		MOV R6, R0	; stores R0 value to be returned
		MOV R5, #1 ; check counter
		MOV R3, #0
		SUB R0, R0, #1
		LDR R10, =BOARD

diag_right_loop
		LDRB R2, [R10, R0]
		CMP R2, #0x30
		BNE diag_right_set_value
		ADD R0, R0, #7
		B	diag_right_loop

		
diag_right_set_value
		MOV R8, R2 ; set check
		BL pos_div		
		; R1 = 1st pos on row
		; R2 = last pos on row
		SUB R1, R0, R1   ; count how far from left column
		SUB R2, R2, R0		; count how far from right column
		MOV R4, R0
		
diag_right_down
		CMP R1, #0
		BEQ diag_right_up
		ADD R4, R4, #8
		CMP R4, #42
		BGE diag_right_up
		LDRB R9, [R10, R4]
		CMP R9, R8						; same idea as diag_left
		BNE diag_right_up				; moves by 8 to move top left to bottom right direction 
		ADD R5, R5, #1
		CMP R5, #4
		BEQ diag_right_win
		SUB R1, R1, #1
		B 	diag_right_down
		
		
diag_right_up
		MOV R4, R0
		
right_up
		CMP R2, #0
		BEQ diag_right_leave
		SUB R4, R4, #8
		CMP R4, #0
		BLT	diag_right_leave
		LDRB R9, [R10, R4]
		CMP R8, R9
		BNE diag_right_leave
		ADD R5, R5, #1
		CMP R5, #4
		BEQ diag_right_win
		SUB R2, R2, #1
		B	right_up
		
diag_right_win
		MOV R3, #1
		
diag_right_leave
		MOV R0, R6
		MOV R1, R5
		LDMFD SP!, {R4-R10,PC}
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
;Computer move
; goes through col. 1 -> 7
; checks each win cond
; best val for R5 is the move to make


comp_move
		STMFD SP!, {R4-R10, LR}
		MOV R10, #0x30

		LDR R4, =BEST_COLUMN
		LDR R5, =BEST_SCORE
		MOV R6, #0
		STRB R6, [R4]	;reset best score and column to zero every move
		STRB R6, [R5]
		ADD R6, R6, #1
		
best_move_check
		MOV R0, R6
		LDRB R7, [R5]
		BL	drop				; drops and finds position to be dropped into
		LDR R9, =DROPPED_INDEX
		LDRB R8, [R9]
		CMP R8, #50				; if col. full move to next
		BEQ increase
		BL	vert_check
		CMP R1, R7
		BGT	change_score
		BL 	horiz_check
		CMP R1, R7					; if any of the checks have a higher chance of winning, changes BEST_COLUMN and BEST_SCORE
		BGT change_score
		BL diag_left_check
		CMP R1, R7
		BGT	change_score
		BL 	diag_right_check
		CMP R1, R7
		BGT change_score
		LDR  R9, =BOARD
		STRB R10, [R9,R8]
		
increase
		ADD R6, R6, #1
		CMP R6, #7
		BLE	best_move_check				; moves to next colunm
		B	comp_make_move
		
change_score
		STRB R1, [R5]
		STRB R6, [R4]
		LDR  R9, =BOARD
		STRB R10, [R9,R8]
		B	best_move_check
		
comp_make_move
		MOV	R10, #1
		LDRB R0, [R4]
		BL drop					; once all possibilities have been checked, make the best move
		
		LDMFD SP!, {R4-R10, PC}
;
; inithw subroutines
; performs hardware initialisation, including console
; parameters:
;	none
; return value:
;	none
;
inithw
	LDR	R0, =PINSEL0		; enable UART0 TxD and RxD signals
	MOV	R1, #0x50
	STRB	R1, [R0]
	LDR	R0, =U0LCR		; 7 data bits + parity
	LDR	R1, =0x02
	STRB	R1, [R0]
	BX	LR

;
; get subroutine
; returns the ASCII code of the next character read on the console
; parameters:
;	none
; return value:
;	R0 - ASCII code of the character read on teh console (byte)
;
get	LDR	R1, =U0LSR		; R1 -> U0LSR (Line Status Register)
get0	LDR	R0, [R1]		; wait until
	ANDS	R0, #0x01		; receiver data
	BEQ	get0			; ready
	LDR	R1, =U0RBR		; R1 -> U0RBR (Receiver Buffer Register)
	LDRB	R0, [R1]		; get received data
	BX	LR			; return

;
; put subroutine
; writes a character to the console
; parameters:
;	R0 - ASCII code of the character to write
; return value:
;	none
;
put	LDR	R1, =U0LSR		; R1 -> U0LSR (Line Status Register)
	LDRB	R1, [R1]		; wait until transmit
	ANDS	R1, R1, #0x20		; holding register
	BEQ	put			; empty
	LDR	R1, =U0THR		; R1 -> U0THR
	STRB	R0, [R1]		; output charcter
put0	LDR	R1, =U0LSR		; R1 -> U0LSR
	LDRB	R1, [R1]		; wait until
	ANDS	R1, R1, #0x40		; transmitter
	BEQ	put0			; empty (data flushed)
	BX	LR			; return

;
; puts subroutine
; writes the sequence of characters in a NULL-terminated string to the console
; parameters:
;	R0 - address of NULL-terminated ASCII string
; return value:
;	R0 - ASCII code of the character read on teh console (byte)
;
puts	STMFD	SP!, {R4, LR} 		; push R4 and LR
	MOV	R4, R0			; copy R0
puts0	LDRB	R0, [R4], #1		; get character + increment R4
	CMP	R0, #0			; 0?
	BEQ	puts1			; return
	BL	put			; put character
	B	puts0			; next character
puts1	LDMFD	SP!, {R4, PC} 		; pop R4 and PC


;
; hint! put the strings used by your program here ...
;

str_go
	DCB	"Let's play Connect4!!",0xA, 0xD, 0xA, 0xD, 0

str_newl
	DCB	0xA, 0xD, 0x0
	
str_Bad_mov
	DCB "Not a valid move", 0xA, 0xD, 0xA, 0xD,0

str_board
	DCB 0xA, 0xD, "The board now looks like: ", 0xA, 0xD, 0

str_player1
	DCB 0xA, 0xD, "Player 1, make a move, or 'q' to restart", 0xA, 0xD, 0 
str_player2
	DCB 0xA, 0xD, "Player 2, make a move, or 'q' to restart", 0xA, 0xD, 0 

str_play_computer
	DCB "Do you want to play the computer (y) or do you have a friend(anything else) ", 0xA, 0xD, 0

str_pl1
	DCB "Player 1 ",0
str_pl2
	DCB "Player 2 ", 0
str_win
	DCB "congratulations you have won!", 0xA, 0xD, 0

str_no_win
	DCB "There is no winner, game over", 0xA, 0xD, 0
	
BOARD1	DCB	0x30,0x52,0x59,0x59,0x52,0x52,0x30
	DCB	0x30,0x59,0x52,0x52,0x59,0x59,0x52
	DCB	0x30,0x52,0x59,0x59,0x52,0x52,0x59
	DCB	0x59,0x59,0x52,0x52,0x59,0x59,0x52
	DCB	0x59,0x52,0x59,0x59,0x52,0x52,0x59
	DCB	0x59,0x59,0x52,0x52,0x59,0x59,0x52

	END
