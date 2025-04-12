extends Node

var cards_dict: Dictionary = {}
var combination_rules: Dictionary = {}

func _ready() -> void:
	load_basic_cards()
	load_enhanced_cards()
	load_advanced_cards()
	load_ultimate_cards()
	setup_combination_rules()

func load_basic_cards() -> void:
	# Elemental Cards
	
	var pebble = create_card("pebble", "Pebble", CardData.CardType.ATTACK, 1, "Deal 2 physical damage", 1)
	pebble.damage = 2
	register_card(pebble)
	
	var seed = create_card("seed", "Seed", CardData.CardType.SKILL, 1, "Block 2 damage", 1)
	seed.block = 2
	register_card(seed)
	
	var leaf = create_card("leaf", "Leaf", CardData.CardType.SKILL, 0, "Draw 1 card, gain 1 block", 1)
	leaf.block = 1
	leaf.draw = 1
	register_card(leaf)
	
	var droplet = create_card("droplet", "Droplet", CardData.CardType.SKILL, 1, "Heal 2 HP", 1)
	seed.heal = 2
	register_card(droplet)
		
#	register_card(create_card("flame", "Flame", CardData.CardType.ATTACK, 1, 
#		"Deal 1 damage and apply 1 burn (1 damage per turn for 2 turns)", 1, 
#		damage = 1, status_effects = ["burn"], status_values = [1]))
		
	# Add more basic cards here...

func load_enhanced_cards() -> void:
	# First-level combinations
	var stone = create_card("stone", "Stone", CardData.CardType.ATTACK, 2,
		"Deal 4 physical damage and stun target for 1 turn", 2)
	stone.damage = 4
	stone.status_effects = ["stun"] as Array[String]
	stone.status_values = [1] as Array[int]
	stone.is_basic = false
	stone.combination_recipe = ["pebble", "pebble"] as Array[String]
	register_card(stone)
	
	var hard_nut = create_card("hard_nut", "Hard Nut", CardData.CardType.SKILL, 2,
		"Block 3 damage and reflect 1 damage back to attacker", 2)
	hard_nut.block = 3
	hard_nut.status_effects = ["reflect"] as Array[String]
	hard_nut.status_values = [1] as Array[int]
	hard_nut.is_basic = false
	hard_nut.combination_recipe = ["pebble", "seed"] as Array[String]
	register_card(hard_nut)
	
	var rolling_stone = create_card("rolling_stone", "Rolling Stone", CardData.CardType.ATTACK, 2,
		"Deal 3 physical damage to all enemies in a row", 2)
	rolling_stone.damage = 3
	rolling_stone.is_basic = false
	rolling_stone.combination_recipe = ["pebble", "leaf"] as Array[String]
	register_card(rolling_stone)
	
	# Add more enhanced cards as needed

func load_advanced_cards() -> void:
	# Advanced combinations
	var boulder = create_card("boulder", "Boulder", CardData.CardType.ATTACK, 3,
		"Deal 7 damage and stun all adjacent enemies", 3)
	boulder.damage = 7
	boulder.status_effects = ["area_stun"] as Array[String]
	boulder.status_values = [1] as Array[int]
	boulder.is_basic = false
	boulder.combination_recipe = ["stone", "hard_nut", "rolling_stone"] as Array[String]
	register_card(boulder)
	
	var crystal_geode = create_card("crystal_geode", "Crystal Geode", CardData.CardType.SPECIAL, 3,
		"Deal 5 damage, heal 3 health, and draw 1 card", 3)
	crystal_geode.damage = 5
	crystal_geode.heal = 3
	crystal_geode.draw = 1
	crystal_geode.is_basic = false
	crystal_geode.combination_recipe = ["stone", "sploosh", "geode"] as Array[String]
	register_card(crystal_geode)
	
	var meteor = create_card("meteor", "Meteor", CardData.CardType.ATTACK, 3,
		"Deal 8 damage from above, ignoring defense and shields", 3)
	meteor.damage = 8
	meteor.is_basic = false
	meteor.combination_recipe = ["stone", "ember", "focused_light"] as Array[String]
	register_card(meteor)
	
	# Add more advanced cards as needed

func load_ultimate_cards() -> void:
	# Ultimate combinations
	var earth_elemental = create_card("earth_elemental", "Earth Elemental", CardData.CardType.ATTACK, 4,
		"Deal 10 damage to all enemies, stun for 2 turns, and create stone barriers", 4)
	earth_elemental.damage = 10
	earth_elemental.status_effects = ["area_stun", "barrier"] as Array[String]
	earth_elemental.status_values = [2, 1] as Array[int]
	earth_elemental.is_basic = false
	earth_elemental.combination_recipe = ["boulder", "avalanche", "stone_catalyst"] as Array[String]
	register_card(earth_elemental)
	
	var phoenix = create_card("phoenix", "Phoenix", CardData.CardType.SPECIAL, 4,
		"Deal 8 fire damage to all enemies, then heal all allies for 5", 4)
	phoenix.damage = 8
	phoenix.heal = 5
	phoenix.is_basic = false
	phoenix.combination_recipe = ["volcano", "firefly", "fire_catalyst"] as Array[String]
	register_card(phoenix)
	
	var tsunami_wave = create_card("tsunami_wave", "Tsunami Wave", CardData.CardType.CONTROL, 4,
		"Deal 12 damage to all enemies, remove all their buffs, and push to back row", 4)
	tsunami_wave.damage = 12
	tsunami_wave.is_basic = false
	tsunami_wave.combination_recipe = ["thunderstorm", "tsunami", "water_catalyst"] as Array[String]
	register_card(tsunami_wave)
	
	# Add more ultimate cards as needed

func create_card(id: String, name: String, type: CardData.CardType, cost: int, 
				description: String, level: int, 
				damage: int = 0, heal: int = 0, block: int = 0, draw: int = 0,
				energy_gain: int = 0, currency_gain: int = 0,
				status_effects: Array[String] = [], status_values: Array[int] = [],
				is_basic: bool = true, combination_recipe: Array[String] = []) -> CardData:
	var card = CardData.new(id, name, type, cost, description, level)
	card.damage = damage
	card.heal = heal
	card.block = block
	card.draw = draw
	card.energy_gain = energy_gain
	card.currency_gain = currency_gain
	card.status_effects = status_effects
	card.status_values = status_values
	card.is_basic = is_basic
	card.combination_recipe = combination_recipe
	return card

func register_card(card: CardData) -> void:
	cards_dict[card.id] = card

func setup_combination_rules() -> void:
	# Set up basic combinations
	add_combination_rule(["pebble", "pebble"], "stone")
	add_combination_rule(["pebble", "seed"], "hard_nut")
	add_combination_rule(["pebble", "leaf"], "rolling_stone")
	# Add more combination rules...

func add_combination_rule(ingredients: Array[String], result: String) -> void:
	# Sort ingredients to ensure consistent lookup
	ingredients.sort()
	var key = ",".join(ingredients)
	combination_rules[key] = result

func get_card(id: String) -> CardData:
	if cards_dict.has(id):
		return cards_dict[id]
	return null

func get_combination_result(card_ids: Array[String]) -> String:
	# Sort card IDs for consistent lookup
	card_ids.sort()
	var key = ",".join(card_ids)
	if combination_rules.has(key):
		return combination_rules[key]
	return ""

func can_combine(card_ids: Array[String]) -> bool:
	# Sort card IDs for consistent lookup
	card_ids.sort()
	var key = ",".join(card_ids)
	return combination_rules.has(key)
