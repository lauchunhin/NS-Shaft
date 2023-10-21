## Name: Lau Chun Hin Kelvin
## ID: 20693530
## email: chklauaa@connect.ust.hk

.data
title: 		.asciiz "NS-Shaft"
game_win:	.asciiz "You Win!"
game_lose:	.asciiz "You lose!"
sep_line:	.asciiz "\n"

##************** Game Screen Info
width:		.word 300 # the width of the screen
height:		.word 600 # the height of the screen

##************** Game Difficulty Info
max_level:	.word 20 	# The maximum number of level before win. -> needs 21 to get a win
platform_y_speed_update_interval:	.word 5 	# Increase the platform_y_speed every 5 levels.  range of value (-inf, 0)
gravity:	.word 2 	# The gravity (the acceration of the y_speed during falling.) player_speed.y_speed when falling += gravity
##**************

##************ Player Info
player_id:	.word -1
player_size:	.word 20 30 	# Player size = 20(width) x 30(height) pixels
player_locs:	.word 0 0 	# Array to save the current player location
player_speed:	.word 0 0  	# The speed of player (x_speed, y_speed)
player_move_on_platform_speed:     .word 8 	# The base running speed of the player on a platform.
player_falling_x_speed:		.word 4		# The x_speed of the player when it is falling.

#************ Player Life Value
life_value:	.word 10 # 0 = lose
max_life_value:	.word 10
increase_life_value:	.word 1
decrease_life_value:	.word 2
#************

#************** Platform Info
platforms:      .word 0:40 	# the array of the platforms in the screen denoted by (id, x_location, y_location, type).
platform_num:   .word 10  	# the maximum number of platforms in one screen.
platform_size:  .word 100 15 	# Platform size
initial_platform_number:	.word 7 	# The number of initial platforms
initial_platform_data:	.word
                  1 100 150 0 # id = 1, x_loc = 100, y_loc = 150, type = 0 = normal
			      2 150 210 3 # id = 2, x_loc = 150, y_loc = 210, type = 3 = flip-able
			      3 200 270 2 # id = 3, x_loc = 200, y_loc = 270, type = 2 = spring
			      4 150 330 1 # id = 4, x_loc = 150, y_loc = 330, type = 1 = flip-able
			      5 100 390 4 # id = 5, x_loc = 100, y_loc = 390, type = 4 = left_rotation
			      6 50  450 5 # id = 6, x_loc = 50 , y_loc = 450, type = 5 = right_rotation
			      7 0   510 0 # id = 7, x_loc = 0  , y_loc = 510, type = 0 = normal
		  	# The configuration data of the first platform: (id = 1, x_loc = 100, y_loc = 150, type = 0)
current_platform_address:	.word 0 	# The address of the unstable platform in "platforms"
platform_height_distance:	.word 60	# The height distance between two platforms in y axis.
platform_y_speed:		.word -1 	# the speed of all platforms.   negative number for moving upward.
initial_platform_y_speed:	.word -1 	# The initial platform speed.
spring_platform_upward_speed:	.word -6  	# The y_speed of the player after landding on a spring platform.
platform_rotation_speed:	.word 0  	# The rotation speed of the current platform.
base_rotation_speed:		.word 1  	# The absolute value of the rotation speed of the rotating platforms.

#************* Time
# for flip-able type 1 platforms
time_landing_on_unstable_platform:	.word 0   # The time when the player lands on an unstable platform
time_unstable_platform_hold:	.word  500	# the unstable platform exists for 0.5s after the player stands on it.
# for spike type 3 platforms
time_player_getting_hurt:	.word 0 	# The time when the player touches a spine.
time_player_recover_from_hurt:	.word 3000	# The player takes 3 secnods to recover from being hurt.
time_sleep:	.word 100 	# Sleep time

#*************** Keyboard Input
input_key:	.word 0 # input key from the player
move_key:	.word 0 # last processed key for a player movement
buffered_move_key: .word 0 # latest buffered movement input during an in-progress player movement
initial_move_iteration: .word 10 # default number of game iterations for a player movement
move_iteration: .word 0 # remained number of game iterations for last player movement
#***************


.text
main:
	li $v0, 200 	# Create the Game Object = load immediate 200 to $v0 = system call code
	syscall         # invoke the system call specified in $v0

game_level_init:

	# Initialize the game by create Game Objects based on game level
	jal init_game   # jump and link, saves the return address in $ra, $ra = PC + 4 ; go to init_game
    # jump to line 164

	# Main loop
m_loop:
	# Check if the player wins or loses the game
	jal check_game_level_status
	bne $v0, $zero, game_end_status   # Win or lose the game in the current level.

	jal get_time
	add $s0, $v0, $zero         # s0 = v0 = game level status = 0

	# Core procedure, the player runs on a platform or falls in the air.
	jal player_movement

	# The platforms move up. Generate a new platform when needed.
	jal platform_movement

	# If the player gets hurt by spines, he/she recovers after some time.
	jal player_hurt_recover

	# If the player jumps on an unstable platform, the platform breaks after a short time.
	jal unstable_platform_break

	# refresh the screen
	li $v0, 206
	syscall

	add $a0, $s0, $zero
	la $t1, time_sleep
	lw $a1, 0($t1)

	jal have_a_nap
	j m_loop


game_end_status:
        # $v0 holds the game status of current level, $v0 = 1: win; $v0 = 2: lose
	li $t1, 1  # $t1 = constant 1
	li $t2, 2
	bne $v0, $t1, lose  # If $v0 != 1, then $v0 = 2, the player wins.

win:
        # play winning sound (sound_id = 3) for winning the current level
	li $a0, 3
	li $a1, 0
	li $v0, 209
	syscall

	# display game win text
	li $a0, -2 	# special id for win_text
	li $a1, 80
	li $a2, 280
	la $a3, game_win
	li $v0, 203
	syscall # game win

	# refresh screen
	li $v0, 206
	syscall

	li $v0, 10
	syscall

#******Condition: lose
# Logic:
# Implement the losing procedure:
# 1. call syscall 209 to play losing sound ($a0 = sound_id = 2, $a1 = 0 to play once);
# 2. call syscall 203 to display game lose text. The lose_text id is $a0 = -3; location ($a1 = x_loc = 80, $a2 = y_loc = 280);
# 3. call syscall 206 to refresh the screen;
# 4. call syscall 10 to terminate the game execution;
lose:
    # 1. call syscall 209 to play losing sound ($a0 = sound_id = 2, $a1 = 0 to play once);
	li $a0, 2
	li $a1, 0
	li $v0, 209
	syscall

    # 2. call syscall 203 to display game lose text. The lose_text id is $a0 = -3; location ($a1 = x_loc = 80, $a2 = y_loc = 280);
	li $a0, -3 	# special id for lose_text
	li $a1, 80
	li $a2, 280
	la $a3, game_lose
	li $v0, 203
	syscall # game win

    # 3. call syscall 206 to refresh the screen;
	li $v0, 206
	syscall

    # 4. call syscall 10 to terminate the game execution;
	li $v0, 10
	syscall

