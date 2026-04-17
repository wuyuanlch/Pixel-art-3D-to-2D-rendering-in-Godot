@tool
extends Control
class_name vfx_preview_panel

# 外部节点引用
var sprite2D2: TextureRect
var three_to_two_ref: threeToTwo  # 改为引用threeToTwo实例

# 所有MeshInstance3D的列表
var allMeshes: Array[MeshInstance3D] = []

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
@export var exportBothButton: Button
var originalMaterial: Material
var isNormalMode: bool = false

# 纹理缓存控制相关变量
@export var frameSlider: HSlider
@export var frameInfoLabel: Label
@export var playPauseButton: Button
@export var prevFrameButton: Button
@export var nextFrameButton: Button
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
enum ExportType { Normal, Both }

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

# 材质选项
@export var material_threshold_hslider: HSlider
@export var material_softness_hslider: HSlider
@export var material_color_picker: ColorPickerButton  # 背景颜色选择器
@export var material_thre_hslider_label: Label  # 阈值滑块标签
@export var material_soft_hslider_label: Label  # 柔化滑块标签

@export var cycle_check_button: CheckButton

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
	# exportBothButton.pressed.connect(_on_export_both_pressed)  # 连接导出两种材质按钮
	
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
	
	# 连接材质滑块信号
	if material_threshold_hslider != null:
		material_threshold_hslider.value_changed.connect(_on_material_threshold_changed)
		# 设置滑块范围
		material_threshold_hslider.min_value = 0.0
		material_threshold_hslider.max_value = 1.0
		material_threshold_hslider.step = 0.01
	
	if material_softness_hslider != null:
		material_softness_hslider.value_changed.connect(_on_material_softness_changed)
		# 设置滑块范围
		material_softness_hslider.min_value = 0.0
		material_softness_hslider.max_value = 0.5
		material_softness_hslider.step = 0.01
	
	# 连接颜色选择器信号
	if material_color_picker != null:
		material_color_picker.color_changed.connect(_on_bg_color_changed)
	
	# 连接纹理循环按钮信号
	if cycle_check_button != null:
		cycle_check_button.toggled.connect(_on_cycle_check_button_toggled)
		#print("已连接纹理循环按钮信号")
	
	# 初始化滑块值
	_initialize_material_sliders()
	
	# 初始化文件对话框
	_initialize_file_dialogs()
	
	# 设置初始状态
	visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# VFX 预览面板的 _process 函数现在为空
	# 所有纹理播放逻辑都在 _play_texture_sequence() 中使用 await 处理
	pass

# 设置外部节点引用
func set_external_references(sprite2d: TextureRect, three_to_two_instance: threeToTwo, normal_mesh: MeshInstance3D):
	sprite2D2 = sprite2d
	three_to_two_ref = three_to_two_instance
	# normalMesh = normal_mesh

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
	# 这个方法现在为空，因为 VFX 预览面板不再处理动画
	# 动画长度信息由 threeToTwo 实例管理
	pass

# 显示预览
func show_vfx_preview():
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
			
			#print("VFX预览面板使用加载的尺寸: " + str(three_to_two_ref.loaded_export_width) + "x" + str(three_to_two_ref.loaded_export_height))
		# else:
		# 	print("VFX预览面板没有加载的尺寸，使用默认尺寸: " + str(currentSize.x) + "x" + str(currentSize.y))
	
	# 检测动画管理器循环状态，并设置纹理循环按钮
	if three_to_two_ref != null:
		var is_animation_looping = _is_selected_animation_looping()
		if cycle_check_button != null:
			# 如果动画是循环的，设置纹理循环按钮为true
			cycle_check_button.button_pressed = is_animation_looping
			# print("检测到动画循环状态: %s，已设置纹理循环按钮为: %s" % [
			# 	"循环" if is_animation_looping else "不循环",
			# 	"选中" if is_animation_looping else "未选中"
			# ])
	
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
			# 关键修复：设置previewTexture的尺寸，确保位置计算正确
			previewTexture.size = currentSize
		else:
			printerr("Sprite2D2纹理为空，无法预览")

			if sprite2D2.texture != null:
				var originalImage: Image = sprite2D2.texture.get_image()
				# 使用新的处理函数，包含插值和Sharp滤镜
				var resizedImage: Image = _process_image_with_interpolation(originalImage, int(currentSize.x), int(currentSize.y))
				var resizedTexture: ImageTexture = ImageTexture.create_from_image(resizedImage)
				previewTexture.texture = resizedTexture
				# 关键修复：设置previewTexture的尺寸，确保位置计算正确
				previewTexture.size = currentSize
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
	previewTexture.position = center + previewOffset - (scaled_size / 2)
	
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
		
		# 如果有缓存的纹理，从原始纹理重新处理所有纹理
		if not original_cached_textures.is_empty():
			_process_all_textures_from_original()
			# 显示当前帧的纹理
			_show_current_texture()
		# 否则，使用实时渲染路径更新预览
		else:
			_update_preview_size()
	else:
		printerr("尺寸必须大于0")

