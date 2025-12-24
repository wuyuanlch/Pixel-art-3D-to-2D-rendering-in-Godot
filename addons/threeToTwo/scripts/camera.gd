@tool
extends Node

# 相机节点引用
@export var camera3D: Camera3D
@export var normalMesh: MeshInstance3D

# 定向光节点引用（用于灯光控制模式）
@export var directionalLight: DirectionalLight3D

# 相机控制参数
@export var rotationSpeed: float = 1.0  # 旋转速度：鼠标中键拖动时相机的旋转灵敏度，值越大旋转越快
@export var zoomSpeed: float = 1.0      # 缩放速度：鼠标滚轮缩放时的速度，值越大缩放幅度越大
@export var panSpeed: float = 0.5       # 平移速度：鼠标右键拖动时相机的平移灵敏度，值越大平移越快
@export var minZoom: float = 1.0        # 最小缩放距离：相机可以靠近物体的最小距离，防止相机穿模
@export var maxZoom: float = 20.0       # 最大缩放距离：相机可以远离物体的最大距离，限制视野范围
@export var autoRotateSpeed: float = 0.5  # 自动旋转速度：点击自动旋转按钮时相机的旋转速度，值越大旋转越快

# 键盘控制参数
@export var keyboardMoveSpeed: float = 1.0      # 键盘移动速度：WASD控制相机移动的速度
@export var keyboardRotateSpeed: float = 0.1    # 键盘旋转速度：箭头键控制相机旋转的速度
@export var keyboardVerticalSpeed: float = 1.0  # 键盘垂直移动速度：Q/E控制相机上下移动的速度

# 相机状态
var originalPosition: Vector3
var originalRotation: Vector3
var originalFov: float
var isRotating: bool = false
var isPanning: bool = false
var isAutoRotating: bool = false
var lastMousePosition: Vector2
var isEnabled: bool = true  # 相机控制是否启用

# 控制模式相关变量
var is_controlling_directional_light: bool = false  # 是否正在控制定向光（而非相机）
var directional_light_original_position: Vector3  # 定向光原始位置
var directional_light_original_rotation: Vector3  # 定向光原始旋转

# 输入框焦点状态
var hasInputFieldFocus: bool = false  # 是否有输入框获得焦点

var isWindowFocused: bool = true
var isPreviewPanelOpen: bool = false

# 相机控制UI引用（在主界面中设置）
var resetCameraButton: Button

# 数字输入框引用（用于实时显示相机状态）
var positionXInput: LineEdit
var positionYInput: LineEdit
var positionZInput: LineEdit
var rotationXInput: LineEdit
var rotationYInput: LineEdit
var rotationZInput: LineEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	# 保存初始相机状态
	if camera3D != null:
		originalPosition = camera3D.position
		originalRotation = camera3D.rotation
		originalFov = camera3D.fov

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if camera3D == null or not isEnabled:
		return
	
	if isAutoRotating:
		# 自动旋转
		camera3D.rotate_y(delta * autoRotateSpeed)
		update_camera_info()
	
	# 处理键盘输入
	handle_keyboard_input(delta)

# 鼠标输入处理
func _input(event):
	if camera3D == null or not isWindowFocused or isPreviewPanelOpen or not isEnabled:
		return
	
	if event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

# 处理鼠标按钮事件
func handle_mouse_button(mouseButton: InputEventMouseButton):
	if mouseButton.button_index == MOUSE_BUTTON_MIDDLE and mouseButton.pressed:
		# 中键按下 - 开始旋转
		isRotating = true
		lastMousePosition = mouseButton.position
		isAutoRotating = false  # 停止自动旋转
	elif mouseButton.button_index == MOUSE_BUTTON_MIDDLE and not mouseButton.pressed:
		# 中键释放 - 停止旋转
		isRotating = false
	elif mouseButton.button_index == MOUSE_BUTTON_RIGHT and mouseButton.pressed:
		# 右键按下 - 开始平移
		isPanning = true
		lastMousePosition = mouseButton.position
	elif mouseButton.button_index == MOUSE_BUTTON_RIGHT and not mouseButton.pressed:
		# 右键释放 - 停止平移
		isPanning = false
	elif mouseButton.button_index == MOUSE_BUTTON_WHEEL_UP and mouseButton.pressed:
		# 滚轮向上 - 放大
		zoom_camera(zoomSpeed)
	elif mouseButton.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouseButton.pressed:
		# 滚轮向下 - 缩小
		zoom_camera(-zoomSpeed)

