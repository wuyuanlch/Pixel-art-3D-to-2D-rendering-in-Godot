@tool
extends Control
class_name preview_panel

# 外部节点引用
var sprite2D2: TextureRect
var three_to_two_ref: threeToTwo  # 改为引用threeToTwo实例
var normalMesh: MeshInstance3D

# 所有MeshInstance3D的列表
var allMeshes: Array[MeshInstance3D] = []

# 存储每个MeshInstance3D的原始材质（用于关闭窗口时恢复）
var original_materials: Dictionary = {}  # key: MeshInstance3D, value: Material

# ModelContainer引用（用于动态查找手动放置的模型）
var modelContainer: Node3D

# 预览相关变量
@export var previewTexture: TextureRect
@export var closePreviewButton: Button
@export var zoomInButton: Button
@export var zoomOutButton: Button
@export var resetZoomButton: Button
@export var zoomLabel: LineEdit
var currentZoom: float = 1.0
var previewOffset: Vector2 = Vector2.ZERO
var isDragging: bool = false
var dragStartPosition: Vector2

# 尺寸控制相关变量
@export var widthInput: LineEdit
@export var heightInput: LineEdit
var currentSize: Vector2 = Vector2(100, 100)

# 材质控制相关变量
@export var materialSelector: OptionButton
@export var previewExportButton: Button
@export var putongExportButton: Button  # 导出普通贴图按钮
@export var normalExportButton: Button
@export var exportBothButton: Button
var normalMaterial: ShaderMaterial
var originalMaterial: Material
var isNormalMode: bool = false

# 动画控制相关变量
@export var frameSlider: HSlider
@export var frameInfoLabel: Label
@export var playPauseButton: Button
@export var prevFrameButton: Button
@export var nextFrameButton: Button
var currentTime: float = 0.0
var animationLength: float = 0.0
var isPlaying: bool = false

# 批量导出相关变量
@export var frameIntervalInput: LineEdit
@export var batchExportButton: Button

# 插值算法控制相关变量
@export var interpolationSelector: OptionButton
var currentInterpolation: Image.Interpolation = Image.INTERPOLATE_NEAREST
var isNearestSharpMode: bool = false
var sharpThreshold: float = 0.99  # 透明度阈值，小于此值的像素将被设为完全透明

# 导出计数器
static var exportCounter: int = 1

# 导出类型枚举
enum ExportType { Normal, NormalMap, Both }

# 文件对话框相关变量
@export var saveFileDialog: FileDialog
var currentExportType: ExportType
var pendingSavePath: String
var pendingNormalSavePath: String

# 批量导出目录选择相关变量
@export var selectDirDialog: FileDialog
var pendingBatchExportDir: String
var pendingAnimationDir: String
var pendingFileNamePrefix: String
var isDirectoryOverwriteDialog: bool = false

# UI标签引用
@export var widthLabel: Label
@export var heightLabel: Label
@export var interpolationLabel: Label
@export var materialLabel: Label
@export var animationLabel: Label

var isWindowFocused: bool = true

func set_window_focus_state(focused: bool):
	isWindowFocused = focused

# Called when the node enters the scene tree for the first time.
func _ready():
	visible=false
	# 连接按钮信号
	closePreviewButton.pressed.connect(_on_close_preview_pressed)
	zoomInButton.pressed.connect(_on_zoom_in_pressed)
	zoomOutButton.pressed.connect(_on_zoom_out_pressed)
	resetZoomButton.pressed.connect(_on_reset_zoom_pressed)
	previewExportButton.pressed.connect(_on_export_button_pressed)
	putongExportButton.pressed.connect(_on_putong_export_pressed)  # 连接导出普通贴图按钮
	exportBothButton.pressed.connect(_on_export_both_pressed)  # 连接导出两种材质按钮
	
	# 连接zoomLabel输入框信号
	if zoomLabel != null:
		zoomLabel.text_submitted.connect(_on_zoom_label_submitted)
		zoomLabel.focus_exited.connect(_on_zoom_label_focus_exited)
	
	# 连接尺寸输入框信号
	if widthInput != null:
		widthInput.text_submitted.connect(_on_size_input_submitted)
		widthInput.focus_exited.connect(_on_size_input_focus_exited)
	if heightInput != null:
		heightInput.text_submitted.connect(_on_size_input_submitted)
		heightInput.focus_exited.connect(_on_size_input_focus_exited)
	
	# 连接批量导出间隔输入框信号
	if frameIntervalInput != null:
		frameIntervalInput.text_submitted.connect(_on_frame_interval_input_submitted)
		frameIntervalInput.focus_exited.connect(_on_frame_interval_input_focus_exited)
	
	# 材质控制信号
	materialSelector.item_selected.connect(_on_material_selected)
	normalExportButton.pressed.connect(_on_normal_export_pressed)
	
	# 动画控制信号（已移除，动画选择在threeToTwo中完成）
	
	# 连接动画控制按钮信号
	playPauseButton.pressed.connect(_on_play_pause_button_pressed)
	prevFrameButton.pressed.connect(_on_prev_frame_button_pressed)
	nextFrameButton.pressed.connect(_on_next_frame_button_pressed)
	frameSlider.value_changed.connect(_on_frame_slider_changed)
	
	# 连接批量导出按钮信号
	if batchExportButton != null:
		batchExportButton.pressed.connect(_on_batch_export_pressed)
	
	# 连接插值算法选择器信号
	if interpolationSelector != null:
		interpolationSelector.item_selected.connect(_on_interpolation_selected)
		# 初始化插值算法选择器选项
		_initialize_interpolation_selector()
	
	# 初始化法线材质
	_initialize_normal_material()
	
	# 初始化文件对话框
	_initialize_file_dialogs()
	
	# 设置初始状态
	visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if isPlaying and three_to_two_ref != null:
		# 获取所有选中的AnimationPlayer
		var selected_players = three_to_two_ref.get_selected_animation_players()
		if selected_players.size() == 0:
			return
		
		# 使用全局时间管理，而不是依赖某个特定动画的时间
		# 增加当前时间（基于delta）
		currentTime += delta
		
		# 获取所有选中动画的最大长度
		var max_anim_length = _get_max_animation_length()
		if max_anim_length > 0:
			# 检查当前动画是否循环
			var is_looping = _is_selected_animation_looping()
			
			# 如果当前时间超过最大动画长度
			if currentTime >= max_anim_length:
				if is_looping:
					# 循环播放：重置时间到0
					currentTime = 0
					# 重置所有动画到开始位置
					for player in selected_players:
						if is_instance_valid(player):
							player.seek(0)
							# 如果动画之前被暂停了，重新播放
							if not player.is_playing():
								var current_anim = player.current_animation
								if current_anim != "":
									player.play(current_anim)
				else:
					# 非循环播放：停止播放
					currentTime = max_anim_length
					isPlaying = false
					playPauseButton.text = "▶"
					# 暂停所有动画，而不是停止
					for player in selected_players:
						if is_instance_valid(player):
							player.pause()
							# 确保动画停留在最后一帧
							var current_anim = player.current_animation
							if current_anim != "":
								var anim = player.get_animation(current_anim)
								if anim:
									# 定位到动画结束位置
									player.seek(anim.length)
		
		# 更新滑块位置
		frameSlider.value = currentTime
		
		# 更新帧信息标签
		_update_frame_info_label()
		
		# 同步所有选中的AnimationPlayer到当前时间
		for player in selected_players:
			if is_instance_valid(player):
				var current_anim = player.current_animation
				if current_anim != "":
					var anim = player.get_animation(current_anim)
					if anim:
						var anim_length = anim.length
						# 计算该动画在当前全局时间下的位置
						# 非循环播放时，如果时间超过动画长度，说明动画已经播放完成
						var is_looping = _is_selected_animation_looping()
						var player_time = fmod(currentTime, anim_length) if is_looping else min(currentTime, anim_length)
						
						# 确保动画在播放状态（只有当时间小于动画长度时才播放）
						if not player.is_playing() and player_time < anim_length:
							player.play(current_anim)
						
						# 精确定位到正确的时间位置
						player.seek(player_time)
		
		# 更新预览
		_update_preview_from_animation()

