class_name Card
extends Node2D

signal card_clicked(card)
signal card_dragged(card)
signal card_dropped(card, position)
signal card_hovered(card)
signal card_unhovered(card)

@export var data: CardData
@export var front_texture: Texture2D
@export var back_texture: Texture2D
@export var is_face_up: bool = true
@export var is_draggable: bool = true

var is_being_dragged: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2
var is_selected: bool = false
var is_playable: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $CardFront/NameLabel
@onready var type_label: Label = $CardFront/TypeLabel
@onready var cost_label: Label = $CardFront/CostLabel
@onready var description_label: Label = $CardFront/DescriptionLabel
@onready var card_front: Control = $CardFront
@onready var card_back: Control = $CardBack
@onready var selection_highlight: ColorRect = $SelectionHighlight
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	selection_highlight.visible = false
	update_card_face()
	if data:
		update_card_data()
	
func update_card_face() -> void:
	card_front.visible = is_face_up
	card_back.visible = !is_face_up

func update_card_data() -> void:
	name_label.text = data.name
	
	var type_text = ""
	match data.type:
		CardData.CardType.ATTACK: type_text = "Attack"
		CardData.CardType.SKILL: type_text = "Skill"
		CardData.CardType.CONTROL: type_text = "Control"
		CardData.CardType.SPECIAL: type_text = "Special"
	
	type_label.text = type_text
	cost_label.text = str(data.cost)
	description_label.text = data.description
	
	# Update the sprite if an image path exists
	if data.image_path and !data.image_path.is_empty():
		var img = load(data.image_path)
		if img:
			sprite.texture = img

func _input(event: InputEvent) -> void:
	if !is_draggable or !is_playable:
		return
		
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Check if the click is on this card
				var local_pos = to_local(mouse_event.position)
				if sprite.get_rect().has_point(local_pos):
					is_being_dragged = true
					drag_offset = local_pos
					original_position = position
					# Move card to top layer
					z_index = 10
					emit_signal("card_clicked", self)
					get_viewport().set_input_as_handled()
			else:
				# Mouse released
				if is_being_dragged:
					is_being_dragged = false
					z_index = 0
					emit_signal("card_dropped", self, get_global_mouse_position())
					get_viewport().set_input_as_handled()
	
	if event is InputEventMouseMotion and is_being_dragged:
		position = get_global_mouse_position() - drag_offset
		emit_signal("card_dragged", self)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	# Check for hover
	if !is_being_dragged and is_playable:
		var mouse_pos = get_global_mouse_position()
		var local_pos = to_local(mouse_pos)
		if sprite.get_rect().has_point(local_pos):
			scale = Vector2(1.1, 1.1)  # Slightly enlarge card
			emit_signal("card_hovered", self)
		else:
			scale = Vector2(1.0, 1.0)  # Normal size
			emit_signal("card_unhovered", self)

func set_selected(value: bool) -> void:
	is_selected = value
	selection_highlight.visible = is_selected

func play_card() -> void:
	animation_player.play("play_card")
	await animation_player.animation_finished
	# Card effect should be applied here or through a signal

func flip() -> void:
	animation_player.play("flip")
	await animation_player.animation_finished
	is_face_up = !is_face_up
	update_card_face()

func get_card_data() -> CardData:
	return data

func set_card_data(p_data: CardData) -> void:
	data = p_data
	update_card_data()