# 批量导出间隔输入框回车键提交事件
func _on_frame_interval_input_submitted(newText: String):
	# 不需要立即应用，只在批量导出时使用
	# print("批量导出帧间隔已设置为: %s帧" % newText)
	pass

# 批量导出间隔输入框焦点丢失事件
func _on_frame_interval_input_focus_exited():
	# 不需要立即应用，只在批量导出时使用
	if frameIntervalInput != null:
		# print("批量导出帧间隔已设置为: %s帧" % frameIntervalInput.text)
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
	previewTexture.position = center - (previewTexture.size / 2)

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
	# 只处理纹理缓存模式
	if cached_textures.is_empty():
		#print("没有缓存的纹理可以播放")
		return
	
	if isPlaying:
		# 暂停播放
		isPlaying = false
		playPauseButton.text = "▶"
	else:
		# 检查是否在最后一帧且停止状态
		if current_texture_index >= cached_textures.size() - 1:
			# 重置到第一帧
			current_texture_index = 0
			_show_current_texture()
		
		# 开始播放纹理序列
		isPlaying = true
		playPauseButton.text = "⏸"
		_play_texture_sequence()


# 帧滑块变化事件
func _on_frame_slider_changed(value: float):
	# 只处理纹理缓存模式
	if cached_textures.is_empty():
		#print("没有缓存的纹理可以浏览")
		return
	
	var index = int(value)
	if index >= 0 and index < cached_textures.size():
		current_texture_index = index
		_show_current_texture()
	

# 更新帧信息标签
func _update_frame_info_label():
	if frameInfoLabel != null:
		# 纹理缓存模式：显示帧信息
		if not cached_textures.is_empty():
			frameInfoLabel.text = "帧: %d/%d" % [current_texture_index + 1, cached_textures.size()]
		else:
			frameInfoLabel.text = "无缓存纹理"

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
		
		# 如果有缓存的纹理，从原始纹理重新处理所有纹理
		if not original_cached_textures.is_empty():
			_process_all_textures_from_original()
			# 显示当前帧的纹理
			_show_current_texture()
		# 否则，使用实时渲染路径更新预览
		elif visible and previewTexture != null and previewTexture.texture != null:
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

# 重新处理所有缓存的纹理（当插值算法改变时调用）
func _reprocess_cached_textures():
	if cached_textures.is_empty():
		return
	
	# print("重新处理 %d 张缓存纹理，使用插值算法: %s" % [cached_textures.size(), 
	# 	"Nearest+Sharp" if isNearestSharpMode else "Nearest"])
	
	var reprocessed_textures: Array[ImageTexture] = []
	
	for i in range(cached_textures.size()):
		var original_texture = cached_textures[i]
		if original_texture == null:
			# 如果纹理为空，跳过
			reprocessed_textures.append(null)
			continue
		
		# 获取原始图像的 Image
		var original_image: Image = original_texture.get_image()
		if original_image == null:
			# 如果无法获取图像，使用原始纹理
			reprocessed_textures.append(original_texture)
			continue
		
		# 使用当前插值算法和尺寸重新处理图像
		var processed_image = _process_image_with_interpolation(original_image, int(currentSize.x), int(currentSize.y))
		
		# 创建新的 ImageTexture
		var new_texture = ImageTexture.create_from_image(processed_image)
		reprocessed_textures.append(new_texture)
	
	# 更新缓存的纹理
	cached_textures = reprocessed_textures
	
	#print("缓存纹理重新处理完成")

# 材质选择事件
func _on_material_selected(index: int):
	# VFX 预览面板只支持普通材质，法线材质功能已移除
	# 这个方法现在只用于内部参考，不再处理材质切换
	pass

