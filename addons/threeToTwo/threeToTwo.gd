@tool
extends EditorPlugin
class_name threeToTwo

# 使用您已经创建好的场景作为右侧停靠面板和弹出窗口
var main_panel_scene: PackedScene
var preview_panel_scene: PackedScene
var main_window: Window
var main_panel_instance: Control
var preview_panel_instance: Control  # 预览面板实例
var dock_panel_instance: Control  # 右侧停靠面板实例

# 场景中的按钮需要连接到这些函数
var selected_camera_node: Camera3D = null  # 选中的 Camera3D 节点
var camera_label: Label  # 显示选中的相机节点名称
var selected_model_container_node: Node3D = null  # 选中的 ModelContainer 节点
var model_container_label: Label  # 显示选中的 ModelContainer 节点名称
var texture_rect: TextureRect  # TextureRect 节点引用
var original_viewport_texture: ViewportTexture  # 原始的 ViewportTexture 引用
var subviewport_camera: Camera3D  # SubViewport 中的相机节点引用
var realtime_sync_checkbutton: CheckButton  # 实时同步 CheckButton 引用

# 场景相机跟随相关变量
var scene_follow_checkbutton: CheckButton  # 场景跟随 CheckButton 引用
var is_following_scene_camera: bool = false  # 是否正在跟随场景相机
var editor_camera: Camera3D = null  # 缓存的编辑器相机

# AnimationPlayer管理器相关变量
class AnimationPlayerEntry:
	var animation_player: AnimationPlayer
	var animation_name: String = ""
	var is_playing: bool = false
	var is_selected: bool = true  # 是否参与全局控制
	var is_looping: bool = false  # 是否循环播放
	var ui_instance: Control  # 对应的UI实例
	var option_button: OptionButton  # 动画选择下拉菜单
	var play_button: Button  # 播放按钮
	var select_checkbutton: CheckButton  # 选择按钮
	var loop_checkbutton: CheckButton    # 循环按钮
	var last_animation_finished_time: float = 0.0  # 上次动画完成时间，用于防重复触发
	
	func _init(player: AnimationPlayer, ui: Control):
		animation_player = player
		ui_instance = ui

var animation_player_entries: Array[AnimationPlayerEntry] = []
var animation_player_container: VBoxContainer  # AnimationPlayer列表容器
var animation_player_entry_scene: PackedScene

# 纹理缓存相关变量
var cached_textures: Array[ImageTexture] = []
var is_caching: bool = false
var is_playing_cached: bool = false
var cache_timer: Timer
var play_timer: Timer
var cache_interval: float = 0.01  # 固定值 0.01 秒
var cache_duration: float = 0.0   # 缓存时长（选中动画的时长）
var current_cache_time: float = 0.0
var current_play_index: int = 0

# UI 引用
var vfx_button: Button  # VBoxContainer/VFXButton
var vfx_mesh_node: MeshInstance3D  # SubViewport/Node3D/Camera/VFXMesh 节点

# VFX 预览面板相关变量
var vfx_preview_panel_scene: PackedScene
var vfx_preview_panel_instance: Control
var vfx_preview_window: Window

var loading_button: Button  # LoadingButton 节点引用

# 加载的导出尺寸（用于预览面板初始化）
var loaded_export_width: float = 0.0  # 保存加载的宽度（浮点数）
var loaded_export_height: float = 0.0  # 保存加载的高度（浮点数）

# 文件对话框（用于上传模型）
var file_dialog: FileDialog = null

func _enter_tree() -> void:
	# 在这里动态加载
	main_panel_scene = load("res://addons/threeToTwo/scence/main.tscn")
	preview_panel_scene = load("res://addons/threeToTwo/scence/preview_panel.tscn")
	vfx_preview_panel_scene = load("res://addons/threeToTwo/scence/vfx_preview_panel.tscn")
	animation_player_entry_scene = load("res://addons/threeToTwo/scence/animation_player_entry.tscn")

	# 加载您的场景作为右侧停靠面板
	dock_panel_instance = main_panel_scene.instantiate()
	dock_panel_instance.name = "3Dto2D"
	
	# 查找场景中的节点并连接信号
	_setup_scene_nodes(dock_panel_instance)
	
	# 初始化定时器
	_initialize_timers()
	
	# 添加到右侧停靠位置（右上角）
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock_panel_instance)


func _exit_tree() -> void:
	
	# 关闭并清理 VFX 预览面板窗口
	_close_existing_vfx_preview_panel()
	
	# 清理纹理缓存
	cached_textures.clear()
	
	# 清理预览面板实例
	if preview_panel_instance != null and is_instance_valid(preview_panel_instance):
		# 恢复原始材质
		if preview_panel_instance.has_method("restore_original_materials"):
			preview_panel_instance.restore_original_materials()
		
		# 从父节点移除并清理
		if main_window != null and preview_panel_instance.get_parent() == main_window:
			main_window.remove_child(preview_panel_instance)
		
		preview_panel_instance.queue_free()
		preview_panel_instance = null
	
	# 移除停靠面板
	if dock_panel_instance != null:
		remove_control_from_docks(dock_panel_instance)
		dock_panel_instance.queue_free()
	
	# 关闭并清理窗口
	if main_window != null:
		main_window.queue_free()
	
	# 清理文件对话框
	if file_dialog != null:
		file_dialog.queue_free()
		file_dialog = null
	
	# 清理定时器
	if cache_timer != null:
		cache_timer.stop()
		cache_timer.queue_free()
		cache_timer = null
	
	if play_timer != null:
		play_timer.stop()
		play_timer.queue_free()
		play_timer = null


# 处理函数 - 用于实时同步相机变换
func _process(delta: float) -> void:
	# 处理场景相机跟随
	if is_following_scene_camera:
		# 检查是否有选中的相机
		if selected_camera_node == null or not is_instance_valid(selected_camera_node):
			# 尝试自动获取当前选中的相机
			_on_get_camera_button_pressed()
			if selected_camera_node == null:
				#print("场景相机跟随模式：请先选中一个相机节点")
				return
		
		var scene_camera = _get_editor_scene_camera()
		if scene_camera != null:
			# 同步选中的相机到场景相机的位置和旋转
			selected_camera_node.global_transform = scene_camera.global_transform
			# 同步相机属性
			# selected_camera_node.fov = scene_camera.fov
			# selected_camera_node.near = scene_camera.near
			# selected_camera_node.far = scene_camera.far
			# selected_camera_node.projection = scene_camera.projection
			
			# 在场景相机跟随模式下，总是更新 SubViewport 相机
			# 这样用户可以在实时预览中看到跟随效果
			if is_instance_valid(subviewport_camera):
				subviewport_camera.global_transform = selected_camera_node.global_transform
				# subviewport_camera.fov = selected_camera_node.fov
				# subviewport_camera.near = selected_camera_node.near
				# subviewport_camera.far = selected_camera_node.far
				# subviewport_camera.projection = selected_camera_node.projection
				
				# 强制 SubViewport 更新
				if is_instance_valid(texture_rect) and texture_rect.texture is ViewportTexture:
					# 获取 SubViewport
					var subviewport = subviewport_camera.get_parent().get_parent()
					if subviewport is SubViewport:
						# 强制更新一次
						subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		else:
			# 编辑器相机未获取到，尝试强制刷新缓存
			editor_camera = null
			#print("等待获取编辑器相机引用...")
		
		return  # 场景相机跟随模式下，跳过原有的实时同步逻辑
	
	# 检查是否启用实时同步
	var enable_realtime_sync = true
	if is_instance_valid(realtime_sync_checkbutton):
		enable_realtime_sync = realtime_sync_checkbutton.button_pressed
	
	if not enable_realtime_sync:
		# 实时同步被禁用，直接返回
		return
	
	# 检查选中相机是否有效且在场景树中
	if is_instance_valid(selected_camera_node) and selected_camera_node.is_inside_tree():
		# 检查 SubViewport 相机是否有效
		if is_instance_valid(subviewport_camera):
			# 同步全局变换
			subviewport_camera.global_transform = selected_camera_node.global_transform
			
			# 同步相机属性（用不到，后续可以自行取消注释）
			# subviewport_camera.fov = selected_camera_node.fov
			# subviewport_camera.near = selected_camera_node.near
			# subviewport_camera.far = selected_camera_node.far
			# subviewport_camera.projection = selected_camera_node.projection
			
			# 强制 SubViewport 更新（如果需要）
			if is_instance_valid(texture_rect) and texture_rect.texture is ViewportTexture:
				# 获取 SubViewport
				var subviewport = subviewport_camera.get_parent().get_parent()
				if subviewport is SubViewport:
					# 强制更新一次
					subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
					# 下一帧恢复为 ALWAYS（如果需要）
					# 注意：这里我们依赖 SubViewport 自己的 UPDATE_ALWAYS 设置
		else:
			# SubViewport 相机无效，清理引用
			print("警告：SubViewport 相机无效")
			subviewport_camera = null
	else:
		# 选中相机无效或不在场景树中，清理引用
		if selected_camera_node != null:
			print("警告：选中相机无效或不在场景树中，清理引用")
			selected_camera_node = null
			if camera_label:
				camera_label.text = "camera：无"


