# CharacterGenerationSystem.gd
# Generates characters (heroes, servants, managers) with stats, traits, etc.
class_name CharacterGenerationSystem
extends Node

var race_templates := {}
var childhood_backgrounds := []
var adulthood_backgrounds := []
var personality_traits := {}
var equipment_templates := {}

var last_char_id = -1

func _ready():
	randomize()
	load_character_data("res://character generation system/character data.json")
	print("CharacterGenerationSystem initialized.")

func load_character_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open character data file.")
		return

	var json_text = file.get_as_text()
	var json = JSON.parse_string(json_text)

	if json == null:
		push_error("Invalid JSON format.")
		return

	race_templates = json.get("race_templates", {})
	childhood_backgrounds = json.get("childhood_backgrounds", [])
	adulthood_backgrounds = json.get("adulthood_backgrounds", [])
	personality_traits = json.get("personality_traits", {})
	equipment_templates = json.get("equipment_templates", {})

func generate_character(is_hero: bool = true, specific_race: String = "") -> Character:
	last_char_id += 1

	var character: Character = Character.new()

	character.id = last_char_id
	character.is_hero = is_hero
	character.name = _generate_name()

	# 1. Random Race (or specified)
	var available_races = race_templates.keys()
	character["race"] = specific_race if specific_race in available_races else available_races[randi() % available_races.size()]
	var template = race_templates[character["race"]]

	# 2. Random Gender
	character["gender"] = "male" if randf() > 0.5 else "female"

	# 3. Backgrounds
	character["childhood_bg"] = childhood_backgrounds[randi() % childhood_backgrounds.size()]
	character["adulthood_bg"] = adulthood_backgrounds[randi() % adulthood_backgrounds.size()]

	# 4. Base Stats from Race Template
	for stat_name in template["base_stats_range"]:
		var s_range = template["base_stats_range"][stat_name]
		character["base_stats"][stat_name] = randi_range(s_range[0], s_range[1])
	
	# Initial combat stats (can be simple or complex)
	var combat_stats = {
		"hp": character["base_stats"].get("Combat_HP", 100),
		"max_hp": character["base_stats"].get("Combat_HP", 100),
		"damage": character["base_stats"].get("Combat_DMG", 10),
		"defense": randi_range(1,5) # Example
	}

	# 5. Personality Traits (1-2 traits)
	var num_traits = randi_range(1, 2)
	var available_traits = personality_traits.keys()
	for _i in range(num_traits):
		var trait_name = available_traits[randi() % available_traits.size()]
		if not trait_name in character["personality_traits"]: # Avoid duplicates
			character["personality_traits"].append(trait_name)

	# 6. Random Equipment
	character["equipment"]["main_hand"] = equipment_templates["main_hand"][randi() % equipment_templates["main_hand"].size()]
	character["equipment"]["armor"] = equipment_templates["armor"][randi() % equipment_templates["armor"].size()]
	if randf() > 0.7: # Chance for a ring
		character["equipment"]["ring"] = equipment_templates["rings"][randi() % equipment_templates["rings"].size()]
	if randf() > 0.7: # Chance for a necklace
		character["equipment"]["necklace"] = equipment_templates["necklaces"][randi() % equipment_templates["necklaces"].size()]

	# 7. Body Parts
	character["body_parts"] = template["body_parts"].duplicate(true) # Deep copy
	# Add properties like color (could be more detailed)
	for part in character["body_parts"]:
		character["body_parts"][part] = {"count": character["body_parts"][part], "color": _random_color_for_race(character["race"])}


	# 8. Stat Calculator (Race + Hormone Multiplier + Background + Traits)
	character["final_stats"] = character["base_stats"].duplicate(true)
	
	# Hormone multiplier (example for combat stats)
	var hormone_mult = template.get("hormone_multiplier", {}).get(character["gender"], 1.0)
	combat_stats["hp"] = int(combat_stats["hp"] * hormone_mult)
	combat_stats["max_hp"] = combat_stats["hp"]
	combat_stats["damage"] = int(combat_stats["damage"] * hormone_mult)

	# Background effects (simplified: +/- 1 to a random stat)
	for _bg_type in ["childhood_bg", "adulthood_bg"]:
		var random_stat_idx = randi() % character["final_stats"].keys().size()
		var stat_to_modify = character["final_stats"].keys()[random_stat_idx]
		if not stat_to_modify.begins_with("Combat_"): # Don't modify HP/DMG this way directly
			character["final_stats"][stat_to_modify] += randi_range(-1, 1)
			character["final_stats"][stat_to_modify] = max(1, character["final_stats"][stat_to_modify]) # Min 1

	# Trait effects
	for trait_name_str in character["personality_traits"]: # Ensure trait_name_str is a string
		var trait_data = personality_traits.get(trait_name_str, {})
		for stat_effect_name in trait_data.get("stat_effects", {}):
			var effect_value = trait_data["stat_effects"][stat_effect_name]
			if stat_effect_name == "Combat_HP_penalty_percent":
				combat_stats["hp"] = int(combat_stats["hp"] * (1.0 - effect_value))
				combat_stats["max_hp"] = combat_stats["hp"]
			elif stat_effect_name == "Combat_DMG_bonus":
				combat_stats["damage"] += effect_value
			elif character["final_stats"].has(stat_effect_name):
				character["final_stats"][stat_effect_name] += effect_value
				character["final_stats"][stat_effect_name] = max(1, character["final_stats"][stat_effect_name])

	character["combat_stats"] = combat_stats

	# 9. Description Generator
	character["description"] = _generate_description(character)
	
	# 10. Hybrid/Half-breed (simplified: could just be a trait or specific race template)
	if randf() < 0.05: # 5% chance of being a half-breed (very basic)
		var other_race_idx = randi() % available_races.size()
		var other_race = available_races[other_race_idx]
		if other_race != character["race"]:
			character["name"] += " (Half-" + other_race.capitalize() + ")"
			# Could mix some stats or body parts here - complex logic

	print("Generated Character: %s (%s %s)" % [character["name"], character["gender"], character["race"]])
	# print_character_sheet(character) # For debugging
	return character

