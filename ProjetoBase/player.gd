extends CharacterBody3D

@export_group("Movimentação")
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera3D

# Gravidade padrão do projeto
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Trava e esconde o cursor do mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Garante que esta é a câmera ativa do viewport
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	# Controle de rotação de câmera via mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Girar o corpo no eixo Y (esquerda/direita)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Girar a cabeça no eixo X (cima/baixo)
		neck.rotate_x(-event.relative.y * mouse_sensitivity)
		# Trava a rotação da cabeça em 89 graus para não dar volta completa
		neck.rotation.x = clamp(neck.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
	
	# Pressionar ESC libera ou recoleta o cursor
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Aplicar gravidade se estiver caindo
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Pulo (usando o comando padrão de espaço / ui_accept)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Capturar entradas direcionais (W, A, S, D / Setas)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