# 处理鼠标移动事件
func handle_mouse_motion(mouseMotion: InputEventMouseMotion):
	var delta: Vector2 = mouseMotion.position - lastMousePosition
	
	if isRotating:
		# 旋转相机
		rotate_camera(delta)
	elif isPanning:
		# 平移相机
		pan_camera(delta)
	
	lastMousePosition = mouseMotion.position

# 旋转相机
func rotate_camera(delta: Vector2):
	if is_controlling_directional_light and directionalLight != null:
		# 旋转定向光
		rotate_directional_light(delta)
	elif camera3D != null:
		# 旋转相机（原有逻辑）
		# 计算旋转角度
		var rotationX: float = -delta.y * rotationSpeed * 0.01
		var rotationY: float = -delta.x * rotationSpeed * 0.01
		
		# 应用旋转
		camera3D.rotate_object_local(Vector3.RIGHT, rotationX)
		camera3D.rotate_y(rotationY)
		
		update_camera_info()

# 平移相机
func pan_camera(delta: Vector2):
	if camera3D == null:
		return
	
	# 计算平移向量（基于相机方向）
	var right: Vector3 = camera3D.global_transform.basis.x
	var up: Vector3 = camera3D.global_transform.basis.y
	
	var panVector: Vector3 = (-right * delta.x + up * delta.y) * panSpeed * 0.01
	
	# 应用平移
	camera3D.position += panVector
	
	update_camera_info()

# 缩放相机
func zoom_camera(amount: float):
	if camera3D == null:
		return
	
	# 计算缩放方向（基于相机前向向量）
	var forward: Vector3 = -camera3D.global_transform.basis.z
	
	# 计算新的位置
	var newPosition: Vector3 = camera3D.position + forward * amount * 0.1
	
	# 检查缩放限制
	var distance: float = newPosition.length()
	if distance >= minZoom and distance <= maxZoom:
		camera3D.position = newPosition
		update_camera_info()

# 重置相机
func reset_camera():
	if is_controlling_directional_light and directionalLight != null:
		# 重置定向光到默认位置和旋转
		reset_directional_light()
	elif camera3D != null:
		# 重置相机（原有逻辑）
		camera3D.position = originalPosition
		camera3D.rotation = originalRotation
		camera3D.fov = originalFov
		isAutoRotating = false
		
		update_camera_info()

# 切换自动旋转
func toggle_auto_rotate():
	isAutoRotating = not isAutoRotating

# 设置FOV
func set_fov(fov: float):
	if camera3D != null:
		camera3D.fov = fov
		update_camera_info()

# 设置相机位置
func set_position(x: float, y: float, z: float):
	if is_controlling_directional_light and directionalLight != null:
		# 设置定向光位置
		directionalLight.position = Vector3(x, y, z)
	elif camera3D != null:
		# 设置相机位置（原有逻辑）
		camera3D.position = Vector3(x, y, z)
		update_camera_info()

# 设置相机旋转（角度为单位）
func set_rotation(xDegrees: float, yDegrees: float, zDegrees: float):
	if is_controlling_directional_light and directionalLight != null:
		# 设置定向光旋转
		# 将角度转换为弧度
		var xRad: float = deg_to_rad(xDegrees)
		var yRad: float = deg_to_rad(yDegrees)
		var zRad: float = deg_to_rad(zDegrees)
		
		directionalLight.rotation = Vector3(xRad, yRad, zRad)
	elif camera3D != null:
		# 设置相机旋转（原有逻辑）
		# 将角度转换为弧度
		var xRad: float = deg_to_rad(xDegrees)
		var yRad: float = deg_to_rad(yDegrees)
		var zRad: float = deg_to_rad(zDegrees)
		
		camera3D.rotation = Vector3(xRad, yRad, zRad)
		update_camera_info()

# 更新相机信息显示
func update_camera_info():
	if camera3D == null:
		return
	
	# 更新数字输入框的值
	update_input_fields()