# 设置外部节点引用
func set_external_references(sprite2d: TextureRect, three_to_two_instance: threeToTwo, normal_mesh: MeshInstance3D):
	sprite2D2 = sprite2d
	three_to_two_ref = three_to_two_instance
	normalMesh = normal_mesh

# 设置导出尺寸（从threeToTwo调用）
func set_export_size(width: int, height: int):
	if widthInput != null:
		widthInput.text = str(width)
	
	if heightInput != null:
		heightInput.text = str(height)
	
	# 更新当前尺寸
	currentSize = Vector2(width, height)
	
	#print("预览面板尺寸已设置为: " + str(width) + "x" + str(height))

# 辅助方法：控制所有选中的AnimationPlayer
func _control_all_selected_animation_players(action: String, time: float = 0.0) -> void:
	if three_to_two_ref == null:
		printerr("threeToTwo引用未设置")
		return
	
	three_to_two_ref.control_all_animation_players(action, time)

# 辅助方法：获取所有选中的AnimationPlayer
func _get_selected_animation_players() -> Array[AnimationPlayer]:
	if three_to_two_ref == null:
		printerr("threeToTwo引用未设置")
		return []
	
	return three_to_two_ref.get_selected_animation_players()

# 辅助方法：获取最大动画长度
func _get_max_animation_length() -> float:
	if three_to_two_ref == null:
		printerr("threeToTwo引用未设置")
		return 0.0
	
	return three_to_two_ref.get_max_selected_animation_length()

# 辅助方法：获取第一个选中的AnimationPlayer（用于时间参考）
func _get_first_selected_animation_player() -> AnimationPlayer:
	var selected_players = _get_selected_animation_players()
	if selected_players.size() > 0:
		return selected_players[0]
	return null

# 检查选中的AnimationPlayer是否设置为循环播放
func _is_selected_animation_looping() -> bool:
	var selected_players = _get_selected_animation_players()
	if selected_players.size() == 0:
		return false  # 默认不循环
	
	# 检查第一个选中的AnimationPlayer
	var first_player = selected_players[0]
	var current_anim = first_player.current_animation
	if current_anim == "":
		return false  # 默认不循环
	
	var anim = first_player.get_animation(current_anim)
	if anim == null:
		return false  # 默认不循环
	
	# 检查动画的loop_mode
	# Animation.LOOP_NONE = 0, LOOP_LINEAR = 1, LOOP_PINGPONG = 2
	return anim.loop_mode != Animation.LOOP_NONE

# 更新动画长度（使用所有选中动画的最大时长）
func _update_animation_length():
	if three_to_two_ref == null:
		printerr("threeToTwo引用未设置")
		return
	
	# 获取所有选中动画的最大长度
	animationLength = three_to_two_ref.get_max_selected_animation_length()
	
	# 更新滑块范围
	if frameSlider != null:
		frameSlider.max_value = animationLength
		frameSlider.value = currentTime
	
	# 更新帧信息标签
	_update_frame_info_label()
	
	# 如果当前时间超过新的动画长度，重置为0
	if currentTime > animationLength:
		currentTime = 0
		if frameSlider != null:
			frameSlider.value = 0

# 显示预览
func show_preview():
	# 检查是否有加载的宽度和高度，如果有则使用保存的值
	if three_to_two_ref != null:
		# 检查是否有保存的宽度和高度（大于0表示有保存的值）
		if three_to_two_ref.loaded_export_width > 0 and three_to_two_ref.loaded_export_height > 0:
			# 使用保存的宽度和高度
			currentSize = Vector2(three_to_two_ref.loaded_export_width, three_to_two_ref.loaded_export_height)
			
			# 更新输入框显示
			if widthInput != null:
				widthInput.text = str(three_to_two_ref.loaded_export_width)
			if heightInput != null:
				heightInput.text = str(three_to_two_ref.loaded_export_height)
			
			#print("使用加载的尺寸: " + str(three_to_two_ref.loaded_export_width) + "x" + str(three_to_two_ref.loaded_export_height))
		# else:
		# 	print("没有加载的尺寸，使用默认尺寸: " + str(currentSize.x) + "x" + str(currentSize.y))
	
	# 强制刷新Viewport
	if sprite2D2 != null:
		# 获取Sprite2D2的纹理，而不是整个视口
		if sprite2D2.texture != null:
			# 将纹理转换为Image并缩放到当前尺寸
			var originalImage: Image = sprite2D2.texture.get_image()
			# 使用新的处理函数，包含插值和Sharp滤镜
			var resizedImage: Image = _process_image_with_interpolation(originalImage, int(currentSize.x), int(currentSize.y))
			
			# 创建新的纹理
			var resizedTexture: ImageTexture = ImageTexture.create_from_image(resizedImage)
			previewTexture.texture = resizedTexture
		else:
			printerr("Sprite2D2纹理为空，无法预览")

			if sprite2D2.texture != null:
				var originalImage: Image = sprite2D2.texture.get_image()
				# 使用新的处理函数，包含插值和Sharp滤镜
				var resizedImage: Image = _process_image_with_interpolation(originalImage, int(currentSize.x), int(currentSize.y))
				var resizedTexture: ImageTexture = ImageTexture.create_from_image(resizedImage)
				previewTexture.texture = resizedTexture
			else:
				printerr("重试失败：Sprite2D2纹理仍然为空")
				return
	else:
		printerr("Sprite2D2节点为空")
		return
	
	# 重置缩放和位置
	currentZoom = 1.0
	previewOffset = Vector2.ZERO
	_update_preview_transform()
	
	# 更新动画长度（使用所有选中动画的最大时长）
	_update_animation_length()
	
	# 显示预览面板
	visible = true

# 更新预览变换
func _update_preview_transform():
	previewTexture.scale = Vector2(currentZoom, currentZoom)
	
	# 动态获取当前窗口大小，以窗口中心点为中心进行缩放
	var window_size: Vector2
	var viewport = get_viewport()
	if viewport != null:
		window_size = viewport.get_visible_rect().size
	else:
		# 使用默认窗口大小 1152x648
		window_size = Vector2(1152, 648)
	
	var center: Vector2 = window_size / 2
	
	# 计算缩放后的尺寸
	var scaled_size = previewTexture.size * currentZoom
	# 计算位置（居中显示）
	previewTexture.position = center + previewOffset-(scaled_size / 2)
	
	zoomLabel.text = "%d%%" % int(currentZoom * 100)

