@tool
extends Control

# 外部节点引用
@export var sprite2D2: TextureRect
@export var previewButton: Button
@export var uploadButton: Button  # 上传模型按钮
@export var tietuButton: Button  # 表面贴图按钮
@export var modelCon: Node3D
@export var languageSelector: OptionButton

# 翻译管理器引用
@export var translation_manager: Node

# 预览面板引用
@export var previewPanel: Control  # 使用Control类型，因为preview_panel.gd继承自Control

@export var animat: AnimationPlayer
@export var normalMesh: MeshInstance3D
@export var cameraController: Node  # 相机控制器，需要确认实际类型

# 相机控制UI引用
@export var resetCameraButton: Button

# 数字输入控制UI引用
@export var positionXInput: LineEdit
@export var positionYInput: LineEdit
@export var positionZInput: LineEdit
@export var rotationXInput: LineEdit
@export var rotationYInput: LineEdit
@export var rotationZInput: LineEdit
@export var caPosition: Label
@export var caRotation: Label
@export var cameraInfoLabel: Label

# 模型控制UI引用
@export var modelPositionXInput: LineEdit
@export var modelPositionYInput: LineEdit
@export var modelPositionZInput: LineEdit
@export var modelRotationXInput: LineEdit
@export var modelRotationYInput: LineEdit
@export var modelRotationZInput: LineEdit
@export var moPosition: Label
@export var moRotation: Label

# 模型缩放控制UI引用
@export var modelScaleXInput: LineEdit
@export var modelScaleYInput: LineEdit
@export var modelScaleZInput: LineEdit
@export var scaleModeButton: CheckBox  # 缩放模式切换按钮
@export var moScale: Label
@export var modelLabel: Label

# 环境光
@export var worldEnvironmentEnergyInput: LineEdit

# WorldEnvironment节点引用
@export var worldEnvironment: WorldEnvironment
@export var environmentLabel: Label

# 动画控制UI引用
@export var animationPlayButton: Button
@export var animationTimeSlider: HSlider
@export var animationTimeLabel: Label
@export var animationTimeInput: LineEdit  # 时间输入框
@export var animationLabel: Label

# ModelContainer节点引用
var modelContainer: Node3D

# 所有MeshInstance3D的列表
var allMeshes: Array[MeshInstance3D] = []

# 缩放控制相关变量
var is_uniform_scale: bool = true  # 是否为统一缩放模式

# 动画控制相关变量
var is_animation_playing: bool = false
var is_animation_looping: bool = false  # 循环播放标志
var current_animation_name: String = ""
var animation_length: float = 0.0
var current_animation_time: float = 0.0

# 控制模式相关变量
var is_controlling_directional_light: bool = false  # 是否正在控制定向光（而非相机）

# 窗口焦点状态相关变量
var parent_window: Window = null
var was_window_focused: bool = true

# 循环播放UI引用
@export var loopCheckBox: CheckBox

# 文件选择对话框
@export var fileDialog: FileDialog
@export var tietuDialog: FileDialog

# 箭头键步进值配置（可在编辑器中调整）
@export var arrowStepNormal: float = 0.1  # 无修饰键时的步进值
@export var arrowStepWithShift: float = 1.0  # Shift + 箭头时的步进值
@export var arrowStepWithCtrl: float = 0.01  # Ctrl + 箭头时的步进值

@export var directionalLight: DirectionalLight3D
@export var directionalLightCheckBox: CheckBox
@export var directionalLightRoCheckBox: CheckBox
@export var directionalLightLineEdit: LineEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().transparent_bg = true
	
	# 获取预览按钮并连接信号
	if previewButton:
		previewButton.pressed.connect(_on_preview_button_pressed)
	
	# 获取上传按钮并连接信号
	if uploadButton:
		uploadButton.pressed.connect(_on_upload_button_pressed)
	
	# 获取表面贴图按钮并连接信号，初始禁用
	if tietuButton:
		tietuButton.pressed.connect(_on_tietu_button_pressed)
		tietuButton.disabled = true  # 初始禁用，上传模型后才能使用
	
	# 获取语言切换按钮并连接信号
	if languageSelector:
		languageSelector.item_selected.connect(_on_language_selected)
	

	# 设置预览面板的外部节点引用
	if previewPanel != null:
		# 尝试将previewPanel转换为实际的脚本类型
		if previewPanel.has_method("set_external_references"):
			# 如果预览面板有设置外部引用的方法，使用它
			previewPanel.set_external_references(sprite2D2, animat, normalMesh)
		else:
			# 否则直接设置属性（向后兼容）
			previewPanel.sprite2D2 = sprite2D2
			previewPanel.animat = animat
			previewPanel.normalMesh = normalMesh
	
	# 获取ModelContainer节点
	modelContainer = modelCon
	
	
	# 初始化相机控制
	initialize_camera_control()
	
	# 初始化模型控制
	initialize_model_control()
	
	# 初始化缩放控制
	initialize_scale_control()
	
	# 初始化环境光控制
	initialize_environment_control()
	
	# 初始化文件选择对话框
	initialize_file_dialog()
	
	# 初始化动画控制
	initialize_animation_control()
	
	# 初始化循环播放控制
	initialize_loop_control()

	# 初始化定向光控制
	initialize_directional_light_control()

	# 初始化插件UI翻译
	update_plugin_ui_translations()
	
	# 获取父窗口引用
	parent_window = get_parent_window()
	if parent_window != null:
		was_window_focused = parent_window.has_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# 实时更新模型输入框的值
	update_model_input_fields()
	
	# 实时更新环境光强度输入框的值
	update_environment_energy_input()
	
	# 更新动画状态
	update_animation_state(delta)
	
	# 监控窗口焦点状态变化
	monitor_window_focus()

# 处理输入事件
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 检查点击是否在输入框内
		if not is_click_inside_input_fields(event.position):
			# 释放所有输入框的焦点
			release_all_input_focus()

# 检查点击是否在输入框内
func is_click_inside_input_fields(click_position: Vector2) -> bool:
	# 检查相机位置输入框
	if positionXInput and is_point_in_control(positionXInput, click_position):
		return true
	if positionYInput and is_point_in_control(positionYInput, click_position):
		return true
	if positionZInput and is_point_in_control(positionZInput, click_position):
		return true
	
	# 检查相机旋转输入框
	if rotationXInput and is_point_in_control(rotationXInput, click_position):
		return true
	if rotationYInput and is_point_in_control(rotationYInput, click_position):
		return true
	if rotationZInput and is_point_in_control(rotationZInput, click_position):
		return true
	
	# 检查模型位置输入框
	if modelPositionXInput and is_point_in_control(modelPositionXInput, click_position):
		return true
	if modelPositionYInput and is_point_in_control(modelPositionYInput, click_position):
		return true
	if modelPositionZInput and is_point_in_control(modelPositionZInput, click_position):
		return true
	
	# 检查模型旋转输入框
	if modelRotationXInput and is_point_in_control(modelRotationXInput, click_position):
		return true
	if modelRotationYInput and is_point_in_control(modelRotationYInput, click_position):
		return true
	if modelRotationZInput and is_point_in_control(modelRotationZInput, click_position):
		return true
	
	# 检查模型缩放输入框
	if modelScaleXInput and is_point_in_control(modelScaleXInput, click_position):
		return true
	if modelScaleYInput and is_point_in_control(modelScaleYInput, click_position):
		return true
	if modelScaleZInput and is_point_in_control(modelScaleZInput, click_position):
		return true
	
	# 检查环境光强度输入框
	if worldEnvironmentEnergyInput and is_point_in_control(worldEnvironmentEnergyInput, click_position):
		return true
	
	# 检查动画时间输入框
	if animationTimeInput and is_point_in_control(animationTimeInput, click_position):
		return true
	
	# 检查定向光强度输入框
	if directionalLightLineEdit and is_point_in_control(directionalLightLineEdit, click_position):
		return true
	
	return false

# 检查点是否在控件内
func is_point_in_control(control: Control, point: Vector2) -> bool:
	# 获取控件的全局位置和大小
	var global_pos: Vector2 = control.global_position
	var size: Vector2 = control.size
	
	# 检查点是否在控件矩形内
	return point.x >= global_pos.x and point.x <= global_pos.x + size.x and \
		   point.y >= global_pos.y and point.y <= global_pos.y + size.y

