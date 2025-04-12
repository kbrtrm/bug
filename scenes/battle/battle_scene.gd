extends Node2D

@export var enemy_scene: PackedScene
@export var enemy_positions: Array[Vector2] = []

var active_enemies: Array = []
var battle_ended: bool = false

@onready var battle_manager: BattleManager = $BattleManager
@onready var hand_manager: HandManager = $BattleManager/HandManager
@onready var deck_manager: DeckManager = $BattleManager/DeckManager
@onready var player_health_bar: ProgressBar = $UI/PlayerHealthBar
@onready var player_energy_label: Label = $UI/PlayerEnergyLabel
@onready var turn_indicator: Label = $UI/TurnIndicator
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var combine_button: Button = $UI/CombineButton
@onready var card_combiner: CardCombiner = $CardCombiner

func _ready() -> void:
	# Connect UI signals
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	combine_button.pressed.connect(_on_combine_button_pressed)
	
	# Connect battle manager signals
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.turn_ended.connect(_on_turn_ended)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.player_health_changed.connect(_on_player_health_changed)
	
	# Connect card combiner signals
	card_combiner.combination_created.connect(_on_combination_created)
	card_combiner.combination_cancelled.connect(_on_combination_cancelled)
	
	# Hide card combiner initially
	card_combiner.visible = false
	
	# Initialize player health display
	player_health_bar.max_value = GameManager.player_max_health
	player_health_bar.value = GameManager.player_health
	
	# Spawn enemies for this battle
	spawn_enemies()
	
	# Start battle
	battle_manager.player_health = GameManager.player_health
	battle_manager.player_max_health = GameManager.player_max_health
	battle_manager.start_battle(active_enemies)

func spawn_enemies() -> void:
	# Determine which enemies to spawn based on current level
	var enemy_types = []
	var level = GameManager.current_level
	
	if level <= 2:
		# Easy enemies for early levels
		enemy_types = ["beetle", "ant", "spider"]
	elif level <= 5:
		# Medium difficulty
		enemy_types = ["scorpion", "wasp", "mantis"]
	else:
		# Hard enemies
		enemy_types = ["hornet", "centipede", "tarantula"]
	
	# Determine number of enemies (1-3 based on level)
	var num_enemies = min(1 + level / 2, 3)
	
	# Spawn enemies
	for i in range(num_enemies):
		if i < enemy_positions.size():
			var enemy_type = enemy_types[randi() % enemy_types.size()]
			var enemy = spawn_enemy(enemy_type, enemy_positions[i])
			active_enemies.append(enemy)

func spawn_enemy(enemy_type: String, position: Vector2) -> Enemy:
	var enemy = enemy_scene.instantiate()
	
	# Configure enemy based on type
	match enemy_type:
		"beetle":
			enemy.enemy_name = "Beetle"
			enemy.health = 15
			enemy.max_health = 15
			enemy.actions = [
				{"type": "attack", "value": 3},
				{"type": "defend", "value": 2}
			]
		"ant":
			enemy.enemy_name = "Ant"
			enemy.health = 10
			enemy.max_health = 10
			enemy.actions = [
				{"type": "attack", "value": 2},
				{"type": "attack", "value": 2},
				{"type": "buff", "effects": [{"name": "block", "value": 3}]}
			]
		"spider":
			enemy.enemy_name = "Spider"
			enemy.health = 12
			enemy.max_health = 12
			enemy.actions = [
				{"type": "attack", "value": 3},
				{"type": "debuff", "effects": [{"name": "sticky", "value": 2}]}
			]
		"scorpion":
			enemy.enemy_name = "Scorpion"
			enemy.health = 25
			enemy.max_health = 25
			enemy.actions = [
				{"type": "attack", "value": 5},
				{"type": "debuff", "effects": [{"name": "poison", "value": 2}]}
			]
		"wasp":
			enemy.enemy_name = "Wasp"
			enemy.health = 18
			enemy.max_health = 18
			enemy.actions = [
				{"type": "attack", "value": 4},
				{"type": "attack", "value": 3, "effects": [{"name": "decay", "value": 1}]}
			]
		"mantis":
			enemy.enemy_name = "Mantis"
			enemy.health = 22
			enemy.max_health = 22
			enemy.actions = [
				{"type": "attack", "value": 6},
				{"type": "buff", "effects": [{"name": "reflect", "value": 2}]}
			]
		"hornet":
			enemy.enemy_name = "Hornet"
			enemy.health = 30
			enemy.max_health = 30
			enemy.actions = [
				{"type": "attack", "value": 5, "effects": [{"name": "poison", "value": 3}]},
				{"type": "attack", "value": 8}
			]
		"centipede":
			enemy.enemy_name = "Centipede"
			enemy.health = 35
			enemy.max_health = 35
			enemy.actions = [
				{"type": "attack", "value": 3, "effects": [{"name": "decay", "value": 2}]},
				{"type": "buff", "effects": [{"name": "block", "value": 5}]},
				{"type": "attack", "value": 7}
			]
		"tarantula":
			enemy.enemy_name = "Tarantula"
			enemy.health = 40
			enemy.max_health = 40
			enemy.actions = [
				{"type": "attack", "value": 10},
				{"type": "debuff", "effects": [{"name": "sticky", "value": 3}]},
				{"type": "heal", "value": 5}
			]
	
	enemy.position = position
	add_child(enemy)
	
	# Connect enemy signals
	enemy.health_changed.connect(_on_enemy_health_changed.bind(enemy))
	
	return enemy

func _on_turn_started(is_player_turn: bool) -> void:
	if is_player_turn:
		turn_indicator.text = "Player Turn"
		end_turn_button.disabled = false
		combine_button.disabled = false
	else:
		turn_indicator.text = "Enemy Turn"
		end_turn_button.disabled = true
		combine_button.disabled = true

func _on_turn_ended(is_player_turn: bool) -> void:
	# Optional: Add special logic when a turn ends
	pass

func _on_battle_ended(player_won: bool) -> void:
	battle_ended = true
	
	if player_won:
		turn_indicator.text = "Victory!"
		
		# Update player health in GameManager
		GameManager.player_health = battle_manager.player_health
		
		# Show reward screen after a delay
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/reward_screen.tscn")
	else:
		turn_indicator.text = "Defeat!"
		
		# Show game over screen after a delay
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	player_health_bar.value = new_health

func _on_enemy_health_changed(current: int, maximum: int, enemy: Enemy) -> void:
	if current <= 0:
		# Check if all enemies are defeated
		var all_defeated = true
		for enemy_unit in active_enemies:
			if enemy_unit.health > 0:
				all_defeated = false
				break
		
		if all_defeated and !battle_ended:
			battle_manager.end_battle(true)

func _on_end_turn_button_pressed() -> void:
	battle_manager.end_player_turn()

func _on_combine_button_pressed() -> void:
	# Show card combiner interface
	card_combiner.visible = true
	
	# Disable other buttons while combining
	end_turn_button.disabled = true
	combine_button.disabled = true

func _on_combination_created(result_card: CardData) -> void:
	# Hide combiner
	card_combiner.visible = false
	
	# Add the resulting card to hand
	hand_manager.draw_card(result_card)
	
	# Re-enable buttons
	end_turn_button.disabled = false
	combine_button.disabled = false

func _on_combination_cancelled() -> void:
	# Hide combiner
	card_combiner.visible = false
	
	# Re-enable buttons
	end_turn_button.disabled = false
	combine_button.disabled = false