# 更新数字输入框的值
func update_input_fields():
	if is_controlling_directional_light and directionalLight != null:
		# 更新定向光位置和旋转到输入框
		update_directional_light_input_fields()
	elif camera3D != null:
		# 更新相机位置和旋转到输入框（原有逻辑）
		# 更新位置输入框
		if positionXInput != null and not positionXInput.has_focus():
			positionXInput.text = "%.2f" % camera3D.position.x
		if positionYInput != null and not positionYInput.has_focus():
			positionYInput.text = "%.2f" % camera3D.position.y
		if positionZInput != null and not positionZInput.has_focus():
			positionZInput.text = "%.2f" % camera3D.position.z
		
		# 更新旋转输入框（转换为角度）
		if rotationXInput != null and not rotationXInput.has_focus():
			rotationXInput.text = "%.2f" % rad_to_deg(camera3D.rotation.x)
		if rotationYInput != null and not rotationYInput.has_focus():
			rotationYInput.text = "%.2f" % rad_to_deg(camera3D.rotation.y)
		if rotationZInput != null and not rotationZInput.has_focus():
			rotationZInput.text = "%.2f" % rad_to_deg(camera3D.rotation.z)

# 设置UI引用（由主界面调用）
func set_ui_references(resetBtn: Button):
	resetCameraButton = resetBtn
	
	# 连接按钮信号
	if resetCameraButton != null:
		resetCameraButton.pressed.connect(reset_camera)
	
	# 更新初始状态
	update_camera_info()

# 设置数字输入框引用（由主界面调用）
func set_input_field_references(posX: LineEdit, posY: LineEdit, posZ: LineEdit, rotX: LineEdit, rotY: LineEdit, rotZ: LineEdit):
	positionXInput = posX
	positionYInput = posY
	positionZInput = posZ
	rotationXInput = rotX
	rotationYInput = rotY
	rotationZInput = rotZ
	
	# 更新初始状态
	update_input_fields()

# 启用相机控制
func enable_camera_control():
	isEnabled = true

# 禁用相机控制
func disable_camera_control():
	isEnabled = false
	isRotating = false
	isPanning = false
	isAutoRotating = false

# 设置输入框焦点状态（由主界面调用）
func set_input_field_focus_state(hasFocus: bool):
	hasInputFieldFocus = hasFocus

func set_window_focus_state(focused: bool):
	isWindowFocused = focused

func set_preview_panel_state(open: bool):
	isPreviewPanelOpen = open

