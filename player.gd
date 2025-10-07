extends CharacterBody2D

const normal_speed = 300.0
var SPEED = normal_speed
const JUMP_VELOCITY = -400.0
var roll_speed = 600.0
var direction

var roll_state = false # check if the player is rolling or not


func _physics_process(delta: float) -> void:
	$CanvasLayer/Label.text = "velocity :" + str(abs(velocity.x))
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump and fall
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$animation/roll_timer.start()
		SPEED = roll_speed







	if roll_state == false:
		direction = Input.get_axis("ui_left", "ui_right")


	if Input.is_action_just_pressed("shift"):
		$animation/roll_timer.start()
		$AnimatedSprite2D.play("roll")
		SPEED = roll_speed
		roll_state = true
		$AnimatedSprite2D.offset.y = 0
	elif velocity.y < 0 and roll_state == false:
		$AnimatedSprite2D.play("jump")
		$AnimatedSprite2D.offset.y = -20.0
	elif velocity.y > 0 and roll_state == false:
		$AnimatedSprite2D.play("fall")
		$AnimatedSprite2D.offset.y = -20.0
	elif $animation/roll_timer.is_stopped():
		$AnimatedSprite2D.play("run")
		$AnimatedSprite2D.offset.y = 0

# handels the sprite direction and idle animation
	if direction >0:
		$AnimatedSprite2D.flip_h = false
	elif direction <0:
		$AnimatedSprite2D.flip_h = true
	else:
		if velocity.y < 0  and roll_state == false:
			print("jumping")
			$AnimatedSprite2D.play("jump")
			$AnimatedSprite2D.offset.y = -20.0
		elif velocity.y > 0  and roll_state == false:
			print("falling")
			$AnimatedSprite2D.play("fall")
			$AnimatedSprite2D.offset.y = -20.0
		else:
			if $animation/roll_timer.is_stopped():
				$AnimatedSprite2D.play("idle")
				$AnimatedSprite2D.offset.y = 0
				
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()







func _on_roll_timer_timeout() -> void:
	$animation/Timer.start()
	roll_state = false


func _on_timer_timeout() -> void:
	if SPEED>normal_speed:
		SPEED -=15
