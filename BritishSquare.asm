# File:		BritishSquare.asm
# Author:	Robert Adams
# Section:	01
#
# Description:	This file plays a round of British Square. It gets input
#		from two players, printing the game board after each valid
#		move, then prints an end message when the game is over.
#		Input accepted includes -2 to quit, -1 to skip, or a valid
#		index between 0 and 24. All other inputs result in an error
#		message.
#

#########################################################################
#Constant definitions
#########################################################################


PRINT_INT       = 1             # code for syscall to print integer
PRINT_STRING    = 4             # code for syscall to print a string
READ_INT        = 5             # code for syscall to read an integer

#########################################################################
#Data areas
#########################################################################

	.data
	.align 4
Border:
	.asciiz "***********************\n"

HorizontalDiv:
	.asciiz "*+---+---+---+---+---+*\n"
	
LeftEdge:
	.asciiz "*|"

RightEdge:
	.asciiz "*\n"

NewLine:
	.asciiz "\n"
	
Blanks:
	.asciiz "   |"
	
FillX:
	.asciiz "XXX|"

FillO:
	.asciiz "OOO|"
	
TopDiv:
	.asciiz "  |"
	
BottomDiv:
	.asciiz " |"
	
WelcomeMsg:
	.ascii  "\n****************************\n"
	.ascii  "**     British Square     **\n"
	.asciiz "****************************\n"
	
ErrorMsgBlocked:
	.asciiz "\nIllegal move, square is blocked\n\n"

ErrorMsgFull:
	.asciiz "\nIllegal move, square is occupied\n\n"

ErrorMsgFirst:
	.ascii  "\nIllegal move, can't place first stone "
	.asciiz "of game in middle square\n\n"

ErrorMsgBounds:
	.asciiz "\nIllegal location, try again\n\n"

NoMoveMsgX:
	.asciiz "Player X has no legal moves, turn skipped.\n\n"
	
NoMoveMsgO:
	.asciiz "Player O has no legal moves, turn skipped.\n\n"

InputMsgX:
	.asciiz "Player X enter a move (-2 to quit, -1 to skip move): "

InputMsgO:
	.asciiz "Player O enter a move (-2 to quit, -1 to skip move): "
	
TotalMsgX:
	.asciiz "Game Totals\nX's total="
	
TotalMsgO:
	.asciiz " O's total="

QuitMsgX:
	.asciiz "\nPlayer X quit the game.\n"

QuitMsgO:
	.asciiz "\nPlayer O quit the game.\n"
	
WinMsgX:
	.ascii  "\n************************\n"
	.ascii	"**   Player X wins!   **\n"
	.asciiz	"************************\n"
	
WinMsgO:
	.ascii  "\n************************\n"
	.ascii	"**   Player O wins!   **\n"
	.asciiz	"************************\n"
	
TieMsg:
	.ascii  "\n************************\n"
	.ascii	"**   Game is a tie    **\n"
	.asciiz	"************************\n"

Board:	
	.byte	-1,-1,-1,-1,-1
	.byte	-1,-1,-1,-1,-1
	.byte	-1,-1,-1,-1,-1
	.byte	-1,-1,-1,-1,-1
	.byte	-1,-1,-1,-1,-1



#########################################################################
#main - Sets up the game and contains the logic to play a round.
#	Checks if game is over. If not, makes sure player can move
#	then asks for input. Continues getting input and switching
#	between players until game is over. Then depending on exit
#	conditions, prints appropriate message and quits.
#########################################################################

	.text
	.globl main
	.align 4
	
main:
	addi	$sp, $sp, -20
	sw	$ra, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	sw	$s2, 4($sp)
	sw	$s3, 0($sp)
#stack stuff

	li	$v0, PRINT_STRING
	la	$a0, WelcomeMsg
	syscall
	jal	printBoard
	addi	$s0, $zero, 1		#s0 is player id, 1 for x
	addi	$s3, $zero, -2		#overloaded first move

play_game:

	jal	isOver
	bne	$v0, $zero, play_done	#if game is over, finish
	
	move	$a0, $s0
	jal	canMove
	
	bne	$v0, $zero, make_move	#if you can move, move
	
	li	$v0, PRINT_STRING	#if not, print error and change player
	la	$a0, NoMoveMsgO
	beq	$s0, $zero, no_move_o
	la	$a0, NoMoveMsgX
no_move_o:
	syscall
	addi	$t0, $zero, 1
	xor	$s0, $s0, $t0
	j	play_game
	
make_move:
	li	$v0, PRINT_STRING
	la	$a0, InputMsgO
	beq	$s0, $zero, get_input
	la	$a0, InputMsgX