# 释放所有输入框的焦点
func release_all_input_focus():
	if positionXInput and positionXInput.has_focus():
		positionXInput.release_focus()
	if positionYInput and positionYInput.has_focus():
		positionYInput.release_focus()
	if positionZInput and positionZInput.has_focus():
		positionZInput.release_focus()
	
	if rotationXInput and rotationXInput.has_focus():
		rotationXInput.release_focus()
	if rotationYInput and rotationYInput.has_focus():
		rotationYInput.release_focus()
	if rotationZInput and rotationZInput.has_focus():
		rotationZInput.release_focus()
	
	if modelPositionXInput and modelPositionXInput.has_focus():
		modelPositionXInput.release_focus()
	if modelPositionYInput and modelPositionYInput.has_focus():
		modelPositionYInput.release_focus()
	if modelPositionZInput and modelPositionZInput.has_focus():
		modelPositionZInput.release_focus()
	
	if modelRotationXInput and modelRotationXInput.has_focus():
		modelRotationXInput.release_focus()
	if modelRotationYInput and modelRotationYInput.has_focus():
		modelRotationYInput.release_focus()
	if modelRotationZInput and modelRotationZInput.has_focus():
		modelRotationZInput.release_focus()
	
	if modelScaleXInput and modelScaleXInput.has_focus():
		modelScaleXInput.release_focus()
	if modelScaleYInput and modelScaleYInput.has_focus():
		modelScaleYInput.release_focus()
	if modelScaleZInput and modelScaleZInput.has_focus():
		modelScaleZInput.release_focus()
	
	if worldEnvironmentEnergyInput and worldEnvironmentEnergyInput.has_focus():
		worldEnvironmentEnergyInput.release_focus()
	
	if animationTimeInput and animationTimeInput.has_focus():
		animationTimeInput.release_focus()
	
	if directionalLightLineEdit and directionalLightLineEdit.has_focus():
		directionalLightLineEdit.release_focus()

# 预览按钮点击事件
func _on_preview_button_pressed():
	# 禁用相机控制
	if cameraController and cameraController.has_method("disable_camera_control"):
		cameraController.disable_camera_control()
		cameraController.set_preview_panel_state(true)
	
	if previewPanel and previewPanel.has_method("show_preview"):
		previewPanel.show_preview()

# 当预览面板关闭时重新启用相机控制
func on_preview_closed():
	# 重新启用相机控制
	if cameraController and cameraController.has_method("enable_camera_control"):
		cameraController.enable_camera_control()
		cameraController.set_preview_panel_state(false)

# 上传按钮点击事件
func _on_upload_button_pressed():
	if fileDialog:
		fileDialog.popup_centered()

# 语言选择事件
func _on_language_selected(index: int):
	var selected_language: String = languageSelector.get_item_text(index)
	
	# 设置插件语言
	set_plugin_language(selected_language)
	# 更新插件UI的翻译
	update_plugin_ui_translations()

# 获取翻译文本（包装方法）
func get_translation(id: String) -> String:
	if translation_manager and translation_manager.has_method("get_translation"):
		return translation_manager.get_translation(id)
	else:
		return id

# 设置插件语言（包装方法）
func set_plugin_language(locale: String):
	if translation_manager and translation_manager.has_method("set_language"):
		translation_manager.set_language(locale)
		# 更新插件UI的翻译
		update_plugin_ui_translations()

# 获取插件当前语言（包装方法）
func get_plugin_language() -> String:
	if translation_manager and translation_manager.has_method("get_current_language"):
		return translation_manager.get_current_language()
	else:
		return "zh_CN"

# 更新插件UI的翻译
func update_plugin_ui_translations():
	# 更新按钮文本
	if previewButton:
		previewButton.text = get_translation("预览")
	if uploadButton:
		uploadButton.text = get_translation("上传模型")
	if resetCameraButton:
		if is_controlling_directional_light:
			resetCameraButton.text = get_translation("重置")
		else:
			resetCameraButton.text = get_translation("重置")
	
	if previewPanel.previewExportButton:
		previewPanel.previewExportButton.text= get_translation("导出当前贴图")
	if previewPanel.putongExportButton:
		previewPanel.putongExportButton.text= get_translation("导出普通贴图")
	if previewPanel.normalExportButton:
		previewPanel.normalExportButton.text= get_translation("导出法线贴图")
	if previewPanel.exportBothButton:
		previewPanel.exportBothButton.text= get_translation("导出两种材质")
	if previewPanel.batchExportButton:
		previewPanel.batchExportButton.text= get_translation("批量导出")
	if previewPanel.resetZoomButton:
		previewPanel.resetZoomButton.text= get_translation("重置")
	
	# 注意：previewPanel的按钮需要根据实际结构更新
	# 这里只是示例，实际需要根据场景结构更新所有标签
	
	# 更新复选框文本
	if loopCheckBox:
		loopCheckBox.text = get_translation("循环")
	if scaleModeButton:
		scaleModeButton.text = get_translation("统一缩放")
	if caPosition:
		caPosition.text = get_translation("位置")
	if caRotation:
		caRotation.text = get_translation("旋转")
	if moPosition:
		moPosition.text = get_translation("位置")
	if moRotation:
		moRotation.text = get_translation("旋转")
	if moScale:
		moScale.text = get_translation("缩放")
	if environmentLabel:
		environmentLabel.text = get_translation("环境光强度")
	if modelLabel:
		modelLabel.text = get_translation("模型")
	if cameraInfoLabel:
		if is_controlling_directional_light:
			cameraInfoLabel.text = get_translation("灯光")
		else:
			cameraInfoLabel.text = get_translation("相机")
	if animationLabel:
		animationLabel.text = get_translation("动画")
	
	if previewPanel.loopCheckBox:
		previewPanel.loopCheckBox.text= get_translation("循环")
	if previewPanel.widthLabel:
		previewPanel.widthLabel.text= get_translation("宽度")
	if previewPanel.heightLabel:
		previewPanel.heightLabel.text= get_translation("高度")
	if previewPanel.interpolationLabel:
		previewPanel.interpolationLabel.text= get_translation("插值算法")
	if previewPanel.materialLabel:
		previewPanel.materialLabel.text= get_translation("材质")
	if previewPanel.animationLabel:
		previewPanel.animationLabel.text= get_translation("动画")
	
	# 更新占位符文本
	if worldEnvironmentEnergyInput:
		worldEnvironmentEnergyInput.placeholder_text = get_translation("环境光强度")
	
	if previewPanel.animationLabel:
		previewPanel.frameIntervalInput.placeholder_text = get_translation("批量导出(秒)")
	
	if previewPanel.materialSelector:
		previewPanel.materialSelector.set_item_text(0,get_translation("普通材质"))
	if previewPanel.materialSelector:
		previewPanel.materialSelector.set_item_text(1,get_translation("法线材质"))
	
	# 更新定向光控件文本
	if directionalLightCheckBox:
		directionalLightCheckBox.text = get_translation("灯光")
	if directionalLightLineEdit:
		directionalLightLineEdit.placeholder_text = get_translation("灯光强度")
	if directionalLightRoCheckBox:
		directionalLightRoCheckBox.text = get_translation("控制灯光")

	if fileDialog:
		fileDialog.title= get_translation("选择3D模型")
	if previewPanel.saveFileDialog:
		previewPanel.saveFileDialog.title= get_translation("保存图片")
	if previewPanel.selectDirDialog:
		previewPanel.selectDirDialog.title= get_translation("保存文件夹")

# 初始化相机控制
func initialize_camera_control():
	if cameraController and resetCameraButton:
		# 设置相机控制UI引用
		if cameraController.has_method("set_ui_references"):
			cameraController.set_ui_references(resetCameraButton)
		
		# 设置数字输入框引用
		if positionXInput and positionYInput and positionZInput and \
		   rotationXInput and rotationYInput and rotationZInput:
			if cameraController.has_method("set_input_field_references"):
				cameraController.set_input_field_references(
					positionXInput, positionYInput, positionZInput,
					rotationXInput, rotationYInput, rotationZInput
				)
		
		# 连接数字输入控制信号（回车键和焦点丢失事件）
		connect_input_field_events()