# 缩放控制方法
func _on_zoom_in_pressed():
	_set_zoom(currentZoom * 1.2)

func _on_zoom_out_pressed():
	_set_zoom(currentZoom / 1.2)

func _on_reset_zoom_pressed():
	currentZoom = 1.0
	previewOffset = Vector2.ZERO
	_update_preview_transform()

func _set_zoom(zoom: float):
	currentZoom = clampf(zoom, 0.1, 15.0)
	_update_preview_transform()

# 解析缩放输入文本
func _parse_zoom_input(inputText: String) -> float:
	if inputText.is_empty():
		return 1.0  # 默认100%
	
	# 移除空格
	inputText = inputText.strip_edges()
	
	# 移除百分号
	if inputText.ends_with("%"):
		inputText = inputText.substr(0, inputText.length() - 1)
	
	# 尝试解析为浮点数
	var value: float = float(inputText)
	if not is_nan(value):
		# 如果输入的是百分比（如150），转换为小数（1.5）
		if value >= 10.0 and value <= 1500.0:
			# 可能是百分比，转换为小数
			return value / 100.0
		elif value >= 0.1 and value <= 15.0:
			# 可能是小数形式的缩放系数
			return value
		else:
			# 超出范围，返回当前缩放值
			printerr("缩放值超出范围: %f，请输入10%%-1500%%或0.1-15.0" % value)
			return currentZoom
	else:
		printerr("无法解析缩放输入: %s" % inputText)
		return currentZoom

# zoomLabel输入框回车键提交事件
func _on_zoom_label_submitted(newText: String):
	_apply_zoom_from_input()

# zoomLabel输入框焦点丢失事件
func _on_zoom_label_focus_exited():
	_apply_zoom_from_input()

# 从输入框应用缩放
func _apply_zoom_from_input():
	if zoomLabel == null:
		return
	
	var newZoom: float = _parse_zoom_input(zoomLabel.text)
	_set_zoom(newZoom)

# 关闭预览
func _on_close_preview_pressed():
	# 重置导出计数器，确保下次打开预览时从1开始
	exportCounter = 1
	
	# 如果当前是法线材质模式，恢复原始状态
	if isNormalMode:
		# 恢复所有MeshInstance3D的原始材质
		restore_original_materials()
		
		# 隐藏normalMesh
		if normalMesh != null:
			normalMesh.visible = false
		
		# 重置材质模式状态
		isNormalMode = false
	
	visible = false
	
	# 通知主界面预览已关闭，重新启用相机控制
	var parent = get_parent()
	if parent != null and parent.has_method("on_preview_closed"):
		parent.on_preview_closed()

# 鼠标输入处理（用于缩放、拖动和输入框焦点）
func _input(event):
	if not visible or not isWindowFocused:
		return
	
	# 检查鼠标是否在滑块区域内
	var isMouseOnSlider: bool = false
	if event is InputEventMouse:
		var mouseEvent: InputEventMouse = event
		var sliderRect: Rect2 = Rect2(frameSlider.position, frameSlider.size)
		isMouseOnSlider = sliderRect.has_point(mouseEvent.position)
	
	if event is InputEventMouseButton:
		var mouseButton: InputEventMouseButton = event
		if mouseButton.button_index == MOUSE_BUTTON_LEFT and mouseButton.pressed:
			# 检查点击是否在输入框内
			if not _is_click_inside_input_fields(mouseButton.position):
				# 释放所有输入框的焦点
				_release_all_input_focus()
		elif mouseButton.button_index == MOUSE_BUTTON_WHEEL_UP and mouseButton.pressed:
			_set_zoom(currentZoom * 1.1)
		elif mouseButton.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouseButton.pressed:
			_set_zoom(currentZoom / 1.1)
		elif mouseButton.button_index == MOUSE_BUTTON_MIDDLE:
			if mouseButton.pressed:
				# 如果鼠标在滑块上，不启动图片拖动
				if not isMouseOnSlider:
					isDragging = true
					dragStartPosition = mouseButton.position - previewOffset
			else:
				isDragging = false
	elif event is InputEventMouseMotion and isDragging:
		var mouseMotion: InputEventMouseMotion = event
		# 如果正在拖动图片，更新位置
		previewOffset = mouseMotion.position - dragStartPosition
		_update_preview_transform()

# 检查点击是否在输入框内
func _is_click_inside_input_fields(clickPosition: Vector2) -> bool:
	# 检查缩放输入框
	if zoomLabel != null and _is_point_in_control(zoomLabel, clickPosition):
		return true
	
	# 检查尺寸输入框
	if widthInput != null and _is_point_in_control(widthInput, clickPosition):
		return true
	if heightInput != null and _is_point_in_control(heightInput, clickPosition):
		return true
	
	# 检查批量导出间隔输入框
	if frameIntervalInput != null and _is_point_in_control(frameIntervalInput, clickPosition):
		return true
	
	return false

# 检查点是否在控件内
func _is_point_in_control(control: Control, point: Vector2) -> bool:
	# 获取控件的全局位置和大小
	var globalPos: Vector2 = control.global_position
	var size: Vector2 = control.size
	
	# 检查点是否在控件矩形内
	return point.x >= globalPos.x and point.x <= globalPos.x + size.x and \
		   point.y >= globalPos.y and point.y <= globalPos.y + size.y

# 释放所有输入框的焦点
func _release_all_input_focus():
	if zoomLabel != null and zoomLabel.has_focus():
		zoomLabel.release_focus()
	if widthInput != null and widthInput.has_focus():
		widthInput.release_focus()
	if heightInput != null and heightInput.has_focus():
		heightInput.release_focus()
	if frameIntervalInput != null and frameIntervalInput.has_focus():
		frameIntervalInput.release_focus()

# 尺寸输入框回车键提交事件
func _on_size_input_submitted(newText: String):
	_apply_size_from_input()

# 尺寸输入框焦点丢失事件
func _on_size_input_focus_exited():
	_apply_size_from_input()

# 从输入框应用尺寸
func _apply_size_from_input():
	if widthInput == null or heightInput == null:
		return
	
	var width: int = int(widthInput.text)
	var height: int = int(heightInput.text)
	if width > 0 and height > 0:
		currentSize = Vector2(width, height)
		_update_preview_size()
	else:
		printerr("尺寸必须大于0")

# 批量导出间隔输入框回车键提交事件
func _on_frame_interval_input_submitted(newText: String):
	# 不需要立即应用，只在批量导出时使用
	#print("批量导出间隔已设置为: %s秒" % newText)
	pass

# 批量导出间隔输入框焦点丢失事件
func _on_frame_interval_input_focus_exited():
	# 不需要立即应用，只在批量导出时使用
	if frameIntervalInput != null:
		#print("批量导出间隔已设置为: %s秒" % frameIntervalInput.text)
		pass

