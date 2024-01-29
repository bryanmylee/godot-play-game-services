extends Control

@onready var back_button: Button = %Back
@onready var show_achievements_button: Button = %ShowAchievements
@onready var achievement_displays: VBoxContainer = %AchievementDisplays

var _achievements_cache: Array[PlayGamesAchievementsClient.Achievement] = []
var _achievement_display := preload("res://scenes/achievements/AchievementDisplay.tscn")

func _ready() -> void:
	if _achievements_cache.is_empty():
		PlayGamesAchievementsClient.load_achievements(true)
	PlayGamesAchievementsClient.achievements_loaded.connect(
		func cache_and_display(achievements: Array[PlayGamesAchievementsClient.Achievement]):
			_achievements_cache = achievements
			if not _achievements_cache.is_empty() and achievement_displays.get_child_count() == 0:
				for achievement: PlayGamesAchievementsClient.Achievement in _achievements_cache:
					var container := _achievement_display.instantiate() as Control
					container.achievement = achievement
					achievement_displays.add_child(container)
	)
	
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	show_achievements_button.pressed.connect(func():
		PlayGamesAchievementsClient.show_achievements()
	)
