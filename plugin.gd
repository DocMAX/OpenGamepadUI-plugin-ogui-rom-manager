extends Plugin

var settings_menu := load("res://plugins/ogui-rom-manager/core/settings.tscn") as PackedScene


func _ready() -> void:
	logger = Log.get_logger("OguiRomManager", Log.LEVEL.INFO)
	logger.info("OguiRomManager plugin initialized")


func get_settings_menu() -> Control:
	logger.info("OguiRomManager settings menu added")
	return settings_menu.instantiate()