# 为所有MeshInstance3D应用材质
func _apply_material_to_all_meshes(material: Material):
	# 收集所有需要应用材质的MeshInstance3D
	var meshesToApply: Array[MeshInstance3D] = []
	
	# 1. 首先使用allMeshes列表（通过文件上传的模型）
	if allMeshes != null and allMeshes.size() > 0:
		meshesToApply.append_array(allMeshes)
	
	# 2. 如果allMeshes为空，尝试动态查找ModelContainer下的网格（手动放置的模型）
	if meshesToApply.size() == 0:
		# 获取ModelContainer引用
		var container: Node3D = _get_model_container()
		if container != null:
			var foundMeshes: Array[MeshInstance3D] = _find_all_mesh_instances_in_container(container)
			if foundMeshes.size() > 0:
				meshesToApply.append_array(foundMeshes)
	
	# 3. 如果仍然没有找到网格，输出调试信息
	if meshesToApply.size() == 0:
		return
	
	# 4. 应用材质到所有找到的网格
	var appliedCount: int = 0
	for meshInstance in meshesToApply:
		if meshInstance != null:
			meshInstance.material_override = material
			appliedCount += 1
	

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
		false,  # isNormalMap 参数，现在总是 false
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
	# 注意：VFX 预览面板不再处理动画时间，所以这里不需要同步
	# if three_to_two_ref != null:
	# 	_control_all_selected_animation_players("seek", currentTime)
	
	# 获取预览图像
	var previewImage: Image = previewTexture.texture.get_image()
	
	# 根据导出类型执行不同的保存逻辑
	match currentExportType:
		ExportType.Normal:
			_save_normal_image(previewImage, savePath)
		ExportType.Both:
			_save_both_images(previewImage, savePath)
	
	# 重置状态
	pendingSavePath = ""

# 保存普通图像
func _save_normal_image(image: Image, savePath: String):
	if image == null:
		printerr("图像为空，无法保存")
		return
	
	# 应用背景透明化处理
	var processed_image = _apply_background_transparency(image)
	if processed_image == null:
		printerr("图像处理失败，使用原始图像")
		processed_image = image
	
	var error: Error = processed_image.save_png(savePath)
	
	if error == OK:
		exportCounter += 1
	else:
		printerr("保存普通贴图失败，错误代码: %d" % error)


	# 保存两种图像（普通和法线）
func _save_both_images(firstImage: Image, firstSavePath: String):
	# VFX 预览面板不再支持法线贴图，所以这个方法现在只保存普通贴图
	# 保存普通贴图
	var error: Error = firstImage.save_png(firstSavePath)
	
	if error == OK:
		exportCounter += 1
	else:
		printerr("保存普通贴图失败，错误代码: %d" % error)
	



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
		# normalMesh.visible = false  # 隐藏normalMesh
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
# func _on_export_both_pressed():
# 	if previewTexture == null or previewTexture.texture == null:
# 		printerr("预览纹理为空，无法导出")
# 		return
# 	if isPlaying:
# 		_on_play_pause_button_pressed()
	
# 	# 打开文件保存对话框，导出两种贴图
# 	_open_save_file_dialog(ExportType.Both)

# 上一帧按钮点击事件
func _on_prev_frame_button_pressed():
	# 只处理纹理缓存模式
	if cached_textures.is_empty():
		#print("没有缓存的纹理可以浏览")
		return
	
	# 显示上一张纹理
	current_texture_index = max(0, current_texture_index - 1)
	_show_current_texture()
	

