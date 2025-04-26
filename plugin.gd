extends Plugin

var settings_menu := load("res://plugins/ogui-rom-manager/core/settings_menu.tscn") as PackedScene

func _ready() -> void:
	logger = Log.get_logger("OGUIRM-Plugin", Log.LEVEL.DEBUG)
	var library: Library = load(plugin_base + "/core/library.tscn").instantiate()
	add_library(library)
	logger.info("OGUIRM plugin loaded")
#	call_deferred("_setup_plugin_tabs")

func get_settings_menu() -> Control:
	return settings_menu.instantiate()

#func _setup_plugin_tabs() -> void:
#	var tabs_state := load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
#	var scene_resource := load("res://plugins/ogui-rom-manager/core/parser_tab.tscn") as PackedScene
#	var my_category_tab_node := scene_resource.instantiate() as ScrollContainer
#	my_category_tab_node.name = "MyCategory"
#	tabs_state.add_tab("MyCategory", my_category_tab_node)