#--------------------------------------------------------------------
# procedure: init_game
# 1. initialize player and platform locations in the current level;
# 2. create the player;
# 3. create platforms;
# 4. refresh the screen
# 5. initialize game level start time
# 6, initialize step count
#--------------------------------------------------------------------
init_game:
	addi $sp, $sp, -20  # push -> adjust stack for 5 items
	sw $ra, 16($sp)     # 1st in stack = |return address| = 84
	sw $s0, 12($sp)     # 2nd in stack = |      s0      |
	sw $s1, 8($sp)      # 3rd in stack = |      s1      |
	sw $s2, 4($sp)      # 4th in stack = |      s2      |
	sw $s3, 0($sp)      # 5th in stack = |      s3      |

	# 1. initialize player and box locations
	jal init_platform_player_locations   # Randomlhy generate 7 layers of platforms, and the player.
    # jump to line 225

	# 2. create the player
	li $v0, 201
	la $t0, player_id
	lw $a0, 0($t0)	# the id of player is -1. Note that, each object has a unique id.
	la $t0, player_locs
	lw $a1, 0($t0)  # the x_loc of player
	lw $a2, 4($t0)  # the y_loc of player
	syscall 	# Create player: $v0=201

	# 3. update life value
	la $a0, life_value
	lw $a0, 0($a0)
	li $v0, 210
	syscall

	# 4. update layer number
	la $a0, current_platform_address
	lw $a0, 0($a0)	# The address of the current platform
	lw $a0, 0($a0)	# The id of the current platform
	li $v0, 204
	syscall

	# 5. initialize platform vertical speed in y axis.
	la $s0, initial_platform_y_speed
	lw $s0, 0($s0)
	la $s1, platform_y_speed
	sw $s0, 0($s1)

	# 6. refresh the screen
	li $v0, 206
	syscall

ig_exit:
	lw $ra, 16($sp)        # ra = 84
	lw $s0, 12($sp)
	lw $s1, 8($sp)
	lw $s2, 4($sp)
	lw $s3, 0($sp)
	addi $sp, $sp, 20      # pop 5 items from the stack
	jr $ra                 # jump register 84


#--------------------------------------------------------------------
# procedurenit_platform_player_locations
# Initialize platform_locations and player locations of the current level
# read the game_level variable, initialize the Platform_locs, player_locs, Platform_num
# by copying the corresponding data.
#--------------------------------------------------------------------
init_platform_player_locations:
	addi $sp, $sp, -20  # push -> adjust stack for 5 items
	sw $ra, 16($sp)     # 1st in stack = |return address| = 178
	sw $s0, 12($sp)     # 2nd in stack = |      s0      | = addr of initial_platform_data
	sw $s1, 8($sp)      # 3rd in stack = |      s1      | = addr of platforms (all info of platform)
	sw $s2, 4($sp)      # 4th in stack = |      s2      |
	sw $s3, 0($sp)      # 5th in stack = |      s3      | = sp

	la $t3, initial_platform_number  # t3 = addr of initial_platform_number
	lw $t3, 0($t3)                   # t3 = 7

	# Create the first platform object via syscall.
	la $s0, initial_platform_data    # s0 = addr of initial_platform_data
	la $s1, platforms                # s1 = addr of platforms

ibl_initialize_loop:
    # s0 storing the address of the array storing info of initial platforms - 7
    # accessing the info insdie the array initial_platform_data
    # e.g. 1 100 150 0 # id = 1, x_loc = 100, y_loc = 150, type = 0 = normal
	lw $a0, 0($s0)  # arr[0] = id of the initial platform
	lw $a1, 4($s0)  # arr[1] = x_loc of the initial platform.
	lw $a2, 8($s0)  # arr[2] = y_loc of the initial platform.
	lw $a3, 12($s0) # arr[3] = type_index of the intital platform
	li $v0, 202# s0 = addr of
	syscall

	# Save the first platform.
	sw $a0, 0($s1)  	# id
	sw $a1, 4($s1)  	# x_loc
	sw $a2, 8($s1)		# y_loc
	sw $a3, 12($s1)  	# type

	subi $t3, $t3, 1    # t3 storing the number of initial platforms left to be initialised

	bgt $t3, $zero, ibl_continue_initialize # branch to ibl_continue_initialize if $t3 > 0 = branch if still not yet initilaised all platforms
	add $s3, $a0, $zero  	# $s3 saves last id
	add $s2, $a1, $zero  	# $s3 saves last x_loc
	add $t0, $a2, $zero  	# $s3 saves last y_loc
	addi $s1, $s1, 16    	# move to the address of the next platform
	j ibl_finish_load_initial_plrtforms

ibl_continue_initialize:
	li $t0, 1                                 # t0 = 1
    # only add the player on the first platform because there is only one player = when id = 1
	bne $a0, $t0, ibl_next_initial_platform   # if a0(id) != 1, branch to ibl_next_initial_platform line 282
	la $a0, player_id
	lw $a0, 0($a0)
	la $s2, player_locs
	addi $a1, $a1, 20   # The player stands on the middle of the first platform.
	sw $a1, 0($s2)   # x_loc of player

	la $t1, player_size
	lw $t1, 4($t1)   # Player height
	sub $a2, $a2, $t1
	sw $a2, 4($s2)   # y_loc of player, from the bottom of the screen.
	li $v0, 201
	syscall

ibl_next_initial_platform:
	addi $s1, $s1, 16  	# move to the address of the next platform
	addi $s0, $s0, 16	# move to the address of the next initial platform
	j ibl_initialize_loop

ibl_finish_load_initial_plrtforms:

	add $a0, $zero, $s3	# last platform id
	add $a1, $zero, $s2	# last platform x_loc
	add $a2, $zero, $t0	# last platform y_loc

	# number of platforms to randomly generate.
	la $s0, platform_num
	lw $s0, 0($s0)      # s0 = 10
	la $t3, initial_platform_number
	lw $t3, 0($t3)      # t3 = 7
	sub $s0, $s0, $t3   # s0 = 3

	# The y_loc of the next platform
	la $t0, platform_height_distance
	lw $t0, 0($t0)


ibl_raondom_init_platform_loop:

	# Generate x_loc of the next platform
	add $a0, $a1, $zero  	# $a1 holds the x_loc of the last platform
	la $a1, width		# screen Width as the range (0, width) of random location
	lw $a1, 0($a1)
	li $v0, 211
	syscall
	add $a1, $v0, $zero  	# $a1 is the new x_loc of the next (new) platform

	# update y_loc of the next platform
	add $a2, $a2, $t0

	# id of the next platform
	addi $s3, $s3, 1 	# update platform id
	add $a0, $s3, $zero

	# randomly sample the type of the next platform
	li $v0, 212
	syscall
	add $a3, $v0, $zero

	# create platform object
	li $v0, 202
	syscall

	# save the platform information
	sw $a0, 0($s1)  # id
	sw $a1, 4($s1)  # x_loc
	sw $a2, 8($s1)  # y_loc
	sw $a3, 12($s1) # type
	addi $s1, $s1, 16  # move to the address of the next platform

	subi $s0, $s0, 1   # count = 3 = max no. of platforms left to be built in one screen
	bne $s0, $zero, ibl_raondom_init_platform_loop

	# initialize the "current_platform_address" as the address of the first platform
	la $s0, current_platform_address    # s0 = addr of the unstable platform in "platforms"
	la $s1, platforms                   # s1 = addr of first element in platforms
	sw $s1, 0($s0)                      # s1 = id o the

