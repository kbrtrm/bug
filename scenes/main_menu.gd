extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var deck_button: Button = $VBoxContainer/DeckButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	# Connect button signals
	start_button.pressed.connect(_on_start_button_pressed)
	deck_button.pressed.connect(_on_deck_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Set title
	title_label.text = "BUG GAME"

func _on_start_button_pressed() -> void:
	# Start a new game
	GameManager.start_game()
	# Go directly to battle scene for testing
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")

func _on_deck_button_pressed() -> void:
	# Go to deck builder
	get_tree().change_scene_to_file("res://scenes/deck_builder.tscn")

func _on_options_button_pressed() -> void:
	# Show options menu
#	var options_dialog = preload("res://scenes/options_dialog.tscn").instantiate()
#	add_child(options_dialog)
#	options_dialog.popup_centered()
	pass

func _on_quit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
