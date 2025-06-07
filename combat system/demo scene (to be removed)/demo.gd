extends Control

@onready var character_1_select = $PanelContainer/HBoxContainer/OptionButton
@onready var character_2_select = $PanelContainer/HBoxContainer/OptionButton2
@onready var begin_duel_btn = $PanelContainer/HBoxContainer/Button
@onready var log_display = $PanelContainer/ScrollContainer/VBoxContainer
@onready var combat_system: CombatSystem = $CombatSystem

func _ready():
	begin_duel_btn.connect("pressed", begin_duel)
	reload_characters()
	combat_system.connect("duel_log_updated", update_log)

func reload_characters():
	character_1_select.clear()
	character_2_select.clear()
	for character in GlobalGameData.characters:
		character_1_select.add_item(character.name, character.id)
		character_2_select.add_item(character.name, character.id)

func begin_duel():
	var char1 = GlobalGameData.characters[character_1_select.get_selected_id() - 1]
	var char2 = GlobalGameData.characters[character_2_select.get_selected_id() - 1]
	combat_system.start_character_duel(char1, char2, char1.id)

func update_log():
	for child in log_display.get_children():
		child.queue_free()
	for lg in combat_system.active_duel.log:
		var label = Label.new()
		label.text = lg
		log_display.add_child(label)
	
