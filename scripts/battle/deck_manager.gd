class_name DeckManager
extends Node

signal deck_emptied
signal card_drawn(card_data)

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []

func _ready() -> void:
	pass

func initialize_deck(card_ids: Array[String]) -> void:
	draw_pile.clear()
	discard_pile.clear()
	
	for id in card_ids:
		var card = CardDatabase.get_card(id)
		if card:
			draw_pile.append(card)
	
	shuffle_draw_pile()

func shuffle_draw_pile() -> void:
	# Fisher-Yates shuffle
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var n = draw_pile.size()
	for i in range(n - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = temp

func draw_card() -> CardData:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			emit_signal("deck_emptied")
			return null
		else:
			# Shuffle discard pile into draw pile
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			shuffle_draw_pile()
	
	var card = draw_pile.pop_back()
	emit_signal("card_drawn", card)
	return card

func draw_specific_card(card_id: String) -> CardData:
	# Search for a specific card in the draw pile
	for i in range(draw_pile.size()):
		if draw_pile[i].id == card_id:
			var card = draw_pile[i]
			draw_pile.remove_at(i)
			emit_signal("card_drawn", card)
			return card
	
	# If not found in draw pile, check discard pile
	for i in range(discard_pile.size()):
		if discard_pile[i].id == card_id:
			var card = discard_pile[i]
			discard_pile.remove_at(i)
			emit_signal("card_drawn", card)
			return card
	
	return null

func draw_multiple_cards(count: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	
	for i in range(count):
		var card = draw_card()
		if card:
			cards.append(card)
	
	return cards

func discard_card(card: CardData) -> void:
	discard_pile.append(card)

func get_draw_pile_size() -> int:
	return draw_pile.size()

func get_discard_pile_size() -> int:
	return discard_pile.size()

func shuffle_discard_into_draw() -> void:
	for card in discard_pile:
		draw_pile.append(card)
	
	discard_pile.clear()
	shuffle_draw_pile()

func add_card_to_deck(card_id: String) -> void:
	var card = CardDatabase.get_card(card_id)
	if card:
		draw_pile.append(card)
		shuffle_draw_pile()

func add_card_to_discard(card_id: String) -> void:
	var card = CardDatabase.get_card(card_id)
	if card:
		discard_pile.append(card)

func get_deck_cards() -> Array:
	# Return a copy of all cards in both draw and discard piles
	var all_cards = []
	all_cards.append_array(draw_pile)
	all_cards.append_array(discard_pile)
	return all_cards
