extends CharacterBody2D

# Constants for movement
const MAX_SPEED = 200
const JUMP_FORCE = -400
const GRAVITY = 800
const WALL_JUMP_FORCE = Vector2(200, -400)  # Adjusted for clarity
const STICK_TO_WALL_TIME = 0.6  # Time to stick to the wall
const SLIDE_ACCELERATION = 140  # Acceleration for sliding down the wall
const MAX_SLIDE_SPEED = 500  # Maximum speed for sliding down the wall
const DASH_SPEED = 600  # Speed of the dash
const DASH_DURATION = 0.2  # Duration of the dash in seconds

# Double jump variables
var can_double_jump = true

# Wall jump variables
var on_wall = false
var wall_direction = 0
var wall_stick_timer = 0.0
var slide_speed = 0.0

# Dash variables
var is_dashing = false
var dash_timer = 0.0
var dash_direction = 0

# Player-specific input actions
var move_right_action = ""
var move_left_action = ""
var jump_action = ""
var dash_action = ""

func _ready():
	# Initialize input actions based on metadata
	var player_id = get_meta("player_id")
	if player_id == 1:
		move_right_action = "ui_right_p1"
		move_left_action = "ui_left_p1"
		jump_action = "ui_up_p1"
		dash_action = "ui_dash_p1"
	elif player_id == 2:
		move_right_action = "ui_right_p2"
		move_left_action = "ui_left_p2"
		jump_action = "ui_up_p2"
		dash_action = "ui_dash_p2"

func _physics_process(delta):
	apply_gravity(delta)
	handle_movement()
	handle_jumping()
	handle_wall_jump()
	handle_wall_stick(delta)
	handle_dash(delta)

	# Apply movement
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor() and not on_wall and not is_dashing:
		velocity.y += GRAVITY * delta

func handle_movement():
	if not is_dashing:
		var direction = 0
		if Input.is_action_pressed(move_right_action):
			direction += 1
		if Input.is_action_pressed(move_left_action):
			direction -= 1

		velocity.x = direction * MAX_SPEED

func handle_jumping():
	if Input.is_action_just_pressed(jump_action):
		if is_on_floor():
			velocity.y = JUMP_FORCE
			can_double_jump = true
		elif can_double_jump and not (on_wall and (wall_direction == get_move_direction())):
			velocity.y = JUMP_FORCE
			can_double_jump = false

func handle_wall_jump():
	var direction = get_move_direction()
	if not is_on_floor() and direction != 0:
		if _is_on_wall(direction):
			if not on_wall:
				wall_stick_timer = STICK_TO_WALL_TIME  # Reset stick timer when first sticking to the wall
				slide_speed = 0.0  # Reset slide speed when first sticking to the wall
			on_wall = true
			wall_direction = direction
			velocity.y = 0  # Stick to the wall
			if Input.is_action_just_pressed(jump_action) and not (wall_direction == get_move_direction()):
				# Wall jump
				velocity.y = WALL_JUMP_FORCE.y
				velocity.x = WALL_JUMP_FORCE.x * wall_direction
				on_wall = false  # Reset wall state after jump
		else:
			on_wall = false
			wall_direction = 0
	else:
		on_wall = false
		wall_direction = 0

func handle_wall_stick(delta):
	if on_wall:
		if (wall_direction == 1 and Input.is_action_pressed(move_right_action)) or (wall_direction == -1 and Input.is_action_pressed(move_left_action)):
			wall_stick_timer -= delta
			if wall_stick_timer <= 0:
				# Apply progressive sliding
				slide_speed = min(slide_speed + SLIDE_ACCELERATION * delta, MAX_SLIDE_SPEED)
				velocity.y = slide_speed
			else:
				velocity.y = 0  # Stick to the wall
				can_double_jump = true  # Regain double jump
		else:
			on_wall = false  # Stop sticking if the move key is not held

func handle_dash(delta):
	if Input.is_action_just_pressed(dash_action) and not is_dashing:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_direction = get_move_direction()
		velocity = Vector2(dash_direction * DASH_SPEED, 0)
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = Vector2(0, velocity.y)

func get_move_direction() -> int:
	var direction = 0
	if Input.is_action_pressed(move_right_action):
		direction += 1
	if Input.is_action_pressed(move_left_action):
		direction -= 1
	return direction

func _is_on_wall(direction: int) -> bool:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = global_position + Vector2(direction * 20, 0)
	query.exclude = [self]
	query.collide_with_bodies = true
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result.size() > 0