# 更新预览尺寸
func _update_preview_size():
	# 先重新应用当前纹理
	if sprite2D2 != null and sprite2D2.texture != null:
		var originalImage: Image = sprite2D2.texture.get_image()
		# 使用新的处理函数，包含插值和Sharp滤镜
		var resizedImage: Image = _process_image_with_interpolation(originalImage, int(currentSize.x), int(currentSize.y))
		var resizedTexture: ImageTexture = ImageTexture.create_from_image(resizedImage)
		previewTexture.texture = resizedTexture

	# 然后更新尺寸和位置
	previewTexture.size = currentSize
	
	# 动态获取当前窗口大小，以窗口中心点为中心进行缩放
	var window_size: Vector2
	var viewport = get_viewport()
	if viewport != null:
		window_size = viewport.get_visible_rect().size
	else:
		# 使用默认窗口大小 1152x648
		window_size = Vector2(1152, 648)
	
	var center: Vector2 = window_size / 2
	previewTexture.position = center

	# 重置位置偏移，确保缩放中心正确
	previewOffset = Vector2.ZERO

	_update_preview_transform()

# 导出渲染图片的方法（预览导出按钮）
func _on_export_button_pressed():
	if isPlaying:
		_on_play_pause_button_pressed()
	# 打开文件保存对话框，导出普通贴图
	_open_save_file_dialog(ExportType.Normal)

# 动画选择事件（已移除，动画选择在threeToTwo中完成）
func _on_animation_selected(index: int):
	# 这个方法现在只用于内部参考，不再用于处理动画选择
	# 动画选择完全在threeToTwo的AnimationPlayer管理器中完成
	pass

# 设置动画（已移除，动画选择在threeToTwo中完成）
func _setup_animation(animationName: String):
	# 这个方法现在只用于内部参考，不再用于设置动画
	# 动画选择完全在threeToTwo的AnimationPlayer管理器中完成
	pass

# 播放/暂停按钮点击事件
func _on_play_pause_button_pressed():
	if three_to_two_ref == null:
		printerr("threeToTwo引用未设置")
		return
	
	if isPlaying:
		# 暂停所有选中的AnimationPlayer
		_control_all_selected_animation_players("pause")
		isPlaying = false
		playPauseButton.text = "▶"
	else:
		if currentTime >= animationLength:
			# 如果已经播放完毕，从头开始播放
			currentTime = 0
		# 开始播放所有选中的AnimationPlayer
		_control_all_selected_animation_players("play", currentTime)
		isPlaying = true
		playPauseButton.text = "⏸"


# 帧滑块变化事件
func _on_frame_slider_changed(value: float):
	if three_to_two_ref == null:
		return
	
	# 更新当前时间
	currentTime = value
	
	# 保存原始播放状态
	var wasPlaying: bool = isPlaying
	
	# 使用正确的 Play(); Seek(); Pause(); 模式
	# 无论是否播放，都先播放动画
	_control_all_selected_animation_players("play", currentTime)
	
	# 如果原本没有播放，立即暂停
	if not wasPlaying:
		_control_all_selected_animation_players("pause")
	# 如果原本在播放，继续播放（从新位置继续）
	else:
		_control_all_selected_animation_players("play", currentTime)  # 确保精确定位
	
	# 更新帧信息标签
	_update_frame_info_label()
	
	# 更新预览
	_update_preview_from_animation()
	

# 更新帧信息标签
func _update_frame_info_label():
	if frameInfoLabel != null:
		frameInfoLabel.text = "%.2fs / %.2fs" % [currentTime, animationLength]

# 从动画更新预览
func _update_preview_from_animation():
	# 等待一帧确保渲染完成
	await wait_for_frame_render()
	
	# 强制更新预览纹理
	if sprite2D2 != null and sprite2D2.texture != null:
		# 获取当前ViewportTexture的Image
		var originalImage: Image = sprite2D2.texture.get_image()
		
		# 检查图像是否有效
		if originalImage != null and originalImage.get_width() > 0 and originalImage.get_height() > 0:
			# 使用新的处理函数，包含插值和Sharp滤镜
			var resizedImage: Image = _process_image_with_interpolation(originalImage, int(currentSize.x), int(currentSize.y))
			
			# 创建新的纹理
			var resizedTexture: ImageTexture = ImageTexture.create_from_image(resizedImage)
			previewTexture.texture = resizedTexture
			
			# 确保更新纹理后保持当前的位置和缩放
			_update_preview_transform()
			
		else:
			printerr("获取的图像无效")
	else:
		printerr("Sprite2D2纹理为空，无法更新预览")

# 加载动画列表（已移除，动画选择在threeToTwo中完成）
func _load_animation_list():
	# 这个方法现在只用于内部参考，不再用于加载动画列表
	# 动画选择完全在threeToTwo的AnimationPlayer管理器中完成
	pass

# 初始化插值算法选择器
func _initialize_interpolation_selector():
	if interpolationSelector == null:
		return
	
	# 清空现有选项
	interpolationSelector.clear()
	
	# 添加五个插值算法选项（包括 Nearest+Sharp）
	interpolationSelector.add_item("Nearest")
	interpolationSelector.add_item("Bilinear")
	interpolationSelector.add_item("Cubic")
	interpolationSelector.add_item("Lanczos")
	interpolationSelector.add_item("Nearest+Sharp")
	
	# 默认选择 Nearest
	interpolationSelector.select(0)
	currentInterpolation = Image.INTERPOLATE_NEAREST
	isNearestSharpMode = false
	

# 插值算法选择事件
func _on_interpolation_selected(index: int):
	if interpolationSelector == null:
		return
	
	var selectedAlgorithm: String = interpolationSelector.get_item_text(index)
	var newInterpolation: Image.Interpolation = Image.INTERPOLATE_NEAREST  # 默认值
	var newIsNearestSharpMode: bool = false
	
	# 根据选择的文本设置插值算法
	match selectedAlgorithm:
		"Nearest":
			newInterpolation = Image.INTERPOLATE_NEAREST
			newIsNearestSharpMode = false
		"Bilinear":
			newInterpolation = Image.INTERPOLATE_BILINEAR
			newIsNearestSharpMode = false
		"Cubic":
			newInterpolation = Image.INTERPOLATE_CUBIC
			newIsNearestSharpMode = false
		"Lanczos":
			newInterpolation = Image.INTERPOLATE_LANCZOS
			newIsNearestSharpMode = false
		"Nearest+Sharp":
			newInterpolation = Image.INTERPOLATE_NEAREST
			newIsNearestSharpMode = true
		_:
			printerr("未知的插值算法: %s，使用默认 Nearest" % selectedAlgorithm)
			newInterpolation = Image.INTERPOLATE_NEAREST
			newIsNearestSharpMode = false
	
	# 更新当前插值算法和模式
	if currentInterpolation != newInterpolation or isNearestSharpMode != newIsNearestSharpMode:
		currentInterpolation = newInterpolation
		isNearestSharpMode = newIsNearestSharpMode
		
		# 如果预览面板可见，立即更新预览
		if visible and previewTexture != null and previewTexture.texture != null:
			_update_preview_size()

# 应用 Sharp 滤镜：移除透明度超过阈值的像素
func _apply_sharp_filter(image: Image) -> Image:
	if not isNearestSharpMode:
		return image
	
	var result = image.duplicate()
	
	# 遍历所有像素
	for y in range(result.get_height()):
		for x in range(result.get_width()):
			var color = result.get_pixel(x, y)
			# 如果透明度小于阈值，设为完全透明
			if color.a < sharpThreshold:
				color.a = 0.0
				result.set_pixel(x, y, color)
	
	return result

