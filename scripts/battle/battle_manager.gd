class_name BattleManager
extends Node

signal turn_started(is_player_turn)
signal turn_ended(is_player_turn)
signal battle_ended(player_won)
signal player_health_changed(new_health, max_health)
signal enemy_health_changed(enemy_id, new_health, max_health)
signal status_effect_applied(target_id, effect_name, effect_value)
signal status_effect_removed(target_id, effect_name)

enum TurnState { PLAYER_TURN, ENEMY_TURN, ANIMATION, GAME_OVER }

var current_state: TurnState = TurnState.PLAYER_TURN
var player_health: int = 30
var player_max_health: int = 30
var enemies: Array = []
var player_status_effects: Dictionary = {}
var enemy_status_effects: Dictionary = {}
var turn_count: int = 0

@onready var deck_manager: DeckManager = $DeckManager
@onready var hand_manager: HandManager = $HandManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hand_manager.card_played.connect(_on_card_played)
	deck_manager.card_drawn.connect(_on_card_drawn)

func start_battle(enemy_data: Array) -> void:
	# Setup initial battle state
	player_health = player_max_health
	enemies = enemy_data
	player_status_effects.clear()
	enemy_status_effects.clear()
	turn_count = 0
	
	# Initial draw
	for i in range(5):
		hand_manager.draw_card(deck_manager.draw_card())
	
	# Start player turn
	start_player_turn()

func end_battle(player_won: bool) -> void:
	current_state = TurnState.GAME_OVER
	emit_signal("battle_ended", player_won)

func start_player_turn() -> void:
	current_state = TurnState.PLAYER_TURN
	turn_count += 1
	
	# Reset player energy
	hand_manager.reset_energy()
	
	# Process status effects
	process_status_effects(true)
	
	# Draw cards
	hand_manager.draw_card(deck_manager.draw_card())
	
	emit_signal("turn_started", true)

func end_player_turn() -> void:
	emit_signal("turn_ended", true)
	start_enemy_turn()

func start_enemy_turn() -> void:
	current_state = TurnState.ENEMY_TURN
	
	# Process enemy status effects
	process_status_effects(false)
	
	emit_signal("turn_started", false)
	
	# Enemy AI actions
	for enemy in enemies:
		if enemy.health > 0:
			enemy_take_action(enemy)
			# Small delay between enemy actions
			await get_tree().create_timer(0.5).timeout
	
	end_enemy_turn()

func end_enemy_turn() -> void:
	emit_signal("turn_ended", false)
	start_player_turn()

func _on_card_played(card_data: CardData) -> void:
	current_state = TurnState.ANIMATION
	
	# Process card effects
	process_card_effect(card_data)
	
	# Add card to discard pile
	deck_manager.discard_card(card_data)
	
	current_state = TurnState.PLAYER_TURN
	
	# Check victory/defeat conditions
	check_battle_end_conditions()

func process_card_effect(card: CardData) -> void:
	# Select target if needed
	var target = null
	if card.type == CardData.CardType.ATTACK:
		# For simplicity, target first living enemy
		for enemy in enemies:
			if enemy.health > 0:
				target = enemy
				break
	
	# Apply card effects
	if card.damage > 0 and target:
		deal_damage(target, card.damage)
	
	if card.heal > 0:
		heal_player(card.heal)
	
	if card.block > 0:
		apply_status_effect("player", "block", card.block)
	
	if card.draw > 0:
		for i in range(card.draw):
			hand_manager.draw_card(deck_manager.draw_card())
	
	if card.energy_gain > 0:
		hand_manager.gain_energy(card.energy_gain)
		
	if card.currency_gain > 0:
		# Add currency to player inventory
		GameManager.add_currency(card.currency_gain)
		
	# Apply status effects
	for i in range(card.status_effects.size()):
		var effect_name = card.status_effects[i]
		var effect_value = card.status_values[i] if i < card.status_values.size() else 1
		
		match effect_name:
			"burn":
				apply_status_effect(target.id, "burn", effect_value)
			"stun":
				apply_status_effect(target.id, "stun", effect_value)
			"reflect":
				apply_status_effect("player", "reflect", effect_value)
			"area_stun":
				for enemy in enemies:
					if enemy.health > 0:
						apply_status_effect(enemy.id, "stun", effect_value)
			"slow":
				apply_status_effect(target.id, "slow", effect_value)
			"decay":
				apply_status_effect(target.id, "decay", effect_value)
			"cleanse":
				if effect_name == "cleanse":
					if effect_value >= 99:  # Special value for "cleanse all"
						clear_status_effects("player")
					else:
						# Cleanse specific number of negative effects
						cleanse_negative_effects("player", effect_value)
			"barrier":
				apply_status_effect("player", "barrier", effect_value)
			"evasion":
				apply_status_effect("player", "evasion", effect_value)

