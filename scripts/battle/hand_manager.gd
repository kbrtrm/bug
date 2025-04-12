class_name HandManager
extends Node2D

signal card_played(card_data)
signal card_selected(card)
signal cards_combined(result_card_data)

@export var card_scene: PackedScene
@export var hand_size: int = 7
@export var card_spacing: float = 120.0
@export var curve_factor: float = 0.5
@export var player_energy: int = 3

var cards: Array[Card] = []
var selected_cards: Array[Card] = []
var combination_mode: bool = false
var current_energy: int = player_energy

@onready var combination_panel: Control = $CombinationPanel
@onready var energy_label: Label = $EnergyLabel

func _ready() -> void:
	combination_panel.visible = false
	update_energy_display()

func draw_card(card_data: CardData) -> void:
	if cards.size() >= hand_size:
		print("Hand full!")
		return
		
	var new_card = card_scene.instantiate() as Card
	new_card.data = card_data
	new_card.is_face_up = true
	
	new_card.card_clicked.connect(_on_card_clicked)
	new_card.card_dragged.connect(_on_card_dragged)
	new_card.card_dropped.connect(_on_card_dropped)
	new_card.card_hovered.connect(_on_card_hovered)
	new_card.card_unhovered.connect(_on_card_unhovered)
	
	add_child(new_card)
	cards.append(new_card)
	
	organize_hand()

func organize_hand() -> void:
	var hand_width = card_spacing * (cards.size() - 1)
	var start_x = -hand_width / 2
	
	for i in range(cards.size()):
		var card = cards[i]
		var target_pos = Vector2(
			start_x + i * card_spacing,
			curve_factor * abs(i - (cards.size() - 1) / 2.0) * curve_factor * 50.0
		)
		
		# Create tween for smooth movement
		var tween = create_tween()
		tween.tween_property(card, "position", target_pos, 0.3)
		
		# Rotate cards slightly based on position
		var rotation_angle = (i - (cards.size() - 1) / 2.0) * 0.05
		tween.parallel().tween_property(card, "rotation", rotation_angle, 0.3)

func _on_card_clicked(card: Card) -> void:
	if combination_mode:
		toggle_card_selection(card)
	else:
		attempt_play_card(card)

func attempt_play_card(card: Card) -> void:
	if current_energy >= card.data.cost:
		spend_energy(card.data.cost)
		remove_card(card)
		emit_signal("card_played", card.data)
		card.queue_free()
	else:
		# Not enough energy, show feedback
		var tween = create_tween()
		tween.tween_property(card, "position:y", card.position.y - 20, 0.1)
		tween.tween_property(card, "position:y", card.position.y, 0.1)

func _on_card_dragged(card: Card) -> void:
	# Cards are above the hand while being dragged
	pass

func _on_card_dropped(card: Card, drop_position: Vector2) -> void:
	# Check if dropped on play area
	var play_threshold = -200  # Y position threshold
	if drop_position.y < play_threshold:
		attempt_play_card(card)
	else:
		# Return to hand
		organize_hand()

func _on_card_hovered(card: Card) -> void:
	# Make card larger or more prominent
	pass

func _on_card_unhovered(card: Card) -> void:
	# Return card to normal size
	pass

func toggle_card_selection(card: Card) -> void:
	if selected_cards.has(card):
		selected_cards.erase(card)
		card.set_selected(false)
	else:
		selected_cards.append(card)
		card.set_selected(true)
	
	update_combination_panel()

func toggle_combination_mode(enabled: bool) -> void:
	combination_mode = enabled
	combination_panel.visible = enabled
	
	# Clear selections when exiting combination mode
	if !enabled:
		for card in selected_cards:
			card.set_selected(false)
		selected_cards.clear()

func update_combination_panel() -> void:
	if selected_cards.size() > 1:
		# Check if selected cards can be combined
		var card_ids = []
		for card in selected_cards:
			card_ids.append(card.data.id)
		
		var can_combine = CardDatabase.can_combine(card_ids)
		$CombinationPanel/CombineButton.disabled = !can_combine
		
		if can_combine:
			var result_id = CardDatabase.get_combination_result(card_ids)
			var result_card = CardDatabase.get_card(result_id)
			$CombinationPanel/ResultPreview.text = "Result: " + result_card.name
		else:
			$CombinationPanel/ResultPreview.text = "No valid combination"
	else:
		$CombinationPanel/CombineButton.disabled = true
		$CombinationPanel/ResultPreview.text = "Select cards to combine"

func _on_combine_button_pressed() -> void:
	var card_ids = []
	for card in selected_cards:
		card_ids.append(card.data.id)
	
	if CardDatabase.can_combine(card_ids):
		var result_id = CardDatabase.get_combination_result(card_ids)
		var result_card = CardDatabase.get_card(result_id)
		
		# Remove selected cards
		for card in selected_cards:
			remove_card(card)
			card.queue_free()
		
		selected_cards.clear()
		
		# Add the resulting card
		draw_card(result_card)
		
		emit_signal("cards_combined", result_card)
		toggle_combination_mode(false)

func _on_cancel_button_pressed() -> void:
	toggle_combination_mode(false)

func remove_card(card: Card) -> void:
	if selected_cards.has(card):
		selected_cards.erase(card)
	cards.erase(card)
	organize_hand()

func clear_hand() -> void:
	for card in cards:
		card.queue_free()
	cards.clear()
	selected_cards.clear()
	organize_hand()

func reset_energy() -> void:
	current_energy = player_energy
	update_energy_display()

func spend_energy(amount: int) -> void:
	current_energy = max(0, current_energy - amount)
	update_energy_display()

func gain_energy(amount: int) -> void:
	current_energy += amount
	update_energy_display()

func update_energy_display() -> void:
	energy_label.text = "Energy: " + str(current_energy) + "/" + str(player_energy)