# 处理图像：先进行插值，然后应用 Sharp 滤镜（如果需要）
func _process_image_with_interpolation(image: Image, width: int, height: int) -> Image:
	var resizedImage = image.duplicate()
	
	# 先进行插值
	resizedImage.resize(width, height, currentInterpolation)
	
	# 如果启用 Nearest+Sharp 模式，应用滤镜
	if isNearestSharpMode:
		resizedImage = _apply_sharp_filter(resizedImage)
	
	return resizedImage

# 初始化法线材质
func _initialize_normal_material():
	# 创建法线着色器材质
	normalMaterial = ShaderMaterial.new()
	var shader: Shader = load("res://addons/threeToTwo/shader/normal.gdshader")
	normalMaterial.shader = shader

# 材质选择事件
func _on_material_selected(index: int):
	var selectedMaterial: String = materialSelector.get_item_text(index)
	var newNormalMode: bool = (index == 1)
	
	# 如果材质模式没有变化，直接返回
	if newNormalMode == isNormalMode:
		return
	
	isNormalMode = newNormalMode
	
	# 切换材质和normalMesh可见性
	if isNormalMode:
		# 切换到法线材质，显示normalMesh作为背景
		normalMesh.visible = true  # 显示normalMesh作为法线贴图背景
		
		# 为所有MeshInstance3D应用法线材质
		_apply_material_to_all_meshes(normalMaterial)
		_update_preview_from_animation()
	else:
		# 切换回普通材质，隐藏normalMesh
		normalMesh.visible = false  # 隐藏normalMesh
		
		# 为所有MeshInstance3D恢复原始材质
		_apply_material_to_all_meshes(originalMaterial)
		_update_preview_from_animation()

# 为所有MeshInstance3D应用材质
func _apply_material_to_all_meshes(material: Material):
	# 收集所有需要应用材质的MeshInstance3D
	var meshesToApply: Array[MeshInstance3D] = []
	
	# 1. 首先使用allMeshes列表（通过文件上传的模型）
	if allMeshes != null and allMeshes.size() > 0:
		meshesToApply.append_array(allMeshes)
	
	# 2. 如果allMeshes为空，尝试通过three_to_two_ref获取ModelContainer中的网格
	if meshesToApply.size() == 0 and three_to_two_ref != null:
		# 使用threeToTwo实例中的方法获取ModelContainer中的MeshInstance3D
		var foundMeshes: Array[MeshInstance3D] = three_to_two_ref.find_all_mesh_instances_in_model_container()
		if foundMeshes.size() > 0:
			meshesToApply.append_array(foundMeshes)
	
	# 3. 如果仍然没有找到网格，尝试动态查找ModelContainer下的网格（手动放置的模型）
	if meshesToApply.size() == 0:
		# 获取ModelContainer引用
		var container: Node3D = _get_model_container()
		if container != null:
			var foundMeshes: Array[MeshInstance3D] = _find_all_mesh_instances_in_container(container)
			if foundMeshes.size() > 0:
				meshesToApply.append_array(foundMeshes)
	
	# 4. 如果仍然没有找到网格，输出调试信息
	if meshesToApply.size() == 0:
		#print("警告：没有找到任何MeshInstance3D节点")
		return
	
	# 5. 应用材质到所有找到的网格
	var appliedCount: int = 0
	for meshInstance in meshesToApply:
		if meshInstance != null and is_instance_valid(meshInstance):
			# 如果是应用法线材质，先保存原始材质
			if material == normalMaterial:
				# 保存原始材质（如果还没有保存过）
				if not original_materials.has(meshInstance):
					original_materials[meshInstance] = meshInstance.material_override
			
			# 应用新材质
			meshInstance.material_override = material
			appliedCount += 1
	
	#print("已为 %d 个MeshInstance3D应用材质" % appliedCount)
	

# 获取ModelContainer节点
func _get_model_container() -> Node3D:
	# 如果已经缓存了引用，直接返回
	if modelContainer != null:
		return modelContainer
	
	# 尝试通过节点路径查找ModelContainer
	# ModelContainer的路径通常是: SubViewport/ModelContainer
	# 首先获取父节点（Node2D）
	var parent = get_parent()
	if parent != null and parent.has_method("get_model_container"):
		# 通过父节点查找ModelContainer
		modelContainer = parent.get_model_container()
		if modelContainer != null:
			return modelContainer
	
	return null

# 在容器中查找所有MeshInstance3D
func _find_all_mesh_instances_in_container(container: Node) -> Array[MeshInstance3D]:
	var meshInstances: Array[MeshInstance3D] = []
	
	if container == null:
		return meshInstances
	
	# 递归查找所有MeshInstance3D
	_find_mesh_instances_recursive(container, meshInstances)
	
	return meshInstances

# 递归查找MeshInstance3D
func _find_mesh_instances_recursive(node: Node, result: Array[MeshInstance3D]):
	if node is MeshInstance3D:
		result.append(node)
	
	# 递归查找子节点
	for child in node.get_children():
		_find_mesh_instances_recursive(child, result)

# 初始化文件对话框
func _initialize_file_dialogs():
	
	# 设置默认目录为当前工作目录
	saveFileDialog.current_dir = "."
	
	# 连接文件选择信号
	saveFileDialog.file_selected.connect(_on_file_selected)
	saveFileDialog.canceled.connect(_on_file_dialog_canceled)
	
	# 设置默认目录为当前工作目录
	selectDirDialog.current_dir = "."
	
	# 连接文件选择信号（使用FileSelected而不是DirSelected）
	selectDirDialog.file_selected.connect(_on_batch_file_selected)
	selectDirDialog.canceled.connect(_on_batch_dialog_canceled)
	

# 打开文件保存对话框
func _open_save_file_dialog(exportType: ExportType):
	if saveFileDialog == null:
		printerr("文件对话框未初始化")
		return
	
	if previewTexture == null or previewTexture.texture == null:
		printerr("预览纹理为空，无法导出")
		return
	
	# 设置当前导出类型
	currentExportType = exportType
	
	# 生成默认文件名
	var defaultFileName: String = _generate_default_filename(
		exportType == ExportType.NormalMap,
		exportType == ExportType.Both
	)
	
	# 设置默认文件名
	saveFileDialog.current_file = defaultFileName
	
	# 显示对话框
	saveFileDialog.popup_centered()

# 生成默认文件名
func _generate_default_filename(isNormalMap: bool = false, isBothExport: bool = false) -> String:
	# 获取第一个选中的AnimationPlayer作为参考
	var first_player = _get_first_selected_animation_player()
	var animationName: String = "Unknown"
	
	if first_player != null:
		# 获取第一个选中的动画名称
		var selected_players = _get_selected_animation_players()
		if selected_players.size() > 0:
			# 使用第一个选中的AnimationPlayer的当前动画作为参考
			var current_anim = first_player.current_animation
			if current_anim != "":
				animationName = current_anim
			else:
				# 如果没有当前动画，使用第一个动画
				var animation_list = first_player.get_animation_list()
				if animation_list.size() > 0:
					animationName = animation_list[0]
	
	animationName = _clean_filename(animationName)
	
	var fileName: String
	if isBothExport:
		# 两种都导出时，使用普通贴图文件名
		fileName = "%s_%d.png" % [animationName, exportCounter]
	elif isNormalMap:
		fileName = "%s_Normal_%d.png" % [animationName, exportCounter]
	else:
		fileName = "%s_%d.png" % [animationName, exportCounter]
	
	return fileName