# 连接输入框事件
func connect_input_field_events():
	# 连接位置输入框事件
	if positionXInput:
		positionXInput.text_submitted.connect(_on_position_input_submitted)
		positionXInput.focus_exited.connect(_on_position_input_focus_exited)
		positionXInput.focus_entered.connect(_on_input_field_focus_entered)
		positionXInput.focus_exited.connect(_on_input_field_focus_exited)
		positionXInput.gui_input.connect(_on_input_field_gui_input)
	
	if positionYInput:
		positionYInput.text_submitted.connect(_on_position_input_submitted)
		positionYInput.focus_exited.connect(_on_position_input_focus_exited)
		positionYInput.focus_entered.connect(_on_input_field_focus_entered)
		positionYInput.focus_exited.connect(_on_input_field_focus_exited)
		positionYInput.gui_input.connect(_on_input_field_gui_input)
	
	if positionZInput:
		positionZInput.text_submitted.connect(_on_position_input_submitted)
		positionZInput.focus_exited.connect(_on_position_input_focus_exited)
		positionZInput.focus_entered.connect(_on_input_field_focus_entered)
		positionZInput.focus_exited.connect(_on_input_field_focus_exited)
		positionZInput.gui_input.connect(_on_input_field_gui_input)
	
	# 连接旋转输入框事件
	if rotationXInput:
		rotationXInput.text_submitted.connect(_on_rotation_input_submitted)
		rotationXInput.focus_exited.connect(_on_rotation_input_focus_exited)
		rotationXInput.focus_entered.connect(_on_input_field_focus_entered)
		rotationXInput.focus_exited.connect(_on_input_field_focus_exited)
		rotationXInput.gui_input.connect(_on_input_field_gui_input)
	
	if rotationYInput:
		rotationYInput.text_submitted.connect(_on_rotation_input_submitted)
		rotationYInput.focus_exited.connect(_on_rotation_input_focus_exited)
		rotationYInput.focus_entered.connect(_on_input_field_focus_entered)
		rotationYInput.focus_exited.connect(_on_input_field_focus_exited)
		rotationYInput.gui_input.connect(_on_input_field_gui_input)
	
	if rotationZInput:
		rotationZInput.text_submitted.connect(_on_rotation_input_submitted)
		rotationZInput.focus_exited.connect(_on_rotation_input_focus_exited)
		rotationZInput.focus_entered.connect(_on_input_field_focus_entered)
		rotationZInput.focus_exited.connect(_on_input_field_focus_exited)
		rotationZInput.gui_input.connect(_on_input_field_gui_input)

# 输入框获得焦点事件
func _on_input_field_focus_entered():
	if cameraController and cameraController.has_method("set_input_field_focus_state"):
		cameraController.set_input_field_focus_state(true)

# 输入框失去焦点事件
func _on_input_field_focus_exited():
	# 检查是否还有其他输入框有焦点
	var any_input_has_focus: bool = false
	
	# 检查相机控制输入框
	if positionXInput and positionXInput.has_focus():
		any_input_has_focus = true
	if positionYInput and positionYInput.has_focus():
		any_input_has_focus = true
	if positionZInput and positionZInput.has_focus():
		any_input_has_focus = true
	if rotationXInput and rotationXInput.has_focus():
		any_input_has_focus = true
	if rotationYInput and rotationYInput.has_focus():
		any_input_has_focus = true
	if rotationZInput and rotationZInput.has_focus():
		any_input_has_focus = true
	
	# 检查模型控制输入框
	if modelPositionXInput and modelPositionXInput.has_focus():
		any_input_has_focus = true
	if modelPositionYInput and modelPositionYInput.has_focus():
		any_input_has_focus = true
	if modelPositionZInput and modelPositionZInput.has_focus():
		any_input_has_focus = true
	if modelRotationXInput and modelRotationXInput.has_focus():
		any_input_has_focus = true
	if modelRotationYInput and modelRotationYInput.has_focus():
		any_input_has_focus = true
	if modelRotationZInput and modelRotationZInput.has_focus():
		any_input_has_focus = true
	
	# 检查模型缩放输入框
	if modelScaleXInput and modelScaleXInput.has_focus():
		any_input_has_focus = true
	if modelScaleYInput and modelScaleYInput.has_focus():
		any_input_has_focus = true
	if modelScaleZInput and modelScaleZInput.has_focus():
		any_input_has_focus = true
	
	# 检查环境光输入框
	if worldEnvironmentEnergyInput and worldEnvironmentEnergyInput.has_focus():
		any_input_has_focus = true
	
	# 检查动画时间输入框
	if animationTimeInput and animationTimeInput.has_focus():
		any_input_has_focus = true
	
	# 检查定向光强度输入框
	if directionalLightLineEdit and directionalLightLineEdit.has_focus():
		any_input_has_focus = true
	
	if cameraController and cameraController.has_method("set_input_field_focus_state"):
		cameraController.set_input_field_focus_state(any_input_has_focus)

# 位置输入框回车键提交事件
func _on_position_input_submitted(new_text: String):
	apply_position_from_input()

# 位置输入框焦点丢失事件
func _on_position_input_focus_exited():
	apply_position_from_input()

# 旋转输入框回车键提交事件
func _on_rotation_input_submitted(new_text: String):
	apply_rotation_from_input()

# 旋转输入框焦点丢失事件
func _on_rotation_input_focus_exited():
	apply_rotation_from_input()

# 输入框GUI输入事件（上下箭头微调）
func _on_input_field_gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		# 检查是否是上下箭头键
		if event.keycode == KEY_UP or event.keycode == KEY_DOWN:
			# 获取当前有焦点的输入框
			var focused_input: LineEdit = get_focused_input_field()
			if focused_input == null:
				return
			
			# 检查修饰键状态
			var shift_pressed: bool = event.shift_pressed
			var ctrl_pressed: bool = event.ctrl_pressed
			
			# 计算步进值
			var step: float = calculate_step(shift_pressed, ctrl_pressed)
			if event.keycode == KEY_DOWN:
				step = -step  # 向下箭头减少值
			
			# 调整输入框的值
			adjust_input_field_value(focused_input, step)
			
			# 根据输入框类型应用更改
			apply_input_field_change(focused_input)
			
			# 接受事件，防止进一步传播
			get_viewport().set_input_as_handled()

# 从输入框应用位置
func apply_position_from_input():
	if cameraController == null:
		return
	
	if positionXInput == null or positionYInput == null or positionZInput == null:
		return
	
	var x: float = 0.0
	var y: float = 0.0
	var z: float = 0.0
	
	# 使用is_valid_float检查输入是否有效
	if not positionXInput.text.is_empty() and positionXInput.text.is_valid_float():
		x = float(positionXInput.text)
	if not positionYInput.text.is_empty() and positionYInput.text.is_valid_float():
		y = float(positionYInput.text)
	if not positionZInput.text.is_empty() and positionZInput.text.is_valid_float():
		z = float(positionZInput.text)
	
	if cameraController.has_method("set_position"):
		cameraController.set_position(x, y, z)

# 从输入框应用旋转
func apply_rotation_from_input():
	if cameraController == null:
		return
	
	if rotationXInput == null or rotationYInput == null or rotationZInput == null:
		return
	
	var x: float = 0.0
	var y: float = 0.0
	var z: float = 0.0
	
	# 使用is_valid_float检查输入是否有效
	if not rotationXInput.text.is_empty() and rotationXInput.text.is_valid_float():
		x = float(rotationXInput.text)
	if not rotationYInput.text.is_empty() and rotationYInput.text.is_valid_float():
		y = float(rotationYInput.text)
	if not rotationZInput.text.is_empty() and rotationZInput.text.is_valid_float():
		z = float(rotationZInput.text)
	
	if cameraController.has_method("set_rotation"):
		cameraController.set_rotation(x, y, z)

# 初始化模型控制
func initialize_model_control():
	if modelContainer == null:
		return
	
	# 连接模型输入框事件
	connect_model_input_field_events()
	
	# 更新初始模型状态到输入框
	update_model_input_fields()
	

# 初始化缩放控制
func initialize_scale_control():
	if modelContainer == null:
		return
	
	# 连接缩放输入框事件
	connect_scale_input_field_events()
	
	# 连接缩放模式按钮事件
	if scaleModeButton != null:
		scaleModeButton.toggled.connect(_on_scale_mode_button_toggled)
		# 设置初始状态：勾选表示统一缩放
		scaleModeButton.button_pressed = is_uniform_scale
	
	# 更新初始缩放状态到输入框
	update_scale_input_fields()
	

# 初始化环境光控制
func initialize_environment_control():
	if worldEnvironment == null or worldEnvironment.environment == null:
		return
	
	# 连接环境光输入框事件
	connect_environment_input_field_events()
	
	# 更新初始环境光强度到输入框
	update_environment_energy_input()
	

