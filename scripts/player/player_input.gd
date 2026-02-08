## A reusable input helper for 2D characters.

class_name InputComponent
extends Node

## Current movement input normalized vector
var move_dir: Vector2

## The normalized vector of the attack direction
var attack_dir: Vector2

## Whether or not the attack button is pressed
var attack_pressed: bool

func update_input():
	# Movement (arrow keys or WASD)
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Attack direction follows movement
	attack_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Attack button pressed 
	attack_pressed = Input.is_action_just_pressed("attack")