func deal_damage(target, amount: int) -> void:
	# Check for damage reduction effects
	var final_damage = amount
	
	if target.id == "player":
		# Player being damaged
		if player_status_effects.has("block"):
			var block = player_status_effects["block"]
			if block >= final_damage:
				player_status_effects["block"] -= final_damage
				emit_signal("status_effect_changed", "player", "block", player_status_effects["block"])
				final_damage = 0
			else:
				final_damage -= block
				player_status_effects.erase("block")
				emit_signal("status_effect_removed", "player", "block")
		
		# Apply damage to player
		if final_damage > 0:
			player_health -= final_damage
			emit_signal("player_health_changed", player_health, player_max_health)
			
			# Check for reflect damage
			if player_status_effects.has("reflect"):
				var reflect_damage = min(player_status_effects["reflect"], final_damage)
				for enemy in enemies:
					if enemy.health > 0:
						enemy.health -= reflect_damage
						emit_signal("enemy_health_changed", enemy.id, enemy.health, enemy.max_health)
						break
	else:
		# Enemy being damaged
		if enemy_status_effects.has(target.id) and enemy_status_effects[target.id].has("block"):
			var block = enemy_status_effects[target.id]["block"]
			if block >= final_damage:
				enemy_status_effects[target.id]["block"] -= final_damage
				emit_signal("status_effect_changed", target.id, "block", enemy_status_effects[target.id]["block"])
				final_damage = 0
			else:
				final_damage -= block
				enemy_status_effects[target.id].erase("block")
				emit_signal("status_effect_removed", target.id, "block")
		
		# Apply damage to enemy
		if final_damage > 0:
			target.health -= final_damage
			emit_signal("enemy_health_changed", target.id, target.health, target.max_health)

func heal_player(amount: int) -> void:
	player_health = min(player_health + amount, player_max_health)
	emit_signal("player_health_changed", player_health, player_max_health)

func apply_status_effect(target_id: String, effect_name: String, effect_value: int) -> void:
	if target_id == "player":
		player_status_effects[effect_name] = effect_value
		emit_signal("status_effect_applied", target_id, effect_name, effect_value)
	else:
		if not enemy_status_effects.has(target_id):
			enemy_status_effects[target_id] = {}
		enemy_status_effects[target_id][effect_name] = effect_value
		emit_signal("status_effect_applied", target_id, effect_name, effect_value)

func process_status_effects(is_player_turn: bool) -> void:
	# Process player status effects
	var effects_to_remove = []
	
	for effect in player_status_effects:
		match effect:
			"burn", "decay", "poison":
				# Take damage from damage-over-time effects
				player_health -= player_status_effects[effect]
				emit_signal("player_health_changed", player_health, player_max_health)
				player_status_effects[effect] -= 1
				if player_status_effects[effect] <= 0:
					effects_to_remove.append(effect)
				else:
					emit_signal("status_effect_changed", "player", effect, player_status_effects[effect])
			"stun", "evasion", "reflect":
				# Reduce duration effects
				player_status_effects[effect] -= 1
				if player_status_effects[effect] <= 0:
					effects_to_remove.append(effect)
				else:
					emit_signal("status_effect_changed", "player", effect, player_status_effects[effect])
	
	# Remove expired effects
	for effect in effects_to_remove:
		player_status_effects.erase(effect)
		emit_signal("status_effect_removed", "player", effect)
	
	# Process enemy status effects
	for enemy_id in enemy_status_effects.keys():
		effects_to_remove = []
		
		for effect in enemy_status_effects[enemy_id]:
			match effect:
				"burn", "decay", "poison":
					# Find the targeted enemy
					var target_enemy = null
					for enemy in enemies:
						if enemy.id == enemy_id:
							target_enemy = enemy
							break
					
					if target_enemy and target_enemy.health > 0:
						# Apply damage effect
						target_enemy.health -= enemy_status_effects[enemy_id][effect]
						emit_signal("enemy_health_changed", enemy_id, target_enemy.health, target_enemy.max_health)
						
						enemy_status_effects[enemy_id][effect] -= 1
						if enemy_status_effects[enemy_id][effect] <= 0:
							effects_to_remove.append(effect)
						else:
							emit_signal("status_effect_changed", enemy_id, effect, enemy_status_effects[enemy_id][effect])
				"stun", "slow", "sticky":
					# Reduce duration effects
					enemy_status_effects[enemy_id][effect] -= 1
					if enemy_status_effects[enemy_id][effect] <= 0:
						effects_to_remove.append(effect)
					else:
						emit_signal("status_effect_changed", enemy_id, effect, enemy_status_effects[enemy_id][effect])
		
		# Remove expired effects
		for effect in effects_to_remove:
			enemy_status_effects[enemy_id].erase(effect)
			emit_signal("status_effect_removed", enemy_id, effect)