get_input:
	syscall
	li	$v0, READ_INT
	syscall
	move	$s1, $v0		#s1 is now index.
	addi	$t0, $zero, -2
	beq	$s1, $t0, quit_done
	addi	$t0, $zero, -1
	beq	$s1, $t0, change_player
	
	move	$a0, $s1		#place on board
	move	$a1, $s0		#player
	addi	$a2, $s3, 1		#print errors, overloaded first move
	jal	isValid
	
	beq	$v0, $zero, make_move
	move	$s3, $zero
	la	$t0, Board
	add	$t0, $t0, $s1		#move index into array
	sb	$s0, 0($t0)
change_player:
	jal	printBoard
	addi	$t0, $zero, 1
	xor	$s0, $s0, $t0
	j	play_game
	
	
quit_done:
	move	$s2, $zero		#total o's
	move	$s3, $zero		#total x's
	la	$t9, Board
	addi	$t1, $zero, 25
	move	$t0, $zero
quit_add:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, quit_add_done
	lb	$t2, 0($t9)
	bne	$t2, $zero, quit_more
	addi	$s2, $s2, 1
	j	quit_to_top
quit_more:
	bltz	$t2, quit_to_top
	addi	$s3, $s3, 1
quit_to_top:
	addi	$t9, $t9, 1
	addi	$t0, $t0, 1
	j	quit_add
quit_add_done:				#finished counting, print and exit
	li	$v0, PRINT_STRING
	la	$a0, NewLine
	syscall
	la	$a0, TotalMsgX
	syscall
	li	$v0, PRINT_INT
	move	$a0, $s3
	syscall
	li	$v0, PRINT_STRING
	la	$a0, TotalMsgO
	syscall
	li	$v0, PRINT_INT
	move	$a0, $s2
	syscall
	
	li	$v0, PRINT_STRING
	la	$a0, QuitMsgO
	beq	$s0, $zero, quit_print_end
	la	$a0, QuitMsgX
quit_print_end:
	syscall
	j exit
	
	
play_done:
	move	$s2, $zero		#total o's
	move	$s3, $zero		#total x's
	la	$t9, Board
	addi	$t1, $zero, 25
	move	$t0, $zero
play_add:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, play_add_done
	lb	$t2, 0($t9)
	bne	$t2, $zero, play_more
	addi	$s2, $s2, 1
	j	play_to_top
play_more:
	bltz	$t2, play_to_top
	addi	$s3, $s3, 1
play_to_top:
	addi	$t9, $t9, 1
	addi	$t0, $t0, 1
	j	play_add
play_add_done:				#finished counting, print and exit
	li	$v0, PRINT_STRING
	la	$a0, TotalMsgX
	syscall
	li	$v0, PRINT_INT
	move	$a0, $s3
	syscall
	li	$v0, PRINT_STRING
	la	$a0, TotalMsgO
	syscall
	li	$v0, PRINT_INT
	move	$a0, $s2
	syscall
	
	li	$v0, PRINT_STRING
	slt	$t0, $s2, $s3
	beq	$t0, $zero, check_tie
	la	$a0, WinMsgX
	syscall
	j	exit
check_tie:
	sub	$t0, $s2, $s3
	beq	$t0, $zero, tie
	la	$a0, WinMsgO
	syscall
	j	exit
tie:
	la	$a0, TieMsg
	syscall

exit:

	lw	$ra, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	lw	$s2, 4($sp)
	lw	$s3, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra

	
#########################################################################
#isOver - Calls canMove for both players. If neither player can move,
#	  isOver returns 1. Otherwise, it returns 0.
#########################################################################

isOver:

	addi	$sp, $sp, -20
	sw	$ra, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	sw	$s2, 4($sp)
	sw	$s3, 0($sp)
	
	move	$s0, $zero
	
	addi	$a0, $zero, 1
	jal	canMove
	move	$s1, $v0		#can X move
	
	move	$a0, $zero
	jal	canMove
	move	$s2, $v0		#can O move
	
	bne	$s1, $zero, isOver_exit
	bne	$s2, $zero, isOver_exit
	addi	$s0, $zero, 1
	
isOver_exit:

	move	$v0, $s0
	
	lw	$ra, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	lw	$s2, 4($sp)
	lw	$s3, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra
	
#########################################################################
#canMove - Takes a player ID in a0. For every spot on the board, calls
#	   isValid for the spot and player. Passes zero in a2 so no error
#	   messages are printed for invalid locations. If any isValid
#	   call returns 1, canMove returns 1. Else, it returns 0.
#########################################################################

canMove:
	addi	$sp, $sp, -20
	sw	$ra, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	sw	$s2, 4($sp)
	sw	$s3, 0($sp)
	
	move	$s0, $zero
	move	$s3, $a0
	
	addi	$s2, $zero, 25
	move	$s1, $zero
	