# 设置场景节点引用和连接信号
func _setup_scene_nodes(scene_instance: Control) -> void:
	# 查找并保存标签引用
	var selected_camera_label = scene_instance.find_child("CameraLabel", true, false)
	var selected_model_container_label = scene_instance.find_child("ModelContainerLabel", true, false)
	
	if selected_camera_label is Label:
		self.camera_label = selected_camera_label
		# 初始化相机标签文本
		self.camera_label.text = "camera：无"
	
	if selected_model_container_label is Label:
		self.model_container_label = selected_model_container_label
	
	var subviewport_node = scene_instance.find_child("SubViewport", true, false)
	
	# 查找 RealTimeTexture 节点
	var texture_rect_node = scene_instance.find_child("RealTimeTexture", true, false)
	if texture_rect_node is TextureRect:
		self.texture_rect = texture_rect_node
		#print("找到 RealTimeTexture 节点")
		
		# 使用 call_deferred 确保在场景树完全建立后执行
		call_deferred("_setup_viewport_texture", texture_rect_node, scene_instance)
	
	# 查找 SubViewport 中的相机节点
	
	if subviewport_node is SubViewport:
		# 查找相机节点
		var camera_node = subviewport_node.find_child("Camera", true, false)
		if camera_node is Camera3D:
			self.subviewport_camera = camera_node
			#print("找到 SubViewport 相机节点")
	
	# 查找 CheckButton 节点
	var checkbutton_node = scene_instance.find_child("CheckButton", true, false)
	if checkbutton_node is CheckButton:
		self.realtime_sync_checkbutton = checkbutton_node
		#print("找到实时同步 CheckButton 节点")
	
	# 查找 ScenceCheckButton 节点
	var scene_checkbutton_node = scene_instance.find_child("ScenceCheckButton", true, false)
	if scene_checkbutton_node is CheckButton:
		self.scene_follow_checkbutton = scene_checkbutton_node
		# 连接信号
		scene_checkbutton_node.toggled.connect(_on_scene_follow_checkbutton_toggled)
		#print("找到场景跟随 CheckButton 节点")
	
	# 查找AnimationPlayer管理器相关节点
	var animation_player_list = scene_instance.find_child("AnimationPlayerList", true, false)
	if animation_player_list is VBoxContainer:
		self.animation_player_container = animation_player_list
		#print("找到AnimationPlayer列表容器")
	
	# 查找 VFXButton
	var vfx_button_node = scene_instance.find_child("VFXButton", true, false)
	if vfx_button_node is Button:
		self.vfx_button = vfx_button_node
		vfx_button_node.pressed.connect(_on_vfx_button_pressed)
		#print("找到 VFXButton 节点")
	
	# 查找 VFXMesh 节点
	var vfx_mesh_node = scene_instance.find_child("VFXMesh", true, false)
	if vfx_mesh_node is MeshInstance3D:
		self.vfx_mesh_node = vfx_mesh_node
		#print("找到 VFXMesh 节点")
	
	# 查找 LoadingButton
	var loading_button_node = scene_instance.find_child("LoadingButton", true, false)
	if loading_button_node is Button:
		self.loading_button = loading_button_node
		loading_button_node.pressed.connect(_on_loading_button_pressed)
		#print("找到 LoadingButton 节点")
	
	# 查找并连接按钮信号
	_connect_button_signals(scene_instance)
	
	# 初始化文件对话框
	_initialize_file_dialog()
	
	# 为插件主面板连接gui_input信号，用于检测鼠标点击并同步循环状态
	if dock_panel_instance:
		dock_panel_instance.gui_input.connect(_on_plugin_panel_gui_input)
		#print("已连接插件面板鼠标点击检测信号")


func _setup_viewport_texture(texture_rect: TextureRect, scene_instance: Control):
	# 动态创建 ViewportTexture
		var viewport_texture = ViewportTexture.new()
		var subviewport_node = scene_instance.find_child("SubViewport", true, false)
		# 查找 SubViewport 节点
		if subviewport_node is SubViewport:
			# 设置 viewport_path
			viewport_texture.viewport_path = subviewport_node.get_path()
			
			# 应用到 TextureRect
			texture_rect.texture = viewport_texture
			
			# 保存引用（如果需要）
			self.original_viewport_texture = viewport_texture

		# 保存原始的 ViewportTexture
		# var current_texture = texture_rect_node.texture
		# if current_texture is ViewportTexture:
		# 	self.original_viewport_texture = current_texture
		# 	#print("保存原始 ViewportTexture")

# 连接按钮信号
func _connect_button_signals(scene_instance: Control) -> void:
	# 查找所有按钮并连接信号
	var buttons = _find_all_buttons(scene_instance)
	
	for button in buttons:
		match button.text:
			"相机选中(Selected)":
				button.pressed.connect(_on_get_camera_button_pressed)
			"ModelContainer选中(Selected)":
				button.pressed.connect(_on_get_model_container_button_pressed)
			"上传模型(Upload Model)":
				button.pressed.connect(_on_upload_model_button_pressed)
			"图片和动画导出(Image and Animation Export)":
				button.pressed.connect(_on_popup_button_pressed)
			"选中动画(Selected AnimationPlayer)":
				button.pressed.connect(_on_get_animation_player_button_pressed)
			"播放所有▶":
				button.pressed.connect(_on_play_all_button_pressed)
			"暂停所有⏸":
				button.pressed.connect(_on_pause_all_button_pressed)
			"停止所有(stop)":
				button.pressed.connect(_on_stop_all_button_pressed)


# 查找所有按钮
func _find_all_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	
	if node is Button:
		buttons.append(node)
	
	for child in node.get_children():
		buttons.append_array(_find_all_buttons(child))
	
	return buttons




# 创建主窗口
func _create_main_window() -> void:
	main_window = Window.new()
	main_window.title = "3D To 2D"
	main_window.size = Vector2i(1200, 800)
	main_window.min_size = Vector2i(800, 600)
	main_window.close_requested.connect(_on_window_close_requested)
	
	# 加载主面板 - 使用您已经创建好的场景
	main_panel_instance = main_panel_scene.instantiate()
	main_window.add_child(main_panel_instance)
	
	# 设置主面板填充整个窗口
	main_panel_instance.anchors_preset = Control.PRESET_FULL_RECT
	main_panel_instance.offset_left = 0
	main_panel_instance.offset_top = 0
	main_panel_instance.offset_right = 0
	main_panel_instance.offset_bottom = 0
	
	# 设置弹出窗口的场景节点
	_setup_scene_nodes(main_panel_instance)
	
	# 将窗口添加到编辑器界面
	get_editor_interface().get_base_control().add_child(main_window)
	
	# 初始隐藏窗口
	main_window.visible = false


# 创建预览窗口
func _create_preview_window() -> void:
	if main_window == null:
		main_window = Window.new()
		main_window.title = "预览面板"
		main_window.size = Vector2i(1152, 648)
		main_window.min_size = Vector2i(800, 600)
		main_window.close_requested.connect(_on_preview_window_close_requested)
	
	# 加载预览面板
	preview_panel_instance = preview_panel_scene.instantiate()
	main_window.add_child(preview_panel_instance)
	
	# 设置预览面板填充整个窗口
	preview_panel_instance.anchors_preset = Control.PRESET_FULL_RECT
	preview_panel_instance.offset_left = 0
	preview_panel_instance.offset_top = 0
	preview_panel_instance.offset_right = 0
	preview_panel_instance.offset_bottom = 0
	
	# 获取必要的节点引用并传递给预览面板
	_setup_preview_panel_references()
	
	# 将窗口添加到编辑器界面
	if not main_window.is_inside_tree():
		get_editor_interface().get_base_control().add_child(main_window)
	
	# 初始隐藏窗口
	main_window.visible = false


# 设置预览面板的节点引用
func _setup_preview_panel_references() -> void:
	if preview_panel_instance == null:
		return
	
	# 获取预览面板的脚本
	var preview_panel_script = preview_panel_instance.get_script()
	if preview_panel_script == null:
		#print("预览面板脚本未找到")
		return
	
	# 查找必要的节点
	# 1. sprite2D2: VBoxContainer/RealTimeTexture
	var sprite2d2_node = dock_panel_instance.find_child("RealTimeTexture", true, false)
	if not sprite2d2_node or not sprite2d2_node is TextureRect:
		#print("未找到 RealTimeTexture 节点")
		sprite2d2_node = null
	
	# 2. normal_mesh: SubViewport/Node3D/Camera/NormalMesh
	var normal_mesh_node = dock_panel_instance.find_child("NormalMesh", true, false)
	if not normal_mesh_node or not normal_mesh_node is MeshInstance3D:
		#print("未找到 NormalMesh 节点")
		normal_mesh_node = null
	
	# 3. vfx_mesh: SubViewport/Node3D/Camera/VFXMesh
	var vfx_mesh_node = dock_panel_instance.find_child("VFXMesh", true, false)
	if not vfx_mesh_node or not vfx_mesh_node is MeshInstance3D:
		#print("未找到 VFXMesh 节点")
		vfx_mesh_node = null
	
	# 调用预览面板的set_external_references方法
	# 传递threeToTwo实例的引用，而不是单个AnimationPlayer
	if preview_panel_instance.has_method("set_external_references"):
		preview_panel_instance.set_external_references(sprite2d2_node, self, normal_mesh_node)
		#print("已设置预览面板的外部引用（传递threeToTwo实例）")
	# else:
	# 	print("预览面板没有set_external_references方法")