# 初始化文件选择对话框
func initialize_file_dialog():
	# fileDialog = FileDialog.new()
	# fileDialog.title = "选择3D模型文件"
	# fileDialog.access = FileDialog.ACCESS_FILESYSTEM
	# fileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	# fileDialog.filters = PackedStringArray(["*.fbx;FBX文件", "*.gltf;GLTF文件", "*.glb;GLB文件", "*.obj;OBJ文件"])
	# fileDialog.size = Vector2i(800, 600)
	
	# 连接文件选择事件
	fileDialog.file_selected.connect(_on_file_selected)
	
	# 初始化表面贴图对话框
	# if tietuDialog != null:
	# 	# 设置对话框属性
	# 	tietuDialog.title = "选择表面贴图图片"
	# 	tietuDialog.access = FileDialog.ACCESS_FILESYSTEM
	# 	tietuDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	# 	tietuDialog.filters = PackedStringArray(["*.png;PNG图片", "*.jpg;JPG图片", "*.jpeg;JPEG图片", "*.bmp;BMP图片", "*.tga;TGA图片"])
	# 	tietuDialog.size = Vector2i(800, 600)
		
	# 连接文件选择事件
	tietuDialog.file_selected.connect(_on_tietu_file_selected)
	
	# 将对话框添加到场景中
	# add_child(fileDialog)
	

# 初始化动画控制
func initialize_animation_control():
	if animationPlayButton != null and animationTimeSlider != null and animationTimeLabel != null:
		# 连接按钮信号
		animationPlayButton.pressed.connect(_on_animation_play_button_pressed)
		
		# 连接滑块信号
		animationTimeSlider.value_changed.connect(_on_animation_time_slider_changed)
		
		# 连接时间输入框信号
		if animationTimeInput != null:
			animationTimeInput.text_submitted.connect(_on_animation_time_input_submitted)
			animationTimeInput.focus_exited.connect(_on_animation_time_input_focus_exited)
			animationTimeInput.focus_entered.connect(_on_input_field_focus_entered)
			animationTimeInput.focus_exited.connect(_on_input_field_focus_exited)
			animationTimeInput.gui_input.connect(_on_input_field_gui_input)
		
		# 初始化动画状态
		update_animation_ui()
		

# 初始化循环播放控制
func initialize_loop_control():
	if loopCheckBox != null:
		loopCheckBox.toggled.connect(_on_loop_check_box_toggled)

# 更新模型输入框的值
func update_model_input_fields():
	if modelContainer == null:
		return
	
	# 更新模型位置输入框
	if modelPositionXInput != null and not modelPositionXInput.has_focus():
		modelPositionXInput.text = "%.2f" % modelContainer.position.x
	if modelPositionYInput != null and not modelPositionYInput.has_focus():
		modelPositionYInput.text = "%.2f" % modelContainer.position.y
	if modelPositionZInput != null and not modelPositionZInput.has_focus():
		modelPositionZInput.text = "%.2f" % modelContainer.position.z
	
	# 更新模型旋转输入框（转换为角度）
	if modelRotationXInput != null and not modelRotationXInput.has_focus():
		modelRotationXInput.text = "%.2f" % rad_to_deg(modelContainer.rotation.x)
	if modelRotationYInput != null and not modelRotationYInput.has_focus():
		modelRotationYInput.text = "%.2f" % rad_to_deg(modelContainer.rotation.y)
	if modelRotationZInput != null and not modelRotationZInput.has_focus():
		modelRotationZInput.text = "%.2f" % rad_to_deg(modelContainer.rotation.z)
	
	# 更新模型缩放输入框
	update_scale_input_fields()

# 更新环境光强度输入框的值
func update_environment_energy_input():
	if worldEnvironment == null or worldEnvironment.environment == null or worldEnvironmentEnergyInput == null:
		return
	
	# 只在输入框没有焦点时更新，避免干扰用户输入
	if not worldEnvironmentEnergyInput.has_focus():
		var current_energy: float = worldEnvironment.environment.ambient_light_energy
		worldEnvironmentEnergyInput.text = "%.2f" % current_energy

# 更新动画状态
func update_animation_state(delta: float):
	if animat == null or not is_animation_playing or current_animation_name.is_empty():
		return
	
	# 更新当前动画时间
	current_animation_time = animat.current_animation_position
	
	# 更新UI
	update_animation_ui()
	
	# 检查动画是否播放完毕
	if current_animation_time >= animation_length - 0.005:
		if is_animation_looping:
			# 循环播放：重新开始
			current_animation_time = 0
			animat.seek(0)
		else:
			# 非循环播放：停止播放
			stop_animation()

# 文件选择事件处理
func _on_file_selected(file_path: String):
	if file_path.is_empty():
		return
	
	
	# 检查模型是否已导入
	var is_imported: bool = _check_if_model_is_imported(file_path)
	
	if is_imported:
		# 已导入：直接加载
		_load_model_directly(file_path)
		normalMesh.visible=false
		previewPanel.materialSelector.select(0)
	else:
		# 未导入：执行完整导入流程
		_import_model_file(file_path)
		normalMesh.visible=false
		previewPanel.materialSelector.select(0)
	
	# 注意：current_model_path 现在在 _import_model_file() 和 _load_model_directly() 中设置
	# 这里不再覆盖，以确保保存的是项目内路径而不是原始外部路径
	
	# 启用表面贴图按钮
	if tietuButton != null:
		tietuButton.disabled = false
		print("表面贴图按钮已启用")


# 缩放模式按钮切换事件
func _on_scale_mode_button_toggled(toggled: bool):
	# 切换缩放模式
	is_uniform_scale = toggled

# 连接模型输入框事件
func connect_model_input_field_events():
	# 连接模型位置输入框事件
	if modelPositionXInput != null:
		modelPositionXInput.text_submitted.connect(_on_model_position_input_submitted)
		modelPositionXInput.focus_exited.connect(_on_model_position_input_focus_exited)
		modelPositionXInput.focus_entered.connect(_on_input_field_focus_entered)
		modelPositionXInput.focus_exited.connect(_on_input_field_focus_exited)
		modelPositionXInput.gui_input.connect(_on_input_field_gui_input)
	
	if modelPositionYInput != null:
		modelPositionYInput.text_submitted.connect(_on_model_position_input_submitted)
		modelPositionYInput.focus_exited.connect(_on_model_position_input_focus_exited)
		modelPositionYInput.focus_entered.connect(_on_input_field_focus_entered)
		modelPositionYInput.focus_exited.connect(_on_input_field_focus_exited)
		modelPositionYInput.gui_input.connect(_on_input_field_gui_input)
	
	if modelPositionZInput != null:
		modelPositionZInput.text_submitted.connect(_on_model_position_input_submitted)
		modelPositionZInput.focus_exited.connect(_on_model_position_input_focus_exited)
		modelPositionZInput.focus_entered.connect(_on_input_field_focus_entered)
		modelPositionZInput.focus_exited.connect(_on_input_field_focus_exited)
		modelPositionZInput.gui_input.connect(_on_input_field_gui_input)
	
	# 连接模型旋转输入框事件
	if modelRotationXInput != null:
		modelRotationXInput.text_submitted.connect(_on_model_rotation_input_submitted)
		modelRotationXInput.focus_exited.connect(_on_model_rotation_input_focus_exited)
		modelRotationXInput.focus_entered.connect(_on_input_field_focus_entered)
		modelRotationXInput.focus_exited.connect(_on_input_field_focus_exited)
		modelRotationXInput.gui_input.connect(_on_input_field_gui_input)
	
	if modelRotationYInput != null:
		modelRotationYInput.text_submitted.connect(_on_model_rotation_input_submitted)
		modelRotationYInput.focus_exited.connect(_on_model_rotation_input_focus_exited)
		modelRotationYInput.focus_entered.connect(_on_input_field_focus_entered)
		modelRotationYInput.focus_exited.connect(_on_input_field_focus_exited)
		modelRotationYInput.gui_input.connect(_on_input_field_gui_input)
	
	if modelRotationZInput != null:
		modelRotationZInput.text_submitted.connect(_on_model_rotation_input_submitted)
		modelRotationZInput.focus_exited.connect(_on_model_rotation_input_focus_exited)
		modelRotationZInput.focus_entered.connect(_on_input_field_focus_entered)
		modelRotationZInput.focus_exited.connect(_on_input_field_focus_exited)
		modelRotationZInput.gui_input.connect(_on_input_field_gui_input)