ibl_exit:
	lw $ra, 16($sp)     # sp = 178
	lw $s0, 12($sp)
	lw $s1, 8($sp)
	lw $s2, 4($sp)
	lw $s3, 0($sp)
	addi $sp, $sp, 20   # pop 5 items from stack
	jr $ra              # jump register to 178


#--------------------------------------------------------------------
# procedure: check_game_level_status
# return: $v0=0: continue playing; =1: win; = 2: lose.
# Check the status of the game to continue, win or lose the game.
# If the current level is greater than or equal to the maximum level, win, $v0 = 1
# If the y_loc of the player is greater than or equal to the screen_height, lose, $v0 = 2
# Otherwise, the status is continue, $v0 = 0
#--------------------------------------------------------------------
check_game_level_status:

#***Condition: Check the status of the game to continue, win or lose the game.
# Logic:
# 1. Check if the id of the current platform (stored in "current_platform_address") is
#    greater than or equals to the maximum level ("max_level").
#    If so, that is, the player has reached the bottom of the cave and wins this level. Set $v0 = 1
# 2. Else, check if the "life_value"==0, if so, set $v0 = 2.
# 3. Otherwise, continue the game: $v0 = 0
    la $t0, current_platform_address
	lw $t0, 0($t0)	# The address of the current platform
	lw $t0, 0($t0)	# The id of the current platform
    la $t1, max_level
    lw $t1, 0($t1)
    # 1. Check if the id of the current platform ≥ the maximum level ("max_level").
    bge $t0, $t1, cgls_won
    # not yet won
    la $t2, life_value
    lw $t2, 0($t2)
    # check dead or not
    beq $t2, $zero, cgls_dead
    # still alive
    li $v0, 0
    j cgls_exit

cgls_dead:
    li $v0, 2
    j cgls_exit

cgls_won:
    li $v0, 1
    j cgls_exit

cgls_exit:
    jr $ra








# ****************** Players **********************


#--------------------------------------------------------------------
# procedure: player_movement
# Check if the player is falling or on a platform.
# if the player is falling, call "player_falling"
# if the player is on a platform, call "process_move_input"
#--------------------------------------------------------------------
player_movement:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# Check if player is on a platform
	# load player location before movement.
	la $t0, player_locs
	lw $a0, 0($t0)	# Load player x_loc
	lw $a1, 4($t0)	# Load player y_loc

	jal check_platform_exist    # check if the player is on a platform before move?

	addi $t0, $zero, 0      # t0 = 0
	beq $v0, $zero, pm_player_falling   # $v0 = 0 : the player is not on a platform. Continue falling. x_loc += x_speed. y_speed change, y_loc change.
	addi $t0, $t0, 1 		# set t0 = 1 -> if $v0 = 1: the player is on a platform, process move input.
	beq $v0, $t0, pm_process_move_input #


pm_player_falling:	# The player is not on a platform
	jal player_falling
	j pm_exit

pm_process_move_input:	# The player is on a platform
	# 1. Get input.
	jal get_keyboard_input
	# 2. Move the player according to the input.
	jal process_move_input

pm_exit:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#--------------------------------------------------------------------
# procedure: process_move_input
# Continue any last in-progress movement repesented by move_key, and
# save any latest movement input key during that process to the
# buffer buffered_move_key.
# If no in-progress movement, perform the action of the new keyboard
# input input_key if it is a valid movement input for the player object,
# otherwise perform the action of any buffered movement input key
# if it is a valid movement input.
# If an input is processed but it cannot actually move the player
# object (e.g. due to a wall), no more movements will be made in later
# iterations for this input.
#--------------------------------------------------------------------

process_move_input:
	addi $sp, $sp, -4       # stack for 1 item
	sw $ra, 0($sp)

	la $t6, move_iteration
	lw $t5, 0($t6) # remaining number of game iterations for last movement
	bne $t5, $zero, pmi_last_move # last movement is not completed, so process it

	la $t0, input_key
	lw $t1, 0($t0) # new input key

	la $t0, initial_move_iteration
	lw $t2, 0($t0)
	addi $t2, $t2, -1 # count this game iteration for any new movement
	sw $t2, 0($t6) # first assume new input key is valid
	la $t8, move_key
	sw $t1, 0($t8) # save new input key in case it is a movement key
	j pmi_check_buffer

pmi_last_move:
	la $t0, input_key
	lw $t7, 0($t0) # new input key
	li $t0, 97 # corresponds to key 'a'
	beq $t7, $t0, pmi_buffer
	li $t0, 100 # corresponds to key 'd'
	beq $t7, $t0, pmi_buffer
	j pmi_start_move

pmi_buffer:
	la $t0, buffered_move_key
	sw $t7, 0($t0) # buffer latest movement input of player during the in-progress movement

pmi_start_move:
	addi $t5, $t5, -1 # process last movement for one more game iteration
	sw $t5, 0($t6)
	la $t0, move_key
	lw $t1, 0($t0) # last movement key
	li $a0, 1 	# check_validity  : 1: check if overlap with a wall.
			# 		    0: no needs to check again whether this movement can actually move the object
	j pmi_check

pmi_check_buffer:
	li $a0, 1 # check whether this movement can actually move the player object
	la $t0, buffered_move_key
	lw $t9, 0($t0) # check whether buffered movement input is valid
	sw $zero, 0($t0) # reset buffer
	li $t0, 97 # corresponds to key 'a'
	beq $t1, $t0, pmi_move_left
	li $t0, 100 # corresponds to key 'd'
	beq $t1, $t0, pmi_move_right
	sw $t9, 0($t8) # save buffered input key in case it is a movement key
	addi $t1, $t9, 0

pmi_check:
	li $t0, 97 # corresponds to key 'a'
	beq $t1, $t0, pmi_move_left
	li $t0, 100 # corresponds to key 'd'
	beq $t1, $t0, pmi_move_right
 	# above assumption of new input key or buffered key being valid is wrong
 	j pmi_no_move

pmi_move_left:
	jal player_move_left
	j pmi_after_move

pmi_move_right:
	jal player_move_right
	j pmi_after_move

pmi_no_move:

	# Set x_speed = 0
	la $t0, platform_rotation_speed
	lw $t0, 0($t0)
	la $t1, player_speed
	sw $t0, 0($t1)

	# Set direction of player. Left: $a1=0.
	li $a0, -1	# id of player
	li $a1, 2 	# $a1 = 2: front
	li $v0, 205
	syscall

	j pmi_before_exit

