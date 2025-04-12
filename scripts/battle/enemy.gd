class_name Enemy
extends Node2D

signal health_changed(current, maximum)
signal status_effect_applied(effect_name, effect_value)
signal status_effect_removed(effect_name)
signal action_selected(action_data)

@export var enemy_name: String = "Enemy"
@export var texture: Texture2D
@export var health: int = 20
@export var max_health: int = 20
@export var actions: Array = []
@export var action_weights: Array = []

var id: String = ""
var status_effects: Dictionary = {}
var next_action: Dictionary = {}
var animation_player: AnimationPlayer
var sprite: Sprite2D
var health_bar: ProgressBar
var action_indicator: Label

func _ready() -> void:
	sprite = $Sprite2D
	animation_player = $AnimationPlayer
	health_bar = $HealthBar
	action_indicator = $ActionIndicator
	
	if texture:
		sprite.texture = texture
	
	health_bar.max_value = max_health
	health_bar.value = health
	
	# Generate a unique ID if not set
	if id.is_empty():
		id = enemy_name.to_lower().replace(" ", "_") + "_" + str(randi() % 1000)
	
	update_ui()
	select_next_action()

func update_ui() -> void:
	health_bar.value = health
	
	# Update action indicator
	if not next_action.is_empty():
		var action_text = ""
		match next_action.type:
			"attack":
				action_text = "Attack " + str(next_action.value)
			"defend":
				action_text = "Defend " + str(next_action.value)
			"heal":
				action_text = "Heal " + str(next_action.value)
			"buff":
				action_text = "Buff"
			"debuff":
				action_text = "Debuff"
		
		action_indicator.text = action_text
	else:
		action_indicator.text = "..."

func select_next_action() -> void:
	if actions.is_empty():
		# Default action if none defined
		next_action = {
			"type": "attack",
			"value": 3
		}
		return
	
	# Use weighted random selection if weights are provided
	if action_weights.size() == actions.size():
		var total_weight = 0
		for weight in action_weights:
			total_weight += weight
		
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var roll = rng.randi_range(1, total_weight)
		
		var cumulative_weight = 0
		for i in range(action_weights.size()):
			cumulative_weight += action_weights[i]
			if roll <= cumulative_weight:
				next_action = actions[i].duplicate()
				break
	else:
		# Equal probability if no weights provided
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var index = rng.randi_range(0, actions.size() - 1)
		next_action = actions[index].duplicate()
	
	# Modify action based on status effects
	if status_effects.has("decay"):
		if next_action.type == "attack":
			next_action.value = max(1, next_action.value - status_effects["decay"])
	
	# Signal the selected action
	emit_signal("action_selected", next_action)
	update_ui()

func get_next_action() -> Dictionary:
	var current_action = next_action.duplicate()
	select_next_action()  # Choose the next action for the following turn
	return current_action

func take_damage(amount: int) -> void:
	var actual_damage = amount
	
	# Apply damage reduction if any
	if status_effects.has("block"):
		if status_effects["block"] >= actual_damage:
			status_effects["block"] -= actual_damage
			emit_signal("status_effect_applied", "block", status_effects["block"])
			actual_damage = 0
		else:
			actual_damage -= status_effects["block"]
			status_effects.erase("block")
			emit_signal("status_effect_removed", "block")
	
	health -= actual_damage
	emit_signal("health_changed", health, max_health)
	update_ui()
	
	if actual_damage > 0:
		animation_player.play("take_damage")

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	emit_signal("health_changed", health, max_health)
	update_ui()
	animation_player.play("heal")

func apply_status_effect(effect_name: String, effect_value: int) -> void:
	status_effects[effect_name] = effect_value
	emit_signal("status_effect_applied", effect_name, effect_value)
	update_ui()

func remove_status_effect(effect_name: String) -> void:
	if status_effects.has(effect_name):
		status_effects.erase(effect_name)
		emit_signal("status_effect_removed", effect_name)
		update_ui()

func clear_status_effects() -> void:
	status_effects.clear()
	emit_signal("status_effect_removed", "all")
	update_ui()

func play_attack_animation() -> void:
	animation_player.play("attack")
	await animation_player.animation_finished

func is_dead() -> bool:
	return health <= 0