# 弹出弹窗按钮点击事件
func _on_popup_button_pressed() -> void:
	control_all_animation_players("stop",0)
	await get_tree().create_timer(0.5).timeout
	# 创建或更新预览窗口
	if main_window == null or preview_panel_instance == null:
		_create_preview_window()
	elif not preview_panel_instance.is_inside_tree():
		# 如果预览面板不在场景树中，重新创建
		preview_panel_instance = preview_panel_scene.instantiate()
		main_window.add_child(preview_panel_instance)
		# 设置预览面板填充整个窗口
		preview_panel_instance.anchors_preset = Control.PRESET_FULL_RECT
		preview_panel_instance.offset_left = 0
		preview_panel_instance.offset_top = 0
		preview_panel_instance.offset_right = 0
		preview_panel_instance.offset_bottom = 0
		
		# 设置预览面板的节点引用
		_setup_preview_panel_references()
	
	# 显示预览面板
	if preview_panel_instance.has_method("show_preview"):
		preview_panel_instance.show_preview()
	
	if main_window.visible:
		# 如果窗口已经显示，将其置于前台
		main_window.grab_focus()
	else:
		# 显示窗口并居中
		main_window.visible = true
		_center_window()


# 窗口关闭请求事件
func _on_window_close_requested() -> void:
	# 从窗口中移除主面板
	if main_window != null and main_panel_instance != null:
		main_window.remove_child(main_panel_instance)
		main_panel_instance.queue_free()
		main_panel_instance = null
	
	# 隐藏窗口
	if main_window != null:
		main_window.visible = false


# 预览窗口关闭请求事件
func _on_preview_window_close_requested() -> void:
	# 在移除预览面板前，恢复所有MeshInstance3D的原始材质
	if preview_panel_instance != null and is_instance_valid(preview_panel_instance):
		# 调用预览面板的恢复材质方法
		if preview_panel_instance.has_method("restore_original_materials"):
			preview_panel_instance.restore_original_materials()
			#print("已恢复所有MeshInstance3D的原始材质")
	
	# 隐藏threeToTwo中的NormalMesh节点
	_hide_normal_mesh_in_three_to_two()
	
	# 从窗口中移除预览面板
	if main_window != null and preview_panel_instance != null:
		main_window.remove_child(preview_panel_instance)
		preview_panel_instance.queue_free()
		preview_panel_instance = null
	
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




# 获取选中相机按钮点击事件
func _on_get_camera_button_pressed() -> void:
	# 获取编辑器选择
	var editor_selection = get_editor_interface().get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()
	
	if selected_nodes.size() == 0:
		#print("请先在场景中选择一个 Camera3D 节点")
		if camera_label:
			camera_label.text = "camera：无"
		selected_camera_node = null
		return
	
	# 获取第一个选中的节点
	var selected_node = selected_nodes[0]
	
	# 检查是否是 Camera3D 节点
	if selected_node is Camera3D:
		selected_camera_node = selected_node
		if camera_label:
			camera_label.text = "camera：" + selected_node.name
		#print("已选择 Camera3D 节点: " + selected_node.name)
		
		# 确保 SubViewport 相机有效并设置为当前相机
		if is_instance_valid(subviewport_camera):
			subviewport_camera.current = true
			#print("已设置 SubViewport 相机为当前相机")
	else:
		#print("选中的节点不是 Camera3D 类型")
		if camera_label:
			camera_label.text = "camera：无"
		selected_camera_node = null


# 获取选中 ModelContainer 按钮点击事件
func _on_get_model_container_button_pressed() -> void:
	# 获取编辑器选择
	var editor_selection = get_editor_interface().get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()
	
	if selected_nodes.size() == 0:
		#print("请先在场景中选择一个节点作为 ModelContainer")
		if model_container_label:
			model_container_label.text = "未选择 ModelContainer"
		selected_model_container_node = null
		return
	
	# 获取第一个选中的节点
	var selected_node = selected_nodes[0]
	
	# 检查是否是 Node3D 节点（或任何可以包含子节点的类型）
	if selected_node is Node3D:
		selected_model_container_node = selected_node
		if model_container_label:
			model_container_label.text = "已选择: " + selected_node.name
		#print("已选择 ModelContainer 节点: " + selected_node.name)
	else:
		#print("选中的节点不是 Node3D 类型")
		if model_container_label:
			model_container_label.text = "选中的节点不是 Node3D"
		selected_model_container_node = null




# ============================================
# AnimationPlayer管理器功能
# ============================================

# 获取选中AnimationPlayer按钮点击事件
func _on_get_animation_player_button_pressed() -> void:
	# 获取编辑器选择
	var editor_selection = get_editor_interface().get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()
	
	if selected_nodes.size() == 0:
		#print("请先在场景中选择一个 AnimationPlayer 节点")
		return
	
	# 获取第一个选中的节点
	var selected_node = selected_nodes[0]
	
	# 检查是否是 AnimationPlayer 节点
	if selected_node is AnimationPlayer:
		# 检查是否已经添加过这个AnimationPlayer
		for entry in animation_player_entries:
			if entry.animation_player == selected_node:
				#print("该AnimationPlayer已经在列表中: " + selected_node.name)
				return
		
		# 创建新的AnimationPlayer条目
		_create_animation_player_entry(selected_node)
		#print("已选择 AnimationPlayer 节点: " + selected_node.name)
	else:
		print("选中的节点不是 AnimationPlayer 类型")


# 创建AnimationPlayer条目
func _create_animation_player_entry(player: AnimationPlayer) -> void:
	# 检查容器是否有效
	if not is_instance_valid(animation_player_container):
		print("错误：AnimationPlayer列表容器无效")
		return
	
	# 实例化条目模板
	var entry_ui = animation_player_entry_scene.instantiate()
	animation_player_container.add_child(entry_ui)
	
	# 查找UI元素
	var player_name_label = entry_ui.find_child("PlayerNameLabel", true, false)
	var animation_option_button = entry_ui.find_child("AnimationOptionButton", true, false)
	var play_button = entry_ui.find_child("PlayButton", true, false)
	var select_checkbutton = entry_ui.find_child("SelectCheckButton", true, false)
	var loop_checkbutton = entry_ui.find_child("LoopCheckButton", true, false)
	var remove_button = entry_ui.find_child("RemoveButton", true, false)
	
	# 设置玩家名称
	if player_name_label is Label:
		player_name_label.text = player.name
	
	# 获取动画列表并填充下拉菜单
	if animation_option_button is OptionButton:
		animation_option_button.clear()
		var animation_list = _get_animation_list(player)
		for anim_name in animation_list:
			animation_option_button.add_item(anim_name)
		
		# 默认选择第一个动画（如果有）
		if animation_list.size() > 0:
			animation_option_button.select(0)
			# 保存动画名称
			var selected_anim = animation_option_button.get_item_text(0)
	
	# 连接按钮信号
	if play_button is Button:
		play_button.pressed.connect(_on_entry_play_button_pressed.bind(player, entry_ui))
	
	if select_checkbutton is CheckButton:
		select_checkbutton.toggled.connect(_on_select_checkbutton_toggled.bind(player, entry_ui))
	
	if loop_checkbutton is CheckButton:
		loop_checkbutton.toggled.connect(_on_loop_checkbutton_toggled.bind(player, entry_ui))
	
	if remove_button is Button:
		remove_button.pressed.connect(_on_entry_remove_button_pressed.bind(player, entry_ui))
	
	# 连接动画下拉菜单信号
	if animation_option_button is OptionButton:
		animation_option_button.item_selected.connect(_on_animation_option_selected.bind(player, entry_ui))
	
	# 连接动画完成信号
	player.animation_finished.connect(_on_animation_finished.bind(player))
	
	# 创建条目对象
	var entry = AnimationPlayerEntry.new(player, entry_ui)
	entry.option_button = animation_option_button
	entry.play_button = play_button
	entry.select_checkbutton = select_checkbutton
	entry.loop_checkbutton = loop_checkbutton
	
	# 根据CheckButton的初始状态设置条目状态
	if select_checkbutton is CheckButton:
		entry.is_selected = select_checkbutton.button_pressed
	
	# 重要修改：检查动画的实际循环模式，而不是使用UI按钮的初始状态
	var is_animation_looping = false
	if animation_option_button is OptionButton and animation_option_button.get_item_count() > 0:
		var selected_index = animation_option_button.get_selected()
		if selected_index >= 0:
			var animation_name = animation_option_button.get_item_text(selected_index)
			var animation = player.get_animation(animation_name)
			if animation:
				# 检查动画的实际循环模式
				is_animation_looping = (animation.loop_mode == Animation.LOOP_LINEAR)
				#print("检测到动画 '%s' 的循环模式: %s" % [animation_name, "循环" if is_animation_looping else "不循环"])
	
	# 根据动画的实际循环模式设置条目状态和UI按钮
	if loop_checkbutton is CheckButton:
		loop_checkbutton.button_pressed = is_animation_looping
		entry.is_looping = is_animation_looping
	
	# 保存到数组
	animation_player_entries.append(entry)


# 获取AnimationPlayer的动画列表
func _get_animation_list(player: AnimationPlayer) -> Array[String]:
	var animations: Array[String] = []
	
	if is_instance_valid(player):
		for anim_name in player.get_animation_list():
			animations.append(anim_name)
	
	return animations