pmi_after_move:
	# Play key-press sound
	li $a0, 1
	li $a1, 0
	li $v0, 209
	syscall

pmi_before_exit:
	# Update the y_speed of the player
	jal player_move_up_on_platform

	# Update player location according to player speed.
	la $t0, player_speed
	la $t1, player_locs

	# Update x_loc
	lw $t2, 0($t0)
	lw $t3, 0($t1)
	add $t3, $t3, $t2
	sw $t3, 0($t1)

	# Update y_loc
	lw $t2, 4($t0)
	lw $t3, 4($t1)
	add $t3, $t3, $t2
	sw $t3, 4($t1)

	# Check the boundary conditions.
	jal check_boundary

	# Update player location via syscall
	la $t0, player_id   # -1
	lw $a0, 0($t0)		# Player id: -1
	la $t0, player_locs
	lw $a1, 0($t0)	# x_loc : $a1
	lw $a2, 4($t0)	# y_loc : $a2
	li $v0, 207 		# syscall set player location
	syscall          	# set new object location of the player.

	# Reset move_iteration
	la $t0, move_iteration
	sw $zero, 0($t0)

pmi_exit:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#--------------------------------------------------------------------
# procedure: player_move_left
# Move the player left on the platform, determined by its speed and input direction.
# If the player is going to cross the boarder, block the movement.
#--------------------------------------------------------------------
player_move_left:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# player running speed.
	la $t0, player_move_on_platform_speed
	lw $t0, 0($t0)

	# rotation speed of the current platform.
	la $t1, platform_rotation_speed
	lw $t1, 0($t1)

	# compute overall speed
	sub $t0, $t1, $t0

	# set the x speed of the player
	la $t2, player_speed
	sw $t0, 0($t2)

	# Set direction of player. Left: $a1=0.
	li $a0, -1	# id of player
	li $a1, 0 	# $a1 = 0: left
	li $v0, 205
	syscall # set new player direction to left

pml_exit:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#--------------------------------------------------------------------
# procedure: player_move_right
# Move the player right on the platform, determined by its speed and input direction.
# If the player is going to cross the boarder, block the movement.
#--------------------------------------------------------------------
player_move_right:

#*****Set the horizontal speed and the direction of the player when the input command is "move right".
# Logic:
# 1. Compute the player overall x_speed according to the player running speed "player_move_on_platform_speed"
#    and the platform rotation speed "platform_rotation_speed".
# 2. Update the x_speed of the player in "player_speed"
# 3. Set the direction of the player via syscall 205. ($a0: player_id = 01, $a1: direction) (direction:  0: left, 1: right, 2:front )

    addi $sp, $sp, -4
	sw $ra, 0($sp)

	# player running speed.
	la $t0, player_move_on_platform_speed
	lw $t0, 0($t0)

	# rotation speed of the current platform.
	la $t1, platform_rotation_speed
	lw $t1, 0($t1)

	# compute overall speed
	sub $t0, $t1, $t0

	# set the x speed of the player
	la $t2, player_speed
	sw $t0, 0($t2)

	# Set direction of player. Right: $a1=1.
	li $a0, -1	# id of player
	li $a1, 1 	# $a1 = 1: left
	li $v0, 205
	syscall # set new player direction to left

pmr_exit:
    lw $ra, 0($sp)
	addi $sp, $sp, 4
    jr $ra


#--------------------------------------------------------------------
#Procedure: check_boundary
#Check if the updated player location is out of game screen. If so, reset the x_loc in to 0 or width. If the player moves out of the upper bound, it may gets hurt or lose the game.
#--------------------------------------------------------------------
check_boundary:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

#********Condition: Check if the player exceeds the horizontal boundaries.
# Logic:
# 1. Load the x_loc from "player_locs", if x_loc < 0, the player exceeds the left boundary, set x_loc = 0.
#    if (x_loc + player_width) > width, the player exceeds the right boundary, x_loc = "width" - player_widh
#    player_widh is stored in "player_size"[0], screen width is stored in "width".
#    Else, jump to "cb_check_y_boundary" to continue.
# 2. If the player exceeds a boundary, reverse its x_speed: x_speed = 0 - x_speed.
    # load x_loc
    la $t0, player_locs
	lw $t1, 0($t0)	# x_loc of player

    # Check exceed left boundary
    blt $t1, $zero, cb_reset_x         # if x_loc < 0 = player exceeds the left boundary
    la $t2, player_size
    lw $t2, 0($t2)                     # storing the player_width 20
    la $t3, width
    lw $t3, 0($t3)                     # storing the width 300
    add $t4, $t1, $t2                  # storing x_loc + player_width
    ble $t4, $t3, cb_check_y_boundary  # if (x_loc + player_width) <= width , branch to cb_check_y_boundary
    # player exceeds the right boundary
    sub $t1, $t3, $t2                  # x_loc = "width" - player_width
    sw $t1, 0($t0)
    j cb_exceed_boundary

cb_reset_x_zero:
    # reset x_loc to 0
    addi $t1, $zero, $zero       # x_loc = 0
    sw $t1, 0($t0)

# reverse its speed as it exceeds a boundary
cb_exceed_boundary:
    la $t1, player_speed
	lw $t5, 0($t1)       # x_speed
    sub $t5, $zero, $t5
	sw $t5, 0($t1)
    j cb_exit


# **** Y *****
cb_check_y_boundary:
	la $t0, player_locs
	lw $t1, 4($t0)	# y_loc of player

	# Check upper boundary.
	la $t2, player_size
	lw $t2, 4($t2)
	bgt $t1, $t2, cb_exit

	# When (player_size - 3 < y_loc < player_size), the player gets hurt by the upper spines.
	sub $t2, $t2, 1
	bgt $t1, $t2, cb_hit_upper_spine

	sub $t2, $zero, $t2
	bgt $t1, $t2, cb_exit

	# The player loses game when the player is fully out of the screen. (y_loc < -1 * player_height)
	jal player_lose
	j cb_exit

cb_hit_upper_spine:	# The player hits the upper spine if y_loc <= player_height.
	li $a0, 0 	# $a0 = 0 for reduce life value.
	jal update_player_life_value

cb_exit:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#--------------------------------------------------------------------
#Procedure: player_move_up_on_platform
#Update the y_speed of the player when it is standing on a platform.
#Note that when the player is standing on a spring, it will jump as it moves.
#This procedure does not update the y_loc of the player.
#--------------------------------------------------------------------
player_move_up_on_platform:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# *** Y ***
	la $t0, current_platform_address
	lw $t0, 0($t0)	# The address of the current platform
	lw $t0, 12($t0)	# The type of the current platform
	li $t1, 2 	# type of Spring platform = 2

	bne $t0, $t1, pmuop_process_y_no_jump   # branch to pmuop_process_y_no_jump if type of currentt platform is not spring

	la $t1, spring_platform_upward_speed
	lw $t1, 0($t1)
	j pmuop_process_y_after_jump

pmuop_process_y_no_jump:
	li $t1, 0

