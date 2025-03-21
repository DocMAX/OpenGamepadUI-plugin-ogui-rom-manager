extends MarginContainer

var data_manager: Node
var tab_ui: Node
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager

# Signal to notify plugin.gd of toggle changes
signal desktop_library_toggled(enabled: bool)

func _ready():
	print("Settings scene initialized")
	
	# Initialize child scripts
	data_manager = preload("res://plugins/ogui-rom-manager/core/parser_data_manager.gd").new()
	tab_ui = preload("res://plugins/ogui-rom-manager/core/parser_tab_ui.gd").new()
	
	add_child(data_manager)
	add_child(tab_ui)
	
	tab_ui.data_manager = data_manager
	
	$HBoxContainer/VBoxContainer/CreateNewParserTab.connect("pressed", Callable(tab_ui, "add_new_tab_in_edit_mode"))
	data_manager.load_settings(tab_ui)
	
	# Setup DesktopLibrary toggle
	var toggle = $HBoxContainer/VBoxContainer/DesktopLibraryToggle
	# Load saved state, default to true (enabled)
	var is_enabled = settings_manager.get_value("plugin.oguirommanager", "desktop_library_enabled", true) as bool
	toggle.button_pressed = is_enabled
	toggle.connect("toggled", Callable(self, "_on_desktop_library_toggled"))

func _on_desktop_library_toggled(enabled: bool):
	# Save the new state
	settings_manager.set_value("plugin.oguirommanager", "desktop_library_enabled", enabled)
	settings_manager.save()
	print("Desktop Library toggled: ", enabled)
	# Emit signal to notify plugin.gd
	emit_signal("desktop_library_toggled", enabled)
