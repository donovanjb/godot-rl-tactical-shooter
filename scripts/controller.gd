extends AIController2D

var move: Vector2 = Vector2(0, 0)
var amt_rotate: float = 0.0
var shoot: bool = false

func get_obs() -> Dictionary:
	# Add player's position and rotation to observations
	#var player_pos = to_local(_player.global_position)
	var obs = []
	
	var player_aim = _player.body_rotate.rotation
	obs.append(player_aim)
	
	## Add enemy positions to observations
	var enemies = _player.get_enemies()
	
	for enemy in enemies:
		var enemy_position: Vector2 = _player.to_local(enemy.global_position)
		obs.append(enemy_position.x)
		obs.append(enemy_position.y)
		
	return {"obs": obs}

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		"move": {
			"size": 2,
			"action_type": "continuous"
		},
		"rotate": {
			"size": 1,
			"action_type": "continuous",
		},
		"shoot": {
			"size": 1,
			"action_type": "discrete",
		}
	}

func set_action(action) -> void:
	move.x = clamp(action["move"][0], -1.0, 1.0)
	move.y = clamp(action["move"][1], -1.0, 1.0)
	amt_rotate = clamp(action["rotate"][0], -1.0, 1.0)
	shoot = action["shoot"]

func get_info() -> Dictionary:
	if done: 
		return {"reward": reward}
	return {}