# 下一帧按钮点击事件
func _on_next_frame_button_pressed():
	# 只处理纹理缓存模式
	if cached_textures.is_empty():
		#print("没有缓存的纹理可以浏览")
		return
	
	# 显示下一张纹理
	current_texture_index = min(cached_textures.size() - 1, current_texture_index + 1)
	_show_current_texture()
	

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
	
	# 获取帧间隔
	var frameInterval: int = int(frameIntervalInput.text) if not frameIntervalInput.text.is_empty() else 1
	if frameInterval <= 0:
		printerr("请输入有效的帧间隔（大于0的数字）")
		_reset_batch_export_state()
		return
	
	# 检查是否有缓存的纹理
	if cached_textures.is_empty():
		printerr("没有缓存的纹理可以批量导出")
		_reset_batch_export_state()
		return
	
	exportCounter = 1
	
	# 保存当前材质模式
	var originalNormalMode: bool = isNormalMode
	
	# 计算总帧数和需要导出的帧
	var totalFrames: int = cached_textures.size()
	var framesToExport: int = ceil(float(totalFrames) / frameInterval)
	
	
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
	
	# 确保目录存在
	_ensure_directory_exists(animationDir)
	_ensure_directory_exists(normalMaterialDir)
	
	# 清空子目录的所有文件（如果目录存在）
	if DirAccess.dir_exists_absolute(normalMaterialDir):
		_clear_directory_files(normalMaterialDir)
	
	# 批量导出
	var frameIndex: int = 0
	var exportedLastFrame: bool = false
	
	while frameIndex < totalFrames:
		# 显示当前帧
		current_texture_index = frameIndex
		_show_current_texture()
		
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
			# normalMesh.visible = false
			_apply_material_to_all_meshes(originalMaterial)
			_update_preview_from_animation()
			await wait_for_frame_render()
		
		# 获取预览图像
		var previewImage: Image = previewTexture.texture.get_image()
		
		# 生成普通贴图文件名
		var fileName: String = "%s_%d.png" % [fileNamePrefix, exportCounter]
		fileName = _clean_filename(fileName)
		var savePath: String = "%s/%s" % [normalMaterialDir, fileName]
		
		# 应用背景透明化处理并保存普通贴图
		var processed_image = _apply_background_transparency(previewImage)
		var error: Error = processed_image.save_png(savePath)
		
		# 增加计数器
		exportCounter += 1
		
		# 检查是否是最后一帧
		if frameIndex == totalFrames - 1:
			exportedLastFrame = true
			break
		
		# 前进 frameInterval 帧
		frameIndex += frameInterval
		
		# 如果前进后超过总帧数，设置为最后一帧
		if frameIndex >= totalFrames:
			frameIndex = totalFrames - 1
	
	# 恢复原始材质模式
	# if originalNormalMode != isNormalMode:
	# 	print("恢复原始材质模式: %s" % ("法线材质" if originalNormalMode else "普通材质"))
	# 	materialSelector.select(1 if originalNormalMode else 0)
	# 	isNormalMode = originalNormalMode
	# 	normalMesh.visible = originalNormalMode
	# 	_apply_material_to_all_meshes(normalMaterial if originalNormalMode else originalMaterial)
	# 	_update_preview_from_animation())
	
	# 保存相机配置到批量导出目录
	_save_camera_config_to_batch_export_dir(animationDir)
	
	# 重置批量导出状态
	_reset_batch_export_state()

# 重置批量导出状态
func _reset_batch_export_state():
	pendingBatchExportDir = ""
	pendingAnimationDir = ""
	pendingFileNamePrefix = ""
	isDirectoryOverwriteDialog = false

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
	
	# 重置纹理缓存状态
	cached_textures.clear()
	current_texture_index = 0
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
	
	# 重置预览纹理
	if previewTexture != null:
		previewTexture.texture = null
	
	# 隐藏normalMesh
	# if normalMesh != null:
	# 	normalMesh.visible = false
	
	# 清空网格列表
	allMeshes.clear()
	
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

# ============================================
# 缓存纹理功能
# ============================================

# 缓存纹理相关变量
var cached_textures: Array[ImageTexture] = []
var original_cached_textures: Array[ImageTexture] = []  # 存储原始未处理的纹理
var current_texture_index: int = 0

# 从原始纹理处理所有纹理
func _process_all_textures_from_original():
	if original_cached_textures.is_empty():
		return
	
	# print("从原始纹理处理所有 %d 张纹理，使用插值算法: %s，尺寸: %dx%d" % [
	# 	original_cached_textures.size(),
	# 	"Nearest+Sharp" if isNearestSharpMode else "Nearest",
	# 	int(currentSize.x), int(currentSize.y)
	# ])
	
	var processed_textures: Array[ImageTexture] = []
	
	for i in range(original_cached_textures.size()):
		var original_texture = original_cached_textures[i]
		if original_texture == null:
			# 如果纹理为空，跳过
			processed_textures.append(null)
			continue
		
		# 获取原始图像的 Image
		var original_image: Image = original_texture.get_image()
		if original_image == null:
			# 如果无法获取图像，使用原始纹理
			processed_textures.append(original_texture)
			continue
		
		# 使用当前插值算法和尺寸处理图像
		var processed_image = _process_image_with_interpolation(original_image, int(currentSize.x), int(currentSize.y))
		
		# 创建新的 ImageTexture
		var new_texture = ImageTexture.create_from_image(processed_image)
		processed_textures.append(new_texture)
	
	# 更新缓存的纹理
	cached_textures = processed_textures
	
	#print("纹理处理完成，已更新 %d 张纹理" % cached_textures.size())