# 条目播放按钮点击事件
func _on_entry_play_button_pressed(player: AnimationPlayer, entry_ui: Control) -> void:
	# 找到对应的条目
	var entry = _find_animation_player_entry(player)
	if entry == null:
		print("错误：找不到对应的AnimationPlayer条目")
		return
	
	# 查找下拉菜单
	var animation_option_button = entry_ui.find_child("AnimationOptionButton", true, false)
	if not animation_option_button or not animation_option_button is OptionButton:
		print("错误：找不到动画选择下拉菜单")
		return
	
	# 获取选中的动画
	var selected_index = animation_option_button.get_selected()
	if selected_index < 0:
		print("请先选择一个动画")
		return
	
	var animation_name = animation_option_button.get_item_text(selected_index)
	
	# 检查动画是否正在播放
	var is_currently_playing = player.is_playing()
	
	# 如果动画正在播放，就暂停它
	if is_currently_playing:
		# 暂停动画
		player.pause()
		entry.is_playing = false
		# 更新按钮文本
		var play_button = entry_ui.find_child("PlayButton", true, false)
		if play_button is Button:
			play_button.text = "▶"
		#print("已暂停动画: " + animation_name)
	else:
		# 每次播放都设置循环模式（确保循环设置生效）
		_update_animation_loop_mode(player, animation_name, entry.is_looping)
		
		# 播放动画
		player.play(animation_name)
		entry.is_playing = true
		entry.animation_name = animation_name
		# 更新按钮文本
		var play_button = entry_ui.find_child("PlayButton", true, false)
		if play_button is Button:
			play_button.text = "⏸"
		#print("已播放动画: " + animation_name + (" (循环)" if entry.is_looping else ""))


# 条目删除按钮点击事件
func _on_entry_remove_button_pressed(player: AnimationPlayer, entry_ui: Control) -> void:
	# 找到对应的条目
	var entry_index = -1
	for i in range(animation_player_entries.size()):
		if animation_player_entries[i].animation_player == player:
			entry_index = i
			break
	
	if entry_index >= 0:
		# 停止动画（如果正在播放）
		if animation_player_entries[entry_index].is_playing:
			player.stop()
		
		# 从容器中移除UI
		if is_instance_valid(animation_player_container):
			animation_player_container.remove_child(entry_ui)
			entry_ui.queue_free()
		
		# 从数组中移除条目
		animation_player_entries.remove_at(entry_index)
		#print("已移除AnimationPlayer: " + player.name)


# 查找AnimationPlayer条目
func _find_animation_player_entry(player: AnimationPlayer) -> AnimationPlayerEntry:
	for entry in animation_player_entries:
		if entry.animation_player == player:
			return entry
	return null


# 播放所有按钮点击事件
func _on_play_all_button_pressed() -> void:
	#print("播放所有选中的AnimationPlayer")
	
	for entry in animation_player_entries:
		# 只播放选中的条目
		if entry.is_selected and is_instance_valid(entry.animation_player):
			# 获取选中的动画
			if entry.option_button and is_instance_valid(entry.option_button):
				var selected_index = entry.option_button.get_selected()
				if selected_index >= 0:
					var animation_name = entry.option_button.get_item_text(selected_index)
					
					# 检查动画是否正在播放
					var is_currently_playing = entry.animation_player.is_playing()
					
					# 如果动画没有在播放，或者已经播放完毕，就重新播放
					if not is_currently_playing:
						# 设置循环模式
						if entry.is_looping:
							_update_animation_loop_mode(entry.animation_player, animation_name, true)
						
						# 播放动画
						entry.animation_player.play(animation_name)
						entry.is_playing = true
						entry.animation_name = animation_name
						
						# 更新按钮文本
						if entry.play_button and is_instance_valid(entry.play_button):
							entry.play_button.text = "⏸"
						
					# 	print("已播放: " + entry.animation_player.name + " - " + animation_name)
					# else:
					# 	print("动画已经在播放: " + entry.animation_player.name + " - " + animation_name)


# 暂停所有按钮点击事件
func _on_pause_all_button_pressed() -> void:
	#print("暂停所有选中的AnimationPlayer")
	
	for entry in animation_player_entries:
		# 只暂停选中的条目
		if entry.is_selected and entry.is_playing and is_instance_valid(entry.animation_player):
			entry.animation_player.pause()
			entry.is_playing = false
			
			# 更新按钮文本
			if entry.play_button and is_instance_valid(entry.play_button):
				entry.play_button.text = "▶"
			
			#print("已暂停: " + entry.animation_player.name)


# 停止所有按钮点击事件
func _on_stop_all_button_pressed() -> void:
	#print("停止所有选中的AnimationPlayer")
	
	for entry in animation_player_entries:
		# 只停止选中的条目
		if entry.is_selected and is_instance_valid(entry.animation_player):
			entry.animation_player.stop()
			entry.is_playing = false
			
			# 更新按钮文本
			if entry.play_button and is_instance_valid(entry.play_button):
				entry.play_button.text = "▶"
			
			#print("已停止: " + entry.animation_player.name)


# ============================================
# CheckButton信号处理函数
# ============================================

# 选择按钮状态变化事件
func _on_select_checkbutton_toggled(button_pressed: bool, player: AnimationPlayer, entry_ui: Control) -> void:
	# 找到对应的条目
	var entry = _find_animation_player_entry(player)
	if entry == null:
		print("错误：找不到对应的AnimationPlayer条目")
		return
	
	# 更新选择状态
	entry.is_selected = button_pressed
	#print("AnimationPlayer " + player.name + " 选择状态: " + ("选中" if button_pressed else "未选中"))


# 循环按钮状态变化事件
func _on_loop_checkbutton_toggled(button_pressed: bool, player: AnimationPlayer, entry_ui: Control) -> void:
	# 找到对应的条目
	var entry = _find_animation_player_entry(player)
	if entry == null:
		print("错误：找不到对应的AnimationPlayer条目")
		return
	
	# 更新循环状态
	entry.is_looping = button_pressed
	#print("AnimationPlayer " + player.name + " 循环状态: " + ("开启" if button_pressed else "关闭"))
	
	# 获取当前选中的动画名称
	var animation_name = ""
	if entry.option_button and is_instance_valid(entry.option_button):
		var selected_index = entry.option_button.get_selected()
		if selected_index >= 0:
			animation_name = entry.option_button.get_item_text(selected_index)
	
	# 如果有动画名称，立即更新动画的循环模式
	if animation_name != "":
		_update_animation_loop_mode(player, animation_name, button_pressed)
		#print("已立即更新动画循环模式: " + animation_name + " -> " + ("循环" if button_pressed else "非循环"))


# 动画下拉菜单选择事件
func _on_animation_option_selected(index: int, player: AnimationPlayer, entry_ui: Control) -> void:
	# 找到对应的条目
	var entry = _find_animation_player_entry(player)
	if entry == null:
		print("错误：找不到对应的AnimationPlayer条目")
		return
	
	# 获取选中的动画名称
	var animation_option_button = entry_ui.find_child("AnimationOptionButton", true, false)
	if not animation_option_button or not animation_option_button is OptionButton:
		print("错误：找不到动画选择下拉菜单")
		return
	
	var animation_name = animation_option_button.get_item_text(index)
	if animation_name == "":
		print("错误：动画名称为空")
		return
	
	# 获取动画资源
	var animation = player.get_animation(animation_name)
	if not animation:
		print("错误：找不到动画资源: " + animation_name)
		return
	
	# 检查动画的实际循环模式
	var is_animation_looping = (animation.loop_mode == Animation.LOOP_LINEAR)
	#print("动画 '%s' 的循环模式: %s" % [animation_name, "循环" if is_animation_looping else "不循环"])
	
	# 更新条目状态
	entry.is_looping = is_animation_looping
	entry.animation_name = animation_name
	
	# 更新UI上的循环按钮状态
	var loop_checkbutton = entry_ui.find_child("LoopCheckButton", true, false)
	if loop_checkbutton is CheckButton:
		loop_checkbutton.button_pressed = is_animation_looping
		#print("已更新循环按钮状态: %s" % ("选中" if is_animation_looping else "未选中"))


# 更新动画循环模式
func _update_animation_loop_mode(player: AnimationPlayer, animation_name: String, is_looping: bool) -> void:
	if not is_instance_valid(player):
		return
	
	# 获取动画资源
	var animation = player.get_animation(animation_name)
	if animation:
		# 设置循环模式
		if is_looping:
			animation.loop_mode = Animation.LOOP_LINEAR
			#print("已设置动画 " + animation_name + " 为循环模式")
		else:
			animation.loop_mode = Animation.LOOP_NONE
			#print("已设置动画 " + animation_name + " 为非循环模式")


# ============================================
# 动画完成信号处理
# ============================================

# 动画完成事件
func _on_animation_finished(anim_name: String, player: AnimationPlayer) -> void:
	# 找到对应的条目
	var entry = _find_animation_player_entry(player)
	if entry == null:
		print("错误：找不到对应的AnimationPlayer条目")
		return
	
	# 防重复触发机制：检查距离上次动画完成时间是否太近
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - entry.last_animation_finished_time < 0.1:  # 100毫秒内不重复处理
		print("防重复触发：忽略短时间内重复的动画完成事件: " + player.name + " - " + anim_name)
		return
	
	# 更新上次动画完成时间
	entry.last_animation_finished_time = current_time
	
	# 更新播放状态
	entry.is_playing = false
	entry.animation_name = anim_name
	
	# 更新UI按钮文本
	if entry.play_button and is_instance_valid(entry.play_button):
		entry.play_button.text = "▶"
	
	#print("动画播放完成: " + player.name + " - " + anim_name)
	
	# 注意：不要在这里修改动画的循环设置
	# 循环设置已经通过 _update_animation_loop_mode 函数持久化到动画资源中
	# 动画完成后，循环设置保持不变，下次播放时会使用当前的循环设置


# ============================================
# 预览面板辅助方法
# ============================================

