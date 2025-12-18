extends CharacterBody2D

# --- Godot Character Movement Configuration ---

const MOVEMENT_CONFIG = {
	"NORMAL_SPEED": 300.0,
	"CROUCH_SPEED": 150.0,   # Slower speed while crouching
	"JUMP_VELOCITY": -400.0,
	"ROLL_SPEED": 700.0,
	"ACCELERATION": 1500.0,
	"DEACCELERATION": 2500.0,
}

enum PlayerState {
	IDLE, RUN, JUMP, FALL, ROLL,
	CROUCH, CROUCH_RUN,
	ATTACK_STRONG, ATTACK_NORMAL, ATTACK_CROUCH,
}

# --- Member Variables ---

var current_speed: float = MOVEMENT_CONFIG.NORMAL_SPEED
var direction: float = 0.0
var state: PlayerState = PlayerState.IDLE
var is_boosted: bool = false
var is_attacking: bool = false # Internal flag to lock state during animation

# --- Built-in Functions ---

func _ready() -> void:
	_set_state(PlayerState.IDLE)
	# Connect the animation_finished signal to handle attacks automatically
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_input()
	_handle_boost_timer()
	_calculate_horizontal_movement(delta)
	move_and_slide()
	_update_state_and_animation()
	
	$CanvasLayer/Label.text = "State: " + PlayerState.keys()[state] + "\nVelocity: " + str(abs(velocity.x))

# --- Core Logic Functions ---

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _handle_input() -> void:
	# 1. Block movement input if rolling or attacking
	if state == PlayerState.ROLL or is_attacking:
		if state == PlayerState.ROLL: direction = direction # Maintain roll direction
		else: direction = 0 # Stop during ground attacks
		return

	direction = Input.get_axis("move_left", "move_right")

	# 2. Handle Attacks (Check if on floor)
	if is_on_floor():
		if Input.is_action_just_pressed("attack_normal"): # Define these in Input Map
			_start_attack(PlayerState.ATTACK_CROUCH if Input.is_action_pressed("crouch") else PlayerState.ATTACK_NORMAL)
			return
		if Input.is_action_just_pressed("attack_strong"):
			_start_attack(PlayerState.ATTACK_STRONG)
			return

	# 3. Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		_start_jump()

	# 4. Handle Roll
	if Input.is_action_just_pressed("shift") and is_on_floor() and abs(direction) > 0.0:
		_start_roll()

func _start_attack(attack_type: PlayerState) -> void:
	is_attacking = true
	_set_state(attack_type)
	velocity.x = 0 # Usually you want to stop when attacking on ground

func _start_jump() -> void:
	velocity.y = MOVEMENT_CONFIG.JUMP_VELOCITY
	_start_speed_boost()

func _start_roll() -> void:
	_set_state(PlayerState.ROLL)
	_start_speed_boost()

func _start_speed_boost() -> void:
	current_speed = MOVEMENT_CONFIG.ROLL_SPEED
	is_boosted = true
	$animation/roll_timer.start()

func _handle_boost_timer() -> void:
	if is_boosted and $animation/roll_timer.is_stopped():
		is_boosted = false
		current_speed = MOVEMENT_CONFIG.NORMAL_SPEED
		if state == PlayerState.ROLL:
			_set_state(PlayerState.IDLE)

func _calculate_horizontal_movement(delta: float) -> void:
	# Determine speed based on crouch vs normal
	var speed_limit = MOVEMENT_CONFIG.NORMAL_SPEED
	if Input.is_action_pressed("crouch") and is_on_floor():
		speed_limit = MOVEMENT_CONFIG.CROUCH_SPEED
	
	var target_speed = direction * (current_speed if is_boosted else speed_limit)
	var accel = MOVEMENT_CONFIG.ACCELERATION

	if state == PlayerState.ROLL and direction == 0.0:
		accel = 0 # No friction during roll
	elif direction == 0.0:
		accel = MOVEMENT_CONFIG.DEACCELERATION

	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

# --- State and Animation Management ---

func _set_state(new_state: PlayerState) -> void:
	if state == new_state: return
	state = new_state
	
	var y_offset = 0.0
	match state:
		PlayerState.IDLE: $AnimatedSprite2D.play("idle")
		PlayerState.RUN: $AnimatedSprite2D.play("run")
		PlayerState.JUMP: 
			$AnimatedSprite2D.play("jump")
			y_offset = -20.0
		PlayerState.FALL: 
			$AnimatedSprite2D.play("fall")
			y_offset = -20.0
		PlayerState.ROLL: $AnimatedSprite2D.play("roll")
		PlayerState.CROUCH: $AnimatedSprite2D.play("crouch_idle")
		PlayerState.CROUCH_RUN: $AnimatedSprite2D.play("crouch_move")
		PlayerState.ATTACK_NORMAL: $AnimatedSprite2D.play("attack_normal")
		PlayerState.ATTACK_STRONG: $AnimatedSprite2D.play("attack_strong")
		PlayerState.ATTACK_CROUCH: $AnimatedSprite2D.play("attack_crouch")

	$AnimatedSprite2D.offset.y = y_offset

func _update_state_and_animation() -> void:
	# Flip sprite
	if direction > 0: $AnimatedSprite2D.flip_h = false
	elif direction < 0: $AnimatedSprite2D.flip_h = true

	# State Priority Logic
	if is_attacking or state == PlayerState.ROLL:
		return # Let the animation or timer finish

	if not is_on_floor():
		_set_state(PlayerState.JUMP if velocity.y < 0 else PlayerState.FALL)
		return

	# Crouch Logic
	if Input.is_action_pressed("crouch"):
		if abs(velocity.x) > 10.0:
			_set_state(PlayerState.CROUCH_RUN)
		else:
			_set_state(PlayerState.CROUCH)
		return

	# Standard Ground Logic
	if abs(velocity.x) > 10.0:
		_set_state(PlayerState.RUN)
	else:
		_set_state(PlayerState.IDLE)

# --- Callbacks ---

func _on_animation_finished() -> void:
	# Reset attacking flag when attack animations finish
	if state in [PlayerState.ATTACK_NORMAL, PlayerState.ATTACK_STRONG, PlayerState.ATTACK_CROUCH]:
		is_attacking = false
		_update_state_and_animation()

func _on_roll_timer_timeout() -> void:
	pass
