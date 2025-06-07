# MagicTreeSystem.gd
# Manages magic research, spell unlocking, and casting.
class_name MagicTreeSystem
extends Node

# Spell definitions (could be loaded from JSON/Resource)
# Format: tree_name: { spell_name: {xp_cost, prerequisites, effect_type, effect_value, target_type}}
var spellbook: Dictionary = {}

signal spell_unlocked()
signal spell_cast()

@export var active_overworld_combat_system: OverWorldCombatSystem
@export var active_combat_system: CombatSystem

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


func can_cast_spell(spell_name: String, tree_name: String) -> bool:
	var research_progress = get_global_research_progress()

	if not research_progress.has(tree_name) or not spell_name in research_progress[tree_name]["unlocked_spells"]:
		print("Cannot cast: Spell '%s' not unlocked or tree '%s' invalid." % [spell_name, tree_name])
		return false
	
	return true

func cast_spell(spell_name: String, tree_name: String) -> Dictionary:
	if not can_cast_spell(spell_name, tree_name):
		return {"success": false, "reason": "Cannot cast spell."}

	var spell_data = spellbook[tree_name][spell_name]
	print("casted '%s' from %s tree on %s targets." % [spell_name, tree_name])

	# Apply spell effects (this is highly game-specific)
	var results = {"success": true, "effects_applied": []}
	
	match spell_data["effect_type"]:

		# Only applicable in over world combat system
		"summon_unit":
			# Logic to spawn a unit (e.g., in CombatSystem or DungeonGridSystem)
			print("Effect: Summoning unit '%s'." % spell_data["unit_id"])
			results["effects_applied"].append("Summoned %s" % spell_data["unit_id"])

			# Summon a random hero into the current battle
			var curr_hero_in_battle: Array = active_overworld_combat_system.team_hero
			var all_hero = GlobalGameData.characters.filter(func (character: Character): return character.is_hero and not curr_hero_in_battle.has(character))
			var random_hero = all_hero.pick_random()

			# if spell name is strengthen summon, add hp to hero
			if spell_name == "StrengthenSummon":
				random_hero.combat_stats["hp"] += 10

			active_overworld_combat_system.team_hero.append(random_hero)

			# Log the event
			if not active_overworld_combat_system.is_duel_active or not active_overworld_combat_system.active_duel.has("log"): return {"success": false, "reason": "Cannot cast spell."}
			active_overworld_combat_system.battle_log.append("Hero %s has been summoned." % random_hero.name)
			if spell_name == "StrengthenSummon":
				active_overworld_combat_system.battle_log.append("Hero %s has been strengthened." % random_hero.name)
			active_overworld_combat_system.emit_signal("update_battle_log")


		"direct_damage":
			if active_overworld_combat_system.battle_begun:
				for monster in active_overworld_combat_system.team_monster:
					monster.stats["Combat_HP"] -= spell_data["base_damage"]
					results["effects_applied"].append("Dealt %s damage to %s" % [spell_data["base_damage"], monster.name])

					# Log the event
					if not active_overworld_combat_system.is_duel_active or not active_overworld_combat_system.active_duel.has("log"): return {"success": false, "reason": "Cannot cast spell."}
					active_overworld_combat_system.battle_log.append("Monster %s has been dealt %s damage." % [monster.name, spell_data["base_damage"]])
					active_overworld_combat_system.emit_signal("update_battle_log")
			else:
				var monster = active_combat_system.active_duel.character_b if active_combat_system.active_duel.character_a.is_hero else active_combat_system.active_duel.character_a
				monster.stats["Combat_HP"] -= spell_data["base_damage"]
				results["effects_applied"].append("Dealt %s damage to %s" % [spell_data["base_damage"], monster.name])

				# Log the event
				if not active_combat_system.is_duel_active: return {"success": false, "reason": "Cannot cast spell."}
				active_combat_system._add_log("Hero %s has been dealt %s damage." % [monster.name, spell_data["base_damage"]])

		"convert_attempt":
			# identify the monster with the lowest martial stat
			var new_team_monster = active_overworld_combat_system.team_monster.duplicate(true)
			new_team_monster.sort_custom(func (a: Character, b: Character): return a.stats.Martial < b.stats.Martial)
			var monster_to_convert: Character = new_team_monster[0]
			if randf_range(spell_data["success_chance"], 2) >= 1:
				monster_to_convert.is_hero = true
				active_overworld_combat_system.team_hero.append(monster_to_convert)
				active_overworld_combat_system.team_monster = active_overworld_combat_system.team_monster.filter(func (monster: Character): return monster.id != monster_to_convert.id)

				# Log the event
				if not active_overworld_combat_system.is_duel_active or not active_overworld_combat_system.active_duel.has("log"): return {"success": false, "reason": "Cannot cast spell."}
				active_overworld_combat_system.battle_log.append("Monster %s has been converted." % monster_to_convert.name)
				active_overworld_combat_system.emit_signal("update_battle_log")
			else:
				# Log the event
				if not active_overworld_combat_system.is_duel_active or not active_overworld_combat_system.active_duel.has("log"): return {"success": false, "reason": "Cannot cast spell."}
				active_overworld_combat_system.battle_log.append("Attempt to convert %s failed." % monster_to_convert.name)
				active_overworld_combat_system.emit_signal("update_battle_log")
	
		"remove_monster":
			# identify the monster with the lowest martial stat
			var new_team_monster = active_overworld_combat_system.team_monster.duplicate(true)
			new_team_monster.sort_custom(func (a: Character, b: Character): return a.stats.Martial < b.stats.Martial)
			var monster_to_remove: Character = new_team_monster[0]
			if randf_range(spell_data["success_chance"], 2) >= 1:
				active_overworld_combat_system.team_monster = active_overworld_combat_system.team_monster.filter(func (monster: Character): return monster.id != monster_to_remove.id)

				# Log the event
				if not active_overworld_combat_system.is_duel_active or not active_overworld_combat_system.active_duel.has("log"): return {"success": false, "reason": "Cannot cast spell."}
				active_overworld_combat_system.battle_log.append("Monster %s has been removed." % monster_to_remove.name)
				active_overworld_combat_system.emit_signal("update_battle_log")
			else:
				# Log the event
				if not active_overworld_combat_system.is_duel_active or not active_overworld_combat_system.active_duel.has("log"): return {"success": false, "reason": "Cannot cast spell."}
				active_overworld_combat_system.battle_log.append("Attempt to remove %s failed." % monster_to_remove.name)
				active_overworld_combat_system.emit_signal("update_battle_log")

	# Deduct mana, start cooldowns, etc.
	# gain_xp(tree_name, 10) # XP for casting, if applicable

	emit_signal("spell_cast")
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
