extends Library

var tabs_state: TabContainerState

func _ready() -> void:
	super()
	logger = Log.get_logger("OguiRomManager", Log.LEVEL.INFO)
	library_id = "ogui-rom-manager"
	logger.info("OguiRomManager Library loaded with library_id: " + library_id)
	
	# Load the TabContainerState
	tabs_state = load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
	if tabs_state:
		# Wait a frame to ensure all menus are ready (Discord hint)
		await get_tree().process_frame
		_update_tabs()

# Helper function to determine the depth and direction of ${title} in the glob
func _get_title_depth(search_glob: String) -> Dictionary:
	var depth = {"direction": "", "level": 0}
	if search_glob == "${title}":
		return {"direction": "left", "level": 0}  # Special case: top-level folder
	
	var parts = search_glob.split("${title}")
	if parts.size() != 2:
		return {"direction": "", "level": -1}  # Invalid glob
	
	var left_part = parts[0].strip_edges()
	var right_part = parts[1].strip_edges()
	
	if left_part.contains("**") or left_part.contains("{"):
		depth["direction"] = "right"
		if right_part:
			depth["level"] = right_part.count("/")
		else:
			depth["level"] = 0
	else:
		depth["direction"] = "left"
		if left_part:
			depth["level"] = left_part.count("/")
		else:
			depth["level"] = 0
	
	return depth

# Helper function to extract the title from a path based on depth
func _extract_title(file_path: String, depth: Dictionary, rom_dir: String) -> String:
	if depth["level"] < 0:
		return ""
	
	# Remove the rom_dir prefix to get the relative path
	var relative_path = file_path.trim_prefix(rom_dir + "/")
	var segments = relative_path.split("/")
	if segments.size() <= depth["level"]:
		return ""
	
	var title_idx = 0
	if depth["direction"] == "left":
		title_idx = depth["level"]
	else:
		title_idx = segments.size() - (depth["level"] + 1)
	
	if title_idx < 0 or title_idx >= segments.size():
		return ""
	
	var raw_title = segments[title_idx]
	# Clean up the title by removing trailing "(year) [number]" patterns
	var title_parts = raw_title.split(" (")
	if title_parts.size() > 0:
		return title_parts[0].strip_edges()
	return raw_title

# Update tabs based on parser names
func _update_tabs() -> void:
	var settings_manager = load("res://core/global/settings_manager.tres") as SettingsManager
	var parser_count = settings_manager.get_value("plugin.oguirommanager", "parser_count", 0)
	
	# Get existing tabs
	var existing_tabs = tabs_state.tabs_text.duplicate()
	var parser_tabs = []
	
	# Collect parser names
	for i in range(parser_count):
		var section = "plugin.oguirommanager.parser_" + str(i)
		var parser_name = settings_manager.get_value(section, "name", "Unnamed Parser")
		if parser_name != "Installed" and parser_name != "All Games":
			parser_tabs.append(parser_name)
	
	# Remove tabs that no longer exist
	for tab in existing_tabs:
		if tab != "Installed" and tab != "All Games" and tab not in parser_tabs:
			tabs_state.remove_tab(tab)
	
	# Add new parser tabs
	for parser_name in parser_tabs:
		if parser_name not in existing_tabs:
			var tab_node = ScrollContainer.new()
			tab_node.name = parser_name
			tab_node.horizontal_scroll_mode = 0
			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 15)
			margin.add_theme_constant_override("margin_top", 100)
			margin.add_theme_constant_override("margin_right", 15)
			margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var grid = HFlowContainer.new()
			grid.name = parser_name + "Grid"
			grid.add_theme_constant_override("h_separation", 26)
			grid.add_theme_constant_override("v_separation", 16)
			grid.alignment = HFlowContainer.ALIGNMENT_CENTER
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			margin.add_child(grid)
			tab_node.add_child(margin)
			tabs_state.add_tab(parser_name, tab_node)
			logger.debug("Added parser tab: " + parser_name)

