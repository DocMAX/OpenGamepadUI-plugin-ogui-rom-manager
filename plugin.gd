extends Plugin

const settings := preload("res://plugins/ogui-rom-manager/core/settings.tscn") as PackedScene
const LibraryManager := preload("res://core/global/library_manager.tres")
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager

# Reference to the DesktopLibrary instance (if active)
var desktop_library: Library = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logger = Log.get_logger("OguiRomManager", Log.LEVEL.INFO)
	logger.info("OguiRomManager plugin initialized")
	
	# Add the ogui-rom-manager library
	var library: Library = load(plugin_base + "/core/library.tscn").instantiate()
	add_child(library)
	
	# Check if DesktopLibrary should be enabled
	var desktop_enabled = settings_manager.get_value("plugin.oguirommanager", "desktop_library_enabled", true) as bool
	if not desktop_enabled:
		remove_desktop_library()
	else:
		restore_desktop_library()
	
	# Connect to settings menu toggle signal when settings are instantiated
	await get_tree().process_frame  # Ensure settings menu is ready if opened

# Returns the settings menu for the plugin
func get_settings_menu() -> Control:
	logger.info("OguiRomManager settings menu added")
	var settings_instance = settings.instantiate()
	# Connect to the toggle signal
	settings_instance.connect("desktop_library_toggled", Callable(self, "_on_desktop_library_toggled"))
	return settings_instance

func remove_desktop_library():
	desktop_library = LibraryManager.get_library_by_id("desktop")
	if desktop_library:
		LibraryManager.unregister_library(desktop_library)
		logger.info("DesktopLibrary removed")
		desktop_library = null  # Clear reference since it's unregistered
	else:
		logger.warn("DesktopLibrary not found or already removed")

func restore_desktop_library():
	if desktop_library == null:
		# Instantiate the DesktopLibrary
		desktop_library = load("res://core/systems/library/library_desktop.tscn").instantiate()
		# Ensure logger is initialized since we're not modifying library_desktop.gd
		if desktop_library.logger == null:
			desktop_library.logger = Log.get_logger("DesktopLibrary", Log.LEVEL.INFO)
		# Add it to the scene tree to trigger _ready()
		add_child(desktop_library)
		# Register it with the LibraryManager
		LibraryManager.register_library(desktop_library)
		logger.info("DesktopLibrary restored")
	else:
		logger.warn("DesktopLibrary already active")

func _on_desktop_library_toggled(enabled: bool):
	if enabled:
		restore_desktop_library()
	else:
		remove_desktop_library()
