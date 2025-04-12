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
	title_label.text = "CLICK BEETLE RPG"

func _on_start_button_pressed() -> void:
	# Start a new game
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")

func _on_deck_button_pressed() -> void:
	# Go to deck builder (for now just return to main menu)
	print("Deck builder not implemented yet")

func _on_options_button_pressed() -> void:
	# Show options menu (for now just print a message)
	print("Options not implemented yet")

func _on_quit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