func interbreed_characters(parent1: Character, parent2: Character) -> Character:
	var offspring: Character = Character.new()
	last_char_id += 1
	offspring.id = last_char_id

	if parent1["race"] == parent2["race"]:
		offspring["race"] = parent1["race"]
	else:
		offspring["race"] = "Half-" + parent1["race"] + "-" + parent2["race"]

	offspring["gender"] = ["male", "female"][randi() % 2]
	offspring["name"] = _generate_name()

	# Inherit stats, traits, etc. (simplified)
	# Inherit base_stats (averaging values)
	offspring.base_stats = {}
	for key in parent1.base_stats.keys():
		if parent2.base_stats.has(key):
			offspring.base_stats[key] = (parent1.base_stats[key] + parent2.base_stats[key]) / 2
		else:
			offspring.base_stats[key] = parent1.base_stats[key]

	# Same for final_stats and combat_stats (can also average or recalculate from base_stats)
	offspring.final_stats = {}
	offspring.combat_stats = {}
	for stats_name in ["final_stats", "combat_stats"]:
		offspring[stats_name] = {}
		for key in parent1[stats_name].keys():
			if parent2[stats_name].has(key):
				offspring[stats_name][key] = (parent1[stats_name][key] + parent2[stats_name][key]) / 2
			else:
				offspring[stats_name][key] = parent1[stats_name][key]

	# Merge personality traits (randomly pick, combine or mutate)
	offspring.personality_traits = []
	var combined_traits = parent1.personality_traits + parent2.personality_traits
	combined_traits = combined_traits.duplicate()
	combined_traits.shuffle()
	offspring.personality_traits = combined_traits.slice(0, 3)  # pick top 3 traits, for example

	# Inherit equipment (random choice from either parent)
	offspring.equipment = {}
	for slot in parent1.equipment.keys():
		if parent2.equipment.has(slot):
			offspring.equipment[slot] = parent1.equipment[slot] if randf() > 0.5 else parent2.equipment[slot]
		else:
			offspring.equipment[slot] = parent1.equipment[slot]

	# Inherit body parts (random or blend logic)
	offspring.body_parts = {}
	for part in parent1.body_parts.keys():
		if parent2.body_parts.has(part):
			offspring.body_parts[part] = parent1.body_parts[part] if randf() > 0.5 else parent2.body_parts[part]
		else:
			offspring.body_parts[part] = parent1.body_parts[part]

	offspring.description = _generate_description(offspring)

	# Background effects (simplified: +/- 1 to a random stat)
	for _bg_type in ["childhood_bg", "adulthood_bg"]:
		var random_stat_idx = randi() % offspring["final_stats"].keys().size()
		var stat_to_modify = offspring["final_stats"].keys()[random_stat_idx]
		if not stat_to_modify.begins_with("Combat_"): # Don't modify HP/DMG this way directly
			offspring["final_stats"][stat_to_modify] += randi_range(-1, 1)
			offspring["final_stats"][stat_to_modify] = max(1, offspring["final_stats"][stat_to_modify]) # Min 1

	return offspring