# 获取所有选中的AnimationPlayer
func get_selected_animation_players() -> Array[AnimationPlayer]:
	var selected_players: Array[AnimationPlayer] = []
	for entry in animation_player_entries:
		if entry.is_selected and is_instance_valid(entry.animation_player):
			selected_players.append(entry.animation_player)
	return selected_players

# 获取所有选中动画的最大长度
func get_max_selected_animation_length() -> float:
	var max_length: float = 0.0
	for entry in animation_player_entries:
		if entry.is_selected and is_instance_valid(entry.animation_player):
			if entry.option_button and is_instance_valid(entry.option_button):
				var selected_index = entry.option_button.get_selected()
				if selected_index >= 0:
					var anim_name = entry.option_button.get_item_text(selected_index)
					var anim = entry.animation_player.get_animation(anim_name)
					if anim:
						max_length = max(max_length, anim.length)
	return max_length

# 获取所有选中动画的最小长度
func get_min_selected_animation_length() -> float:
	var min_length: float = INF
	var has_selected: bool = false
	for entry in animation_player_entries:
		if entry.is_selected and is_instance_valid(entry.animation_player):
			if entry.option_button and is_instance_valid(entry.option_button):
				var selected_index = entry.option_button.get_selected()
				if selected_index >= 0:
					var anim_name = entry.option_button.get_item_text(selected_index)
					var anim = entry.animation_player.get_animation(anim_name)
					if anim:
						min_length = min(min_length, anim.length)
						has_selected = true
	return min_length if has_selected else 0.0

# 获取所有选中的动画名称
func get_selected_animation_names() -> Array[String]:
	var animation_names: Array[String] = []
	for entry in animation_player_entries:
		if entry.is_selected and is_instance_valid(entry.animation_player):
			if entry.option_button and is_instance_valid(entry.option_button):
				var selected_index = entry.option_button.get_selected()
				if selected_index >= 0:
					var anim_name = entry.option_button.get_item_text(selected_index)
					animation_names.append(anim_name)
	return animation_names

# 获取选中动画的时长信息
func get_selected_animation_info() -> Dictionary:
	var info = {
		"count": 0,
		"max_length": 0.0,
		"min_length": 0.0,
		"animation_names": [],
		"player_names": []
	}
	
	for entry in animation_player_entries:
		if entry.is_selected and is_instance_valid(entry.animation_player):
			info.count += 1
			info.player_names.append(entry.animation_player.name)
			
			if entry.option_button and is_instance_valid(entry.option_button):
				var selected_index = entry.option_button.get_selected()
				if selected_index >= 0:
					var anim_name = entry.option_button.get_item_text(selected_index)
					info.animation_names.append(anim_name)
					
					var anim = entry.animation_player.get_animation(anim_name)
					if anim:
						info.max_length = max(info.max_length, anim.length)
						if info.min_length == 0.0 or anim.length < info.min_length:
							info.min_length = anim.length
	
	return info

# 控制所有选中的AnimationPlayer（播放各自的选中动画）
func control_all_animation_players(action: String, time: float = 0.0) -> void:
	for entry in animation_player_entries:
		if entry.is_selected and is_instance_valid(entry.animation_player):
			# 获取该AnimationPlayer选中的动画名称
			var anim_to_play = ""
			if entry.option_button and is_instance_valid(entry.option_button):
				var selected_index = entry.option_button.get_selected()
				if selected_index >= 0:
					anim_to_play = entry.option_button.get_item_text(selected_index)
			
			match action:
				"play":
					if anim_to_play != "" and entry.animation_player.has_animation(anim_to_play):
						var anim = entry.animation_player.get_animation(anim_to_play)
						if anim and time < anim.length-0.001:  # 只有时间小于动画长度时才播放
							entry.animation_player.play(anim_to_play)
							entry.animation_player.seek(time)
							entry.is_playing = true
							entry.animation_name = anim_to_play
						else:
							# 动画已经播放完成，暂停它
							entry.animation_player.pause()
							entry.is_playing = false
							# print("跳过已完成的动画: " + entry.animation_player.name + " - " + anim_to_play)
				
				"pause":
					if entry.animation_player.is_playing():
						entry.animation_player.pause()
						entry.is_playing = false
						# print("暂停: " + entry.animation_player.name)
				
				"stop":
					entry.animation_player.stop()
					entry.animation_player.seek(time)
					entry.is_playing = false
					print("停止: " + entry.animation_player.name)
				
				"seek":
					if anim_to_play != "" and entry.animation_player.has_animation(anim_to_play):
						entry.animation_player.seek(time)
						# print("跳转到: " + entry.animation_player.name + " (时间: " + str(time) + ")")
				
				_:
					print("未知的控制动作: " + action)

# 获取选中的AnimationPlayer数量
func get_selected_animation_player_count() -> int:
	var count: int = 0
	for entry in animation_player_entries:
		if entry.is_selected:
			count += 1
	return count

# 获取汇总状态信息
func get_animation_status_summary() -> Dictionary:
	var status = {
		"selected_count": 0,
		"playing_count": 0,
		"paused_count": 0,
		"stopped_count": 0,
		"max_length": 0.0
	}
	
	for entry in animation_player_entries:
		if entry.is_selected:
			status.selected_count += 1
			if entry.is_playing:
				status.playing_count += 1
			elif is_instance_valid(entry.animation_player) and entry.animation_player.is_playing():
				status.playing_count += 1
			else:
				status.stopped_count += 1
	
	status.max_length = get_max_selected_animation_length()
	return status


# ============================================
# ModelContainer 网格搜索功能
# ============================================

# 搜索 ModelContainer 下的所有 MeshInstance3D
func find_all_mesh_instances_in_model_container() -> Array[MeshInstance3D]:
	var mesh_instances: Array[MeshInstance3D] = []
	
	if selected_model_container_node == null or not is_instance_valid(selected_model_container_node):
		#print("请先选择一个 ModelContainer 节点")
		return mesh_instances
	
	# 递归查找所有 MeshInstance3D
	_find_mesh_instances_recursive(selected_model_container_node, mesh_instances)
	
	#print("在 ModelContainer 中找到 %d 个 MeshInstance3D" % mesh_instances.size())
	return mesh_instances

# 递归查找 MeshInstance3D
func _find_mesh_instances_recursive(node: Node, result: Array[MeshInstance3D]):
	if node is MeshInstance3D:
		result.append(node)
	
	# 递归查找子节点
	for child in node.get_children():
		_find_mesh_instances_recursive(child, result)


# ============================================
# 隐藏threeToTwo中的NormalMesh节点
# ============================================

# 隐藏threeToTwo中的NormalMesh节点
func _hide_normal_mesh_in_three_to_two():
	# 在dock_panel_instance中查找NormalMesh节点
	if dock_panel_instance != null and is_instance_valid(dock_panel_instance):
		var normal_mesh_node = dock_panel_instance.find_child("NormalMesh", true, false)
		if normal_mesh_node != null and normal_mesh_node is MeshInstance3D:
			normal_mesh_node.visible = false
			#print("已隐藏threeToTwo中的NormalMesh节点")
		else:
			print("未找到threeToTwo中的NormalMesh节点")
	else:
		print("dock_panel_instance无效，无法隐藏NormalMesh节点")


# ============================================
# 场景相机跟随功能
# ============================================

# 重写 EditorPlugin 的 _forward_3d_gui_input 方法
func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	# 缓存编辑器相机的引用
	if viewport_camera != editor_camera:
		editor_camera = viewport_camera
		#print("获取到编辑器3D相机: ", editor_camera.name if editor_camera else "null")
	return EditorPlugin.AFTER_GUI_INPUT_PASS


# 获取编辑器场景相机
func _get_editor_scene_camera() -> Camera3D:
	# 首先尝试使用缓存的编辑器相机
	if editor_camera != null and is_instance_valid(editor_camera):
		return editor_camera
	
	# 备用方案：通过 EditorInterface 获取编辑器视口
	var editor_interface = get_editor_interface()
	if editor_interface:
		# 获取第一个3D编辑器视口
		var viewport_3d = editor_interface.get_editor_viewport_3d(0)
		if viewport_3d:
			# 尝试获取相机
			var camera = viewport_3d.get_camera_3d()
			if camera != null and is_instance_valid(camera):
				editor_camera = camera
				#print("通过备用方法获取到编辑器3D相机: ", camera.name)
				return camera
	
	return null


# 场景跟随按钮信号处理函数
func _on_scene_follow_checkbutton_toggled(button_pressed: bool) -> void:
	is_following_scene_camera = button_pressed
	
	if button_pressed:
		#print("启用场景相机跟随模式 - 选中的相机将跟随编辑器场景相机")
		
		# 检查是否已选中相机
		if selected_camera_node == null or not is_instance_valid(selected_camera_node):
			#print("提示：请先选中一个相机节点")
			# 尝试自动获取当前选中的相机
			_on_get_camera_button_pressed()
		
		# 尝试立即获取编辑器相机
		editor_camera = null  # 清除缓存，强制重新获取
		var scene_camera = _get_editor_scene_camera()
		if scene_camera != null:
			#print("成功获取到编辑器相机: ", scene_camera.name)
			# 立即同步一次
			if selected_camera_node != null and is_instance_valid(selected_camera_node):
				selected_camera_node.global_transform = scene_camera.global_transform
				# 注释掉相机属性同步，只同步位置和旋转
				# selected_camera_node.fov = scene_camera.fov
				# selected_camera_node.near = scene_camera.near
				# selected_camera_node.far = scene_camera.far
				# selected_camera_node.projection = scene_camera.projection
				#print("已立即同步到编辑器相机位置")
		else:
			print("提示：请在3D编辑器中移动鼠标以获取编辑器相机引用")
	else:
		print("禁用场景相机跟随模式")