move_check_loop:				#loop to make sure there is a
						#valid possible move
	slt	$t0, $s1, $s2
	beq	$t0, $zero, canMove_exit
	move	$a0, $s1
	move	$a1, $s3
	move	$a2, $zero
	jal	isValid
	addi	$s1, $s1, 1
	beq	$v0, $zero, move_check_loop
	addi	$s0, $zero, 1
	
canMove_exit:

	move	$v0, $s0
	
	lw	$ra, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	lw	$s2, 4($sp)
	lw	$s3, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra
	
#########################################################################
#isValid - Takes 3 arguments: a0 is the board index to check, a1 is the
#	   player to check for, and a2 is a toggle. a2 will be -1 on the
#	   first round, to indicate playing the middle square is invalid.
#	   On all other rounds, it will be either 0, to indicate no error
#	   messages, or 1 to indicate errors should be printed. 
#	   Checks to make sure index passed is within range, the space
#	   is already occupied, the space is not blocked on the top,
#	   bottom, left and right by an enemy piece, and on the first
#	   turn, checks to make sure index isn't 12 (the middle).
#########################################################################


isValid:

	addi	$sp, $sp, -20
	sw	$ra, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	sw	$s2, 4($sp)
	sw	$s3, 0($sp)
	
	move	$s0, $a0		#position to check
	addi	$t0, $zero, 1
	xor	$s1, $a1, $t0		#opponent
	
	addi	$v0, $zero, 1
	
	bgez	$s0, upper_check	#check to make sure value is in range
	beq	$a2, $zero, check_fail
	li	$v0, PRINT_STRING
	la	$a0, ErrorMsgBounds
	syscall
check_fail:
	move	$v0, $zero
	j	isValid_exit
	
upper_check:
	addi	$t0, $zero, 25
	slt	$t1, $s0, $t0
	bne	$t1, $zero, full_check	#check upper bounds
	beq	$a2, $zero, check_fail
	li	$v0, PRINT_STRING
	la	$a0, ErrorMsgBounds
	syscall
	j	check_fail
	
full_check:
	la	$t0, Board		#check if square is empty
	add	$t0, $t0, $s0
	lb	$t1, 0($t0)
	bltz	$t1, first_check
	beq	$a2, $zero, check_fail
	li	$v0, PRINT_STRING
	la	$a0, ErrorMsgFull
	syscall
	j	check_fail
	
first_check:
	addi	$t0, $zero, 12		#check for placement into middle
	bne	$s0, $t0, top_check	#square on the first turn
	bgez	$a2, top_check
	li	$v0, PRINT_STRING
	la	$a0, ErrorMsgFirst
	syscall
	j	check_fail
	
top_check:
	addi	$t0, $zero, 4		#top block check, etc.
	slt	$t1, $t0, $s0
	beq	$t1, $zero, bottom_check
	la	$t0, Board
	add	$t0, $t0, $s0
	addi	$t0, $t0, -5
	lb	$t1, 0($t0)
	bne	$s1, $t1, bottom_check
	beq	$a2, $zero, check_fail
	li	$v0, PRINT_STRING
	la	$a0, ErrorMsgBlocked
	syscall
	j	check_fail
	
bottom_check:
	slti	$t0, $s0, 20
	beq	$t0, $zero, left_check
	la	$t0, Board
	add	$t0, $t0, $s0
	addi	$t0, $t0, 5
	lb	$t1, 0($t0)
	bne	$s1, $t1, left_check
	beq	$a2, $zero, check_fail
	li	$v0, PRINT_STRING
	la	$a0, ErrorMsgBlocked
	syscall
	j	check_fail
	
left_check:
	rem	$t0, $s0, 5
	beq	$t0, $zero, right_check
	la	$t0, Board
	add	$t0, $t0, $s0
	addi	$t0, $t0, -1
	lb	$t1, 0($t0)
	bne	$s1, $t1, right_check
	beq	$a2, $zero, check_fail
	li	$v0, PRINT_STRING
	la	$a0, ErrorMsgBlocked
	syscall
	j	check_fail
	
right_check:
	addi	$t1, $s0, -4
	rem	$t0, $t1, 5
	beq	$t0, $zero, isValid_exit
	la	$t0, Board
	add	$t0, $t0, $s0
	addi	$t0, $t0, 1
	lb	$t1, 0($t0)
	bne	$s1, $t1, isValid_exit
	beq	$a2, $zero, check_fail
	li	$v0, PRINT_STRING
	la	$a0, ErrorMsgBlocked
	syscall
	j	check_fail
	
isValid_exit:	
	
	lw	$ra, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	lw	$s2, 4($sp)
	lw	$s3, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra
	
