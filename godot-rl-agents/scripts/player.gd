extends CharacterBody2D

@export var speed: float = 0.0
@export var lr_flag: bool = false # Enable body left right animation
@export var rotate_flag: bool = true # Enable body rotation 
@export var rotation_speed: float = 20.0 # Rotation speed in radians per second

var screen_size # Size of the game window.
var lr: bool = true # Default face right
var aim_pos: Vector2 = Vector2(0, 0)
var is_shot_cd: bool = false
var total_bullets: int = 10
var ammo: int

# Reference
@onready var body_lr: Polygon2D = $BodyLR
@onready var body_rotate: Polygon2D = $BodyRotate
@onready var body_lr_player: AnimationPlayer = $BodyLRPlayer
@onready var body_rotete_player: AnimationPlayer = $BodyRotatePlayer
@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var bullet_spawn_pos: Node2D = $BodyRotate/BulletSpawnPoint
@onready var shot_timer: Timer = $ShotTimer
@onready var shot_effect: GPUParticles2D = $BodyRotate/ShootingEffect
@onready var body_lr_collider: CollisionPolygon2D = $CollisionBodyLR
@onready var ai_controller = $AIController2D
@onready var game = get_parent()

func _ready():
	screen_size = get_viewport_rect().size
	ai_controller.init(self)
	reload()
	
func _physics_process(delta):
	
	# 1. initializing
	velocity = Vector2.ZERO # The player's movement vector.
	
	if ai_controller.needs_reset:
		ai_controller.reset()
		game.reset()

	var amt_rotate: float = 0.0
	var is_shoot: bool

	# 2. accepting inputs
	if ai_controller.heuristic == "human":
	
		# movement input
		if Input.is_action_pressed("move_right"):
			velocity.x += 1
		if Input.is_action_pressed("move_left"):
			velocity.x -= 1
		if Input.is_action_pressed("move_down"):
			velocity.y += 1
		if Input.is_action_pressed("move_up"):
			velocity.y -= 1
		# rotation input
		if Input.is_action_pressed("rotate_left"):
			amt_rotate -= 1
		if Input.is_action_pressed("rotate_right"):
			amt_rotate += 1
		# shooting input
		if Input.is_action_pressed("shot") and not is_shot_cd:
			is_shoot = true
	else: # non-human inputs
		velocity.x += ai_controller.move[0]
		velocity.y += ai_controller.move[1]
		amt_rotate += ai_controller.amt_rotate
		is_shoot = ai_controller.shoot
		
	# 3. executing actions
	if rotate_flag:
		body_rotate.rotation += amt_rotate * delta * rotation_speed
		ai_controller.reward -= abs(amt_rotate) * delta
	
	if is_shoot and not is_shot_cd and ammo > 0:
		shoot()
		is_shot_cd = true
		shot_timer.start(.2)
		
	# Normalize velocity if move along x and y together
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	if get_enemies() != null and ammo == 0:
		ai_controller.needs_reset = true
		ai_controller.done = true
	# Handle body_lr
	#update_body_lr()

	# Move and clamp position after movement
	move_and_slide()
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

func setup(pos: Vector2):
	position = pos
	reload()
	show()

func get_enemies() -> Array:
	var enemies = []
	
	if game:
		for child in game.get_children():
			if child.name != self.name and child.is_in_group("enemy"):
				enemies.append(child)
	
	return enemies

func update_body_lr():
	if not lr_flag:
		return
	# Play body animation
	if velocity.length() > 0:
		# Move up / down
		if lr:
			body_lr_player.play("MoveR")
		else:
			body_lr_player.play("MoveL")
		# Move left / right
		if velocity.x > 0:
			body_lr_player.play("MoveR")
			body_lr_collider.scale.x = -1
			lr = true
		elif velocity.x < 0:
			body_lr_player.play("MoveL")
			body_lr_collider.scale.x = 1
			lr = false
	else:
		# Idle
		if lr:
			body_lr_player.play("IdleR")
		else:
			body_lr_player.play("IdleL")

func shoot():
	ai_controller.reward -= 0.1
	body_rotete_player.play("Shot")
	var bullet = bullet_scene.instantiate()
	bullet.setup(bullet_spawn_pos.global_transform)
	get_tree().root.add_child(bullet)
	shot_effect.emitting = true
	ammo -= 1

func _on_shot_timer_timeout():
	is_shot_cd = false

func reload():
	ammo = total_bullets

func kill():
	ai_controller.reward += 1.0
