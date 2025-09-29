extends CharacterBody3D

@onready var player_pcam: PhantomCamera3D
@onready var player_visual: Node3D = $PlayerVisual
@onready var animation_player: AnimationPlayer = $PlayerVisual/AnimationPlayer

@export var mouse_sensitivity: float = 0.05
@export var min_pitch: float = -89.9
@export var max_pitch: float = 50

# Movement parameters
@export var walk_speed: float = 3.0
@export var run_speed: float = 6.0
@export var jump_velocity: float = 4.5
@export var acceleration: float = 40.0  # Much faster acceleration
@export var deceleration: float = 30.0  # Much faster deceleration
@export var air_control: float = 0.3  # Reduced air control
@export var rotation_speed: float = 15.0

enum AnimState { IDLE, WALK, RUN, JUMP, FALL }
var current_anim_state: AnimState = AnimState.IDLE
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	player_pcam = owner.get_node("%PlayerPhantomCamera3D")
	if player_pcam.get_follow_mode() == player_pcam.FollowMode.THIRD_PERSON:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	
	# Gravity
	if not on_floor:
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and on_floor:
		velocity.y = jump_velocity
	
	# Input and direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var camera_basis: Basis = player_pcam.global_transform.basis
	var direction := (camera_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0
	
	var is_sprinting: bool = Input.is_action_pressed("sprint") and on_floor
	var target_speed: float = run_speed if is_sprinting else walk_speed
	
	# Apply acceleration (less in air)
	var accel := acceleration if on_floor else acceleration * air_control
	var decel := deceleration if on_floor else deceleration * air_control
	
	if direction:
		var target_velocity := direction * target_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
		
		var target_rotation := atan2(direction.x, direction.z)
		player_visual.rotation.y = lerp_angle(player_visual.rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)
		velocity.z = move_toward(velocity.z, 0, decel * delta)
	
	move_and_slide()
	update_animation_state(is_sprinting)

func update_animation_state(is_sprinting: bool) -> void:
	var new_state: AnimState
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	
	if not is_on_floor():
		new_state = AnimState.JUMP if velocity.y > 0 else AnimState.FALL
	elif horizontal_speed > 0.2:
		new_state = AnimState.RUN if is_sprinting else AnimState.WALK
	else:
		new_state = AnimState.IDLE
	
	if new_state != current_anim_state:
		current_anim_state = new_state
		play_animation(current_anim_state)

func play_animation(state: AnimState) -> void:
	match state:
		AnimState.IDLE: animation_player.play("PlayerCharacter/Idle")
		AnimState.WALK: animation_player.play("PlayerCharacter/Walk")
		AnimState.RUN: animation_player.play("PlayerCharacter/Run")
		AnimState.JUMP: animation_player.play("PlayerCharacter/Jump")
		AnimState.FALL:
			if animation_player.has_animation("fall"):
				animation_player.play("fall")
			else:
				animation_player.play("PlayerCharacter/Jump")

func _unhandled_input(event: InputEvent) -> void:
	if player_pcam.get_follow_mode() == player_pcam.FollowMode.THIRD_PERSON:
		set_pcam_rotation(player_pcam, event)

func set_pcam_rotation(pcam: PhantomCamera3D, event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var pcam_rotation_degrees: Vector3 = pcam.get_third_person_rotation_degrees()
		
		pcam_rotation_degrees.x -= event.relative.y * mouse_sensitivity
		pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_pitch, max_pitch)
		
		pcam_rotation_degrees.y -= event.relative.x * mouse_sensitivity
		pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, 0, 360)
		
		pcam.set_third_person_rotation_degrees(pcam_rotation_degrees)