func get_library_launch_items() -> Array[LibraryLaunchItem]:
	var items: Array[LibraryLaunchItem] = []
	var settings_manager = load("res://core/global/settings_manager.tres") as SettingsManager
	var parser_count = settings_manager.get_value("plugin.oguirommanager", "parser_count", 0)

	for i in range(parser_count):
		var section = "plugin.oguirommanager.parser_" + str(i)
		var rom_dirs = settings_manager.get_value(section, "roms_dirs", [])
		var search_glob = settings_manager.get_value(section, "search_glob", "")
		var executable = settings_manager.get_value(section, "executable", "")
		var parser_title = settings_manager.get_value(section, "name", "Unnamed Parser")
		var titles_found = 0

		# Validate and parse the glob
		if not "${title}" in search_glob:
			logger.error("Invalid glob for parser '" + parser_title + "': ${title} missing")
			continue
		
		var depth = _get_title_depth(search_glob)
		if depth["level"] < 0:
			logger.error("Invalid glob pattern for parser '" + parser_title + "': " + search_glob)
			continue
		
		# Special case: search_glob is just "${title}"
		if search_glob == "${title}":
			logger.info("Parser '" + parser_title + "' uses simple glob '${title}', using folder names as titles")
			for rom_dir in rom_dirs:
				var dir = DirAccess.open(rom_dir)
				if dir == null:
					logger.error("Could not open directory: " + rom_dir)
					continue

				dir.list_dir_begin()
				var filename = dir.get_next()
				while filename != "":
					if not filename.begins_with(".") and dir.dir_exists(rom_dir + "/" + filename):
						var full_path = rom_dir + "/" + filename
						var game_title = _extract_title(full_path, depth, rom_dir)
						if game_title:
							var item = LibraryLaunchItem.new()
							item.name = game_title
							item.command = executable
							item.args = [full_path]
							item.tags = [parser_title]
							item.installed = true
							items.append(item)
							titles_found += 1
					filename = dir.get_next()
				dir.list_dir_end()

		# Standard case: Parse glob for a target file
		else:
			var target_file = ""
			var glob_parts = search_glob.split("${title}")
			if glob_parts.size() == 2 and glob_parts[1]:
				var file_pattern = glob_parts[1].strip_edges()
				if file_pattern.begins_with("(*"):
					var file_part = file_pattern.split("(*")[1]
					# Handle missing closing parenthesis gracefully
					if file_part.ends_with(")"):
						target_file = file_part.substr(0, file_part.length() - 1).lstrip("*/")
					else:
						target_file = file_part.lstrip("*/")
				else:
					target_file = file_pattern.lstrip("/")
			
			if target_file == "":
				logger.info("Parser '" + parser_title + "' has no specific target file, using directory")
			else:
				logger.info("Parser '" + parser_title + "' target file from glob: " + target_file)

			for rom_dir in rom_dirs:
				var dir = DirAccess.open(rom_dir)
				if dir == null:
					logger.error("Could not open directory: " + rom_dir)
					continue

				dir.list_dir_begin()
				var filename = dir.get_next()
				while filename != "":
					if not filename.begins_with(".") and dir.dir_exists(rom_dir + "/" + filename):
						var full_path = rom_dir + "/" + filename
						var target_path = full_path + "/" + target_file if target_file else full_path
						if target_file == "" or FileAccess.file_exists(target_path):
							var game_title = _extract_title(full_path, depth, rom_dir)
							if game_title:
								var item = LibraryLaunchItem.new()
								item.name = game_title
								item.command = executable
								item.args = [target_path]
								item.tags = [parser_title]
								item.installed = true
								items.append(item)
								titles_found += 1
					filename = dir.get_next()
				dir.list_dir_end()

		logger.info("Parser '" + parser_title + "' loaded " + str(titles_found) + " titles")

	return items
