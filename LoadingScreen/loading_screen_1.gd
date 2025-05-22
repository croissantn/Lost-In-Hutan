extends Node

var loading_screen_scene = preload("res://LoadingScreen/loading_screen1.tscn")
var loading_instance

func load_scene_async(scene_path):
	# Tampilkan loading screen
	loading_instance = loading_screen_scene.instantiate()
	get_tree().root.add_child(loading_instance)
	loading_instance.move_to_front()  # Changed from move_to_top() to move_to_front()

	var progress_bar = loading_instance.get_node("ProgressBar")
	var label = loading_instance.get_node("Label")

	# Mulai loading secara async
	ResourceLoader.load_threaded_request(scene_path)

	# Periksa status loading
	var progress = []
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# Loading selesai
			var packed_scene = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(packed_scene)
			loading_instance.queue_free()
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			# Gagal loading
			push_error("Gagal loading scene.")
			loading_instance.queue_free()
			break
		else:
			# Masih loading, update progress
			var percent = progress[0] * 100.0
			progress_bar.value = percent
			label.text = "Loading... %d%%" % int(percent)
			
		await get_tree().process_frame