#########################################################################
#printBoard - Prints out the board in sections, first the top, then the
#	      rows with single digit indexes, then the rows with double
#	      digit indexes. Contains logic to fill in X's or O's when
#	      necessary.
#########################################################################

printBoard:

	addi	$sp, $sp, -20
	sw	$ra, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	sw	$s2, 4($sp)
	sw	$s3, 0($sp)
	
	li	$v0, PRINT_STRING		#print top of board
	la	$a0, NewLine
	syscall
	la	$a0, Border
	syscall
	la	$a0, HorizontalDiv
	syscall
	
	la	$s1, Board
	move	$s2, $zero
	addi	$s3, $s3, 5
	move	$s0, $s1
	move	$t8, $zero
	addi	$t9, $zero, 2
small_loop:					#prints rows with single digit
	slt	$t7, $t8, $t9			#indexes (top 2)
	beq	$t7, $zero, small_loop_end
	la	$a0, LeftEdge
	syscall
	move	$s0, $s1
	move	$t0, $s2
	move	$t1, $s3
top_loop1:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, end_top_loop1
	lb	$t2, 0($s0)
	beq	$t2, $zero, set_o_top1
	bltz	$t2, set_space_top1
	la	$a0, FillX
	j	print_top1
set_o_top1:
	la	$a0, FillO
	j	print_top1
set_space_top1:
	la	$a0, Blanks
print_top1:
	syscall
	addi	$t0, $t0, 1
	addi	$s0, $s0, 1
	j	top_loop1
end_top_loop1:
	la	$a0, RightEdge
	syscall
	la	$a0, LeftEdge
	syscall
	move	$s0, $s1
	move	$t0, $s2
	move	$t1, $s3
	
top_loop2:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, end_top_loop2
	lb	$t2, 0($s0)
	beq	$t2, $zero, set_o_top2
	bltz	$t2, set_space_top2
	la	$a0, FillX
	j	print_top2
set_o_top2:
	la	$a0, FillO
	j	print_top2
set_space_top2:
	li	$v0, PRINT_INT
	move	$a0, $t0
	syscall
	li	$v0, PRINT_STRING
	la	$a0, TopDiv
print_top2:
	syscall
	addi	$t0, $t0, 1
	addi	$s0, $s0, 1
	j	top_loop2
end_top_loop2:
	la	$a0, RightEdge
	syscall
	la	$a0, HorizontalDiv
	syscall
	addi	$s1, $s1, 5
	addi	$s2, $s2, 5
	addi	$s3, $s3, 5
	addi	$t8, $t8, 1
	j	small_loop
	
	
small_loop_end:	
	move	$s0, $s1
	move	$t8, $zero
	addi	$t9, $zero, 3
	

big_loop:					#prints rows with double
	slt	$t7, $t8, $t9			#digit indexes (bottom 3)
	beq	$t7, $zero, big_loop_end
	la	$a0, LeftEdge
	syscall
	move	$s0, $s1
	move	$t0, $s2
	move	$t1, $s3
bottom_loop1:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, end_bottom_loop1
	lb	$t2, 0($s0)
	beq	$t2, $zero, set_o_bottom1
	bltz	$t2, set_space_bottom1
	la	$a0, FillX
	j	print_bottom1
set_o_bottom1:
	la	$a0, FillO
	j	print_bottom1
set_space_bottom1:
	la	$a0, Blanks
print_bottom1:
	syscall
	addi	$t0, $t0, 1
	addi	$s0, $s0, 1
	j	bottom_loop1
end_bottom_loop1:
	la	$a0, RightEdge
	syscall
	la	$a0, LeftEdge
	syscall
	move	$s0, $s1
	move	$t0, $s2
	move	$t1, $s3
	
bottom_loop2:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, end_bottom_loop2
	lb	$t2, 0($s0)
	beq	$t2, $zero, set_o_bottom2
	bltz	$t2, set_space_bottom2
	la	$a0, FillX
	j	print_bottom2
set_o_bottom2:
	la	$a0, FillO
	j	print_bottom2
set_space_bottom2:
	li	$v0, PRINT_INT
	move	$a0, $t0
	syscall
	li	$v0, PRINT_STRING
	la	$a0, BottomDiv
print_bottom2:
	syscall
	addi	$t0, $t0, 1
	addi	$s0, $s0, 1
	j	bottom_loop2
end_bottom_loop2:
	la	$a0, RightEdge
	syscall
	la	$a0, HorizontalDiv
	syscall
	addi	$s1, $s1, 5
	addi	$s2, $s2, 5
	addi	$s3, $s3, 5
	addi	$t8, $t8, 1
	j	big_loop
big_loop_end:
	
	la	$a0, Border			#prints bottom of board
	syscall
	la	$a0, NewLine
	syscall
	
	lw	$ra, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	lw	$s2, 4($sp)
	lw	$s3, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra
	