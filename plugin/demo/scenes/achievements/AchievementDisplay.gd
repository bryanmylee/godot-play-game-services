extends Control

@onready var icon_rect: TextureRect = %IconRect

@onready var id_label: Label = %IdLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var type_label: Label = %TypeLabel
@onready var state_label: Label = %StateLabel
@onready var xp_value_label: Label = %XPValueLabel

@onready var current_steps_holder: HBoxContainer = %CurrentStepsHolder
@onready var current_steps_label: Label = %CurrentStepsLabel
@onready var total_steps_holder: HBoxContainer = %TotalStepsHolder
@onready var total_steps_label: Label = %TotalStepsLabel

@onready var unlock_holder: VBoxContainer = %UnlockHolder
@onready var unlock_button: Button = %UnlockButton

var achievement: PlayGamesAchievementsClient.Achievement

var _waiting := false

func _ready() -> void:
	if achievement:
		_set_up_display()
		_set_up_button_pressed()
		_connect_signals()

func _set_up_display() -> void:
	id_label.text = achievement.achievement_id
	name_label.text = achievement.achievement_name
	description_label.text = achievement.description
	type_label.text = PlayGamesAchievementsClient.Type.find_key(achievement.type)
	state_label.text = PlayGamesAchievementsClient.State.find_key(achievement.state)
	xp_value_label.text = str(achievement.xp_value)
	
	if achievement.type == PlayGamesAchievementsClient.Type.TYPE_INCREMENTAL:
		current_steps_holder.visible = true
		current_steps_label.text = achievement.formatted_current_steps
		total_steps_holder.visible = true
		total_steps_label.text = achievement.formatted_total_steps
	
	match achievement.state:
		PlayGamesAchievementsClient.State.STATE_UNLOCKED:
			unlock_button.text = "Unlocked!"
			unlock_button.disabled = true
		PlayGamesAchievementsClient.State.STATE_HIDDEN:
			unlock_button.text = "Reveal!"
			unlock_button.disabled = false
		PlayGamesAchievementsClient.State.STATE_REVEALED:
			match achievement.type:
				PlayGamesAchievementsClient.Type.TYPE_INCREMENTAL:
					unlock_button.text = "Increment!"
					unlock_button.disabled = false
				PlayGamesAchievementsClient.Type.TYPE_STANDARD:
					unlock_button.text = "Unlock!"
					unlock_button.disabled = false

func _set_up_button_pressed() -> void:
	unlock_button.pressed.connect(func():
		match achievement.state:
			PlayGamesAchievementsClient.State.STATE_HIDDEN:
				PlayGamesAchievementsClient.reveal_achievement(achievement.achievement_id)
				_set_up_waiting()
			PlayGamesAchievementsClient.State.STATE_REVEALED:
				match achievement.type:
					PlayGamesAchievementsClient.Type.TYPE_INCREMENTAL:
						PlayGamesAchievementsClient.increment_achievement(
							achievement.achievement_id,
							1
						)
						_set_up_waiting()
					PlayGamesAchievementsClient.Type.TYPE_STANDARD:
						PlayGamesAchievementsClient.unlock_achievement(
							achievement.achievement_id
						)
						_set_up_waiting()
	)

func _connect_signals() -> void:
	PlayGamesAchievementsClient.achievement_revealed.connect(
		func refresh_achievement(_is_revealed: bool, achievement_id: String):
			if achievement_id ==achievement.achievement_id and _waiting:
				PlayGamesAchievementsClient.load_achievements(true)
	)
	PlayGamesAchievementsClient.achievement_unlocked.connect(
		func refresh_achievement(_is_unlocked: bool, achievement_id: String):
			if achievement_id == achievement.achievement_id and _waiting:
				PlayGamesAchievementsClient.load_achievements(true)
	)
	PlayGamesAchievementsClient.achievements_loaded.connect(
		func refresh_achievement(achievements: Array[PlayGamesAchievementsClient.Achievement]):
			for new_achievement: PlayGamesAchievementsClient.Achievement in achievements:
				if new_achievement.achievement_id == achievement.achievement_id \
				and _waiting:
					achievement = new_achievement
					_waiting = false
					_set_up_display()
	)
	GodotPlayGamesServices.image_stored.connect(func(file_path: String):
		if file_path == achievement.revealed_image_uri\
		or file_path == achievement.unlocked_image_uri:
			_set_up_icon()
	)

func _set_up_waiting() -> void:
	_waiting = true
	unlock_button.disabled = true
	unlock_button.text = "Wait..."

func _set_up_icon() -> void:
	var property: String
	match achievement.state:
		PlayGamesAchievementsClient.State.STATE_REVEALED:
			property = achievement.revealed_image_uri
		PlayGamesAchievementsClient.State.STATE_UNLOCKED:
			property = achievement.unlocked_image_uri
	
	if property and not property.is_empty():
		GodotPlayGamesServices.display_image_in_texture_rect(
			icon_rect,
			property
		)
