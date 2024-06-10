extends CharacterBody2D

# Constants for movement
const MAX_SPEED = 200
const JUMP_FORCE = -400
const GRAVITY = 800
const WALL_JUMP_FORCE = Vector2(200, -400)  # Adjusted for clarity
const STICK_TO_WALL_TIME = 0.6  # Time to stick to the wall
const SLIDE_ACCELERATION = 140  # Acceleration for sliding down the wall
const MAX_SLIDE_SPEED = 500  # Maximum speed for sliding down the wall

# Double jump variables
var can_double_jump = true

# Wall jump variables
var on_wall = false
var wall_direction = 0
var wall_stick_timer = 0.0
var slide_speed = 0.0

func _ready():
	# Initialize anything here
	pass

func _physics_process(delta):
	apply_gravity(delta)
	handle_movement()
	handle_jumping()
	handle_wall_jump()
	handle_wall_stick(delta)

	# Apply movement
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor() and not on_wall:
		velocity.y += GRAVITY * delta

func handle_movement():
	var direction = 0
	if Input.is_action_pressed("ui_right"):
		direction += 1
	if Input.is_action_pressed("ui_left"):
		direction -= 1

	velocity.x = direction * MAX_SPEED

func handle_jumping():
	if Input.is_action_just_pressed("ui_up"):
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
			if Input.is_action_just_pressed("ui_up") and not (wall_direction == get_move_direction()):
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
		if (wall_direction == 1 and Input.is_action_pressed("ui_right")) or (wall_direction == -1 and Input.is_action_pressed("ui_left")):
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

func get_move_direction() -> int:
	var direction = 0
	if Input.is_action_pressed("ui_right"):
		direction += 1
	if Input.is_action_pressed("ui_left"):
		direction -= 1
	return direction

func _is_on_wall(direction: int) -> bool:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = global_position + Vector2(direction * 20, 0)  # Increased to 20 pixels
	query.exclude = [self]
	query.collide_with_bodies = true
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result.size() > 0
