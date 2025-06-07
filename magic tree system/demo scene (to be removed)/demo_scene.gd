extends Control

@onready var magic_tree: MagicTreeSystem = $MagicTreeSystem
@onready var summoning_tree = $PanelContainer/HBoxContainer/Summoning
@onready var elemental_tree = $PanelContainer/HBoxContainer/Elemental
@onready var mind_control_tree = $PanelContainer/HBoxContainer/MindControl
@onready var spell_details_display = $PanelContainer/HBoxContainer/Details
@onready var cast_spell_btn = $"PanelContainer/HBoxContainer/Details/Cast Spell"

func _ready():
	summoning_tree.get_node("Button").connect("pressed", add_xp_to_tree.bindv(["Summoning", 50]))
	elemental_tree.get_node("Button").connect("pressed", add_xp_to_tree.bindv(["Elemental", 50]))
	mind_control_tree.get_node("Button").connect("pressed", add_xp_to_tree.bindv(["MindControl", 50]))
	cast_spell_btn.connect("pressed", cast_spell)

	display_tree()

func add_xp_to_tree(tree_name: String, amount: int):
	magic_tree.gain_xp(tree_name, amount)
	display_tree()

func display_tree():
	var research_progress = magic_tree.get_global_research_progress()
	# Summoning
	summoning_tree.get_node("Label").text = "Summoning: %s XP" % research_progress["Summoning"]["xp"]
	for child in summoning_tree.get_node("Tree").get_children():
		child.queue_free()
	var unlocked_spells = research_progress["Summoning"]["unlocked_spells"]
	for spell_name in magic_tree.spellbook["Summoning"]:
		var spell_btn = Button.new() 
		spell_btn.text = spell_name
		if not spell_name in unlocked_spells:
			spell_btn.modulate.a = 0.5
		spell_btn.connect("pressed", display_spell_details.bindv([spell_name, "Summoning"]))
		summoning_tree.get_node("Tree").add_child(spell_btn)

	# Elemental
	elemental_tree.get_node("Label").text = "Elemental: %s XP" % research_progress["Elemental"]["xp"]
	for child in elemental_tree.get_node("Tree").get_children():
		child.queue_free()
	unlocked_spells = research_progress["Elemental"]["unlocked_spells"]
	for spell_name in magic_tree.spellbook["Elemental"]:
		var spell_btn = Button.new() 
		spell_btn.text = spell_name
		if not spell_name in unlocked_spells:
			spell_btn.modulate.a = 0.5
		spell_btn.connect("pressed", display_spell_details.bindv([spell_name, "Elemental"]))
		elemental_tree.get_node("Tree").add_child(spell_btn)

	# Mind Control
	mind_control_tree.get_node("Label").text = "Mind Control: %s XP" % research_progress["MindControl"]["xp"]
	for child in mind_control_tree.get_node("Tree").get_children():
		child.queue_free()
	unlocked_spells = research_progress["MindControl"]["unlocked_spells"]
	for spell_name in magic_tree.spellbook["MindControl"]:
		var spell_btn = Button.new() 
		spell_btn.text = spell_name
		if not spell_name in unlocked_spells:
			spell_btn.modulate.a = 0.5
		spell_btn.connect("pressed", display_spell_details.bindv([spell_name, "MindControl"]))
		mind_control_tree.get_node("Tree").add_child(spell_btn)

func display_spell_details(spell_name: String, tree_name: String):
	var spell_details = magic_tree.get_spell_details(spell_name, tree_name)
	var other_attributes = "Other Attributes: \n"
	spell_details_display.get_node("Label").text = spell_name
	spell_details_display.get_node("Tree").text = tree_name
	for details in spell_details:
		match details:
			"xp_cost":
				spell_details_display.get_node("XP Cost").text = "XP Cost: %s" % spell_details[details]
			"description":
				spell_details_display.get_node("Description").text = "Description: %s" % spell_details[details]
			"effect_type":
				spell_details_display.get_node("Effect Type").text = "Effect Type: %s" % spell_details[details]
			"prerequisites":
				spell_details_display.get_node("Prerequisites").text = "Prerequisites: \n %s" % "\n".join(spell_details[details])
			_:
				other_attributes += "%s: %s\n" % [details, str(spell_details[details])]
	spell_details_display.get_node("Other Attributes").text = other_attributes
	
func cast_spell():
	magic_tree.cast_spell(spell_details_display.get_node("Label").text, spell_details_display.get_node("Tree").text)
	display_tree()