# 清理文件名中的非法字符
func _clean_filename(fileName: String) -> String:
	# Windows 文件系统中不允许的字符
	var invalidChars: PackedStringArray = ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]
	
	for invalidChar in invalidChars:
		fileName = fileName.replace(invalidChar, "_")
	
	# 同时替换其他可能的问题字符
	fileName = fileName.replace(" ", "_")  # 替换空格
	
	return fileName

# 文件选择事件
func _on_file_selected(path: String):
	
	# 直接保存，让Godot的FileDialog处理覆盖确认
	_perform_save(path)

# 文件对话框取消事件
func _on_file_dialog_canceled():
	# 重置状态
	pendingSavePath = ""

# 执行实际保存操作
func _perform_save(savePath: String):
	if previewTexture == null or previewTexture.texture == null:
		printerr("预览纹理为空，无法保存")
		return
	
	# 轻微同步：确保所有选中的AnimationPlayer定位到当前预览的时间位置
	if three_to_two_ref != null:
		_control_all_selected_animation_players("seek", currentTime)
	
	# 获取预览图像
	var previewImage: Image = previewTexture.texture.get_image()
	
	# 根据导出类型执行不同的保存逻辑
	match currentExportType:
		ExportType.Normal:
			_save_normal_image(previewImage, savePath)
		ExportType.NormalMap:
			_save_normal_map_image(previewImage, savePath)
		ExportType.Both:
			_save_both_images(previewImage, savePath)
	
	# 重置状态
	pendingSavePath = ""

# 保存普通图像
func _save_normal_image(image: Image, savePath: String):
	var error: Error = image.save_png(savePath)
	
	if error == OK:
		exportCounter += 1
	else:
		printerr("保存普通贴图失败，错误代码: %d" % error)

# 保存法线贴图图像
func _save_normal_map_image(image: Image, savePath: String):
	var error: Error = image.save_png(savePath)
	
	if error == OK:
		exportCounter += 1
	else:
		printerr("保存法线贴图失败，错误代码: %d" % error)

	# 保存两种图像（普通和法线）
func _save_both_images(firstImage: Image, firstSavePath: String):
	
	# 保存当前材质模式
	var originalNormalMode: bool = isNormalMode
	
	# 第一步：保存普通贴图
	if isNormalMode:
		# 切换到普通材质模式
		materialSelector.select(0)
		await wait_for_frame_render()
		isNormalMode = false
		normalMesh.visible = false
		_apply_material_to_all_meshes(originalMaterial)
		_update_preview_from_animation()
		await wait_for_frame_render()
		
		
		# 重新获取图像（现在是普通材质）
		firstImage = previewTexture.texture.get_image()
	
	# 保存普通贴图
	var error: Error = firstImage.save_png(firstSavePath)
	
	if error != OK:
		printerr("保存普通贴图失败，错误代码: %d" % error)
		# 恢复原始材质模式
		if originalNormalMode != isNormalMode:
			_restore_material_mode(originalNormalMode)
		return
	
	await wait_for_frame_render()
	# 第二步：保存法线贴图
	# 切换到法线材质模式
	materialSelector.select(1)
	await wait_for_frame_render()
	isNormalMode = true
	normalMesh.visible = true
	_apply_material_to_all_meshes(normalMaterial)
	_update_preview_from_animation()
	await wait_for_frame_render()
	
	# 获取法线贴图图像
	var normalImage: Image = previewTexture.texture.get_image()
	
	# 生成法线贴图保存路径（在相同目录，添加_Normal后缀）
	var directory: String = firstSavePath.get_base_dir()
	var fileNameWithoutExt: String = firstSavePath.get_file().get_basename()
	var extension: String = firstSavePath.get_extension()
	var normalSavePath: String = "%s/%s_Normal.%s" % [directory, fileNameWithoutExt, extension]
	
	# 保存法线贴图
	error = normalImage.save_png(normalSavePath)
	
	
	# 增加计数器
	exportCounter += 1
	
	# 第三步：恢复原始材质模式
	# if originalNormalMode != isNormalMode:
	# 	_restore_material_mode(originalNormalMode)
	

# 恢复材质模式
func _restore_material_mode(originalNormalMode: bool):
	materialSelector.select(1 if originalNormalMode else 0)
	isNormalMode = originalNormalMode
	normalMesh.visible = originalNormalMode
	_apply_material_to_all_meshes(normalMaterial if originalNormalMode else originalMaterial)
	_update_preview_from_animation()

# 法线贴图导出按钮事件
func _on_normal_export_pressed():
	if previewTexture == null or previewTexture.texture == null:
		printerr("预览纹理为空，无法导出法线贴图")
		return
	if isPlaying:
		_on_play_pause_button_pressed()
	
	# 确保当前是法线材质模式
	if not isNormalMode:
		materialSelector.select(1)  # 选择法线材质
		isNormalMode = true
		
		# 应用法线材质并显示normalMesh作为背景
		normalMesh.visible = true  # 显示normalMesh作为法线贴图背景
		# 为所有MeshInstance3D应用法线材质
		_apply_material_to_all_meshes(normalMaterial)
		_update_preview_from_animation()
		# 延迟0.1秒后打开文件对话框，确保Viewport有足够时间重新渲染
		var timer: SceneTreeTimer = get_tree().create_timer(0.1)
		timer.timeout.connect(func():
			_open_save_file_dialog(ExportType.NormalMap)
		)
		return
	
	# 如果已经是法线模式，确保normalMesh可见并打开文件对话框
	normalMesh.visible = true  # 确保normalMesh可见
	
	_open_save_file_dialog(ExportType.NormalMap)

# 导出普通贴图按钮事件
func _on_putong_export_pressed():
	if previewTexture == null or previewTexture.texture == null:
		printerr("预览纹理为空，无法导出普通贴图")
		return
	if isPlaying:
		_on_play_pause_button_pressed()

	# 确保当前是普通材质模式
	if isNormalMode:
		materialSelector.select(0)  # 选择普通材质
		isNormalMode = false
		
		# 切换到普通材质，隐藏normalMesh
		normalMesh.visible = false  # 隐藏normalMesh
		# 为所有MeshInstance3D恢复原始材质
		_apply_material_to_all_meshes(originalMaterial)
		_update_preview_from_animation()
		
		# 延迟0.1秒后打开文件对话框，确保Viewport有足够时间重新渲染
		var timer: SceneTreeTimer = get_tree().create_timer(0.1)
		timer.timeout.connect(func():
			_open_save_file_dialog(ExportType.Normal)
		)
		return
	
	# 如果已经是普通模式，直接打开文件对话框
	_open_save_file_dialog(ExportType.Normal)