# 连接缩放输入框事件
func connect_scale_input_field_events():
	# 连接缩放输入框事件
	if modelScaleXInput != null:
		modelScaleXInput.text_submitted.connect(_on_scale_input_submitted)
		modelScaleXInput.focus_exited.connect(_on_scale_input_focus_exited)
		modelScaleXInput.focus_entered.connect(_on_input_field_focus_entered)
		modelScaleXInput.focus_exited.connect(_on_input_field_focus_exited)
		modelScaleXInput.gui_input.connect(_on_input_field_gui_input)
	
	if modelScaleYInput != null:
		modelScaleYInput.text_submitted.connect(_on_scale_input_submitted)
		modelScaleYInput.focus_exited.connect(_on_scale_input_focus_exited)
		modelScaleYInput.focus_entered.connect(_on_input_field_focus_entered)
		modelScaleYInput.focus_exited.connect(_on_input_field_focus_exited)
		modelScaleYInput.gui_input.connect(_on_input_field_gui_input)
	
	if modelScaleZInput != null:
		modelScaleZInput.text_submitted.connect(_on_scale_input_submitted)
		modelScaleZInput.focus_exited.connect(_on_scale_input_focus_exited)
		modelScaleZInput.focus_entered.connect(_on_input_field_focus_entered)
		modelScaleZInput.focus_exited.connect(_on_input_field_focus_exited)
		modelScaleZInput.gui_input.connect(_on_input_field_gui_input)

# 连接环境光输入框事件
func connect_environment_input_field_events():
	if worldEnvironmentEnergyInput != null:
		worldEnvironmentEnergyInput.text_submitted.connect(_on_environment_energy_input_submitted)
		worldEnvironmentEnergyInput.focus_exited.connect(_on_environment_energy_input_focus_exited)
		worldEnvironmentEnergyInput.focus_entered.connect(_on_input_field_focus_entered)
		worldEnvironmentEnergyInput.focus_exited.connect(_on_input_field_focus_exited)
		worldEnvironmentEnergyInput.gui_input.connect(_on_input_field_gui_input)

# 模型位置输入框回车键提交事件
func _on_model_position_input_submitted(new_text: String):
	apply_model_position_from_input()

# 模型位置输入框焦点丢失事件
func _on_model_position_input_focus_exited():
	apply_model_position_from_input()

# 模型旋转输入框回车键提交事件
func _on_model_rotation_input_submitted(new_text: String):
	apply_model_rotation_from_input()

# 模型旋转输入框焦点丢失事件
func _on_model_rotation_input_focus_exited():
	apply_model_rotation_from_input()

# 缩放输入框回车键提交事件
func _on_scale_input_submitted(new_text: String):
	apply_model_scale_from_input()

# 缩放输入框焦点丢失事件
func _on_scale_input_focus_exited():
	apply_model_scale_from_input()

# 环境光强度输入框回车键提交事件
func _on_environment_energy_input_submitted(new_text: String):
	apply_environment_energy_from_input()

# 环境光强度输入框焦点丢失事件
func _on_environment_energy_input_focus_exited():
	apply_environment_energy_from_input()

# 从输入框应用模型位置
func apply_model_position_from_input():
	if modelContainer == null:
		return
	
	if modelPositionXInput == null or modelPositionYInput == null or modelPositionZInput == null:
		return
	
	var x: float = 0.0
	var y: float = 0.0
	var z: float = 0.0
	
	# 使用is_valid_float检查输入是否有效
	if not modelPositionXInput.text.is_empty() and modelPositionXInput.text.is_valid_float():
		x = float(modelPositionXInput.text)
	if not modelPositionYInput.text.is_empty() and modelPositionYInput.text.is_valid_float():
		y = float(modelPositionYInput.text)
	if not modelPositionZInput.text.is_empty() and modelPositionZInput.text.is_valid_float():
		z = float(modelPositionZInput.text)
	
	modelContainer.position = Vector3(x, y, z)

# 从输入框应用模型旋转
func apply_model_rotation_from_input():
	if modelContainer == null:
		return
	
	if modelRotationXInput == null or modelRotationYInput == null or modelRotationZInput == null:
		return
	
	var x: float = 0.0
	var y: float = 0.0
	var z: float = 0.0
	
	# 使用is_valid_float检查输入是否有效
	if not modelRotationXInput.text.is_empty() and modelRotationXInput.text.is_valid_float():
		x = float(modelRotationXInput.text)
	if not modelRotationYInput.text.is_empty() and modelRotationYInput.text.is_valid_float():
		y = float(modelRotationYInput.text)
	if not modelRotationZInput.text.is_empty() and modelRotationZInput.text.is_valid_float():
		z = float(modelRotationZInput.text)
	
	# 将角度转换为弧度
	var x_rad: float = deg_to_rad(x)
	var y_rad: float = deg_to_rad(y)
	var z_rad: float = deg_to_rad(z)
	
	modelContainer.rotation = Vector3(x_rad, y_rad, z_rad)

# 从输入框应用模型缩放
func apply_model_scale_from_input():
	if modelContainer == null:
		return
	
	if modelScaleXInput == null or modelScaleYInput == null or modelScaleZInput == null:
		return
	
	var x: float = 1.0
	var y: float = 1.0
	var z: float = 1.0
	
	# 使用is_valid_float检查输入是否有效
	if not modelScaleXInput.text.is_empty() and modelScaleXInput.text.is_valid_float():
		x = float(modelScaleXInput.text)
	if not modelScaleYInput.text.is_empty() and modelScaleYInput.text.is_valid_float():
		y = float(modelScaleYInput.text)
	if not modelScaleZInput.text.is_empty() and modelScaleZInput.text.is_valid_float():
		z = float(modelScaleZInput.text)
	
	# 如果是统一缩放模式，确保三个值相同
	if is_uniform_scale:
		# 使用X轴的值作为统一缩放值
		var uniform_scale: float = x
		# 检查哪个输入框有焦点，使用该输入框的值
		if modelScaleYInput != null and modelScaleYInput.has_focus():
			uniform_scale = y
		elif modelScaleZInput != null and modelScaleZInput.has_focus():
			uniform_scale = z
		
		x = uniform_scale
		y = uniform_scale
		z = uniform_scale
		
		# 更新输入框显示
		if modelScaleXInput != null and not modelScaleXInput.has_focus():
			modelScaleXInput.text = "%.2f" % uniform_scale
		if modelScaleYInput != null and not modelScaleYInput.has_focus():
			modelScaleYInput.text = "%.2f" % uniform_scale
		if modelScaleZInput != null and not modelScaleZInput.has_focus():
			modelScaleZInput.text = "%.2f" % uniform_scale
	
	modelContainer.scale = Vector3(x, y, z)

# 从输入框应用环境光强度
func apply_environment_energy_from_input():
	if worldEnvironment == null or worldEnvironment.environment == null or worldEnvironmentEnergyInput == null:
		return
	
	var energy: float = 1.0
	if not worldEnvironmentEnergyInput.text.is_empty() and worldEnvironmentEnergyInput.text.is_valid_float():
		energy = float(worldEnvironmentEnergyInput.text)
	
	# 限制范围在合理值内（0.0-16.0）
	energy = clamp(energy, 0.0, 16.0)
	
	worldEnvironment.environment.ambient_light_energy = energy
	
	# 更新输入框显示（确保显示的是实际设置的值）
	update_environment_energy_input()

# 更新缩放输入框的值
func update_scale_input_fields():
	if modelContainer == null:
		return
	
	# 更新模型缩放输入框
	if modelScaleXInput != null and not modelScaleXInput.has_focus():
		modelScaleXInput.text = "%.2f" % modelContainer.scale.x
	if modelScaleYInput != null and not modelScaleYInput.has_focus():
		modelScaleYInput.text = "%.2f" % modelContainer.scale.y
	if modelScaleZInput != null and not modelScaleZInput.has_focus():
		modelScaleZInput.text = "%.2f" % modelContainer.scale.z

# 获取当前有焦点的输入框
func get_focused_input_field() -> LineEdit:
	# 检查相机位置输入框
	if positionXInput != null and positionXInput.has_focus():
		return positionXInput
	if positionYInput != null and positionYInput.has_focus():
		return positionYInput
	if positionZInput != null and positionZInput.has_focus():
		return positionZInput
	
	# 检查相机旋转输入框
	if rotationXInput != null and rotationXInput.has_focus():
		return rotationXInput
	if rotationYInput != null and rotationYInput.has_focus():
		return rotationYInput
	if rotationZInput != null and rotationZInput.has_focus():
		return rotationZInput
	
	# 检查模型位置输入框
	if modelPositionXInput != null and modelPositionXInput.has_focus():
		return modelPositionXInput
	if modelPositionYInput != null and modelPositionYInput.has_focus():
		return modelPositionYInput
	if modelPositionZInput != null and modelPositionZInput.has_focus():
		return modelPositionZInput
	
	# 检查模型旋转输入框
	if modelRotationXInput != null and modelRotationXInput.has_focus():
		return modelRotationXInput
	if modelRotationYInput != null and modelRotationYInput.has_focus():
		return modelRotationYInput
	if modelRotationZInput != null and modelRotationZInput.has_focus():
		return modelRotationZInput
	
	# 检查模型缩放输入框
	if modelScaleXInput != null and modelScaleXInput.has_focus():
		return modelScaleXInput
	if modelScaleYInput != null and modelScaleYInput.has_focus():
		return modelScaleYInput
	if modelScaleZInput != null and modelScaleZInput.has_focus():
		return modelScaleZInput
	
	# 检查环境光强度输入框
	if worldEnvironmentEnergyInput != null and worldEnvironmentEnergyInput.has_focus():
		return worldEnvironmentEnergyInput
	
	# 检查动画时间输入框
	if animationTimeInput != null and animationTimeInput.has_focus():
		return animationTimeInput
	
	# 检查定向光强度输入框
	if directionalLightLineEdit != null and directionalLightLineEdit.has_focus():
		return directionalLightLineEdit
	
	return null