# ============================================
# 纹理缓存功能
# ============================================

# VFXButton 点击事件
func _on_vfx_button_pressed() -> void:
	# 第一步：关闭现有的 vfx_preview_panel 窗口（如果存在）
	_close_existing_vfx_preview_panel()
	control_all_animation_players("stop",0)
	await get_tree().create_timer(0.5).timeout
	# 第二步：执行原来的缓存逻辑
	if is_caching:
		# 如果正在缓存，停止缓存
		stop_caching()
	else:
		# 关键修改：触发选中的 AnimationPlayer 的"播放所有"按钮
		_on_play_all_button_pressed()
		
		# 然后开始纹理缓存
		start_caching()

# 开始缓存纹理
func start_caching():
	if is_caching:
		return
	
	# 获取选中动画的最大时长
	cache_duration = get_max_selected_animation_length()
	if cache_duration <= 0:
		print("错误：没有选中的动画或动画时长为0")
		return
	
	# 清空之前的缓存
	cached_textures.clear()
	
	# print("开始缓存特效纹理，动画时长: %.2f秒，间隔: %.3f秒" % [cache_duration, cache_interval])
	
	# 在开始缓存前先开启 VFXMesh 节点
	if vfx_mesh_node != null and is_instance_valid(vfx_mesh_node):
		vfx_mesh_node.visible = true
		#print("已开启 VFXMesh 节点")
	else:
		print("警告：VFXMesh 节点未找到或无效")
	
	# 设置定时器
	cache_timer.wait_time = cache_interval
	cache_timer.start()
	
	is_caching = true
	current_cache_time = 0.0
	
	# 更新按钮文本
	if vfx_button:
		vfx_button.text = "停止导出⏸"

# 停止缓存
func stop_caching():
	if not is_caching:
		return
	
	cache_timer.stop()
	is_caching = false
	current_cache_time = 0.0
	
	# 更新按钮文本
	if vfx_button:
		vfx_button.text = "特效导出(Special Effects Export)"
	
	#print("停止缓存，共捕获 %d 张纹理" % cached_textures.size())
	
	# 停止缓存后关闭 VFXMesh 节点
	if vfx_mesh_node != null and is_instance_valid(vfx_mesh_node):
		vfx_mesh_node.visible = false
		#print("已关闭 VFXMesh 节点")
	
	# 如果有缓存的纹理，弹出 VFX 预览面板（支持中途停止）
	if not cached_textures.is_empty():
		_show_vfx_preview_panel()

# 捕获当前纹理
func capture_current_texture() -> ImageTexture:
	if texture_rect == null or texture_rect.texture == null:
		return null
	
	var viewport_texture = texture_rect.texture
	if viewport_texture is ViewportTexture:
		# 获取ViewportTexture的图像
		var image: Image = viewport_texture.get_image()
		if image == null or image.is_empty():
			return null
		
		# 创建ImageTexture
		var texture = ImageTexture.create_from_image(image)
		return texture
	
	return null

# 缓存定时器超时事件
func _on_cache_timer_timeout():
	if not is_caching or current_cache_time > cache_duration:
		# 缓存完成
		stop_caching()
		return
	
	# 捕获纹理
	var texture = capture_current_texture()
	if texture != null:
		cached_textures.append(texture)
		# print("捕获纹理 %d，时间: %.2f/%.2f" % [cached_textures.size(), current_cache_time, cache_duration])
	
	# 更新时间
	current_cache_time += cache_interval

# 开始播放缓存纹理
func start_playing_cached():
	if is_playing_cached or cached_textures.is_empty():
		return
	
	#print("开始播放缓存纹理，数量: %d" % cached_textures.size())
	
	play_timer.wait_time = cache_interval
	play_timer.start()
	
	is_playing_cached = true
	current_play_index = 0

# 停止播放缓存纹理
func stop_playing_cached():
	if not is_playing_cached:
		return
	
	play_timer.stop()
	is_playing_cached = false
	current_play_index = 0
	
	#print("停止播放缓存纹理")

# 播放定时器超时事件
func _on_play_timer_timeout():
	if not is_playing_cached or current_play_index >= cached_textures.size():
		# 播放完成
		stop_playing_cached()
		return
	
	# 设置纹理
	if texture_rect != null and current_play_index < cached_textures.size():
		texture_rect.texture = cached_textures[current_play_index]
		#print("播放纹理 %d/%d" % [current_play_index + 1, cached_textures.size()])
	
	current_play_index += 1

# 初始化定时器（在 _enter_tree 中调用）
func _initialize_timers():
	# 创建缓存定时器
	cache_timer = Timer.new()
	cache_timer.name = "CacheTimer"
	cache_timer.one_shot = false
	cache_timer.timeout.connect(_on_cache_timer_timeout)
	add_child(cache_timer)
	
	# 创建播放定时器
	play_timer = Timer.new()
	play_timer.name = "PlayTimer"
	play_timer.one_shot = false
	play_timer.timeout.connect(_on_play_timer_timeout)
	add_child(play_timer)

# ============================================
# VFX 预览面板功能
# ============================================

# 显示 VFX 预览面板
func _show_vfx_preview_panel():
	if cached_textures.is_empty():
		#print("错误：没有缓存的纹理可以预览")
		return
	
	# 创建窗口
	vfx_preview_window = Window.new()
	vfx_preview_window.title = "VFX 特效预览"
	vfx_preview_window.size = Vector2i(1152, 648)
	vfx_preview_window.min_size = Vector2i(800, 600)
	vfx_preview_window.close_requested.connect(_on_vfx_preview_window_close_requested)
	
	# 加载 VFX 预览面板
	vfx_preview_panel_instance = vfx_preview_panel_scene.instantiate()
	vfx_preview_window.add_child(vfx_preview_panel_instance)
	
	# 设置面板填充整个窗口
	vfx_preview_panel_instance.anchors_preset = Control.PRESET_FULL_RECT
	vfx_preview_panel_instance.offset_left = 0
	vfx_preview_panel_instance.offset_top = 0
	vfx_preview_panel_instance.offset_right = 0
	vfx_preview_panel_instance.offset_bottom = 0
	
	# 传递缓存的纹理给预览面板
	_setup_vfx_preview_panel_references()
	
	# 将窗口添加到编辑器界面
	get_editor_interface().get_base_control().add_child(vfx_preview_window)
	
	# 显示窗口并居中
	vfx_preview_window.visible = true
	_center_vfx_preview_window()

	# 调用预览面板的 show_preview 方法
	if vfx_preview_panel_instance != null and vfx_preview_panel_instance.has_method("show_vfx_preview"):
		vfx_preview_panel_instance.show_vfx_preview()
	
	#print("弹出 VFX 预览面板，共 %d 张纹理" % cached_textures.size())

# 关闭现有的 VFX 预览面板窗口
func _close_existing_vfx_preview_panel():
	if vfx_preview_window != null and is_instance_valid(vfx_preview_window):
		#print("关闭现有的 VFX 预览面板窗口")
		
		# 移除面板实例
		if vfx_preview_panel_instance != null and is_instance_valid(vfx_preview_panel_instance):
			vfx_preview_window.remove_child(vfx_preview_panel_instance)
			vfx_preview_panel_instance.queue_free()
			vfx_preview_panel_instance = null
		
		# 关闭窗口
		vfx_preview_window.queue_free()
		vfx_preview_window = null
		
		#print("VFX 预览面板窗口已关闭并清理")
	elif vfx_preview_panel_instance != null and is_instance_valid(vfx_preview_panel_instance):
		# 如果窗口不存在但面板实例存在，也清理面板实例
		#print("清理孤立的 VFX 预览面板实例")
		vfx_preview_panel_instance.queue_free()
		vfx_preview_panel_instance = null

# 设置 VFX 预览面板的引用
func _setup_vfx_preview_panel_references():
	if vfx_preview_panel_instance == null:
		return
	
	# 调用预览面板的 set_external_references 方法
	if vfx_preview_panel_instance.has_method("set_external_references"):
		# 传递必要的引用
		vfx_preview_panel_instance.set_external_references(texture_rect, self, null)
		#print("已设置 VFX 预览面板的外部引用")
	
	# 传递缓存的纹理数组
	if vfx_preview_panel_instance.has_method("set_cached_textures"):
		vfx_preview_panel_instance.set_cached_textures(cached_textures)
		#print("已传递 %d 张缓存纹理给 VFX 预览面板" % cached_textures.size())

# VFX 预览窗口关闭事件
func _on_vfx_preview_window_close_requested():
	# 清理纹理缓存
	cached_textures.clear()
	
	if vfx_preview_window != null and vfx_preview_panel_instance != null:
		vfx_preview_window.remove_child(vfx_preview_panel_instance)
		vfx_preview_panel_instance.queue_free()
		vfx_preview_panel_instance = null
	
	if vfx_preview_window != null:
		vfx_preview_window.visible = false

# 居中 VFX 预览窗口
func _center_vfx_preview_window():
	if vfx_preview_window == null:
		return
	
	var viewport_size: Vector2 = get_editor_interface().get_base_control().get_viewport().get_visible_rect().size
	var window_size: Vector2 = vfx_preview_window.size
	
	var x: float = (viewport_size.x - window_size.x) / 2
	var y: float = (viewport_size.y - window_size.y) / 2
	
	vfx_preview_window.position = Vector2i(int(x), int(y))