pmuop_process_y_after_jump:
	la $t0, platform_y_speed
	lw $t2, 0($t0)
	add $t2, $t1, $t2 	# Overall y_speed of the player
	la $t1, player_speed
	sw $t2, 4($t1)

pmuop_exit:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#--------------------------------------------------------------------
# procedure: player_hurt_recover
# If the player is hurted, then after "time_player_recover_from_hurt", the player should get recoverd.
#--------------------------------------------------------------------
player_hurt_recover:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $t0, time_player_getting_hurt
	lw $t2, 0($t0)

	beq $t2, $zero, phr_exit
	jal get_time
	sub $v0, $v0, $t2
	la $t1, time_player_recover_from_hurt
	lw $t1, 0($t1)

	blt $v0, $t1, phr_exit
	sw $zero, 0($t0)

	# Player hurt -> recover
	li $a0, -1
	li $a1, 0 	# $a1 = 0 hurt = false
	li $v0, 213
	syscall

phr_exit:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#--------------------------------------------------------------------
# procedure: player_lose
# player lose the game by falling or hitting the top.
# Set life value to 0.
#--------------------------------------------------------------------
player_lose:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $t0, life_value
	addi $t1, $zero, 0
	sw $t1, 0($t0)

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#--------------------------------------------------------------------
# procedure: update_player_life_value
# input: $a0: 0 for reduce life_value, 1 for recover_life_value.
#--------------------------------------------------------------------
update_player_life_value:

# ****** Update the life value of the player.
# Logic:
# 1. If $a0==0, decrease life value. If $a0==1, increase life value.
# 2. Increase case:
#       a) set "life_value" += "increase_life_value"
#       b) if "life_value" > "max_life_value", set "life_value" = "max_life_value".
#       c) Syscall 210 with $a0 = "life_value" to update life value for display.
# 3. Decrease case:
#       a) set "life_value" -= "decrease_life_value"
#       b) if "life_value" < 0, set "life_value" = 0.
#       c) Syscall 210 with $a0 = "life_value" to update life value for display.
#       d) Syscall 213 with $a0 = "player_id", $a1=1 to set player being hurt. (0 for normal and 1 for hurt.)
#       e) Syscall 209 with $a0 = 4 (hurt sound id), $a1 = 0 (play it once), to play hurt sound.
#       f) Get time via the procedure get_time and save the current time to time_player_getting_hurt.
# 4. Exit
    # decrease life value if $a0 == 0
    li $t0, $zero
    beq $t0, $a0, uplv_decrease
    #increase life value
    # a) set "life_value" += "increase_life_value"
    la $t0, life_value
    lw $t1, 0($t0)
    la $t2, increase_life_value
    lw $t2, 0($t2)
    add $t1, $t1, $t2
    sw $t1, 0($t0)
    # b) if "life_value" > "max_life_value", set "life_value" = "max_life_value".
    la $t2, max_life_value
    bgt $t1, $t2, uplv_max_life
    # c) Syscall 210 with $a0 = "life_value" to update life value for display.
    la $a0, life_value
	lw $a0, 0($a0)
	li $v0, 210
    j uplv_exit

uplv_decrease:
    # a) set "life_value" -= "decrease_life_value"
    la $t0, life_value
    lw $t1, 0($t0)
    la $t2, decrease_life_value
    lw $t2, 0($t2)
    sub $t1, $t1, $t2
    sw $t1, 0($t0)
    # b) if "life_value" < 0, set "life_value" = 0.
    blt $t1, $zero, uplv_min_life
    # c) Syscall 210 with $a0 = "life_value" to update life value for display.
    la $a0, life_value
	lw $a0, 0($a0)
	li $v0, 210
	syscall
    # d) Syscall 213 with $a0 = "player_id", $a1=1 to set player being hurt. (0 for normal and 1 for hurt.)
    li $a0, -1
	li $a1, 1 	# $a1 = 0 hurt = false
	li $v0, 213
	syscall
    # e) Syscall 209 with $a0 = 4 (hurt sound id), $a1 = 0 (play it once), to play hurt sound.
    li $a0, 4
	li $a1, 0
	li $v0, 209
	syscall

    # f) Get time via the procedure get_time and save the current time to time_player_getting_hurt.
    # Please update the time_player_getting_hurt variable after the life value decreases.
    la $t0, time_player_getting_hurt
    jal get_time   # return $vo = current time
	sw $v0, 0($t0)
    j uplv_exit

uplv_max_life:
    # set "life_value" = "max_life_value".
    la $t0, life_value
    la $t1, max_life_value
    lw $t1, 0($t1)
    sw $t1, 0($t0)

uplv_min_life:
    # set "life_value" = 0.
    la $t0, life_value
    la $t1, max_life_value
    lw $t1, 0($t1)
    sw $t1, 0($t0)

uplv_exit:
    li $v0, 0
    jr $ra


#--------------------------------------------------------------------
# procedure: player_falling
# The player falls in the air with an accereration.
# The player may hit wall or a platform during falling.
# If the player is going to cross the wall or a platform, block the move operation.
# Three cases: continue falling, falling out of screen and lose, and landing on a platform.
#--------------------------------------------------------------------
player_falling:
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)


	la $t2, player_falling_x_speed
	lw $t2, 0($t2)

	la $s1, player_speed
	lw $t3, 0($s1) 	# x_speed

	blt $t3, $zero, pf_x_speed_lt
	bgt $t3, $zero, pf_x_speed_gt
	j pf_after_x_speed_check

pf_x_speed_lt:
	sub $t2, $zero, $t2

pf_x_speed_gt:
	sw $t2, 0($s1)

pf_after_x_speed_check:

	lw $t3, 4($s1) # y_speed
	la $t4, gravity
	lw $t4, 0($t4)
	add $t3, $t3, $t4		# Update y_speed

	# Invoke player falling
	la $s0, player_locs
	lw $t0, 0($s0)	# x_loc of player before move
	lw $t1, 4($s0)	# y_loc of player before move

	lw $t2, 0($s1)
	add $t0, $t0, $t2 	# Update x_loc

	sw $t3, 4($s1)
	add $t1, $t1, $t3 	# Update y_loc
	sw $t1, 4($s0)

# Check player exceeds y boundary
	la $s1, height
	lw $s1, 0($s1)
	bge $t1, $s1, pf_player_lose  # branch to pf_player_lose if t1(y_loc) >= s1 (600)

# Check player exceeds x boundary.
	blt $t0, $zero, pf_exceeds_left_boundary
	la $t5, width
	lw $t5, 0($t5)       # t5 = 300
	la $t6, player_size
	lw $t6, 0($t6)
	sub $t5, $t5, $t6    # t5 = 300 - 20 = 280
	bgt $t0, $t5, pf_exceeds_right_boundary # brand to pf_exceeds_right_boundary if x_loc > 280
	sw $t0, 0($s0)
	j pf_check_platform

pf_exceeds_left_boundary:
	# Set x_loc
	addi $t0, $zero, 0
	sw $t0, 0($s0)

	# Reverse x_speed
	la $s1, player_speed
	lw $t2, 0($s1) # x_speed
	sub $t2, $zero, $t2
	sw $t2, 0($s1)

	j pf_check_platform