# 导出两种材质按钮事件
func _on_export_both_pressed():
	if previewTexture == null or previewTexture.texture == null:
		printerr("预览纹理为空，无法导出")
		return
	if isPlaying:
		_on_play_pause_button_pressed()
	
	# 打开文件保存对话框，导出两种贴图
	_open_save_file_dialog(ExportType.Both)

# 上一帧按钮点击事件（改为上一秒）
func _on_prev_frame_button_pressed():
	if three_to_two_ref == null:
		return
	
	# 向前移动1秒
	currentTime = maxf(0, currentTime - 0.01)
	
	# 保存原始播放状态
	var wasPlaying: bool = isPlaying
	
	# 使用正确的 Play(); Seek(); Pause(); 模式控制所有选中的AnimationPlayer
	_control_all_selected_animation_players("play", currentTime)
	
	# 如果原本没有播放，立即暂停
	if not wasPlaying:
		_control_all_selected_animation_players("pause")
	# 如果原本在播放，继续播放（从新位置继续）
	else:
		_control_all_selected_animation_players("play", currentTime)  # 确保精确定位
	
	# 更新滑块位置
	frameSlider.value = currentTime
	
	# 更新帧信息标签
	_update_frame_info_label()
	
	# 更新预览
	_update_preview_from_animation()
	

# 下一帧按钮点击事件（改为下一秒）
func _on_next_frame_button_pressed():
	if three_to_two_ref == null:
		return
	
	if currentTime >= animationLength:
		# 如果已经播放完毕，从头开始播放
		currentTime = 0
	# 向后移动1秒
	currentTime = minf(animationLength, currentTime + 0.01)
	
	# 保存原始播放状态
	var wasPlaying: bool = isPlaying
	
	# 使用正确的 Play(); Seek(); Pause(); 模式控制所有选中的AnimationPlayer
	_control_all_selected_animation_players("play", currentTime)
	
	# 如果原本没有播放，立即暂停
	if not wasPlaying:
		_control_all_selected_animation_players("pause")
	# 如果原本在播放，继续播放（从新位置继续）
	else:
		_control_all_selected_animation_players("play", currentTime)  # 确保精确定位
	
	# 更新滑块位置
	frameSlider.value = currentTime
	
	# 更新帧信息标签
	_update_frame_info_label()
	
	# 更新预览
	_update_preview_from_animation()
	

# 批量导出按钮点击事件
func _on_batch_export_pressed():
	if previewTexture == null or previewTexture.texture == null:
		printerr("预览纹理为空，无法批量导出")
		return
	
	if three_to_two_ref == null:
		printerr("threeToTwo引用未设置")
		return
	if isPlaying:
		_on_play_pause_button_pressed()
	# 设置默认文件名（使用第一个选中的动画名）
	var animationName: String = "Unknown"
	var first_player = _get_first_selected_animation_player()
	if first_player != null:
		var current_anim = first_player.current_animation
		if current_anim != "":
			animationName = current_anim
		else:
			var animation_list = first_player.get_animation_list()
			if animation_list.size() > 0:
				animationName = animation_list[0]
	
	animationName = _clean_filename(animationName)
	var defaultFileName: String = animationName
	
	# 设置默认文件名
	if selectDirDialog != null:
		selectDirDialog.current_file = defaultFileName
		selectDirDialog.popup_centered()
	else:
		printerr("批量导出对话框未初始化")

# 批量导出文件选择事件
func _on_batch_file_selected(filePath: String):
	
	# 从文件路径中提取目录和文件名
	var directory: String = filePath.get_base_dir()
	var fileName: String = filePath.get_file().get_basename()
	
	# 清理文件名
	fileName = _clean_filename(fileName)
	
	# 如果用户没有输入文件名，使用第一个选中的动画名作为默认值
	if fileName.is_empty() or fileName == ".":
		var animationName: String = "Unknown"
		var first_player = _get_first_selected_animation_player()
		if first_player != null:
			var current_anim = first_player.current_animation
			if current_anim != "":
				animationName = current_anim
			else:
				var animation_list = first_player.get_animation_list()
				if animation_list.size() > 0:
					animationName = animation_list[0]
		
		fileName = _clean_filename(animationName)
	
	pendingBatchExportDir = directory
	pendingFileNamePrefix = fileName
	
	# 直接开始批量导出，让文件系统处理目录覆盖问题
	_start_batch_export()

# 批量导出对话框取消事件
func _on_batch_dialog_canceled():
	# 重置状态
	_reset_batch_export_state()


# 开始批量导出
func _start_batch_export():
	if pendingBatchExportDir.is_empty():
		printerr("批量导出目录为空")
		return
	
	# 获取间隔时间
	var intervalSeconds: float = float(frameIntervalInput.text) if not frameIntervalInput.text.is_empty() else 1.0
	if intervalSeconds <= 0:
		printerr("请输入有效的间隔时间（大于0的数字）")
		_reset_batch_export_state()
		return
	
	_control_all_selected_animation_players("stop")

	exportCounter = 1
	
	# 保存当前材质模式
	var originalNormalMode: bool = isNormalMode
	
	# 计算需要导出的时间点
	var totalTime: float = animationLength
	var frameCount: int = ceil(totalTime / intervalSeconds)
	
	
	# 使用用户输入的文件名前缀，如果没有输入则使用第一个选中的动画名
	var fileNamePrefix: String = pendingFileNamePrefix
	if fileNamePrefix.is_empty():
		var animationName: String = "Unknown"
		var first_player = _get_first_selected_animation_player()
		if first_player != null:
			var current_anim = first_player.current_animation
			if current_anim != "":
				animationName = current_anim
			else:
				var animation_list = first_player.get_animation_list()
				if animation_list.size() > 0:
					animationName = animation_list[0]
		fileNamePrefix = animationName
	
	fileNamePrefix = _clean_filename(fileNamePrefix)
	
	# 创建目录结构
	var animationDir: String = "%s/%s" % [pendingBatchExportDir, fileNamePrefix]
	var normalMaterialDir: String = "%s/普通贴图" % animationDir
	var normalMapDir: String = "%s/法线贴图" % animationDir
	
	# 确保目录存在
	_ensure_directory_exists(animationDir)
	_ensure_directory_exists(normalMaterialDir)
	_ensure_directory_exists(normalMapDir)
	
	# 清空两个子目录的所有文件（如果目录存在）
	if DirAccess.dir_exists_absolute(normalMaterialDir):
		_clear_directory_files(normalMaterialDir)
	
	if DirAccess.dir_exists_absolute(normalMapDir):
		_clear_directory_files(normalMapDir)
	
	# 批量导出
	for i in range(frameCount + 1):
		var exportTime: float = i * intervalSeconds
		if exportTime > totalTime:
			exportTime = totalTime
		
		
		# 定位所有选中的AnimationPlayer到指定时间
		_control_all_selected_animation_players("play", exportTime)
		_control_all_selected_animation_players("pause")
		
		# 更新当前时间
		currentTime = exportTime
		
		# 更新滑块位置
		frameSlider.value = currentTime
		
		# 更新帧信息标签
		_update_frame_info_label()
		
		# 等待渲染
		await wait_for_frame_render()
		
		# 第一步：导出普通贴图
		if isNormalMode:
			# 切换到普通材质模式
			materialSelector.select(0)
			await wait_for_frame_render()
			isNormalMode = false
			normalMesh.visible = false
			_apply_material_to_all_meshes(originalMaterial)
			_update_preview_from_animation()
			await wait_for_frame_render()
		
		# 获取预览图像
		var previewImage: Image = previewTexture.texture.get_image()
		
		# 生成普通贴图文件名
		var fileName: String = "%s_%d.png" % [fileNamePrefix, exportCounter]
		fileName = _clean_filename(fileName)
		var savePath: String = "%s/%s" % [normalMaterialDir, fileName]
		
		# 保存普通贴图
		var error: Error = previewImage.save_png(savePath)
		
		await wait_for_frame_render()
		# 第二步：导出法线贴图
		# 切换到法线材质模式
		materialSelector.select(1)
		await wait_for_frame_render()
		isNormalMode = true
		normalMesh.visible = true
		_apply_material_to_all_meshes(normalMaterial)
		_update_preview_from_animation()
		await wait_for_frame_render()
		# 获取法线预览图像
		previewImage = previewTexture.texture.get_image()
		
		# 生成法线贴图文件名
		var normalFileName: String = "%s_Normal_%d.png" % [fileNamePrefix, exportCounter]
		normalFileName = _clean_filename(normalFileName)
		var normalSavePath: String = "%s/%s" % [normalMapDir, normalFileName]
		
		# 保存法线贴图
		error = previewImage.save_png(normalSavePath)
		
		
		# 增加计数器
		exportCounter += 1
	
	# 恢复原始材质模式
	# if originalNormalMode != isNormalMode:
	# 	print("恢复原始材质模式: %s" % ("法线材质" if originalNormalMode else "普通材质"))
	# 	materialSelector.select(1 if originalNormalMode else 0)
	# 	isNormalMode = originalNormalMode
	# 	normalMesh.visible = originalNormalMode
	# 	_apply_material_to_all_meshes(normalMaterial if originalNormalMode else originalMaterial)
	# 	_update_preview_from_animation()
	
	
	# 保存相机配置到批量导出目录
	_save_camera_config_to_batch_export_dir(animationDir)
	
	# 重置批量导出状态
	_reset_batch_export_state()

