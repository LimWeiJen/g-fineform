extends Control

func _ready():
	($"TabContainer/Combat System/CombatSystem" as CombatSystem).connect("duel_ended", func (): $"TabContainer/Character Generation System".list_out_all_char())
	($"TabContainer/Overworld Combat System/OverWorldCombatSystem" as OverWorldCombatSystem).connect("battle_ended", func (): $"TabContainer/Character Generation System".list_out_all_char())

func _on_tab_container_tab_changed(tab:int):
	if tab == 1:
		$"TabContainer/Combat System".reload_characters()
	if tab == 3:
		$"TabContainer/Overworld Combat System".reload_characters()
