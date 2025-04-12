extends Node

# Game state
enum GameState { TITLE_SCREEN, WORLD_MAP, BATTLE, DECK_BUILDING, SHOP, GAME_OVER }

var current_state: GameState = GameState.TITLE_SCREEN
var player_currency: int = 0
var player_deck: Array[String] = []
var player_health: int = 30
var player_max_health: int = 30
var current_level: int = 1

# References to other managers
var battle_manager
var deck_manager
var hand_manager

# Battle results
var last_battle_rewards: Dictionary = {}

# Singleton pattern
static var _instance: Node

static func get_instance() -> Node:
	return _instance

func _ready() -> void:
	_instance = self
	
	# Initialize with some basic cards
	player_deck = [
		"pebble", "pebble", "seed", "seed", 
		"leaf", "leaf", "droplet", "droplet" 
#		"flame", "flame", "spark", "spark", 
#		"moss", "moss", "snowflake", "snowflake",
#		"button", "brass_ring", "paperclip", "penny"
	]

func start_game() -> void:
	current_state = GameState.BATTLE # for testing
	player_currency = 10
	player_health = player_max_health
	current_level = 1
	
	# Signal to UI
	emit_signal("game_started")

func start_battle(enemy_data: Array) -> void:
	current_state = GameState.BATTLE
	
	# Get references if needed
	if not battle_manager:
		battle_manager = get_node("/root/BattleScene/BattleManager")
	if not deck_manager:
		deck_manager = battle_manager.get_node("DeckManager")
	if not hand_manager:
		hand_manager = battle_manager.get_node("HandManager")
	
	# Initialize the deck for this battle
	deck_manager.initialize_deck(player_deck)
	
	# Start the battle
	battle_manager.start_battle(enemy_data)
	
	# Connect signals
	if not battle_manager.is_connected("battle_ended", Callable(self, "_on_battle_ended")):
		battle_manager.battle_ended.connect(_on_battle_ended)

func _on_battle_ended(player_won: bool) -> void:
	if player_won:
		# Generate rewards
		last_battle_rewards = {
			"currency": randi_range(5, 15) * current_level,
			"card_choices": generate_card_rewards(3),
			"health_restore": randi_range(2, 5)
		}
		
		# Add currency
		player_currency += last_battle_rewards.currency
		
		# Restore some health
		player_health = min(player_health + last_battle_rewards.health_restore, player_max_health)
		
		# Show reward screen
		get_tree().change_scene_to_file("res://scenes/reward_screen.tscn")
	else:
		# Game over
		current_state = GameState.GAME_OVER
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func generate_card_rewards(count: int) -> Array:
	var rewards = []
	var available_cards = []
	
	# Get all basic cards
	for card_id in CardDatabase.cards_dict.keys():
		var card = CardDatabase.cards_dict[card_id]
		if card.is_basic:
			available_cards.append(card_id)
	
	# Add some enhanced cards based on current level
	if current_level >= 2:
		for card_id in CardDatabase.cards_dict.keys():
			var card = CardDatabase.cards_dict[card_id]
			if not card.is_basic and card.level <= 2:
				available_cards.append(card_id)
	
	# Randomly select rewards
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(count):
		if available_cards.size() > 0:
			var index = rng.randi_range(0, available_cards.size() - 1)
			rewards.append(available_cards[index])
			available_cards.remove_at(index)
	
	return rewards

func add_card_to_deck(card_id: String) -> void:
	player_deck.append(card_id)

func remove_card_from_deck(card_id: String) -> void:
	var index = player_deck.find(card_id)
	if index != -1:
		player_deck.remove_at(index)

func add_currency(amount: int) -> void:
	player_currency += amount

func spend_currency(amount: int) -> bool:
	if player_currency >= amount:
		player_currency -= amount
		return true
	return false

func advance_level() -> void:
	current_level += 1
	# Additional logic for level progression

func get_player_health_percentage() -> float:
	return float(player_health) / float(player_max_health)

# Signals
signal game_started
signal level_advanced
signal currency_changed(new_amount)
signal player_health_changed(health, max_health)