func _generate_name() -> String:
	# Simple name generator
	var first_parts = ["Bel", "Gar", "El", "Mor", "Zyl", "Fael"]
	var mid_parts = ["a", "i", "o", "u", "en", "ar"]
	var last_parts = ["thor", "dred", "wyn", "mir", "nar", "ion"]
	return first_parts.pick_random() + mid_parts.pick_random() + last_parts.pick_random() 

func _random_color_for_race(race_name: String) -> String:
	match race_name:
		"Human": return ["fair", "tanned", "dark"][randi() % 3] + " skin"
		"Orc": return ["green", "grey", "dark green"][randi() % 3] + " skin"
		"Elf": return ["pale", "sun-kissed", "moonlit"][randi() % 3] + " skin"
		_: return "nondescript"

func _generate_description(character: Character) -> String:
	var desc = "%s is a %s %s, known for being %s. " % [
		character["name"], character["gender"], character["race"], 
		", ".join(character["personality_traits"]) if character["personality_traits"] else "rather plain"
	]
	desc += "Their upbringing as a %s and later life as a %s shaped them. " % [character["childhood_bg"], character["adulthood_bg"]]
	if character["equipment"].has("main_hand"):
		desc += "They often carry a %s. " % character["equipment"]["main_hand"]
	# Add body part descriptions
	var body_part_descs = []
	for part_name in character["body_parts"]:
		var part_info = character["body_parts"][part_name]
		body_part_descs.append(str(int(part_info["count"])) + " " + part_info["color"].replace(" skin","") + " " + part_name)
	if body_part_descs:
		desc += "Visibly, they have %s." % (", ".join(body_part_descs))
	return desc

func print_character_sheet(character: Character):
	print("\n--- CHARACTER SHEET ---")
	print("ID: %s" % character["id"])
	print("Name: %s" % character["name"])
	print("Race: %s, Gender: %s" % [character["race"], character["gender"]])
	print("Backgrounds: %s (Childhood), %s (Adulthood)" % [character["childhood_bg"], character["adulthood_bg"]])
	print("Stats:")
	for stat_name in character["final_stats"]:
		print("  %s: %s" % [stat_name.capitalize(), character["final_stats"][stat_name]])
	print("Personality Traits: %s" % ", ".join(character["personality_traits"]))
	print("Equipment:")
	for slot in character["equipment"]:
		print("  %s: %s" % [slot.capitalize(), character["equipment"][slot]])
	print("Body Parts:")
	for part_name in character["body_parts"]:
		var part_info = character["body_parts"][part_name]
		print("  %s: Count %s, Color/Type: %s" % [part_name.capitalize(), int(part_info["count"]), part_info["color"]])
	print("Description: %s" % character["description"])
	print("-----------------------\n")
