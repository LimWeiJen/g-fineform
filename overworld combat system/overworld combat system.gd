class_name OverWorldCombatSystem
extends CombatSystem

var battle_log = []
var battle_begun = false

var team_hero: Array[Character]
var team_monster: Array[Character]

signal battle_ended()
signal update_battle_log()

func start_battle(hero_team: Array[Character], monster_team: Array[Character]):
	team_hero = hero_team
	team_monster = monster_team
	battle_begun = true

	while team_hero.size() > 0 and team_monster.size() > 0:
		var hero = team_hero[0]
		var monster = team_monster[0]

		start_character_duel(hero, monster, hero.id)

		await get_tree().create_timer(5.0).timeout

		battle_log.append_array(last_duel_log)

		emit_signal("update_battle_log")

		if winner_character:
			if winner_character.id == hero.id:
				team_monster.remove_at(0)
			else:
				team_hero.remove_at(0)
	battle_log.append("team hero won" if team_hero.size() > 0 else "team monster won")
	emit_signal("battle_ended")
	battle_begun = false