# 接收缓存纹理的方法
func set_cached_textures(textures: Array[ImageTexture]):
	# 保存原始纹理
	original_cached_textures = textures.duplicate()
	
	# 初始处理：使用当前插值算法和尺寸处理所有纹理
	_process_all_textures_from_original()
	
	#print("VFX 预览面板接收到 %d 张原始纹理，已使用当前设置处理" % textures.size())
	
	# 更新 FrameSlider 的最大值
	if frameSlider != null:
		frameSlider.max_value = cached_textures.size() - 1
		frameSlider.value = 0
	
	# 显示第一张纹理
	_show_current_texture()

# 显示当前纹理
func _show_current_texture():
	if cached_textures.is_empty() or previewTexture == null:
		return
	
	if current_texture_index >= 0 and current_texture_index < cached_textures.size():
		previewTexture.texture = cached_textures[current_texture_index]
		
		# 更新显示尺寸，确保与处理后的图像尺寸一致
		previewTexture.size = currentSize
		
		# 重置位置偏移，确保居中显示
		previewOffset = Vector2.ZERO
		
		# 更新预览变换
		_update_preview_transform()
		
		# 更新帧信息标签
		if frameInfoLabel != null:
			frameInfoLabel.text = "帧: %d/%d" % [current_texture_index + 1, cached_textures.size()]
		
		# 更新 FrameSlider
		if frameSlider != null:
			frameSlider.value = current_texture_index

# 播放纹理序列
func _play_texture_sequence():
	while isPlaying and not cached_textures.is_empty():
		# 检查纹理循环按钮状态（而不是动画管理器状态）
		var is_texture_looping = cycle_check_button.button_pressed
		
		# 显示下一帧
		if is_texture_looping:
			# 循环播放：使用取模运算
			current_texture_index = (current_texture_index + 1) % cached_textures.size()
		else:
			# 非循环播放：递增索引，到达最后一帧后停止
			if current_texture_index < cached_textures.size() - 1:
				current_texture_index += 1
			else:
				# 到达最后一帧，停止播放
				isPlaying = false
				playPauseButton.text = "▶"
				break
		
		_show_current_texture()
		
		# 等待一段时间（根据缓存间隔）
		await get_tree().create_timer(0.01).timeout

# FrameSlider 值改变事件（修改版）
func _on_frame_slider_value_changed(value: float):
	if cached_textures.is_empty():
		return
	
	var index = int(value)
	if index >= 0 and index < cached_textures.size():
		current_texture_index = index
		_show_current_texture()

# 初始化材质滑块值
func _initialize_material_sliders():
	if previewTexture == null:
		return
	
	# 获取PreviewTexture的材质
	var material = previewTexture.material as ShaderMaterial
	if material == null:
		printerr("PreviewTexture材质为空或不是ShaderMaterial")
		return
	
	# 设置threshold滑块初始值
	if material_threshold_hslider != null:
		var threshold_value = material.get_shader_parameter("threshold")
		if threshold_value != null:
			material_threshold_hslider.value = threshold_value
			_update_threshold_label(threshold_value)  # 更新标签
		else:
			# 使用默认值
			material_threshold_hslider.value = 0.1
			_update_threshold_label(0.1)  # 更新标签
	
	# 设置softness滑块初始值
	if material_softness_hslider != null:
		var softness_value = material.get_shader_parameter("softness")
		if softness_value != null:
			material_softness_hslider.value = softness_value
			_update_softness_label(softness_value)  # 更新标签
		else:
			# 使用默认值
			material_softness_hslider.value = 0.05
			_update_softness_label(0.05)  # 更新标签
	
	# 设置颜色选择器初始值
	if material_color_picker != null:
		var bg_color_param = material.get_shader_parameter("bg_color")
		if bg_color_param != null:
			# 处理背景颜色参数（可能是 Color 或 Vector3 类型）
			var bg_color: Color
			if bg_color_param is Color:
				bg_color = bg_color_param
			elif bg_color_param is Vector3:
				bg_color = Color(bg_color_param.x, bg_color_param.y, bg_color_param.z, 1.0)
			else:
				# 默认黑色
				bg_color = Color(0, 0, 0, 1)
			material_color_picker.color = bg_color

