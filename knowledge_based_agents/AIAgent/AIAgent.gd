class_name AIAgent extends CharacterBody3D

signal movement_started
signal movement_stopped

# Base Agent Script Setting
@export_group("Agent")
@export var agent_enabled = true
@export var agent_script: Script
@export var agent_update_interval = 1.0
@export var agent_show_debug = false

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

# Perception Settings
@export_group("Perception")
@export var perception_enabled = true
@export var perception_radius: float = 10.0
@export var debug_perception: bool = false

# Emotion Settings
@export_group("Emotions")
@export var emotions_enabled = true
@export var emotion_update_interval: float = 0.05
@export var emotion_lerp_speed: float = 8.0
@export var strong_emotion_threshold: float = 0.75
@export var moderate_emotion_threshold: float = 0.4

# Child Node References
@onready var actuator: AgentActuator = $NavigationAgent3D
@onready var emoji_manager: Sprite3D = $EmojiManager

# Integrated Components
var base_agent: AgentBaseBehaviour
var impulse_controller: ImpulseApplicator
var emotion_controller: EmotionController
var perception: AgentPerception

func _init():
	# Create components that don't need node references
	emotion_controller = EmotionController.new()

func _ready():
	# Get required world state reference
	var world_state = WorldState.find(get_tree())
	if not world_state:
		push_error("AIAgent requires valid WorldState in scene!")
		return
	
	# Initialize perception first since others depend on it
	perception = AgentPerception.new(self, world_state)
	perception.show_debug = debug_perception
	
	# Now initialize impulse controller with perception
	impulse_controller = ImpulseApplicator.new(self, perception)
	impulse_controller.push_force = push_force
	
	# Configure navigation actuator
	actuator.speed = movement_speed
	actuator.debug_info = debug_navigation
	actuator.random_movement = random_movement
	actuator.update_interval = random_movement_interval
	actuator.distance_threshold = stuck_threshold_distance
	actuator.max_stuck_time = max_stuck_time
	
	# Configure emotion system
	if emotions_enabled:
		emotion_controller.update_interval = emotion_update_interval
		emotion_controller.emotion_lerp_speed = emotion_lerp_speed
		emotion_controller.strong_emotion_threshold = strong_emotion_threshold
		emotion_controller.moderate_emotion_threshold = moderate_emotion_threshold
		emotion_controller.emoji_manager = emoji_manager
	
	# Initialize base agent last since it depends on other systems
	_initialize_base_agent(world_state)

func _initialize_base_agent(world_state: WorldState):
	if not agent_script:
		push_error("AIAgent requires valid agent_script!")
		return
		
	# Instantiate and configure base agent
	base_agent = agent_script.new()
	base_agent.update_interval = agent_update_interval
	base_agent.show_debug = agent_show_debug
	
	# Provide required references
	base_agent.scene_tree = get_tree()
	base_agent.world_state = world_state
	base_agent.actuator = actuator
	base_agent.emotion_controller = emotion_controller if emotions_enabled else null
	base_agent.perception = perception
	
	# Initialize agent systems
	base_agent._ready()

func _process(delta):
	if agent_enabled and base_agent:
		base_agent._process(delta)
	if emotions_enabled and emotion_controller:
		emotion_controller._process(delta)

func _physics_process(delta):
	if perception_enabled:
		perception.process_collisions()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if not agent_script:
		warnings.append("No base agent script specified!")
	elif not (agent_script.new() is AgentBaseBehaviour):
		warnings.append("Specified script must extend AgentBaseBehaviour!")
	if not has_node("NavigationAgent3D"):
		warnings.append("Missing required NavigationAgent3D node")
	if not has_node("EmojiManager"):
		warnings.append("Missing required EmojiManager node")
		
	if emotions_enabled and not has_node("EmojiManager"):
		warnings.append("Emotions enabled but missing EmojiManager node")
	
	return warnings
