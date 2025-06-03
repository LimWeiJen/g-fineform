# MagicTreeSystem.gd
# Manages magic research, spell unlocking, and casting.
class_name MagicTreeSystem
extends Node

# Spell definitions (could be loaded from JSON/Resource)
# Format: tree_name: { spell_name: {xp_cost, prerequisites, effect_type, effect_value, target_type}}
var spellbook: Dictionary = {}

signal spell_unlocked(tree_name, spell_name)
signal spell_cast(caster, spell_name, targets, results)

func _ready():
	load_spellbook("res://magic tree system/spellbook.json")
	print("MagicTreeSystem initialized.")
	# Example: Grant some starting XP
	# gain_xp("Summoning", 50)

func load_spellbook(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open character data file.")
		return

	var json_text = file.get_as_text()
	var json = JSON.parse_string(json_text)

	if json == null:
		push_error("Invalid JSON format.")
		return
	
	spellbook = json

func get_global_research_progress() -> Dictionary:
	if get_node("/root/GlobalGameData"):
		return get_node("/root/GlobalGameData").research_progress
	printerr("MagicTreeSystem: GlobalGameData not found!")
	return {} 

func gain_xp(tree_name: String, amount: int):
	var research_progress = get_global_research_progress()
		
	if research_progress.has(tree_name):
		research_progress[tree_name]["xp"] += amount
		print("%s XP gained for %s tree. Total: %s" % [amount, tree_name, research_progress[tree_name]["xp"]])
		check_for_unlocks(tree_name)
	else:
		printerr("Magic tree '%s' not found for XP gain." % tree_name)

func check_for_unlocks(tree_name: String):
	var research_progress = get_global_research_progress()

	if not research_progress.has(tree_name) or not spellbook.has(tree_name):
		return

	var tree_spells = spellbook[tree_name]
	var current_xp = research_progress[tree_name]["xp"]
	var unlocked_list = research_progress[tree_name]["unlocked_spells"]

	for spell_name in tree_spells:
		if not spell_name in unlocked_list:
			var spell_data = tree_spells[spell_name]
			if current_xp >= spell_data["xp_cost"]:
				var prereqs_met = true
				for prereq_spell in spell_data.get("prerequisites", []):
					if not prereq_spell in unlocked_list:
						prereqs_met = false
						break
				if prereqs_met:
					_unlock_spell_internal(tree_name, spell_name) # Use internal to update GlobalGameData via its methods
					
func _unlock_spell_internal(tree_name: String, spell_name: String):
	if get_node("/root/GlobalGameData"):
		get_node("/root/GlobalGameData").unlock_spell(tree_name, spell_name)
		emit_signal("spell_unlocked", tree_name, spell_name)
		# No print here, GlobalGameData.unlock_spell does it.


func can_cast_spell(caster_char_data: Dictionary, spell_name: String, tree_name: String) -> bool:
	var research_progress = get_global_research_progress()
	if research_progress.empty() and not get_node("/root/GlobalGameData"): return false

	if not research_progress.has(tree_name) or not spell_name in research_progress[tree_name]["unlocked_spells"]:
		print("Cannot cast: Spell '%s' not unlocked or tree '%s' invalid." % [spell_name, tree_name])
		return false
	
	return true

func cast_spell(caster_char_data: Dictionary, spell_name: String, tree_name: String, targets: Array) -> Dictionary:
	if not can_cast_spell(caster_char_data, spell_name, tree_name):
		return {"success": false, "reason": "Cannot cast spell."}

	var spell_data = spellbook[tree_name][spell_name]
	print("%s casts '%s' from %s tree on %s targets." % [caster_char_data.get("name", "Caster"), spell_name, tree_name, targets.size()])

	# Apply spell effects (this is highly game-specific)
	var results = {"success": true, "effects_applied": []}
	
	match spell_data["effect_type"]:
		"summon_unit":
			# Logic to spawn a unit (e.g., in CombatSystem or DungeonGridSystem)
			print("Effect: Summoning unit '%s'." % spell_data["unit_id"])
			results["effects_applied"].append("Summoned %s" % spell_data["unit_id"])
			# Example: CombatSystem.add_summoned_unit(caster_char_data["id"], spell_data["unit_id"], spell_data["duration"])
		"direct_damage":
			for target_char_data in targets: # Assuming targets are character dictionaries
				var damage = spell_data["base_damage"]
				# Apply damage to target_char_data (e.g., target_char_data["stats"]["Combat"]["hp"] -= damage)
				print("Effect: Dealing %s %s damage to %s." % [damage, spell_data["damage_type"], target_char_data.get("name", "Target")])
				results["effects_applied"].append("Dealt %s damage to %s" % [damage, target_char_data.get("name", "Target")])
		"direct_damage_status":
			for target_char_data in targets:
				var damage = spell_data["base_damage"]
				var status = spell_data["status_effect"]
				var duration = spell_data["duration"]
				print("Effect: Dealing %s %s damage and applying %s for %s turns to %s." % [damage, spell_data["damage_type"], status, duration, target_char_data.get("name", "Target")])
				results["effects_applied"].append("Dealt %s damage, applied %s to %s" % [damage, status, target_char_data.get("name", "Target")])
		"convert_attempt":
			# Logic for CorruptionSystem to handle conversion
			if get_node("/root/CorruptionSystem"):
				for target_char_data in targets:
					var success = get_node("/root/CorruptionSystem").attempt_magic_conversion(caster_char_data, target_char_data, spell_data)
					results["effects_applied"].append("Attempted conversion on %s: %s" % [target_char_data.get("name", "Target"), "Succeeded" if success else "Failed"])
			else:
				print("CorruptionSystem not found for conversion spell.")

	# Deduct mana, start cooldowns, etc.
	# gain_xp(tree_name, 10) # XP for casting, if applicable

	emit_signal("spell_cast", caster_char_data, spell_name, targets, results)
	return results

func get_unlocked_spells(tree_name: String = "") -> Array:
	var research_progress = get_global_research_progress()
	if research_progress.empty() and not get_node("/root/GlobalGameData"): return []

	if tree_name == "": # Get all unlocked spells
		var all_spells = []
		for t_name in research_progress:
			all_spells.append_array(research_progress[t_name]["unlocked_spells"])
		return all_spells
	elif research_progress.has(tree_name):
		return research_progress[tree_name]["unlocked_spells"]
	return []

func get_spell_details(spell_name: String, tree_name: String) -> Dictionary:
	if spellbook.has(tree_name) and spellbook[tree_name].has(spell_name):
		return spellbook[tree_name][spell_name]
	return {}
