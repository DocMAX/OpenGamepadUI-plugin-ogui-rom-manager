# library.gd
extends Library

func _ready() -> void:
	super()
	logger = Log.get_logger("OguiRomManager", Log.LEVEL.INFO)
	logger.info("OguiRomManager Library loaded")

func get_library_launch_items() -> Array[LibraryLaunchItem]:
	var items: Array[LibraryLaunchItem] = []
	var settings_manager = load("res://core/global/settings_manager.tres") as SettingsManager
	var parser_count = settings_manager.get_value("plugin.oguirommanager", "parser_count", 0)

	for i in range(parser_count):
		var section = "plugin.oguirommanager.parser_" + str(i)
		var rom_dirs = settings_manager.get_value(section, "roms_dirs", [])
		var search_glob = settings_manager.get_value(section, "search_glob", "")
		var executable = settings_manager.get_value(section, "executable", "")
		var parser_title = settings_manager.get_value(section, "title", "Unnamed Parser")

		# Parse the glob to extract the target file (e.g., ".start.sh")
		var target_file = ""
		if search_glob.begins_with("${title}"):
			var glob_parts = search_glob.split("${title}")
			if glob_parts.size() > 1:
				# Extract the file part after "${title}(*/"
				var file_pattern = glob_parts[1].strip_edges()
				if file_pattern.begins_with("(*"):
					var file_part = file_pattern.split("(*")[1]
					if file_part.ends_with(")"):
						file_part = file_part.substr(0, file_part.length() - 1)
					target_file = file_part.lstrip("*/")  # e.g., ".start.sh"
		if target_file == "":
			logger.error("Invalid glob pattern: " + search_glob + ". Expected format like '${title}(*/filename)'")
			continue

		logger.info("Target file from glob: " + target_file)

		for rom_dir in rom_dirs:
			var dir = DirAccess.open(rom_dir)
			if dir == null:
				logger.error("Could not open directory: " + rom_dir)
				continue

			dir.list_dir_begin()
			var filename = dir.get_next()
			while filename != "":
				if not filename.begins_with("."):  # Avoid hidden files/directories
					var full_path = rom_dir + "/" + filename
					if dir.dir_exists(full_path):  # Depth 1 directory
						# Construct the expected path based on the glob
						var target_path = full_path + "/" + target_file
						logger.info("Checking for: " + target_path)
						if FileAccess.file_exists(target_path):
							# Replace ${title} with the folder name for title extraction
							var game_title = filename
							# Refine title (e.g., remove "(2023) [00]")
							var title_parts = game_title.split(" (")
							if title_parts.size() > 0:
								game_title = title_parts[0].strip_edges()
							
							logger.info("Found game: " + game_title + " at " + full_path)
							var item = LibraryLaunchItem.new()
							item.name = game_title
							item.command = executable
							item.args = [target_path]  # Use the matched file (e.g., .start.sh)
							item.tags = [parser_title]
							item.installed = true
							items.append(item)
					# Skip files at depth 1; we only want directories
				filename = dir.get_next()
			dir.list_dir_end()
	return items
