extends Control

@onready var hero_select = $"PanelContainer/HBoxContainer/Hero Team/VBoxContainer/HBoxContainer/OptionButton"
@onready var add_hero_btn = $"PanelContainer/HBoxContainer/Hero Team/VBoxContainer/HBoxContainer/Button"
@onready var hero_list = $"PanelContainer/HBoxContainer/Hero Team/VBoxContainer/VBoxContainer"

@onready var monster_select = $"PanelContainer/HBoxContainer/Monster Team/VBoxContainer/HBoxContainer/OptionButton"
@onready var add_monster_btn = $"PanelContainer/HBoxContainer/Monster Team/VBoxContainer/HBoxContainer/Button"
@onready var monster_list = $"PanelContainer/HBoxContainer/Monster Team/VBoxContainer/VBoxContainer"

@onready var begin_battle_btn = $Button
@onready var log_display = $"PanelContainer/HBoxContainer/ScrollContainer2/VBoxContainer"

@onready var character_generation_system = $"../Character Generation System"
@onready var overworld_combat_system: OverWorldCombatSystem = $OverWorldCombatSystem

var hero_team: Array[Character] = []
var monster_team: Array[Character] = []

func _ready():
	add_hero_btn.connect("pressed", add_hero)
	add_monster_btn.connect("pressed", add_monster)
	begin_battle_btn.connect("pressed", begin_battle)
	overworld_combat_system.connect("update_battle_log", update_log)
	overworld_combat_system.connect("update_battle_log", list_out_teams)
	overworld_combat_system.connect("battle_ended", reload_characters)
	overworld_combat_system.connect("battle_ended", list_out_teams)
	overworld_combat_system.connect("battle_ended", update_log)

func list_out_teams():
	for child in hero_list.get_children():
		child.queue_free()
	for child in monster_list.get_children():
		child.queue_free()
	
	for hero in hero_team:
		var label = Label.new()
		label.text = hero.name
		hero_list.add_child(label)
	for monster in monster_team:
		var label = Label.new()
		label.text = monster.name
		monster_list.add_child(label)

func reload_characters():
	hero_select.clear()
	monster_select.clear()
	for character in GlobalGameData.characters:
		if character.is_hero:
			hero_select.add_item(character.name, character.id)
		else:
			monster_select.add_item(character.name, character.id)

func add_hero():
	var character = GlobalGameData.characters[hero_select.get_selected_id()]
	hero_team.append(character)
	list_out_teams()

func add_monster():
	var character = GlobalGameData.characters[monster_select.get_selected_id()]
	monster_team.append(character)
	list_out_teams()

func begin_battle():
	for display in log_display.get_children():
		display.queue_free()
	overworld_combat_system.start_battle(hero_team, monster_team)

func update_log():
	for child in log_display.get_children():
		child.queue_free()
	for lg in overworld_combat_system.battle_log:
		var label = Label.new()
		label.text = lg
		log_display.add_child(label)
	character_generation_system.list_out_all_char()
