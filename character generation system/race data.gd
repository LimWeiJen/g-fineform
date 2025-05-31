const RACES = {
    "Human": {"multipliers": {"Diplomacy": 1.0, "Martial": 1.0, "Learning": 1.0}},
    "Elf": {"multipliers": {"Diplomacy": 1.2, "Learning": 1.3, "Martial": 0.8}},
    "Orc": {"multipliers": {"Martial": 1.4, "Diplomacy": 0.7, "Stewardship": 0.9}},
    "Demon": {"multipliers": {"Intrigue": 1.5, "Combat": 1.5}},
    "Hybrid": {"multipliers": {}}  # Filled during runtime by averaging parent races
}
