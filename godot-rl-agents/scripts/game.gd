extends Node2D

var start_pos: Vector2
var enemy_list: Array = []

@onready var camera: Camera2D = $Camera2D
@onready var enemy_class = preload("res://scenes/enemy.tscn")
@onready var player: CharacterBody2D = $Player
@onready var screen_size

func _ready():
	screen_size = get_viewport_rect().size
	start_pos = Vector2(screen_size.x/2, screen_size.y/2)
	player.setup(start_pos)

func _process(_delta: float):
	if enemy_list.size() == 0:
		# refresh ammo
		player.reload()
		
		# respawn enemies
		var n = 3
		for i in range(0, n):
			
			#var pos = self.position + Vector2(randf_range(100, screen_size.x - 100), randf_range(100, screen_size.y - 100))
			var pos = self.position + Vector2(100, randf_range(100, screen_size.y-100))
			var enemy = enemy_class.instantiate()
			enemy.connect("enemy_destroyed", on_enemy_destroyed)
			
			enemy.setup(pos, player)
			get_tree().root.add_child(enemy)
			enemy_list.append(enemy)

func on_enemy_destroyed(enemy):
	player.kill()
	enemy_list.erase(enemy)
	
func reset():
	# Remove existing enemies
	for e in enemy_list:
		e.queue_free()
	enemy_list.clear()
	
	# Reset player position and state
	player.setup(start_pos)
