class_name AIAgent extends CharacterBody3D

# Basic Settings
@export_group("General")
@export var enabled: bool = true

# Navigation and Movement Settings
@export_group("Navigation")
@export var movement_speed: float = 2.0
@export var debug_navigation: bool = false
@export var random_movement: bool = false
@export var random_movement_interval: float = 1.5
@export var stuck_threshold_distance: float = 0.001
@export var max_stuck_time: float = 0.5

# Physics and Collision Settings
@export_group("Physics")
@export var apply_impulse: bool = true
@export var push_force: float = 2.0

# Emotion Settings
@export_group("Emotions")
@export var emotion_update_interval: float = 0.05
@export var emotion_lerp_speed: float = 8.0
@export var strong_emotion_threshold: float = 0.75
@export var moderate_emotion_threshold: float = 0.4

# Child Node References
@onready var nav_actuator: AgentActuator = $NavigationAgent3D
@onready var emoji_manager: Sprite3D = $EmojiManager
@onready var base_agent: BaseAgent = _get_base_agent()

# Integrated Components
var impulse_controller: ImpulseApplicator
var emotion_controller: EmotionController

func _init():
	impulse_controller = ImpulseApplicator.new()
	emotion_controller = EmotionController.new()

func _ready():
	# Validate required components
	if not base_agent:
		push_error("AIAgent requires a child node that extends BaseAgent!")
		return
		
	# Configure Navigation
	nav_actuator.speed = movement_speed
	nav_actuator.debug_info = debug_navigation
	nav_actuator.random_movement = random_movement
	nav_actuator.update_interval = random_movement_interval
	nav_actuator.distance_threshold = stuck_threshold_distance
	nav_actuator.max_stuck_time = max_stuck_time
	
	# Configure Physics
	impulse_controller.character = self
	impulse_controller.push_force = push_force
	
	# Configure Emotions
	emotion_controller.update_interval = emotion_update_interval
	emotion_controller.emotion_lerp_speed = emotion_lerp_speed
	emotion_controller.strong_emotion_threshold = strong_emotion_threshold
	emotion_controller.moderate_emotion_threshold = moderate_emotion_threshold
	emotion_controller.emoji_manager = emoji_manager

func _process(delta):
	if enabled:
		emotion_controller._process(delta)

func _physics_process(_delta):
	if enabled and apply_impulse and not is_on_floor_only():
		impulse_controller._physics_process()

func _get_base_agent() -> BaseAgent:
	# Look for any child node that extends BaseAgent
	for child in get_children():
		if child is BaseAgent:
			return child
			
	# Log warning in editor if no BaseAgent is found
	if Engine.is_editor_hint():
		push_warning("This node requires a child that extends BaseAgent (e.g. TeacherAgent, StudentAgent)")
	return null

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	# Check for required node-based components
	if not has_node("AgentNavActuator"):
		warnings.append("Missing required AgentNavActuator node")
	if not has_node("EmojiManager"):
		warnings.append("Missing required EmojiManager node")
	if not has_node("BaseAgent"):
		warnings.append("Missing required BaseAgent node")
	
	return warnings