# LoadingButton 点击事件
func _on_loading_button_pressed():
	# 创建文件对话框
	var file_dialog = FileDialog.new()
	file_dialog.title = "选择相机配置文件"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.json ; JSON 文件"]
	file_dialog.current_dir = "."
	
	# 连接信号
	file_dialog.file_selected.connect(_on_camera_config_file_selected)
	file_dialog.canceled.connect(_on_camera_config_dialog_canceled.bind(file_dialog))
	file_dialog.close_requested.connect(_on_camera_config_dialog_canceled.bind(file_dialog))
	
	# 添加到编辑器界面
	get_editor_interface().get_base_control().add_child(file_dialog)
	
	# 显示对话框
	file_dialog.popup_centered(Vector2i(800, 600))
	#print("打开相机配置文件选择对话框")

# 相机配置文件选择事件
func _on_camera_config_file_selected(path: String):
	#print("选择的相机配置文件: " + path)
	
	# 读取文件
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		printerr("无法打开文件: " + path + ", 错误: " + str(error))
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		printerr("文件损坏或者格式不对: " + json.get_error_message())
		return
	
	var camera_config = json.get_data()
	
	# 验证数据结构
	if not camera_config.has("version") or not camera_config.has("camera") or not camera_config.has("export_size"):
		printerr("配置文件格式不正确")
		return
	
	# 保存加载的宽度和高度到变量中
	if camera_config["export_size"].has("width"):
		loaded_export_width = float(camera_config["export_size"]["width"])
	if camera_config["export_size"].has("height"):
		loaded_export_height = float(camera_config["export_size"]["height"])
	
	#print("已保存加载的尺寸: " + str(loaded_export_width) + "x" + str(loaded_export_height))
	
	# 应用相机配置
	_apply_camera_config(camera_config)
	
	# 更新预览面板的宽度和高度
	_update_preview_panel_size(camera_config["export_size"])

# 应用相机配置
func _apply_camera_config(config: Dictionary):
	if selected_camera_node == null or not is_instance_valid(selected_camera_node):
		#print("没有选中的相机，请先选择一个相机节点")
		# 尝试自动获取当前选中的相机
		_on_get_camera_button_pressed()
		if selected_camera_node == null:
			printerr("无法应用相机配置：没有选中的相机")
			return
	
	var camera_data = config["camera"]
	
	# 应用位置
	if camera_data.has("position"):
		var pos = camera_data["position"]
		selected_camera_node.global_position = Vector3(pos["x"], pos["y"], pos["z"])
	
	# 应用旋转
	if camera_data.has("rotation"):
		var rot = camera_data["rotation"]
		var quat = Quaternion(rot["x"], rot["y"], rot["z"], rot["w"])
		selected_camera_node.global_transform.basis = Basis(quat)
	
	# 应用相机属性
	if camera_data.has("fov"):
		selected_camera_node.fov = camera_data["fov"]
	
	if camera_data.has("near"):
		selected_camera_node.near = camera_data["near"]
	
	if camera_data.has("far"):
		selected_camera_node.far = camera_data["far"]
	
	if camera_data.has("scale"):
		var scale_data = camera_data["scale"]
		selected_camera_node.scale = Vector3(scale_data["x"], scale_data["y"], scale_data["z"])
	
	#print("已应用相机配置到: " + selected_camera_node.name)

# 更新预览面板尺寸
func _update_preview_panel_size(export_size: Dictionary):
	# 检查预览面板是否已创建
	if preview_panel_instance == null or not is_instance_valid(preview_panel_instance):
		#print("预览面板未创建，无法更新尺寸")
		return
	
	# 获取宽度和高度
	var width = export_size.get("width", 100)
	var height = export_size.get("height", 100)
	
	# 更新预览面板的宽度和高度输入框
	if preview_panel_instance.has_method("set_export_size"):
		preview_panel_instance.set_export_size(width, height)
		#print("已更新预览面板尺寸: " + str(width) + "x" + str(height))
	else:
		# 尝试直接设置输入框文本
		var width_input = preview_panel_instance.find_child("WidthInput", true, false)
		var height_input = preview_panel_instance.find_child("HeightInput", true, false)
		
		if width_input is LineEdit:
			width_input.text = str(width)
		
		if height_input is LineEdit:
			height_input.text = str(height)
		
		#print("已设置宽度和高度输入框: " + str(width) + "x" + str(height))

# 相机配置对话框取消事件
func _on_camera_config_dialog_canceled(dialog: FileDialog):
	if dialog != null and is_instance_valid(dialog):
		dialog.queue_free()
	#print("取消选择相机配置文件")

# ============================================
# 文件对话框初始化
# ============================================

# 初始化文件对话框
func _initialize_file_dialog() -> void:
	if file_dialog != null:
		return
	
	file_dialog = FileDialog.new()
	file_dialog.title = "选择3D模型文件"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.fbx;FBX文件", "*.gltf;GLTF文件", "*.glb;GLB文件", "*.obj;OBJ文件"]
	file_dialog.size = Vector2i(800, 600)
	
	# 连接文件选择事件
	file_dialog.file_selected.connect(_on_model_file_selected)
	file_dialog.canceled.connect(_on_model_file_dialog_canceled)
	file_dialog.close_requested.connect(_on_model_file_dialog_canceled)
	
	# 将对话框添加到编辑器界面
	get_editor_interface().get_base_control().add_child(file_dialog)
	#print("文件对话框初始化完成")

# 模型文件选择事件
func _on_model_file_selected(path: String) -> void:
	#print("选择的模型文件: " + path)
	
	# 检查是否选择了 ModelContainer 节点
	if selected_model_container_node == null:
		print("错误：请先选择一个 ModelContainer 节点")
		return
	
	# 检查节点是否仍然有效
	if not is_instance_valid(selected_model_container_node):
		print("错误：选择的 ModelContainer 节点已无效")
		if model_container_label:
			model_container_label.text = "节点已无效"
		selected_model_container_node = null
		return
	
	# 确保ModelContainer在当前编辑的场景中
	var edited_root = get_editor_interface().get_edited_scene_root()
	if edited_root == null:
		print("错误：没有当前编辑的场景")
		if model_container_label:
			model_container_label.text = "无编辑场景"
		return
	
	if selected_model_container_node.get_tree().edited_scene_root != edited_root:
		print("错误：选中的ModelContainer不在当前编辑的场景中")
		if model_container_label:
			model_container_label.text = "节点不在当前场景"
		return
	
	# 更新UI标签
	if model_container_label:
		model_container_label.text = "正在加载模型..."
	
	# 处理模型文件
	_process_model_file(path)

# 模型文件对话框取消事件
func _on_model_file_dialog_canceled() -> void:
	if file_dialog != null and is_instance_valid(file_dialog):
		file_dialog.hide()
	#print("取消选择模型文件")

# 处理模型文件
func _process_model_file(file_path: String) -> void:
	# 检查模型是否已导入
	var is_imported: bool = _check_if_model_is_imported(file_path)
	
	if is_imported:
		# 已导入：直接加载
		#print("模型已导入，直接加载")
		_load_model_directly(file_path)
	else:
		# 未导入：执行完整导入流程
		#print("模型未导入，执行导入流程")
		_import_model_file(file_path)

# 检查模型是否已导入（检查 .import 文件）
func _check_if_model_is_imported(file_path: String) -> bool:
	# 获取绝对路径
	var absolute_path: String = ProjectSettings.globalize_path(file_path)
	
	# 获取文件名
	var file_name: String = absolute_path.get_file()
	
	# 检查1：文件所在目录是否有 .import 文件
	var directory: String = absolute_path.get_base_dir()
	var import_file_in_dir: String = directory.path_join(file_name + ".import")
	
	if FileAccess.file_exists(import_file_in_dir):
		return true
	
	# 检查2：项目根目录是否有 .import 文件
	var project_dir: String = OS.get_executable_path().get_base_dir()
	var import_file_in_project: String = project_dir.path_join(file_name + ".import")
	
	if FileAccess.file_exists(import_file_in_project):
		return true
	
	return false

# 直接加载已导入的模型
func _load_model_directly(file_path: String) -> void:
	# 获取绝对路径
	var absolute_path: String = ProjectSettings.globalize_path(file_path)
	
	# 调用延迟加载方法，直接传递绝对路径
	call_deferred("_deferred_load_model", absolute_path)

# 导入模型文件
func _import_model_file(source_path: String) -> void:
	# 获取文件名和扩展名
	var file_name: String = source_path.get_file()
	var file_name_without_ext: String = file_name.get_basename()
	var file_extension: String = file_name.get_extension()
	
	# 使用项目根目录的实际路径
	var project_dir: String = ProjectSettings.globalize_path("res://").get_base_dir()
	
	# 创建以文件名命名的文件夹
	var folder_path: String = project_dir.path_join(file_name_without_ext)
	var target_path: String = folder_path.path_join(file_name)
	
	# 检查文件是否存在
	if not FileAccess.file_exists(source_path):
		#print("错误：文件不存在: " + source_path)
		return
	
	# 创建文件夹
	var dir := DirAccess.open(project_dir)
	if dir == null:
		print("错误：无法打开项目目录")
		return
	
	if not dir.dir_exists(folder_path):
		var error := dir.make_dir_recursive(folder_path)
		if error != OK:
			print("错误：无法创建文件夹: " + folder_path)
			return
	
	# 复制文件到目标文件夹
	var error := DirAccess.copy_absolute(source_path, target_path)
	if error != OK:
		print("错误：无法复制文件到: " + target_path)
		return
	
	#print("已复制文件到: " + target_path)
	
	# 等待一帧让Godot检测到新文件
	# 使用绝对路径传递给_deferred_load_model
	call_deferred("_deferred_load_model", target_path)

