extends Label

func _process(_delta):
	var memory_usage = OS.get_static_memory_usage()
	var peak_memory_usage = OS.get_static_memory_peak_usage()
	
	# Convert to MB and round to 2 decimal places
	var memory_usage_mb = snappedf(memory_usage / 1024.0 / 1024.0, 0.01)
	var peak_memory_mb = snappedf(peak_memory_usage / 1024.0 / 1024.0, 0.01)
	
	# Show both current and peak memory in a readable format
	text = "Memory: %.2f MB\nPeak: %.2f MB" % [memory_usage_mb, peak_memory_mb]
