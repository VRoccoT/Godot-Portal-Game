extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

func _ready() -> void:
	# Captura o mouse na tela para controle 3D
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Trecho da rotação do mouse em Jogador.gd:
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Gira o corpo inteiro no eixo Y (isso permite o teletransporte rotacionar o jogador)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Gira apenas a câmera/pivot no eixo X (olhar cima/baixo)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pulo (Espaço)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Direção WASD
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Alternativa para mapeamento WASD se não configurou as Input Actions:
	if input_dir == Vector2.ZERO:
		var raw_x := Input.get_axis("ui_left", "ui_right")
		var raw_y := Input.get_axis("ui_up", "ui_down")
		input_dir = Vector2(raw_x, raw_y)

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
