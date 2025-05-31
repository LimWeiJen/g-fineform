extends Node

const BASE_STATS = ["Diplomacy", "Martial", "Stewardship", "Intrigue", "Learning", "Combat"]

@onready var RaceData = preload("res://character generation system/race data.gd")
@onready var BackgroundData = preload("res://character generation system/background data.gd")
@onready var TraitData = preload("res://character generation system/trait data.gd")
@onready var EquipmentData = preload("res://character generation system/equipment data.gd")

func generate_character(race1 = "", race2 = "") -> Dictionary:
	var character = {}
	character.name = "Unnamed"
	character.gender = ["Male", "Female"].pick_random()

	character.race = race1 if race2 == "" else "Hybrid"
	var multipliers = _get_race_multipliers(race1, race2)

	character.childhood = BackgroundData.BACKGROUNDS["childhood"].keys().pick_random()
	character.adulthood = BackgroundData.BACKGROUNDS["adulthood"].keys().pick_random()

	character.traits = [TraitData.TRAITS.keys().pick_random()]

	character.stats = {}
	for stat in BASE_STATS:
		var base = randi_range(1, 5)
		var mult = multipliers.get(stat, 1.0)
		var bg_bonus = BackgroundData.BACKGROUNDS["childhood"].get(character.childhood, {}).get(stat, 0)
		bg_bonus += BackgroundData.BACKGROUNDS["adulthood"].get(character.adulthood, {}).get(stat, 0)
		var trait_bonus = 0
		for t in character["traits"]:
			trait_bonus += TraitData.TRAITS[t].get(stat, 0)
		character.stats[stat] = int(round((base + bg_bonus + trait_bonus) * mult))
    
	# Equipment
	character.equipment = {
		"main_hand": EquipmentData.MAIN_HAND.pick_random(),
		"armor": EquipmentData.ARMOR.pick_random(),
		"accessory": EquipmentData.ACCESSORIES.pick_random()
	}

	# Body parts (cosmetic)
	character.body_parts = {
		"skin_color": ["Red", "Green", "Blue", "Pale", "Dark"].pick_random(),
		"horn_type": ["None", "Curved", "Straight"].pick_random(),
		"tail": ["Yes", "No"].pick_random()
	}

	# Description
	character.description = _generate_description(character)
	return character

func _get_race_multipliers(race1: String, race2: String) -> Dictionary:
	if race2 == "":
		return RaceData.RACES.get(race1, {}).multipliers
	var combined = {}
	for stat in BASE_STATS:
		var m1 = RaceData.RACES.get(race1, {}).multipliers.get(stat, 1.0)
		var m2 = RaceData.RACES.get(race2, {}).multipliers.get(stat, 1.0)
		combined[stat] = (m1 + m2) / 2.0
	return combined

func _generate_description(character: Dictionary) -> String:
	return "%s %s of %s origin with %s skin and %s horns." % [
		character.gender,
		character.race,
		character.adulthood,
		character.body_parts["skin_color"],
		character.body_parts["horn_type"]
	]

