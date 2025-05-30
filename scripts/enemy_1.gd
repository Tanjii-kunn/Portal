extends CharacterBody2D

var player: Node2D
@onready var area_2d: Area2D = $Area2D
@onready var left: RayCast2D = $left
@onready var right: RayCast2D = $right
@onready var down: RayCast2D = $down
@onready var bullet = preload("res://Scenes/enebullet.tscn")

var speed: int = 70
var dir: int = -1
var detec: bool = false
var float_timer = 0.0
var float_offset = 0.0
var float_speed = 2.0  # speed of up/down float
var shoot_cooldown = 1.5  # seconds between shots
var shoot_timer = 0.0


func _ready() -> void: 
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if $ProgressBar.value > 0:
		if detec and player:
			chase_player(delta)

			shoot_timer -= delta
			if shoot_timer <= 0:
				shoot_at_player()
				shoot_timer = shoot_cooldown
		else:
			wander(delta)
	else:
		var particles = preload("res://Scenes/death.tscn").instantiate()
		particles.global_position = global_position
		get_tree().current_scene.add_child(particles)
		queue_free()

	move_and_slide()


func chase_player(delta: float) -> void:
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * speed

	# Bobbing while chasing
	float_timer += delta * float_speed
	float_offset = sin(float_timer) * 25  # keep it slightly tighter during chase
	velocity.y = float_offset


func wander(delta: float) -> void:
	# Update ray direction
	down.target_position.x = 10 * dir
	down.force_raycast_update()

	# Flip if wall or edge
	if (dir == -1 and left.is_colliding()) or (dir == 1 and right.is_colliding()) or !down.is_colliding():
		dir *= -1

	# Horizontal patrol
	velocity.x = dir * speed

	# Flying bob effect
	float_timer += delta * float_speed
	float_offset = sin(float_timer) * 35  # from -35 to +35 (adjust as needed)
	velocity.y = float_offset

func shoot_at_player():
	if player == null: return

	var bullet_instance = bullet.instantiate()
	bullet_instance.global_position = global_position

	# Aim directly at player
	var dir = (player.global_position - global_position).normalized()
	bullet_instance.direction = dir

	get_tree().current_scene.add_child(bullet_instance)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		detec = true

func _on_exit_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		detec = false
		
func deplet():
	$ProgressBar.value -= Dmg.dmg