# 计算步进值（根据修饰键）
func calculate_step(shift_pressed: bool, ctrl_pressed: bool) -> float:
	if ctrl_pressed:
		return arrowStepWithCtrl  # Ctrl + 箭头：0.01
	if shift_pressed:
		return arrowStepWithShift  # Shift + 箭头：1.0
	return arrowStepNormal  # 无修饰键：0.1

# 调整输入框的值
func adjust_input_field_value(input_field: LineEdit, step: float):
	if input_field == null:
		return
	
	var current_value: float = 0.0
	if not input_field.text.is_empty() and input_field.text.is_valid_float():
		current_value = float(input_field.text)
	
	# 应用步进
	var new_value: float = current_value + step
	
	# 对于环境光强度，限制范围在0.0-16.0
	if input_field == worldEnvironmentEnergyInput:
		new_value = clamp(new_value, 0.0, 16.0)
	
	# 更新文本框（保持两位小数）
	input_field.text = "%.2f" % new_value
	

# 根据输入框类型应用更改
func apply_input_field_change(input_field: LineEdit):
	if input_field == null:
		return
	
	# 检查是否是相机位置输入框
	if input_field == positionXInput or input_field == positionYInput or input_field == positionZInput:
		apply_position_from_input()
	# 检查是否是相机旋转输入框
	elif input_field == rotationXInput or input_field == rotationYInput or input_field == rotationZInput:
		apply_rotation_from_input()
	# 检查是否是模型位置输入框
	elif input_field == modelPositionXInput or input_field == modelPositionYInput or input_field == modelPositionZInput:
		apply_model_position_from_input()
	# 检查是否是模型旋转输入框
	elif input_field == modelRotationXInput or input_field == modelRotationYInput or input_field == modelRotationZInput:
		apply_model_rotation_from_input()
	# 检查是否是模型缩放输入框
	elif input_field == modelScaleXInput or input_field == modelScaleYInput or input_field == modelScaleZInput:
		apply_model_scale_from_input()
	# 检查是否是环境光强度输入框
	elif input_field == worldEnvironmentEnergyInput:
		apply_environment_energy_from_input()
	# 检查是否是动画时间输入框
	elif input_field == animationTimeInput:
		seek_to_time_from_input()
	# 检查是否是定向光强度输入框
	elif input_field == directionalLightLineEdit:
		apply_directional_light_energy_from_input()

# 动画播放按钮点击事件
func _on_animation_play_button_pressed():
	if animat == null:
		return
	
	if is_animation_playing:
		# 停止动画
		stop_animation()
	else:
		# 开始播放动画
		start_animation()

# 循环播放CheckBox切换事件
func _on_loop_check_box_toggled(toggled: bool):
	is_animation_looping = toggled

# 动画时间滑块变化事件
func _on_animation_time_slider_changed(value: float):
	if animat == null or current_animation_name.is_empty():
		return
	
	# 更新当前时间
	current_animation_time = value
	
	# 保存原始播放状态
	var was_playing: bool = is_animation_playing
	
	# 关键修复：无论是否播放，都先播放动画
	animat.play(current_animation_name)
	animat.seek(current_animation_time)  # 定位到指定时间
	
	# 如果原本没有播放，立即暂停
	if not was_playing:
		animat.advance(0)
		animat.pause()
	# 如果原本在播放，继续播放（从新位置继续）
	else:
		animat.play(current_animation_name)
		animat.seek(current_animation_time)  # 确保精确定位
	
	# 更新UI
	update_animation_ui()

# 时间输入框回车键提交事件
func _on_animation_time_input_submitted(new_text: String):
	seek_to_time_from_input()

# 时间输入框焦点丢失事件
func _on_animation_time_input_focus_exited():
	seek_to_time_from_input()

# 从输入框定位到指定时间
func seek_to_time_from_input():
	if animat == null or current_animation_name.is_empty() or animationTimeInput == null:
		return
	
	var target_time: float = 0.0
	if not animationTimeInput.text.is_empty() and animationTimeInput.text.is_valid_float():
		target_time = float(animationTimeInput.text)
	
	# 限制时间范围在 0 到动画长度之间
	target_time = clamp(target_time, 0.0, animation_length)
	
	# 定位到指定时间
	seek_to_time(target_time)

# 定位到指定时间（通用方法）
func seek_to_time(time: float):
	if animat == null or current_animation_name.is_empty():
		return
	
	# 更新当前时间
	current_animation_time = time
	
	# 保存原始播放状态
	var was_playing: bool = is_animation_playing
	
	# 关键修复：无论是否播放，都先播放动画
	animat.play(current_animation_name)
	animat.seek(current_animation_time)  # 定位到指定时间
	
	# 如果原本没有播放，立即暂停
	if not was_playing:
		animat.pause()
	# 如果原本在播放，继续播放（从新位置继续）
	else:
		animat.play(current_animation_name)
		animat.seek(current_animation_time)  # 确保精确定位
	
	# 更新UI
	update_animation_ui()

# 更新动画UI
func update_animation_ui():
	if animationPlayButton != null:
		# 更新按钮文本
		animationPlayButton.text = "⏸" if is_animation_playing else "▶"
	
	if animationTimeSlider != null:
		# 更新滑块值
		animationTimeSlider.value = current_animation_time
		
		# 更新滑块范围（如果有动画）
		if animation_length > 0:
			animationTimeSlider.max_value = animation_length
	
	if animationTimeLabel != null:
		# 更新时间标签
		animationTimeLabel.text = "%.2fs / %.2fs" % [current_animation_time, animation_length]
	
	# 更新时间输入框
	update_animation_time_input()

# 更新时间输入框的值
func update_animation_time_input():
	if animationTimeInput != null and not animationTimeInput.has_focus():
		animationTimeInput.text = "%.2f" % current_animation_time

# 开始播放动画
func start_animation():
	if animat == null:
		return
	
	# 获取动画列表
	var animation_names: PackedStringArray = animat.get_animation_list()
	if animation_names.is_empty():
		return

	# 使用第一个动画
	var animation_name: String = animation_names[0]
	
	# 设置当前动画
	current_animation_name = animation_name
	var animation: Animation = animat.get_animation(animation_name)
	animation_length = animation.length

	if current_animation_time >= animation_length - 0.005:
		# 如果已经播放完毕，从头开始播放
		current_animation_time = 0
	
	# 播放动画
	animat.play(animation_name)
	is_animation_playing = true
	
	# 更新UI
	update_animation_ui()
	

# 停止动画（改为暂停在当前时间）
func stop_animation():
	if animat == null:
		return
	
	# 暂停动画，保持当前时间
	animat.pause()
	is_animation_playing = false
	
	# 更新UI
	update_animation_ui()
	

# ============================================
# 上传模型功能 - 完全按照C#版本转换
# ============================================

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
func _load_model_directly(file_path: String):
	
	# 获取绝对路径
	var absolute_path: String = ProjectSettings.globalize_path(file_path)
	
	# 保存当前模型路径（如果是项目内路径）
	current_model_path = file_path
	print("保存直接加载模型路径: %s" % current_model_path)
	
	# 调用延迟加载方法，直接传递绝对路径
	call_deferred("_deferred_load_model", absolute_path)
	

# 导入模型文件
func _import_model_file(source_path: String):
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
		return
	
	# 创建文件夹
	var dir := DirAccess.open(project_dir)
	if dir == null:
		return
	
	if not dir.dir_exists(folder_path):
		var error := dir.make_dir_recursive(folder_path)
		if error != OK:
			return
	
	# 复制文件到目标文件夹
	var error := DirAccess.copy_absolute(source_path, target_path)
	if error != OK:
		return
	
	# 保存项目内生成的文件路径到 current_model_path
	current_model_path = target_path
	print("保存项目内模型路径: %s" % current_model_path)
	
	# 等待一帧让Godot检测到新文件
	# 使用绝对路径传递给_deferred_load_model
	call_deferred("_deferred_load_model", target_path)