# 材质threshold滑块值变化事件
func _on_material_threshold_changed(value: float):
	if previewTexture == null:
		return
	
	# 获取PreviewTexture的材质
	var material = previewTexture.material as ShaderMaterial
	if material == null:
		printerr("PreviewTexture材质为空或不是ShaderMaterial")
		return
	
	# 更新材质参数（ShaderMaterial会实时更新）
	material.set_shader_parameter("threshold", value)
	
	# 更新标签值
	_update_threshold_label(value)

# 材质softness滑块值变化事件
func _on_material_softness_changed(value: float):
	if previewTexture == null:
		return
	
	# 获取PreviewTexture的材质
	var material = previewTexture.material as ShaderMaterial
	if material == null:
		printerr("PreviewTexture材质为空或不是ShaderMaterial")
		return
	
	# 更新材质参数（ShaderMaterial会实时更新）
	material.set_shader_parameter("softness", value)
	
	# 更新标签值
	_update_softness_label(value)

# 背景颜色选择器值变化事件
func _on_bg_color_changed(color: Color):
	if previewTexture == null:
		return
	
	# 获取PreviewTexture的材质
	var material = previewTexture.material as ShaderMaterial
	if material == null:
		printerr("PreviewTexture材质为空或不是ShaderMaterial")
		return
	
	# 更新材质参数（ShaderMaterial会实时更新）
	# shader需要vec3格式的颜色，所以只传递RGB分量
	material.set_shader_parameter("bg_color", Vector3(color.r, color.g, color.b))

# 应用背景透明化处理到图像
func _apply_background_transparency(image: Image) -> Image:
	# 获取当前 shader 参数
	var material = previewTexture.material as ShaderMaterial
	if material == null:
		return image
	
	var bg_color_param = material.get_shader_parameter("bg_color")
	var threshold = material.get_shader_parameter("threshold")
	var softness = material.get_shader_parameter("softness")
	
	# 处理背景颜色参数（可能是 Color 或 Vector3 类型）
	var bg_color: Color
	if bg_color_param is Color:
		bg_color = bg_color_param
	elif bg_color_param is Vector3:
		bg_color = Color(bg_color_param.x, bg_color_param.y, bg_color_param.z, 1.0)
	else:
		# 默认黑色
		bg_color = Color(0, 0, 0, 1)
	
	# 创建图像副本进行处理
	var processed_image = image.duplicate()
	
	# 在 Godot 4 中，Image 类没有 lock()/unlock() 方法
	# 我们可以直接访问像素数据
	for y in range(processed_image.get_height()):
		for x in range(processed_image.get_width()):
			var pixel_color = processed_image.get_pixel(x, y)
			
			# 计算颜色差异（欧几里得距离）
			var diff = sqrt(
				pow(pixel_color.r - bg_color.r, 2) +
				pow(pixel_color.g - bg_color.g, 2) +
				pow(pixel_color.b - bg_color.b, 2)
			)
			
			# 应用 smoothstep 函数
			var alpha = 1.0 - _smoothstep(threshold, threshold + softness, diff)
			
			# 设置新透明度
			pixel_color.a = pixel_color.a * (1.0 - alpha)
			processed_image.set_pixel(x, y, pixel_color)
	
	return processed_image

# 更新阈值滑块标签
func _update_threshold_label(value: float):
	if material_thre_hslider_label != null:
		material_thre_hslider_label.text = "%.2f" % value

# 更新柔化滑块标签
func _update_softness_label(value: float):
	if material_soft_hslider_label != null:
		material_soft_hslider_label.text = "%.2f" % value

# smoothstep 辅助函数
func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

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


# ============================================
# 纹理循环控制功能
# ============================================

# 纹理循环按钮状态变化事件
func _on_cycle_check_button_toggled(button_pressed: bool):
	#print("纹理循环按钮状态: %s" % ("循环" if button_pressed else "不循环"))
	pass