func enemy_take_action(enemy) -> void:
	# Skip turn if stunned
	if enemy_status_effects.has(enemy.id) and enemy_status_effects[enemy.id].has("stun"):
		return
	
	# Get enemy action
	var action = enemy.get_next_action()
	
	# Process the action
	match action.type:
		"attack":
			# Check for evasion
			var hits = true
			if player_status_effects.has("evasion"):
				var evasion_chance = player_status_effects["evasion"] * 0.25  # 25% per level
				if randf() < evasion_chance:
					hits = false
			
			# Check for sticky effect (chance to miss)
			if enemy_status_effects.has(enemy.id) and enemy_status_effects[enemy.id].has("sticky"):
				var sticky_chance = enemy_status_effects[enemy.id]["sticky"] * 0.25  # 25% per level
				if randf() < sticky_chance:
					hits = false
			
			if hits:
				deal_damage("player", action.value)
				# Apply any additional effects
				if action.has("effects"):
					for effect in action.effects:
						apply_status_effect("player", effect.name, effect.value)
		"heal":
			enemy.health = min(enemy.health + action.value, enemy.max_health)
			emit_signal("enemy_health_changed", enemy.id, enemy.health, enemy.max_health)
		"buff":
			for effect in action.effects:
				apply_status_effect(enemy.id, effect.name, effect.value)
		"debuff":
			for effect in action.effects:
				apply_status_effect("player", effect.name, effect.value)

func check_battle_end_conditions() -> void:
	# Check for player defeat
	if player_health <= 0:
		end_battle(false)
		return
	
	# Check for enemy defeat
	var all_enemies_defeated = true
	for enemy in enemies:
		if enemy.health > 0:
			all_enemies_defeated = false
			break
	
	if all_enemies_defeated:
		end_battle(true)

func clear_status_effects(target_id: String) -> void:
	if target_id == "player":
		var positive_effects = ["block", "reflect", "evasion", "barrier"]
		var effects_to_remove = []
		
		for effect in player_status_effects.keys():
			if not effect in positive_effects:
				effects_to_remove.append(effect)
		
		for effect in effects_to_remove:
			player_status_effects.erase(effect)
			emit_signal("status_effect_removed", "player", effect)
	else:
		if enemy_status_effects.has(target_id):
			enemy_status_effects.erase(target_id)
			emit_signal("status_effect_removed", target_id, "all")

func cleanse_negative_effects(target_id: String, count: int) -> void:
	if target_id == "player":
		var negative_effects = ["burn", "decay", "poison", "slow", "sticky"]
		var effects_to_remove = []
		var removed_count = 0
		
		for effect in player_status_effects.keys():
			if effect in negative_effects and removed_count < count:
				effects_to_remove.append(effect)
				removed_count += 1
		
		for effect in effects_to_remove:
			player_status_effects.erase(effect)
			emit_signal("status_effect_removed", "player", effect)

func _on_end_turn_button_pressed() -> void:
	if current_state == TurnState.PLAYER_TURN:
		end_player_turn()

func _on_card_drawn(card_data: CardData) -> void:
	# Update UI elements if needed
	pass
