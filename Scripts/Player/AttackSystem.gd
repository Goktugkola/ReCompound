extends Node
var attack_action = ""
var shoot_action = ""
var special_action = ""
@export var attack_cooldown: float = 0.5
@export var bullet_scene: PackedScene
@export var hurtbox : Area2D
#-------------apply_knockback_and_	 damage() 
#-------------her saldırıya özel eklenicek ve target nodeu collisiondetectionla belirlenecek

# Internal state
var can_attack: bool = true

# Signals
signal shoot

func _ready():
	var player_id = get_parent().get_meta("player_id")

	if player_id == 1:
		attack_action = "ui_attack_p1"
		shoot_action = "ui_shoot_p1"
		special_action = "ui_special_p1"

	if player_id == 2:
		attack_action = "ui_attack_p2"
		shoot_action = "ui_shoot_p2"
		special_action = "ui_special_p2"

	pass # Replace with function body.
func _process(delta):
	if Input.is_action_just_pressed(shoot_action):
		handle_shooting()
	elif Input.is_action_just_pressed(attack_action):
		var parent = get_parent()
		handle_attack1(parent.is_on_floor(),parent.velocity)
	pass
func get_target() -> Array:
	return hurtbox.get_overlapping_areas()

func apply_knockback_and_damage(knockback: Vector2, damage: int):
	var targets = get_target()
	print(targets)
	for target in targets:
		if target.get_parent().has_method("apply_knockback"):
			target.get_parent().apply_knockback(knockback)
func handle_attack1(is_on_floor: bool, velocity: Vector2):
	if is_on_floor:
		if velocity.x != 0:
			perform_dash_attack(Vector2(400,0), 5)
		else:
			perform_standing_attack(Vector2(200,-200), 5)
	else:
		perform_air_attack()

func perform_dash_attack(knockback: Vector2,damage: int):
	print("Dash Attack")
	apply_knockback_and_damage(knockback,damage)
func perform_standing_attack(knockback: Vector2,damage: int):
	print("Standing Attack")
	apply_knockback_and_damage(knockback,damage)

func perform_air_attack():
	print("Air Attack")

func handle_attack2():
	# Placeholder for special attack
	print("Special Attack")


#Shooting
func handle_shooting():
	if can_attack:
		can_attack = false
		emit_signal("shoot")
		perform_shooting_attack()
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
func perform_shooting_attack():
	print("Shooting Attack")
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