# 延迟加载模型
func _deferred_load_model(model_path: String) -> void:
	#print("开始延迟加载模型: " + model_path)
	
	# 等待FBX导入完成
	var import_success: bool = await _wait_for_fbx_import(model_path)
	if not import_success:
		printerr("FBX导入失败或超时: " + model_path)
		if model_container_label:
			model_container_label.text = "导入失败"
		return
	
	# 使用ResourceLoader加载模型 - 使用绝对路径
	var model_resource = ResourceLoader.load(model_path)
	
	if model_resource == null:
		printerr("无法加载模型资源: " + model_path)
		if model_container_label:
			model_container_label.text = "加载失败"
		return
	
	#print("成功加载模型资源")
	
	# 根据资源类型处理模型
	if model_resource is PackedScene:
		# 如果是场景文件，创建继承场景并加载到ModelContainer
		_create_inherited_scene_and_load(model_resource, model_path)
	else:
		printerr("不支持的资源类型: " + model_resource.get_class())
		if model_container_label:
			model_container_label.text = "不支持的格式"

# 等待FBX导入完成
func _wait_for_fbx_import(model_path: String) -> bool:
	#print("等待FBX导入完成: " + model_path)
	
	# 获取导入文件路径（model_path现在是绝对路径）
	var import_file_path: String = model_path + ".import"
	
	var max_retries: int = 30  # 最大重试次数（30秒）
	var retry_count: int = 0
	
	while retry_count < max_retries:
		# 检查导入文件是否存在
		if FileAccess.file_exists(import_file_path):
			#print("找到导入文件，尝试加载资源验证...")
			
			# 尝试加载资源来验证导入是否完成（使用绝对路径）
			var test_resource = ResourceLoader.load(model_path)
			if test_resource != null:
				#print("FBX导入成功完成")
				return true
		
		# 等待1秒
		await get_tree().create_timer(1.0).timeout
		retry_count += 1
		#print("等待导入... (" + str(retry_count) + "/" + str(max_retries) + ")")
	
	printerr("FBX导入超时: " + model_path)
	return false

# 创建继承场景并加载到ModelContainer
func _create_inherited_scene_and_load(original_scene: PackedScene, model_path: String) -> void:
	#print("创建继承场景并加载")
	
	# 实例化原始场景
	var scene_instance = original_scene.instantiate()
	if scene_instance == null:
		printerr("场景实例化失败")
		if model_container_label:
			model_container_label.text = "实例化失败"
		return
	
	# 获取当前编辑的场景根节点
	var edited_scene_root = get_editor_interface().get_edited_scene_root()
	if edited_scene_root == null:
		printerr("无法获取当前编辑的场景")
		if model_container_label:
			model_container_label.text = "无编辑场景"
		return
	
	# 确保ModelContainer在当前编辑的场景中
	if selected_model_container_node.get_tree().edited_scene_root != edited_scene_root:
		printerr("ModelContainer不在当前编辑的场景中")
		if model_container_label:
			model_container_label.text = "节点不在当前场景"
		return
	
	# 将实例添加到ModelContainer
	selected_model_container_node.add_child(scene_instance)
	
	# 关键：设置owner为当前编辑场景的根节点，这样实例才能在编辑器中显示和保存
	scene_instance.owner = edited_scene_root
	
	# 递归设置所有子节点的owner
	_set_owner_recursive(scene_instance, edited_scene_root)
	
	# 重置变换到局部原点（相对于ModelContainer）
	scene_instance.transform = Transform3D.IDENTITY
	
	# 确保模型可见
	scene_instance.visible = true
	
	# 更新节点的名称（避免重名）
	scene_instance.name = _get_unique_name(selected_model_container_node, model_path.get_file().get_basename())
	
	#print("成功在编辑器中实例化模型到: " + selected_model_container_node.name + "/" + scene_instance.name)
	
	# 更新UI标签
	if model_container_label:
		model_container_label.text = "已加载: " + scene_instance.name
	
	# 刷新编辑器视图
	_update_editor_view()
	
	# 更新组件引用
	_update_component_references(scene_instance)

# 清理当前场景
# func _clear_current_scene() -> void:
# 	if selected_model_container_node == null or not is_instance_valid(selected_model_container_node):
# 		return
	
# 	# 清理ModelContainer中的所有子节点
# 	var children_to_remove: Array[Node] = []
	
# 	for child in selected_model_container_node.get_children():
# 		children_to_remove.append(child)
	
# 	# 删除所有子节点
# 	for child in children_to_remove:
# 		child.queue_free()
	
# 	print("已清理当前场景")

# 更新组件引用
func _update_component_references(scene_instance: Node) -> void:
	if scene_instance == null:
		return
	
	#print("更新组件引用")
	
	# 这里可以添加更新其他组件引用的逻辑
	# 例如：查找AnimationPlayer、MeshInstance3D等
	
	# 示例：查找所有MeshInstance3D
	var mesh_instances: Array[MeshInstance3D] = _find_all_mesh_instances(scene_instance)
	#print("找到 " + str(mesh_instances.size()) + " 个MeshInstance3D")

# 在节点树中查找所有MeshInstance3D
func _find_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var mesh_instances: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		mesh_instances.append_array(_find_all_mesh_instances(child))
	
	return mesh_instances

# ============================================
# 编辑器场景操作辅助函数
# ============================================

# 递归设置节点的owner
func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_set_owner_recursive(child, owner_node)

# 获取唯一的节点名称
func _get_unique_name(parent: Node, base_name: String) -> String:
	var unique_name = base_name
	var counter = 1
	
	while parent.has_node(unique_name):
		unique_name = base_name + "_" + str(counter)
		counter += 1
	
	return unique_name

# 刷新编辑器视图
func _update_editor_view() -> void:
	# 获取编辑器界面
	var editor_interface = get_editor_interface()
	
	# 方法1：清除并重新选中ModelContainer来刷新视图
	var selection = editor_interface.get_selection()
	selection.clear()
	selection.add_node(selected_model_container_node)
	
	# 方法2：触发场景树更新
	if editor_interface.get_edited_scene_root():
		# 稍微延迟一下确保节点已经添加
		await get_tree().process_frame
		
		# 选中新添加的模型，让用户看到
		if selected_model_container_node.get_child_count() > 0:
			var last_child = selected_model_container_node.get_child(selected_model_container_node.get_child_count() - 1)
			selection.clear()
			selection.add_node(last_child)
			#print("已选中新添加的模型: " + last_child.name)

# ============================================
# 修改上传模型按钮点击事件
# ============================================

# 上传模型按钮点击事件
func _on_upload_model_button_pressed() -> void:
	# 检查是否选择了 ModelContainer 节点
	if selected_model_container_node == null:
		#print("请先选择一个 ModelContainer 节点（点击'获取选中 ModelContainer'按钮）")
		return
	
	# 检查节点是否仍然有效
	if not is_instance_valid(selected_model_container_node):
		#print("选择的 ModelContainer 节点已无效")
		if model_container_label:
			model_container_label.text = "节点已无效"
		selected_model_container_node = null
		return
	
	# 确保ModelContainer在当前编辑的场景中
	var edited_root = get_editor_interface().get_edited_scene_root()
	if edited_root == null:
		print("错误：没有当前编辑的场景")
		if model_container_label:
			model_container_label.text = "无编辑场景"
		return
	
	if selected_model_container_node.get_tree().edited_scene_root != edited_root:
		print("错误：选中的ModelContainer不在当前编辑的场景中")
		if model_container_label:
			model_container_label.text = "节点不在当前场景"
		return
	
	# 检查文件对话框是否已初始化
	if file_dialog == null:
		print("错误：文件对话框未初始化")
		return
	
	# 显示文件对话框
	file_dialog.popup_centered(Vector2i(800, 600))
	#print("选择要加载到 " + selected_model_container_node.name + " 的模型文件")


# ============================================
# 动画循环状态同步功能
# ============================================

# 同步所有AnimationPlayer条目的循环状态
func sync_animation_loop_states():
	for entry in animation_player_entries:
		if not is_instance_valid(entry.animation_player):
			continue
		
		# 获取当前选中的动画
		if entry.option_button and is_instance_valid(entry.option_button):
			var selected_index = entry.option_button.get_selected()
			if selected_index >= 0:
				var animation_name = entry.option_button.get_item_text(selected_index)
				var animation = entry.animation_player.get_animation(animation_name)
				if animation:
					# 检查动画的实际循环模式
					var is_animation_looping = (animation.loop_mode == Animation.LOOP_LINEAR)
					
					# 与UI状态比较
					if entry.is_looping != is_animation_looping:
						# 更新条目状态
						entry.is_looping = is_animation_looping
						
						# 更新UI按钮
						if entry.loop_checkbutton and is_instance_valid(entry.loop_checkbutton):
							entry.loop_checkbutton.button_pressed = is_animation_looping
						
						# print("同步循环状态: " + entry.animation_player.name + " - " + 
						# 	  animation_name + " -> " + ("循环" if is_animation_looping else "不循环"))

# 插件面板鼠标点击事件处理
func _on_plugin_panel_gui_input(event: InputEvent):
	# 检测鼠标点击事件
	if event is InputEventMouseButton and event.pressed:
		# 同步循环状态
		sync_animation_loop_states()
