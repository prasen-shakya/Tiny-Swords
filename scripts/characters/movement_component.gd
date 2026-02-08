## A reusable movement helper for 2D characters.

class_name MovementComponent
extends Node

@export var speed := 400
@export var body: CharacterBody2D

## Applies a velocity to a CharacterBody2D given a normalized direction vector
func apply_movement(dir: Vector2):
	body.velocity = dir * speed
	body.move_and_slide()

## Sets velocity to zero on a given CharacterBody2D
func stop():
	body.velocity = Vector2.ZERO
	body.move_and_slide()
