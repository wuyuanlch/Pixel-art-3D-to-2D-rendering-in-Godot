@tool
extends EditorPlugin

# 主面板场景
var main_panel_scene = preload("res://addons/threeToTwo/scene/main.tscn")
var main_window: Window
var main_panel_instance: Control
var toolbar_button: Button

# 翻译资源
var translation_zh_cn: Translation
var translation_en: Translation


func _enter_tree() -> void:
	
	# 创建工具栏按钮
	toolbar_button = Button.new()
	toolbar_button.text = "3D To 2D"
	toolbar_button.pressed.connect(_on_toolbar_button_pressed)
	
	# 添加到编辑器工具栏
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)


func _exit_tree() -> void:
	
	# 移除工具栏按钮
	if toolbar_button != null:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)
		toolbar_button.queue_free()
	
	# 关闭并清理窗口
	if main_window != null:
		main_window.queue_free()


# 创建主窗口
func _create_main_window() -> void:
	main_window = Window.new()
	main_window.title = "3D To 2D"
	main_window.size = Vector2i(1200, 800)
	main_window.min_size = Vector2i(800, 600)
	main_window.close_requested.connect(_on_window_close_requested)
	
	# 加载主面板
	main_panel_instance = main_panel_scene.instantiate()
	main_window.add_child(main_panel_instance)
	
	# 设置主面板填充整个窗口
	main_panel_instance.anchors_preset = Control.PRESET_FULL_RECT
	main_panel_instance.offset_left = 0
	main_panel_instance.offset_top = 0
	main_panel_instance.offset_right = 0
	main_panel_instance.offset_bottom = 0
	
	# 将窗口添加到编辑器界面
	get_editor_interface().get_base_control().add_child(main_window)
	
	# 初始隐藏窗口
	main_window.visible = false


# 工具栏按钮点击事件
func _on_toolbar_button_pressed() -> void:
	if main_window == null:
		_create_main_window()
	elif main_panel_instance == null:
		# 如果主面板被清理了，重新创建
		main_panel_instance = main_panel_scene.instantiate()
		main_window.add_child(main_panel_instance)
		# 设置主面板填充整个窗口
		main_panel_instance.anchors_preset = Control.PRESET_FULL_RECT
		main_panel_instance.offset_left = 0
		main_panel_instance.offset_top = 0
		main_panel_instance.offset_right = 0
		main_panel_instance.offset_bottom = 0
	
	if main_window.visible:
		# 如果窗口已经显示，将其置于前台
		main_window.grab_focus()
	else:
		# 显示窗口并居中
		main_window.visible = true
		_center_window()


# 窗口关闭请求事件
func _on_window_close_requested() -> void:
	# 清理主面板资源
	if main_panel_instance != null and main_panel_instance.has_method("cleanup"):
		main_panel_instance.cleanup()
	
	# 从窗口中移除主面板
	if main_window != null and main_panel_instance != null:
		main_window.remove_child(main_panel_instance)
		main_panel_instance.queue_free()
		main_panel_instance = null
	
	# 隐藏窗口
	if main_window != null:
		main_window.visible = false


# 居中窗口
func _center_window() -> void:
	var viewport_size: Vector2 = get_editor_interface().get_base_control().get_viewport().get_visible_rect().size
	var window_size: Vector2 = main_window.size
	
	var x: float = (viewport_size.x - window_size.x) / 2
	var y: float = (viewport_size.y - window_size.y) / 2
	
	main_window.position = Vector2i(int(x), int(y))
