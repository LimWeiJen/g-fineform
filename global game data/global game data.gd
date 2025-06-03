# GlobalGameData.gd
# Autoload this script to store global game state and references.
extends Node

# --- General Game State ---
var research_progress: Dictionary = {
	"Summoning": {"xp": 0, "unlocked_spells": []},
	"Elemental": {"xp": 0, "unlocked_spells": []},
	"MindControl": {"xp": 0, "unlocked_spells": []}
}

var characters: Array[Character] = []

func update_research_xp(tree_name: String, amount: int):
	if research_progress.has(tree_name):
		research_progress[tree_name]["xp"] += amount
		print("%s tree XP increased by %s. Total: %s" % [tree_name, amount, research_progress[tree_name]["xp"]])
		# Add logic for unlocking spells based on XP

func unlock_spell(tree_name: String, spell_name: String):
	if research_progress.has(tree_name):
		if not spell_name in research_progress[tree_name]["unlocked_spells"]:
			research_progress[tree_name]["unlocked_spells"].append(spell_name)
			print("Spell unlocked in %s: %s" % [tree_name, spell_name])