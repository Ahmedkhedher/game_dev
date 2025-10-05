extends CharacterBody2D

const normal_speed = 300.0
var SPEED = normal_speed
const JUMP_VELOCITY = -400.0


var roll_speed = 600.0


func _physics_process(delta: float) -> void:
	$CanvasLayer/Label.text = "velocity :" + str(abs(velocity.x))
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction >0:
		if Input.is_action_just_pressed("shift"):
			$AnimatedSprite2D.play("roll")
			$animation/roll_timer.start()
			SPEED =roll_speed
			SPEED =lerp(roll_speed,normal_speed,0.5)
		elif $animation/roll_timer.is_stopped():
			$AnimatedSprite2D.play("run")
			$AnimatedSprite2D.flip_h = false

	elif direction <0:
		if Input.is_action_just_pressed("shift"):
			$AnimatedSprite2D.play("roll")
			$animation/roll_timer.start()
			SPEED =lerp(roll_speed,normal_speed,0.5)
		elif $animation/roll_timer.is_stopped():
			$AnimatedSprite2D.play("run")
			$AnimatedSprite2D.flip_h = true
	else:
		if $animation/roll_timer.is_stopped():
			$AnimatedSprite2D.play("idle")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()



func roll_physics():
	var jump_distance = 500
	if Input.is_action_just_pressed("shift"):
		$AnimatedSprite2D.play("roll")


func _on_roll_timer_timeout() -> void:
	SPEED=normal_speed