# 处理键盘输入
func handle_keyboard_input(delta: float):
	if camera3D == null:
		return
	
	# 如果有输入框获得焦点，跳过键盘控制
	if hasInputFieldFocus or not isWindowFocused or isPreviewPanelOpen or not isEnabled:
		return
	
	var cameraMoved: bool = false
	var cameraRotated: bool = false
	
	# 计算移动向量
	var moveVector: Vector3 = Vector3.ZERO
	
	# WS上下移动控制
	if Input.is_key_pressed(KEY_W):
		# 向上移动
		moveVector += Vector3.UP
	if Input.is_key_pressed(KEY_S):
		# 向下移动
		moveVector += Vector3.DOWN
	
	# QE前后移动控制
	if Input.is_key_pressed(KEY_Q):
		# 前向移动（基于相机前向向量在XZ平面）
		var forward: Vector3 = -camera3D.global_transform.basis.z
		forward.y = 0  # 保持在水平面
		forward = forward.normalized()
		moveVector += forward
	if Input.is_key_pressed(KEY_E):
		# 后向移动
		var backward: Vector3 = camera3D.global_transform.basis.z
		backward.y = 0
		backward = backward.normalized()
		moveVector += backward
	
	# AD左右移动控制
	if Input.is_key_pressed(KEY_A):
		# 左移
		var left: Vector3 = -camera3D.global_transform.basis.x
		left.y = 0
		left = left.normalized()
		moveVector += left
	if Input.is_key_pressed(KEY_D):
		# 右移
		var right: Vector3 = camera3D.global_transform.basis.x
		right.y = 0
		right = right.normalized()
		moveVector += right
	
	# 应用移动
	if moveVector != Vector3.ZERO:
		# 分离水平和垂直移动速度
		var horizontalMove: Vector3 = Vector3(moveVector.x, 0, moveVector.z)
		var verticalMove: Vector3 = Vector3(0, moveVector.y, 0)
		
		if horizontalMove != Vector3.ZERO:
			horizontalMove = horizontalMove.normalized() * keyboardMoveSpeed * delta
			camera3D.position += horizontalMove
			cameraMoved = true
		
		if verticalMove != Vector3.ZERO:
			verticalMove = verticalMove.normalized() * keyboardVerticalSpeed * delta
			camera3D.position += verticalMove
			cameraMoved = true
	
	# 小键盘8246旋转控制
	var rotateX: float = 0
	var rotateY: float = 0
	
	if Input.is_key_pressed(KEY_KP_8):
		# 向上看（俯仰）- 小键盘8
		rotateX = -keyboardRotateSpeed * delta
	if Input.is_key_pressed(KEY_KP_2):
		# 向下看（俯仰）- 小键盘2
		rotateX = keyboardRotateSpeed * delta
	if Input.is_key_pressed(KEY_KP_4):
		# 向左看（偏航）- 小键盘4
		rotateY = keyboardRotateSpeed * delta
	if Input.is_key_pressed(KEY_KP_6):
		# 向右看（偏航）- 小键盘6
		rotateY = -keyboardRotateSpeed * delta
	
	# 应用旋转
	if rotateX != 0 or rotateY != 0:
		# 俯仰旋转（绕X轴）
		if rotateX != 0:
			camera3D.rotate_object_local(Vector3.RIGHT, rotateX)
		
		# 偏航旋转（绕Y轴）
		if rotateY != 0:
			camera3D.rotate_y(rotateY)
		
		cameraRotated = true
	
	# 如果相机移动或旋转了，更新UI信息
	if cameraMoved or cameraRotated:
		update_camera_info()

# ============================================
# 控制模式切换功能
# ============================================

# 设置控制模式
func set_control_mode(controlling_light: bool, light_node: DirectionalLight3D = null):
	is_controlling_directional_light = controlling_light
	
	if controlling_light and light_node != null:
		directionalLight = light_node
		# 保存定向光的原始状态
		directional_light_original_position = directionalLight.position
		directional_light_original_rotation = directionalLight.rotation
	
	# 更新输入框显示
	update_input_fields()

# 旋转定向光
func rotate_directional_light(delta: Vector2):
	if directionalLight == null:
		return
	
	# 计算旋转角度
	var rotationX: float = -delta.y * rotationSpeed * 0.01
	var rotationY: float = -delta.x * rotationSpeed * 0.01
	
	# 应用旋转（绕全局轴旋转）
	directionalLight.rotate_x(rotationX)
	directionalLight.rotate_y(rotationY)
	
	# 更新输入框显示
	update_input_fields()

# 重置定向光
func reset_directional_light():
	if directionalLight == null:
		return
	
	directionalLight.position = directional_light_original_position
	directionalLight.rotation = directional_light_original_rotation
	
	
	# 更新输入框显示
	update_input_fields()

# 更新定向光输入框的值
func update_directional_light_input_fields():
	if directionalLight == null:
		return
	
	# 更新位置输入框
	if positionXInput != null and not positionXInput.has_focus():
		positionXInput.text = "%.2f" % directionalLight.position.x
	if positionYInput != null and not positionYInput.has_focus():
		positionYInput.text = "%.2f" % directionalLight.position.y
	if positionZInput != null and not positionZInput.has_focus():
		positionZInput.text = "%.2f" % directionalLight.position.z
	
	# 更新旋转输入框（转换为角度）
	if rotationXInput != null and not rotationXInput.has_focus():
		rotationXInput.text = "%.2f" % rad_to_deg(directionalLight.rotation.x)
	if rotationYInput != null and not rotationYInput.has_focus():
		rotationYInput.text = "%.2f" % rad_to_deg(directionalLight.rotation.y)
	if rotationZInput != null and not rotationZInput.has_focus():
		rotationZInput.text = "%.2f" % rad_to_deg(directionalLight.rotation.z)
