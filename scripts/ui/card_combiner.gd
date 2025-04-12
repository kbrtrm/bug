class_name CardCombiner
extends Control

signal combination_created(result_card)
signal combination_cancelled

@export var card_scene: PackedScene
@export var max_input_cards: int = 3

var selected_cards: Array[CardData] = []
var result_preview: CardData = null
var combination_possible: bool = false

@onready var input_slots: HBoxContainer = $InputCardsContainer
@onready var output_slot: TextureRect = $OutputCardContainer/OutputSlot
@onready var result_card_instance = null
@onready var combine_button: Button = $CombineButton
@onready var cancel_button: Button = $CancelButton
@onready var no_result_label: Label = $OutputCardContainer/NoResultLabel

func _ready() -> void:
	combine_button.disabled = true
	no_result_label.visible = true
	
	# Connect button signals
	combine_button.pressed.connect(_on_combine_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)

func add_card(card_data: CardData) -> bool:
	if selected_cards.size() >= max_input_cards:
		return false
	
	selected_cards.append(card_data)
	update_input_slots()
	check_combination()
	return true

func remove_card(index: int) -> CardData:
	if index < 0 or index >= selected_cards.size():
		return null
	
	var card = selected_cards[index]
	selected_cards.remove_at(index)
	update_input_slots()
	check_combination()
	return card

func clear_cards() -> void:
	selected_cards.clear()
	update_input_slots()
	check_combination()

func update_input_slots() -> void:
	# Clear existing card instances
	for child in input_slots.get_children():
		if child is Control:  # Skip HBoxContainer's spacers
			child.queue_free()
	
	# Create card instances for selected cards
	for card_data in selected_cards:
		var card_instance = card_scene.instantiate()
		card_instance.data = card_data
		card_instance.is_draggable = false
		input_slots.add_child(card_instance)
		
		# Add a remove button for each card
		var remove_button = Button.new()
		remove_button.text = "X"
		remove_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card_instance.add_child(remove_button)
		
		# Connect remove button
		var index = selected_cards.find(card_data)
		remove_button.pressed.connect(func(): _on_remove_card_pressed(index))

func check_combination() -> void:
	# Get card IDs
	var card_ids = []
	for card in selected_cards:
		card_ids.append(card.id)
	
	# Check if a valid combination exists
	combination_possible = CardDatabase.can_combine(card_ids)
	combine_button.disabled = !combination_possible
	
	# Update result preview
	if combination_possible:
		var result_id = CardDatabase.get_combination_result(card_ids)
		result_preview = CardDatabase.get_card(result_id)
		update_result_preview()
	else:
		result_preview = null
		clear_result_preview()

func update_result_preview() -> void:
	# Remove previous preview
	if result_card_instance:
		result_card_instance.queue_free()
		result_card_instance = null
	
	if result_preview:
		no_result_label.visible = false
		
		# Create new preview
		result_card_instance = card_scene.instantiate()
		result_card_instance.data = result_preview
		result_card_instance.is_draggable = false
		output_slot.add_child(result_card_instance)
	else:
		clear_result_preview()

func clear_result_preview() -> void:
	if result_card_instance:
		result_card_instance.queue_free()
		result_card_instance = null
	
	no_result_label.visible = true

func _on_combine_button_pressed() -> void:
	if combination_possible and result_preview:
		emit_signal("combination_created", result_preview)
		clear_cards()

func _on_cancel_button_pressed() -> void:
	emit_signal("combination_cancelled")
	clear_cards()

func _on_remove_card_pressed(index: int) -> void:
	remove_card(index)