# 延迟加载模型
func _deferred_load_model(model_path: String):
	
	# 等待FBX导入完成
	var import_success: bool = await _wait_for_fbx_import(model_path)
	if not import_success:
		printerr("FBX导入失败或超时: %s" % model_path)
		return
	
	# 使用ResourceLoader加载模型 - 使用绝对路径
	var model_resource = ResourceLoader.load(model_path)
	
	if model_resource == null:
		printerr("无法加载模型资源: %s" % model_path)
		return
	
	
	# 根据资源类型处理模型
	if model_resource is PackedScene:
		# 如果是场景文件，创建继承场景并加载到SubViewport
		_create_inherited_scene_and_load(model_resource, model_path)
	else:
		printerr("不支持的资源类型: %s" % model_resource.get_class())
		return
	

# 等待FBX导入完成
func _wait_for_fbx_import(model_path: String) -> bool:
	
	# 获取导入文件路径（model_path现在是绝对路径）
	var import_file_path: String = model_path + ".import"
	
	
	var max_retries: int = 30  # 最大重试次数（30秒）
	var retry_count: int = 0
	
	while retry_count < max_retries:
		# 检查导入文件是否存在
		if FileAccess.file_exists(import_file_path):
			
			# 尝试加载资源来验证导入是否完成（使用绝对路径）
			var test_resource = ResourceLoader.load(model_path)
			if test_resource != null:
				return true
		
		# 等待1秒
		await get_tree().create_timer(1.0).timeout
		retry_count += 1
	
	printerr("FBX导入超时: %s" % model_path)
	return false

# 场景本地化：直接加载原始场景到SubViewport并更新组件引用
func _create_inherited_scene_and_load(original_scene: PackedScene, model_path: String):
	
	# 实例化原始场景
	var scene_instance = original_scene.instantiate()
	if scene_instance == null:
		printerr("场景实例化失败")
		return
	
	# 获取ModelContainer节点
	var model_container = modelCon
	if model_container == null:
		printerr("ModelContainer节点未找到")
		return
	
	# 清理当前场景
	_clear_current_scene()
	
	# 将场景实例添加到ModelContainer
	model_container.add_child(scene_instance)
	
	
	# 更新组件引用
	_update_component_references(scene_instance)
	

# 清理当前场景
func _clear_current_scene():
	var model_container = modelCon
	if model_container == null:
		return
	
	# 清理ModelContainer中的所有子节点
	var children_to_remove: Array[Node] = []
	
	for child in model_container.get_children():
		children_to_remove.append(child)
	
	# 删除所有子节点
	for child in children_to_remove:
		child.queue_free()
	

# 更新组件引用（场景本地化核心方法）
func _update_component_references(scene_instance: Node):
	if scene_instance == null:
		return
	
	
	# 查找AnimationPlayer并更新animat引用
	var anim_player: AnimationPlayer = _find_animation_player(scene_instance)
	if anim_player != null:
		animat = anim_player
		previewPanel.animat = anim_player
	else:
		animat=null
		previewPanel.animat=null
		printerr("未找到AnimationPlayer")
	
	# 查找所有MeshInstance3D并保存到列表
	var mesh_instances: Array[MeshInstance3D] = _find_all_mesh_instances(scene_instance)
	if mesh_instances.size() > 0:
		# 清空现有列表
		allMeshes.clear()
		
		# 保存所有MeshInstance3D到列表
		allMeshes.append_array(mesh_instances)
		
		# 将MeshInstance3D列表传递给预览面板
		previewPanel.allMeshes.clear()
		previewPanel.allMeshes.append_array(mesh_instances)
		
		
		# 注意：normalMesh保持原有的QuadMesh，不更新其网格
		# 这样normalMesh可以继续用于法线材质渲染
	else:
		printerr("未找到MeshInstance3D")
	

# 在节点树中查找AnimationPlayer
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result: AnimationPlayer = _find_animation_player(child)
		if result != null:
			return result
	
	return null

# 在节点树中查找所有MeshInstance3D
func _find_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var mesh_instances: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		mesh_instances.append_array(_find_all_mesh_instances(child))
	
	return mesh_instances

# 获取父窗口引用
func get_parent_window() -> Window:
	# 尝试获取父窗口
	var parent = get_parent()
	while parent != null:
		if parent is Window:
			return parent as Window
		parent = parent.get_parent()
	return null

# 监控窗口焦点状态变化
func monitor_window_focus():
	if parent_window == null or cameraController == null:
		return
	
	var is_focused: bool = parent_window.has_focus()
	
	# 检查焦点状态是否发生变化
	if is_focused != was_window_focused:
		was_window_focused = is_focused
		
		if is_focused:
			# 窗口获得焦点，启用相机控制
			if cameraController.has_method("enable_camera_control"):
				cameraController.enable_camera_control()
				cameraController.set_window_focus_state(true)
				previewPanel.set_window_focus_state(true)
		else:
			# 窗口失去焦点，禁用相机控制
			if cameraController.has_method("disable_camera_control"):
				cameraController.disable_camera_control()
				cameraController.set_window_focus_state(false)
				previewPanel.set_window_focus_state(false)

# ============================================
# 定向光控制功能
# ============================================

# 初始化定向光控制
func initialize_directional_light_control():
	if directionalLight == null or directionalLightCheckBox == null or directionalLightLineEdit == null:
		return
	
	# 连接定向光事件
	connect_directional_light_events()
	
	# 设置初始状态：常态下灯光关闭
	directionalLight.visible = false
	directionalLightCheckBox.button_pressed = false
	
	# 设置默认灯光强度为1.0（如果当前为0）
	if directionalLight.light_energy == 0:
		directionalLight.light_energy = 1.0
	
	# 更新初始灯光强度到输入框
	update_directional_light_energy_input()
	
	# 连接定向光旋转控制复选框事件
	if directionalLightRoCheckBox != null:
		directionalLightRoCheckBox.toggled.connect(_on_directional_light_ro_check_box_toggled)
		# 设置初始状态：关闭（控制相机）
		directionalLightRoCheckBox.button_pressed = false
		is_controlling_directional_light = false
	

# 连接定向光事件
func connect_directional_light_events():
	# 连接复选框事件
	if directionalLightCheckBox != null:
		directionalLightCheckBox.toggled.connect(_on_directional_light_check_box_toggled)
	
	# 连接LineEdit事件（与其他LineEdit保持一致）
	if directionalLightLineEdit != null:
		directionalLightLineEdit.text_submitted.connect(_on_directional_light_line_edit_submitted)
		directionalLightLineEdit.focus_exited.connect(_on_directional_light_line_edit_focus_exited)
		directionalLightLineEdit.focus_entered.connect(_on_input_field_focus_entered)
		directionalLightLineEdit.focus_exited.connect(_on_input_field_focus_exited)
		directionalLightLineEdit.gui_input.connect(_on_input_field_gui_input)

# 定向光复选框切换事件
func _on_directional_light_check_box_toggled(toggled: bool):
	if directionalLight != null:
		directionalLight.visible = toggled

# 定向光LineEdit回车键提交事件
func _on_directional_light_line_edit_submitted(new_text: String):
	apply_directional_light_energy_from_input()

# 定向光LineEdit焦点丢失事件
func _on_directional_light_line_edit_focus_exited():
	apply_directional_light_energy_from_input()

# 从输入框应用定向光强度
func apply_directional_light_energy_from_input():
	if directionalLight == null or directionalLightLineEdit == null:
		return
	
	var energy: float = 0.0
	if not directionalLightLineEdit.text.is_empty() and directionalLightLineEdit.text.is_valid_float():
		energy = float(directionalLightLineEdit.text)
	
	# 限制范围在合理值内（0.0-16.0）
	energy = clamp(energy, 0.0, 16.0)
	
	directionalLight.light_energy = energy
	
	# 更新输入框显示（确保显示的是实际设置的值）
	update_directional_light_energy_input()

# 更新定向光强度输入框的值
func update_directional_light_energy_input():
	if directionalLight == null or directionalLightLineEdit == null:
		return
	
	# 只在输入框没有焦点时更新，避免干扰用户输入
	if not directionalLightLineEdit.has_focus():
		var current_energy: float = directionalLight.light_energy
		directionalLightLineEdit.text = "%.2f" % current_energy

# 定向光旋转控制复选框切换事件
func _on_directional_light_ro_check_box_toggled(toggled: bool):
	is_controlling_directional_light = toggled
	update_control_mode_ui()
	
	# 通知相机控制器切换控制模式
	if cameraController != null and cameraController.has_method("set_control_mode"):
		cameraController.set_control_mode(toggled, directionalLight)
	