pf_exceeds_right_boundary:
	# Set x_loc
	add $t0, $t5, $zero
	sw $t0, 0($s0)

	# Reverse x_speed
	la $s1, player_speed
	lw $t2, 0($s1) # x_speed
	sub $t2, $zero, $t2
	sw $t2, 0($s1)

pf_check_platform:
	# check platform exist
	# hit platform if :y_loc of platform in range [y_loc,  y_loc + player_height)
	jal check_platform_exist
	beq $v0, $zero, pf_continue_falling
	addi $t0, $zero, 1
	beq $v0, $t0, pf_land_on_platform

pf_player_lose:
	jal player_lose
	j pf_exit

pf_land_on_platform:
	li $v0, 1
	j pf_exit

pf_continue_falling:
	li $v0, 0

pf_exit:
	la $s0, player_id
	la $s1, player_locs
	lw $a0, 0($s0)
	lw $a1, 0($s1)
	lw $a2, 4($s1)
	li $v0, 207
	syscall

	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	jr $ra


# ****************** Platforms **********************


#--------------------------------------------------------------------
# procedure: platform_movement
# Move each platform upward according to the platform_speed.  (y_loc = y_loc - platform_speed)
# Increase the speed of all platforms.
#--------------------------------------------------------------------
platform_movement:
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)

	la $s0, platforms
	la $s1, platform_num
	lw $s1, 0($s1)


	la $s2, platform_y_speed
	lw $s2, 0($s2)

	lw $t1, 8($s0)	# y_loc of the highest platform before movement
	add $t1, $t1, $s2
	bge $t1, $zero, platm_loop

	jal destroy_and_create_platform

platm_loop:
	subi $s1, $s1, 1
	# Move platform up by y_loc = y_loc + platform_y_speed
	lw $t1, 8($s0)
	add $t1, $t1, $s2
	sw $t1, 8($s0)

	# Update object location
	lw $a0, 0($s0)

	lw $a1, 4($s0)
	lw $a2, 8($s0)

	li $v0, 207
	syscall

	addi $s0, $s0, 16
	bne $s1, $zero, platm_loop

	# The platform moves faster gradually.
	jal update_platform_speed

platm_exit:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	jr $ra


#--------------------------------------------------------------------
# procedure: process_landing_on_new_platform
# player lands on a new platform.
# Input: $a0: the address of the new platform in "platforms"
# First, we conduct default operations by 1). resetting the y_speed of the player as platform_y_speed.
# 2). reset the platform_rotation_speed to zero.
# Then, we branch to conduct platform-specific operations, by checking the type of the platform.
#  type=0, normal platform, recover life value via update_player_life_value($a0=1).
#  type=1, un-stable platform, reset the time_landing_on_unstable_platform to current time by calling get_time().
#  type=2, spring platform, set the y_speed of the player to spring_platform_upward_speed.
#  type=3, spine platform, decrease life value via update_player_life_value($a0=0).
#  type=4, left-rotating platform, set the rotation speed of the current platform (platform_rotation_speed) to -1 * base_rotation_speed.
#  type=5, right-rotating platform, set the rotation speed of the current platform (platform_rotation_speed) to base_rotation_speed.
#--------------------------------------------------------------------
process_landing_on_new_platform:

#******* Take different actions when the player lands on different platforms.
# Logic:
# 1. Take defaults operations:
#    i) reset y_speed (in "player_speed") of the player as "platform_y_speed".
#    ii) reset the rotation speed of the current platform to 0.
#    iii) save the address of the current platform from $a0 to "current_platform_address"
# 2. Load the platform type form the current platform address and compare with [0, 1, 2, 3, 4, 5]
#    If type = 0, increase life value via "update_player_life_value" with $a0 = 1
#    If type = 1, call "get_time" and save the current time from $v0 to "time_landing_on_unstable_platform"
#    If type = 2, set player y_speed = "spring_platform_upward_speed" + "platform_y_speed",
#                 y_speed of player is stored in "player_speed"
#    If type = 3, decrease life value via "update_player_life_value" with $a0 = 0
#    If type = 4, set "platform_rotation_speed" = 0 - "base_rotation_speed"
#    If type = 5, set "platform_rotation_speed" = "base_rotation_speed"
	addi $sp, $sp, -24  # adjust stack for 4 items
	sw $ra, 0($sp)      # | s4 |
	sw $s0, 4($sp)      # | s3 | = current_platform_address
	sw $s1, 8($sp)      # | s2 | = platform_rotation_speed
	sw $s2, 12($sp)     # | s1 | = platform_y_speed
	sw $s3, 16($sp)     # | s0 | = player_speed
	sw $s4, 20($sp)     # | ra | <- sp

    # Default Operations
    # Reset player_y_speed = platform_y_speed
    la $s0, player_speed
    la $s1, platform_y_speed
    lw $t0, 0($s1)           # platform_y_speed
    sw $t0, 4($s0)           # reset player_y_speed

    # Reset platform_rotation_speed = 0
    la $s2, platform_rotation_speed
    add $t1, $zero, $zero    # t1 = 0
    sw $t1, 0($s2)           # rest platform_rotation_speed

    # save the address of the current platform from $a0 to "current_platform_address"
    la $s3, current_platform_address
    sw $a0, 0($s3)           # addr of $a0 saved in current_platform_address

    # Branch to different platforms specifically
    # Load the platform type form the current platform address
    lw $t0, 0($s3)	         # The address of the current platform
    lw $t0, 12($t0)	         # The type of the current platform
    # compare the platform type with [0, 1, 2, 3, 4, 5]
    # If type = 0
    li $t1, $zero            # t1 = count = 0
    beq $t0, $t1, plnp_normal_type
    # If type = 1
    addi $t1, 1              # t1 = count = 1
    beq $t0, $t1, plnp_flip_type
    # If type = 1
    addi $t1, 1              # t1 = count = 2
    beq $t0, $t1, plnp_spring_type
    # If type = 1
    addi $t1, 1              # t1 = count = 3
    beq $t0, $t1, plnp_spike_type
    # If type = 1
    addi $t1, 1              # t1 = count = 4
    beq $t0, $t1, plnp_left_rot_type
    # If type = 5, set "platform_rotation_speed" = "base_rotation_speed"
    la $t2, base_rotation_speed
    lw $t2, 0($t2)           # base_rotation_speed
    sw $t2, 0($s2)
    j plnp_exit

# If type = 0, increase life value via "update_player_life_value" with $a0 = 1
plnp_normal_type:
    li $a0, 0 	# $a0 = 1 for increase life value.
	jal update_player_life_value
    j plnp_exit

# If type = 1, call "get_time" and save the current time from $v0 to "time_landing_on_unstable_platform"
plnp_flip_type:
    jal get_time   # return $vo = current time
    la $t2, time_landing_on_unstable_platform
    sw $v0, 0($t2) #save the current time from $v0 to "time_landing_on_unstable_platform"
    j plnp_exit

