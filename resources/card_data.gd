class_name CardData
extends Resource

enum CardType {ATTACK, SKILL, CONTROL, SPECIAL}

@export var id: String = ""
@export var name: String = ""
@export var type: CardType = CardType.ATTACK
@export var cost: int = 1
@export var description: String = ""
@export var level: int = 1
@export var image_path: String = ""

# Effects
@export var damage: int = 0
@export var heal: int = 0
@export var block: int = 0
@export var draw: int = 0
@export var energy_gain: int = 0
@export var currency_gain: int = 0
@export var status_effects: Array[String] = []
@export var status_values: Array[int] = []

# Combination info
@export var is_basic: bool = true
@export var combination_recipe: Array[String] = []

func _init(p_id: String = "", p_name: String = "", p_type: CardType = CardType.ATTACK, 
		   p_cost: int = 1, p_description: String = "", p_level: int = 1,
		   p_image_path: String = "") -> void:
	id = p_id
	name = p_name
	type = p_type
	cost = p_cost
	description = p_description
	level = level
	image_path = p_image_path

func can_combine_with(other_card: CardData) -> bool:
	# This is just a placeholder. The actual combination logic
	# is implemented in CardDatabase
	return false  # Return a default value

func get_combination_result() -> String:
	# This is just a placeholder. The actual combination results
	# are managed by CardDatabase
	return ""  # Return a default empty string