# 更新控制模式UI
func update_control_mode_ui():
	if is_controlling_directional_light:
		# 灯光模式
		if cameraInfoLabel:
			cameraInfoLabel.text = get_translation("灯光")
		if resetCameraButton:
			resetCameraButton.text = get_translation("重置")
		if caPosition:
			caPosition.text = get_translation("灯光位置")
		if caRotation:
			caRotation.text = get_translation("灯光旋转")
		
		# 更新输入框的占位符文本
		if positionXInput:
			positionXInput.placeholder_text = get_translation("X")
		if positionYInput:
			positionYInput.placeholder_text = get_translation("Y")
		if positionZInput:
			positionZInput.placeholder_text = get_translation("Z")
		if rotationXInput:
			rotationXInput.placeholder_text = get_translation("X°")
		if rotationYInput:
			rotationYInput.placeholder_text = get_translation("Y°")
		if rotationZInput:
			rotationZInput.placeholder_text = get_translation("Z°")
	else:
		# 相机模式
		if cameraInfoLabel:
			cameraInfoLabel.text = get_translation("相机")
		if resetCameraButton:
			resetCameraButton.text = get_translation("重置")
		if caPosition:
			caPosition.text = get_translation("位置")
		if caRotation:
			caRotation.text = get_translation("旋转")
		
		# 恢复输入框的占位符文本
		if positionXInput:
			positionXInput.placeholder_text = get_translation("X")
		if positionYInput:
			positionYInput.placeholder_text = get_translation("Y")
		if positionZInput:
			positionZInput.placeholder_text = get_translation("Z")
		if rotationXInput:
			rotationXInput.placeholder_text = get_translation("X°")
		if rotationYInput:
			rotationYInput.placeholder_text = get_translation("Y°")
		if rotationZInput:
			rotationZInput.placeholder_text = get_translation("Z°")
	
	# 更新翻译函数中的相关文本
	update_plugin_ui_translations()

# 清理所有资源
func cleanup():
	
	# 停止动画
	if animat != null:
		if is_animation_playing:
			animat.stop()
			is_animation_playing = false
		# 重置动画引用
		animat = null
		if previewPanel != null:
			previewPanel.animat = null
	
	# 清理当前场景
	_clear_current_scene()
	
	# 清空网格列表
	allMeshes.clear()
	if previewPanel != null:
		previewPanel.allMeshes.clear()
	
	# 重置动画状态变量
	current_animation_name = ""
	animation_length = 0.0
	current_animation_time = 0.0
	is_animation_playing = false
	is_animation_looping = false
	
	# 重置控制模式
	is_controlling_directional_light = false
	if cameraController != null and cameraController.has_method("set_control_mode"):
		cameraController.set_control_mode(false, null)
	
	# 重置定向光状态
	if directionalLight != null:
		directionalLight.visible = false
		if directionalLightCheckBox != null:
			directionalLightCheckBox.button_pressed = false
	
	# 重置模型容器位置、旋转、缩放
	if modelContainer != null:
		modelContainer.position = Vector3.ZERO
		modelContainer.rotation = Vector3.ZERO
		modelContainer.scale = Vector3.ONE
	
	# 重置环境光
	if worldEnvironment != null and worldEnvironment.environment != null:
		worldEnvironment.environment.ambient_light_energy = 1.0
	
	# 重置预览面板状态
	if previewPanel != null and previewPanel.has_method("reset"):
		previewPanel.reset()
	
	# 更新UI显示
	update_model_input_fields()
	update_environment_energy_input()
	update_animation_ui()
	update_control_mode_ui()
	
	# 禁用表面贴图按钮
	if tietuButton != null:
		tietuButton.disabled = true
	

# ============================================
# 表面贴图功能
# ============================================

# 表面贴图按钮点击事件
func _on_tietu_button_pressed():
	if modelContainer == null or tietuDialog == null:
		printerr("ModelContainer或tietuDialog未设置")
		return
	
	# 查找所有MeshInstance3D节点
	var mesh_instances: Array[MeshInstance3D] = _find_all_mesh_instances(modelContainer)
	if mesh_instances.size() == 0:
		printerr("未找到MeshInstance3D节点")
		return
	
	# 保存MeshInstance3D列表和当前索引
	tietu_mesh_instances = mesh_instances
	tietu_current_index = 0
	
	# 设置对话框的当前目录为当前模型的文件夹（如果有的话）
	if not current_model_path.is_empty():
		var model_dir: String = current_model_path.get_base_dir()
		
		# 确保目录存在
		if DirAccess.dir_exists_absolute(model_dir):
			tietuDialog.current_dir = model_dir
			print("设置表面贴图对话框目录为项目内路径: %s" % model_dir)
		else:
			# 如果项目内目录不存在，尝试使用项目根目录
			var project_dir: String = ProjectSettings.globalize_path("res://").get_base_dir()
			if DirAccess.dir_exists_absolute(project_dir):
				tietuDialog.current_dir = project_dir
				print("项目内目录不存在，使用项目根目录: %s" % project_dir)
			else:
				print("使用默认目录")
	else:
		# 如果没有当前模型路径，使用项目根目录
		var project_dir: String = ProjectSettings.globalize_path("res://").get_base_dir()
		if DirAccess.dir_exists_absolute(project_dir):
			tietuDialog.current_dir = project_dir
			print("没有当前模型路径，使用项目根目录: %s" % project_dir)
	
	# 弹出第一个文件选择对话框
	_show_next_tietu_dialog()

# 表面贴图文件选择事件
func _on_tietu_file_selected(file_path: String):
	if file_path.is_empty():
		printerr("文件路径为空")
		_reset_tietu_state()
		return
	
	if tietu_mesh_instances.is_empty() or tietu_current_index >= tietu_mesh_instances.size():
		printerr("MeshInstance3D列表无效或索引越界")
		_reset_tietu_state()
		return
	
	# 获取当前处理的MeshInstance3D
	var current_mesh_instance: MeshInstance3D = tietu_mesh_instances[tietu_current_index]
	
	# 加载图片纹理
	var texture: Texture2D = load(file_path)
	if texture == null:
		printerr("无法加载图片: %s" % file_path)
		# 继续处理下一个
		tietu_current_index += 1
		_show_next_tietu_dialog()
		return
	
	# 应用到MeshInstance3D的material overlay
	_apply_texture_to_mesh_instance(current_mesh_instance, texture)
	
	# 处理下一个MeshInstance3D
	tietu_current_index += 1
	_show_next_tietu_dialog()

# 显示下一个表面贴图对话框
func _show_next_tietu_dialog():
	if tietu_current_index >= tietu_mesh_instances.size():
		# 所有MeshInstance3D都已处理完毕
		print("表面贴图应用完成，共处理了 %d 个MeshInstance3D" % tietu_mesh_instances.size())
		_reset_tietu_state()
		return
	
	# 弹出文件选择对话框
	tietuDialog.popup_centered()

# 重置表面贴图状态
func _reset_tietu_state():
	tietu_mesh_instances.clear()
	tietu_current_index = 0

# 查找所有CollisionObject3D节点
func _find_all_collision_objects(node: Node) -> Array[CollisionObject3D]:
	var collision_objects: Array[CollisionObject3D] = []
	
	if node is CollisionObject3D:
		collision_objects.append(node)
	
	# 递归查找子节点
	for child in node.get_children():
		collision_objects.append_array(_find_all_collision_objects(child))
	
	return collision_objects

# 将纹理应用到MeshInstance3D的material overlay
func _apply_texture_to_mesh_instance(mesh_instance: MeshInstance3D, texture: Texture2D):
	if mesh_instance == null:
		printerr("MeshInstance3D为空")
		return
	
	var material: Material = mesh_instance.get_surface_override_material(0)
	
	if material == null:
		# 如果没有材质，创建一个新的StandardMaterial3D
		material = StandardMaterial3D.new()
		mesh_instance.set_surface_override_material(0, material)
	
	# 设置材质的albedo_texture
	if material is StandardMaterial3D:
		var std_material: StandardMaterial3D = material as StandardMaterial3D
		std_material.albedo_texture = texture
		print("已将纹理应用到MeshInstance3D: %s" % mesh_instance.name)
	else:
		printerr("MeshInstance3D的材质不是StandardMaterial3D类型，无法设置纹理")

# 表面贴图相关变量
var tietu_mesh_instances: Array[MeshInstance3D] = []
var tietu_current_index: int = 0
var current_model_path: String = ""  # 当前模型文件的路径
