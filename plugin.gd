extends Plugin

var settings_menu := load("res://plugins/ogui-rom-manager/core/settings_menu.tscn") as PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logger = Log.get_logger("OGUIRM-Plugin", Log.LEVEL.DEBUG)
	logger.info("OGUIRM plugin loaded")
	var library: Library = load(plugin_base + "/core/library.tscn").instantiate()
	add_child(library)

func get_settings_menu() -> Control:
	return settings_menu.instantiate()