# If type = 2, set player y_speed = "spring_platform_upward_speed" + "platform_y_speed", y_speed of player is stored in "player_speed"
plnp_spring_type:
    la $t2, spring_platform_upward_speed
    lw $t2, 0($t2)     # spring_platform_upward_speed
    lw $t3, 0($s1)     # platform_y_speed
    add $t2, $t2, $t3  # t2 = "spring_platform_upward_speed" + "platform_y_speed"
    sw $t2, 4($s0)     # reset player_y_speed
    j plnp_exit

# If type = 3, decrease life value via "update_player_life_value" with $a0 = 0
plnp_spike_type:
    li $a0, 0 	# $a0 = 0 for reduce life value.
	jal update_player_life_value
    j plnp_exit

# If type = 4, set "platform_rotation_speed" = 0 - "base_rotation_speed"
plnp_left_rot_type:
    la $t2, base_rotation_speed
    lw $t2, 0($t2)        # base_rotation_speed
    sub $t2, $zero, $t2   # t2 = 0 - base_rotation_speed
    sw $t2, 0($s2)

plnp_exit:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	jr $ra


#--------------------------------------------------------------------
# procedure: check_platform_exist
# Input: $a0: x_loc, $a1: y_loc.   (x_loc, y_loc) is the expected next position of the falling player.
# Output: $v0: 0 if no platform. 1 if exist platform.
# If the input position (x_loc, y_loc) does not loverlap any platform, exit with $v0=0.
#--------------------------------------------------------------------

check_platform_exist:

# ******* Condition: Check if the player is standing on a platform
# Logic:
# 1. load "platforms" and "platform_num"
    la $t0, platforms
    lw $t0, 0($t0)
    la $t1, platform_num
    lw $t1, 0($t1)
    # a0  = x_loc of the expected next position of the falling player.
    # a1  = y_loc of the expected next position of the falling player.
# 2. Loop over all the platforms saved in "platforms"
cpe_loop:
# 3. Check if the player has overlap with any platform:
    # i) Load the the "platform_locs"
    #sw $t2, 4($t0)  	# platform_top_x_loc
	sw $t2, 8($t0)		# platform_top_y_loc
    # "player_locs"
    la $t3, player_locs
    #lw $t4, 0($t3)  # the top_x_loc of player
	lw $t4, 4($t3)   # the top_y_loc of player
    # "platform_size"
    #la $t4, platform_size
    #lw $t5, 0($t4)  # 100 = width
	#lw $t5, 4($t4)  # 15 = height
    # "player_size"
    la $t5, player_size
    #lw $t6, 0($t5)  # 20 = width
	lw $t6, 4($t5)  # 30 = height
    # ii) If platform_top_y_loc < player_top_y_loc: "platforms" address += 16, "platform_num" -= 1 and check the next platform
    blt $t2, $t4, cpe_continue_loop
    # iii) If platform_top_y_loc > player_bottom_y_loc: the player hits no platform, $v0 = 0, exit directly.
    sub $t4, $t4, $t6    # player_bottom_y_loc = player_top_y - player_height
    bgt $t2, $t4, cpe_no_platform

    # if (player_right_x_loc < platform_left_x_loc)
    # calculate player_right_x_loc  = player_top_x_loc + player_width
    sw $t2, 4($t0)    # platform_top_x_loc
    lw $t4, 0($t3)    # the top_x_loc of player
    lw $t6, 0($t5)    # 20 = width
    add $t4, $t4, $t6 # t4 = player_right_x_loc
    # The player hits no platform, $v0 = 0, exit directly.
    blt $t4, $t2, cpe_no_platform

    # if (player_left_x_loc > platform_right_x_loc)
    # calculate platform_rightt_x_loc = platform_top_x_loc + platform_width
    lw $t4, 0($t3)    # the top_x_loc of player
    la $t6, platform_size
    lw $t6, 0($t4)    # 100 = width
    add $t6, $t6, $t2 # platform_rightt_x_loc
    # The player hits no platform, $v0 = 0, exit directly.
    bgt $t4, $t6, cpe_no_platform
    # Otherwise, the player hits a platform.
    # 5. If the player hits a platform:
    # i) Save the y_loc of the player to 4("player_locs") as the (player_y_loc = platform_y_loc - player_height)
    sw $t2, 8($t0)  # platform_top_y_loc
    lw $t6, 4($t5)  # 30 = height
    sub $t1, $t2, $t6
    sw $t1, 4($t3)

    # ii) Update player location via syscall 207: with ($a0="player_id", $a1=0("player_locs"), $a2=4("player_locs"))
    la $t1, player_id   # -1
	lw $a0, 0($t1)		# Player id: -1
	la $t1, player_locs
	lw $a1, 0($t1)	# x_loc : $a1
	lw $a2, 4($t1)	# y_loc : $a2
	li $v0, 207 		# syscall set player location
	syscall          	# set new object location of the player.

    # iii) Update "player_speed" = (0, "platform_y_speed")
    la $t1, player_speed
    add $t2, $zero, $zero
    sw $t2, 0($t1) # set player_x_speed
    la $t2, platform_y_speed
    lw $t2, 0($t2)
    sw $t2, 4($t1) # set player_y_speed

    # 6. Compare to the platform id with the id saved in "current_platform_address".
    la $t1, current_platform_address
	lw $t1, 0($t1)	# The address of the current platform
	lw $t1, 0($t1)	# The id of the current platform

	sw $t2, 0($t0)		# platform id
    # If the ids are the same, the player lands on an old platform (e.g. jumping on a spring platform).
    beq $t1, $t2, cpe_have_platform
    # If the ids are different, the player lands on a new platform.
    # i) Store the **address** of the current platform to "current_platform_address".
    la $t1, current_platform_address
    sw $t0, 0($t1)
    # ii) Update current level via syscall 204 with $a0=current_platform_ID.  (Important for "Level" display)
    la $a0, current_platform_address
	lw $a0, 0($a0)	# The address of the current platform
	lw $a0, 0($a0)	# The id of the current platform
	li $v0, 204
	syscall
    # iii) Call "process_landing_on_new_platform" with $a0="current_platform_address"
    la $a0, current_platform_address
	lw $a0, 0($a0)	# The address of the current platform
    jal process_landing_on_new_platform

    # 7. Before exit, set $v0 = 1
    li $v0, 1   # player is on a platform
    j cpe_exit
    #    End_Loop

cpe_continue_loop:
    addi $t0, $t0, 16  # move to the address of the next platform
    subi $t1, $t1, 1    # t1 storing the number of platforms left to be looped
    j cpe_loop

cpe_have_platform:
    li $v0, 1   # player is not on a platform
    j cpe_exit

cpe_no_platform:
    li $v0, 0   # player is not on a platform

cpe_exit:
    jr $ra


