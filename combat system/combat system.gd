# CombatSystem.gd
# Handles dungeon combat (1v1 duels) and overworld army combat.
class_name CombatSystem
extends Node

# --- Dungeon Duel System ---
var active_duel: Dictionary = {
	# "character_a": {}, # Full data from CharGen
	# "character_b": {},
	# "current_attacker_id": "",
	# "current_opponent_id": "",
	# "round": 0,
	# "log": []
}
var is_duel_active: bool = false
var winner_character: Character
var last_duel_log: Array = []

# Emitted when a duel starts. Args: char_A_stats, char_B_stats, player_aligned_char_id, first_attacker_id
signal duel_started(character_a_combat_stats, character_b_combat_stats, player_aligned_id, active_turn_char_id)
# Emitted when it's an opportunity for the player-aligned character to act (cast spell or attack)
signal request_player_action(active_char_id_in_duel, opponent_char_id_in_duel, current_round)
# Emitted for each significant combat event. Arg: log_entry_string
signal duel_log_updated()
# Emitted when a character's HP/MP or status changes. Args: char_id_in_duel, new_hp, new_max_hp, new_mp, new_max_mp (or full combat_stats dict)
signal duel_character_stats_changed(char_id, new_hp, new_max_hp) # Simplified for HP for now
# Emitted when the duel ends. Args: winner_combat_stats, loser_combat_stats, final_log_array
signal duel_ended(winner_stats, loser_stats, combat_log)

func _ready():
	print("CombatSystem initialized.")
	connect("request_player_action", player_proceed_duel_turn)

# --- DUEL SYSTEM FUNCTIONS ---

func start_character_duel(character_a: Character, character_b: Character, player_aligned_char_id: int):
	if is_duel_active:
		print("COMBAT_SYSTEM: Cannot start new duel, one is already active.")
		return

	if character_a.stats["Martial"] < 5.0 and randf() < 0.5:
		_add_log("%s fled the duel due to low martial!" % character_a.name)
		winner_character = character_b
		return
	if character_b.stats["Martial"] < 5.0 and randf() < 0.5:
		_add_log("%s fled the duel due to low martial!" % character_b.name)
		winner_character = character_a
		return

	active_duel = {
		"character_a": character_a,
		"character_b": character_b,
		"player_aligned_char_id": player_aligned_char_id,
		"current_attacker_id": character_a.id, # Char A starts by default (can be randomized)
		"current_opponent_id": character_b.id,
		"round": 1,
		"log": []
	}
	is_duel_active = true

	_add_log("Duel started between %s and %s!" % [character_a.name, character_b.name])
	
	# Determine who goes first (e.g., higher Martial or random, for now A starts)
	
	emit_signal("duel_started")
	
	# Initial state: if player's aligned character is up first, request action. Otherwise, AI acts.
	if active_duel.current_attacker_id == active_duel.player_aligned_char_id:
		emit_signal("request_player_action")
	else: # AI's turn first
		_execute_attack_action(active_duel.current_attacker_id)
		# After AI attack, check win, then if player's turn, request action.
		if not _check_duel_winner():
			emit_signal("request_player_action")

func player_proceed_duel_turn():
	await get_tree().create_timer(1).timeout

	if not is_duel_active: return
	if active_duel.current_attacker_id == active_duel.player_aligned_char_id:
		_execute_attack_action(active_duel.current_attacker_id) # Player's aligned character attacks
		if not _check_duel_winner(): # If game not over, switch to AI's turn or next player action
			_advance_duel_state()
	else:
		# print("COMBAT_SYSTEM: Not player's aligned character's turn to proceed with attack via this method.") # Less verbose
		_advance_duel_state() # Still advance state, likely to AI's turn


func _advance_duel_state():
	if not is_duel_active: return

	# Switch turns
	var previous_attacker = active_duel.current_attacker_id
	active_duel.current_attacker_id = active_duel.current_opponent_id
	active_duel.current_opponent_id = previous_attacker

	# Increment round if the opponent (who just became attacker) is the one who started this round
	# This logic is tricky. A round = A attacks, B attacks.
	# For simplicity now: just switch. If player turn, emit. If AI, AI acts.
	# If current attacker was char_B (meaning char_A just went, or player used spell for char_A), increment round
	if active_duel.character_a.id == active_duel.current_opponent_id: # Check if a full exchange (A then B, or vice-versa) might have completed.
		active_duel.round += 1
		_add_log("--- Round %s ---" % active_duel.round)


	if active_duel.current_attacker_id == active_duel.player_aligned_char_id:
		emit_signal("request_player_action")
	else: # AI's turn
		_execute_attack_action(active_duel.current_attacker_id)
		# After AI attack, check win. If no win AND it becomes player's turn, request action.
		if not _check_duel_winner():
			emit_signal("request_player_action")

func _execute_attack_action(attacker_id_in_duel: int):
	if not is_duel_active: return
	
	var attacker: Character = active_duel.character_a if active_duel.character_a.id == attacker_id_in_duel else active_duel.character_b
	var defender: Character = active_duel.character_b if active_duel.character_a.id == attacker_id_in_duel else active_duel.character_a

	# Basic attack logic
	var damage_dealt = attacker.stats.Combat_DMG + randi_range(-2, 2) # Base damage with variance
	var actual_damage = max(0, damage_dealt - defender.stats.defense) # Apply defense
	
	defender.stats.Combat_HP -= actual_damage
	defender.stats.Combat_HP = max(0, defender.stats.Combat_HP) # Clamp HP to 0

	_add_log("%s attacks %s for %s damage. %s HP remaining: %s" % [attacker.name, defender.name, actual_damage, defender.name, defender.stats.Combat_HP])
	emit_signal("duel_character_stats_changed")
	
	# Don't advance state here, it's called by the function that invoked _execute_attack_action

func _check_duel_winner() -> bool:
	if not is_duel_active: return false

	var char_A = active_duel.character_a
	var char_B = active_duel.character_b
	var winner = null
	var loser = null

	if char_A.stats.Combat_HP <= 0:
		winner = char_B
		loser = char_A
	elif char_B.stats.Combat_HP <= 0:
		winner = char_A
		loser = char_B
	
	if winner:
		for character in GlobalGameData.characters:
			if character.id == winner.id:
				winner_character = character
		GlobalGameData.characters = GlobalGameData.characters.filter(func (character): return character.id != loser.id)
		last_duel_log = active_duel.log
		_add_log("%s has been defeated! %s is victorious!" % [loser.name, winner.name])
		emit_signal("duel_ended")
		is_duel_active = false # Reset for next duel
		active_duel = {} 
		return true
	return false

func _add_log(message: String):
	if not is_duel_active or not active_duel.has("log"): return
	active_duel.log.append(message)
	emit_signal("duel_log_updated")
