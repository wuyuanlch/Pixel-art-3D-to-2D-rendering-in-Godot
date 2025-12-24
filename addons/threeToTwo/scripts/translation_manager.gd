@tool
extends Node

# 自定义翻译数据
var translation_data: Dictionary = {}
# 插件当前语言
var current_language: String = "zh_CN"
# 支持的语言列表
var supported_languages: Array[String] = ["zh_CN", "en"]
# 翻译文件路径
var translation_file_path: String = "res://addons/threeToTwo/language/translate.csv"
# 是否已初始化（私有变量，使用下划线前缀）
var _is_initialized: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# 加载翻译数据
	load_translation_csv()
	
	# 设置默认语言
	set_language("zh_CN")
	

# 加载自定义翻译CSV文件
func load_translation_csv():
	var file = FileAccess.open(translation_file_path, FileAccess.READ)
	if file == null:
		return
	
	# 读取CSV文件内容
	var csv_content: String = file.get_as_text()
	var lines: PackedStringArray = csv_content.split("\n")
	
	if lines.size() == 0:
		return
	
	# 解析表头
	var headers: PackedStringArray = lines[0].strip_edges().split(",")
	if headers.size() < 3:
		return
	
	# 语言列索引
	var id_index: int = 0
	var zh_cn_index: int = 1
	var en_index: int = 2
	
	# 解析数据行
	for i in range(1, lines.size()):
		var line: String = lines[i].strip_edges()
		if line.is_empty():
			continue
		
		var fields: PackedStringArray = line.split(",")
		if fields.size() < 3:
			continue
		
		var id: String = fields[id_index].strip_edges()
		var zh_cn: String = fields[zh_cn_index].strip_edges()
		var en: String = fields[en_index].strip_edges()
		
		# 添加到翻译数据
		var translations: Dictionary = {}
		translations["zh_CN"] = zh_cn
		translations["en"] = en
		
		translation_data[id] = translations
	
	_is_initialized = true

# 获取翻译文本
func get_translation(id: String) -> String:
	if not _is_initialized:
		return id
	
	if translation_data.has(id):
		var translations: Dictionary = translation_data[id]
		if translations.has(current_language):
			return translations[current_language]
		elif translations.has("zh_CN"):
			# 如果当前语言没有翻译，返回中文作为默认
			return translations["zh_CN"]
	
	# 如果找不到翻译，返回ID本身
	return id

# 设置插件语言
func set_language(locale: String):
	# 检查是否支持该语言
	if not supported_languages.has(locale):
		return
	
	# 保存插件当前语言
	current_language = locale
	

# 获取插件当前语言
func get_current_language() -> String:
	return current_language

# 检查是否支持某种语言
func is_language_supported(locale: String) -> bool:
	return supported_languages.has(locale)

# 获取支持的语言列表
func get_supported_languages() -> Array[String]:
	return supported_languages.duplicate()

# 获取翻译数量
func get_translation_count() -> int:
	return translation_data.size()

# 检查是否已初始化
func is_initialized() -> bool:
	return _is_initialized