#--------------------------------------------------------------------
# procedure: destroy_and_create_platform
# 1. If the first platform is out of screen (y_loc <= 0), remove the first platform
# element from the array "platforms" and destroy the game object via syscall 208.
# 2. Move each left platform in the array "platforms" leftward.
# 3. Randomly create a new platform via syscall 212.
# 4. Add the generated platform to game objects via syscall 202.
# 5. Add the platform element to the end of the array "platforms"
#--------------------------------------------------------------------
destroy_and_create_platform:

# ***** Destroy the first platform and create a new platform
# As the platform moves up, the first platform moves out of the screen. We need to remove the first
# platform from the "platforms". Create a new platform and save to
# the end of the array.
    # 1. Load "platforms" and "platform_num", compute the count_down value: 4 * ("platform_num" - 1)
    la $t0, platforms
    lw $t0, 0($t0)       # = addr of platforms
    la $t1, platform_num
    lw $t1, 0($t1)
    addi $t2, $t1, -1
    sll $t2, $t2, 2        # saving the count_down_value
    # 2. Destroy the first platform with its id: Syscall 208 with $a0 = id, 0("platforms")
    la $a0, platforms
	lw $a0, 0($a0)	# The address of the current platform
	lw $a0, 0($a0)	# The id of the current platform
    li $v0, 208
    syscall
    # 4. Start looping:
dncp_loop:
    # i) load 16(address), save to 0(address)
    lw $t3, 16($t0)
    sw $t3, 0($t0)
    # ii) update address
    addi $t0, $t0, 16  # move to the address of the next platform
    # iii) update count_down value.
    subi $t2, $t2, 1
    # if count_down value==0, break
    bneq $t2, $zero, dncp_loop

    # 5. Compute the id of the new platform: id = the last id + 1
    addi $t4, $t4, 1

    # The syscall 211 random_x_location requires two inputs:
    # 6. Generate the x_loc of the new platform: x_loc = Syscall_211 ($a0=x_loc of last platform, $a1=screen width)
    lw $a0, 4($t0)
    la $a1, width		# screen Width as the range (0, width) of random location
	lw $a1, 0($a1)
	li $v0, 211
	syscall
    add $a1, $v0, $zero  	# $a1 is the new x_loc of the next (new) platform
    # 7. Compute the y_loc of the new platform: y_loc = y_lof of last platform + "platform_height_distance"
    lw $a2, 8($t0)
    la $t5, platform_height_distance
    lw $t5, 0($t5)
    add $a2, $a2, $t5       # $a2 is the new y_loc of the next new platform
    # 8. Randomly generate the type of the new platform: type = Syscall_212()
	li $v0, 212
	syscall
    add $a3, $v0, $zero  	# $a3 is the new type of the next (new) platform

    # The syscall 202 creates a new platform.
    # 9. Create the new platform object via Syscall_202($a0=id, $a1=x_loc, $a2=y_loc, $a3=type)
    add $a0, $t4, $zero
	li $v0, 202
	syscall
    # 10. Store the information of the new platform to the end of "platforms".
    sw $a0, 0($t0)  # id
	sw $a1, 4($t0)  # x_loc
	sw $a2, 8($t0)  # y_loc
	sw $a3, 12($t0) # type
    # 11. Update the "current_platform_address" via: "current_platform_address" -= 16.
    la $t6, current_platform_address
    lw $t7, 0($t6)
	addi $t7, $t7, -16
    sw $t7, 0($t6)

dncp_exit:
    jr $ra


#--------------------------------------------------------------------
# procedure: unstable_platform_break
#
#--------------------------------------------------------------------
unstable_platform_break:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $t0, time_landing_on_unstable_platform
	lw $t2, 0($t0)
	beq $t2, $zero, upb_exit

	jal get_time
	sub $v0, $v0, $t2

	la $t1, time_unstable_platform_hold
	lw $t1, 0($t1)
	blt $v0, $t1, upb_exit

	# Reset time_landing_on_unstable_platform
	sw $zero, 0($t0)

	# If the current platform is not an unstable platform, exit
	la $t1, current_platform_address
	lw $t1, 0($t1)
	lw $t2, 12($t1)
	li $t3, 1
	bne $t2, $t3, upb_exit

	la $t2, width
	lw $t2, 0($t2)
	addi $t2, $t2, 30
	sw $t2, 4($t1)	# set the x_loc of the unstable platform = width+30, move this platform out of screen.

	lw $a0, 0($t1)
	lw $a1, 4($t1)
	lw $a2, 8($t1)
	li $v0, 207
	syscall 	# Update the location of the platform

upb_exit:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#--------------------------------------------------------------------
# procedure: update_platform_speed
# Increase the "platform_y_speed" gradually. When the current_platform_id increases by 10, the "platform_y_speed" increses by 1.
# platform_y_speed = initial_platform_y_speed - (current_platform_id / platform_y_speed_update_interval)
# 	because platform_y_speed < 0, initial_platform_y_speed < 0, current_platform_id > 0
#--------------------------------------------------------------------
update_platform_speed:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $t0, current_platform_address
	lw $t0, 0($t0)	# The current_platform_address
	lw $t0, 0($t0)	# The current_platform_id
	la $t1, platform_y_speed_update_interval
	lw $t1, 0($t1)
	divu $t0, $t0, $t1

	la $t3, initial_platform_y_speed
	lw $t3, 0($t3)

	sub $t0, $t3, $t0
	la $t2, platform_y_speed 	 # platform_y_speed = initial_platform_y_speed - (current_platform_id / platform_y_speed_update_interval)
	sw $t0, 0($t2)

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra











# *************   Time and Keyboard Input ***************


#--------------------------------------------------------------------
# procedure: get_time
# Get the current time
# $v0 = current time
#--------------------------------------------------------------------
get_time:
	li $v0, 30
	syscall # this syscall also changes the value of $a1
	andi $v0, $a0, 0x3FFFFFFF # truncated to milliseconds from some years ago
	jr $ra


#--------------------------------------------------------------------
# procedure: have_a_nap(last_iteration_time, nap_time)
# This is a sleep function
#--------------------------------------------------------------------
have_a_nap:
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	add $s0, $a0, $a1
	jal get_time
	sub $a0, $s0, $v0
	slt $t0, $zero, $a0
	bne $t0, $zero, han_p
	li $a0, 1 # sleep for at least 1ms
han_p:	li $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
	syscall
	lw $ra, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra


#--------------------------------------------------------------------
# procedure: get_keyboard_input
# $v0: ASCII value of the input character if input is available;
#      otherwise, the value is 0;
# Save the key in "input_key"
#--------------------------------------------------------------------
get_keyboard_input:
	add $t2, $zero, $zero  # t2 = 0
	lui $t0, 0xFFFF        # load upper immediate: t0 = 16 bits = !! all the bits are 1 !!
	lw $t1, 0($t0)         # t1 = 32 bits
	andi $t1, $t1, 1       # t1 = t1 & 1 bit by bit comparison
	beq $t1, $zero, gki_exit  # branch to gki_exit to save the key if input is available
	lw $t2, 4($t0)         # t2 = 1111
gki_exit:
	la $t0, input_key
	sw $t2, 0($t0) # save input key
	jr $ra
