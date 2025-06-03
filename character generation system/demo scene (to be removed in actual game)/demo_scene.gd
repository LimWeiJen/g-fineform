extends Control

@onready var generate_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/Button
@onready var interbreed_button: Button = $PanelContainer/VBoxContainer/HBoxContainer3/Interbreed
@onready var hero_checkbox: CheckBox = $PanelContainer/VBoxContainer/HBoxContainer/CheckBox
@onready var race_option_button: OptionButton = $PanelContainer/VBoxContainer/HBoxContainer/OptionButton
@onready var characters_list: VBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer2/VBoxContainer
@onready var label: Label = $PanelContainer/VBoxContainer/HBoxContainer2/ScrollContainer/Label
@onready var interbreed_panel = $"Interbreed Panel"
@onready var parent1_select: OptionButton = $"Interbreed Panel/HBoxContainer/OptionButton"
@onready var parent2_select: OptionButton = $"Interbreed Panel/HBoxContainer/OptionButton2"
@onready var start_interbreed_button: Button = $"Interbreed Panel/HBoxContainer/Button"

@onready var character_generator: CharacterGenerationSystem = $CharacterGenerationSystem

var curr_character: Character

func _ready():
	generate_button.connect("pressed", generate_char)
	interbreed_button.connect("pressed", show_interbreed_panel)
	start_interbreed_button.connect("pressed", interbreed)

func interbreed():
	var parent1 = GlobalGameData.characters[parent1_select.get_selected_id()-1]
	var parent2 = GlobalGameData.characters[parent2_select.get_selected_id()-1]
	var new_char = character_generator.interbreed_characters(parent1, parent2)
	display_character(new_char)
	curr_character = new_char
	save_char()
	interbreed_panel.visible = false

func show_interbreed_panel():
	interbreed_panel.visible = true
	parent1_select.clear()
	parent2_select.clear()
	for character in GlobalGameData.characters:
		parent1_select.add_item(character.name, character.id)
		parent2_select.add_item(character.name, character.id)

func list_out_all_char():
	for child in characters_list.get_children():
		child.queue_free()
	for character in GlobalGameData.characters:
		var btn = Button.new()
		btn.name = str(character.id)
		btn.text = character.name
		btn.connect("pressed", get_char.bind(int(btn.name)))
		characters_list.add_child(btn)

func display_character(character):
	var display_text = ""
	display_text += "\n--- CHARACTER SHEET --- \n"
	display_text += "ID: %s \n" % character["id"]
	display_text += "Name: %s \n" % character["name"]
	display_text += "Race: %s, Gender: %s \n" % [character["race"], character["gender"]]
	display_text += "Backgrounds: %s (Childhood), %s (Adulthood) \n" % [character["childhood_bg"], character["adulthood_bg"]]
	display_text += "Stats: \n"
	for stat_name in character["final_stats"]:
		display_text += "  %s: %s \n" % [stat_name.capitalize(), character["final_stats"][stat_name]]
	display_text += "Personality Traits: %s \n" % ", ".join(character["personality_traits"])
	display_text += "Equipment: \n"
	for slot in character["equipment"]:
		display_text += "  %s: %s \n" % [slot.capitalize(), character["equipment"][slot]]
	display_text += "Body Parts: \n"
	for part_name in character["body_parts"]:
		var part_info = character["body_parts"][part_name]
		display_text += "  %s: Count %s, Color/Type: %s \n" % [part_name.capitalize(), int(part_info["count"]), part_info["color"]]
	display_text += "Description: %s \n" % character["description"]
	display_text += "-----------------------\n"
	label.text = display_text

func get_char(id: int):
	curr_character = GlobalGameData.characters[id]
	display_character(curr_character)

func generate_char():
	var race = race_option_button.get_item_text(race_option_button.get_selected_id()) if race_option_button.get_selected_id() != -1 else "Random"
	var new_char = character_generator.generate_character(
		hero_checkbox.button_pressed,
		race if race != "Random" else ""
	)
	display_character(new_char)
	curr_character = new_char
	save_char()

func save_char():
	GlobalGameData.characters.append(curr_character)
	list_out_all_char()