# 保存相机配置到批量导出目录
func _save_camera_config_to_batch_export_dir(animationDir: String):
	if three_to_two_ref == null:
		#print("threeToTwo引用未设置，无法保存相机配置")
		return
	
	# 获取当前选中的相机
	var selected_camera = three_to_two_ref.selected_camera_node
	if selected_camera == null or not is_instance_valid(selected_camera):
		#print("没有选中的相机，无法保存相机配置")
		return
	
	# 创建相机配置字典
	var camera_config = {
		"version": "1.0",
		"camera": {
			"position": {
				"x": selected_camera.global_position.x,
				"y": selected_camera.global_position.y,
				"z": selected_camera.global_position.z
			},
			"rotation": {
				"x": selected_camera.global_transform.basis.get_rotation_quaternion().x,
				"y": selected_camera.global_transform.basis.get_rotation_quaternion().y,
				"z": selected_camera.global_transform.basis.get_rotation_quaternion().z,
				"w": selected_camera.global_transform.basis.get_rotation_quaternion().w
			},
			"fov": selected_camera.fov,
			"near": selected_camera.near,
			"far": selected_camera.far,
			"scale": {
				"x": selected_camera.scale.x,
				"y": selected_camera.scale.y,
				"z": selected_camera.scale.z
			}
		},
		"export_size": {
			"width": int(currentSize.x),
			"height": int(currentSize.y)
		},
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	# 转换为JSON字符串
	var json_string = JSON.stringify(camera_config, "\t")
	
	# 保存到文件
	var config_path = animationDir + "/camera_config.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_string)
		file.close()
		#print("相机配置已保存到: " + config_path)
	else:
		printerr("无法保存相机配置文件: " + config_path)

# 重置批量导出状态
func _reset_batch_export_state():
	pendingBatchExportDir = ""
	pendingAnimationDir = ""
	pendingFileNamePrefix = ""
	isDirectoryOverwriteDialog = false

# 恢复所有MeshInstance3D的原始材质
func restore_original_materials():
	var restoredCount: int = 0
	var invalidCount: int = 0
	
	for mesh_instance in original_materials.keys():
		if is_instance_valid(mesh_instance):
			mesh_instance.material_override = original_materials[mesh_instance]
			restoredCount += 1
		else:
			invalidCount += 1
	
	# 清空原始材质字典
	original_materials.clear()
	
	#print("已恢复 %d 个MeshInstance3D的原始材质，%d 个无效引用已清理" % [restoredCount, invalidCount])

# 重置预览面板状态
func reset():
	
	# 重置缩放和位置
	currentZoom = 1.0
	previewOffset = Vector2.ZERO
	
	# 重置尺寸
	currentSize = Vector2(100, 100)
	
	# 重置材质模式
	isNormalMode = false
	if materialSelector != null:
		materialSelector.select(0)
	
	# 重置动画状态
	currentTime = 0.0
	animationLength = 0.0
	isPlaying = false
	
	# 重置导出计数器
	exportCounter = 1
	
	# 重置插值算法
	if interpolationSelector != null:
		interpolationSelector.select(0)
		currentInterpolation = Image.INTERPOLATE_NEAREST
	
	# 重置UI显示
	if zoomLabel != null:
		zoomLabel.text = "100%"
	
	if widthInput != null:
		widthInput.text = "100"
	
	if heightInput != null:
		heightInput.text = "100"
	
	if frameIntervalInput != null:
		frameIntervalInput.text = "1.0"
	
	# 清空动画选择器（已移除，动画选择在threeToTwo中完成）
	
	# 重置预览纹理
	if previewTexture != null:
		previewTexture.texture = null
	
	# 隐藏normalMesh
	if normalMesh != null:
		normalMesh.visible = false
	
	# 清空网格列表
	allMeshes.clear()
	
	# 恢复原始材质
	restore_original_materials()
	
	# 重置动画播放器引用
	three_to_two_ref = null
	

# 确保目录存在
func _ensure_directory_exists(directoryPath: String):
	if not DirAccess.dir_exists_absolute(directoryPath):
		DirAccess.make_dir_recursive_absolute(directoryPath)

# 清空目录中的所有文件（不删除子目录）
func _clear_directory_files(directoryPath: String):
	if not DirAccess.dir_exists_absolute(directoryPath):
		return
	
	var dir = DirAccess.open(directoryPath)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var fileName = dir.get_next()
	var deletedCount: int = 0
	
	while not fileName.is_empty():
		if fileName != "." and fileName != ".." and not dir.current_is_dir():
			# 只删除文件，不处理子目录
			var fullPath = "%s/%s" % [directoryPath, fileName]
			var error = dir.remove(fullPath)
			if error == OK:
				deletedCount += 1
			else:
				printerr("删除文件失败: %s, 错误: %d" % [fileName, error])
		fileName = dir.get_next()
	
	dir.list_dir_end()


# 等待渲染完成（使用RenderingServer.frame_post_draw信号）
func wait_for_frame_render() -> void:
	# 使用信号等待渲染完成
	await RenderingServer.frame_post_draw
	
	# 额外等待一小段时间确保完全稳定（可选）
	await get_tree().create_timer(0.01).timeout
