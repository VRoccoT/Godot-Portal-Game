extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const TEMPO_INERCIA_PORTAL = 0.25

var inercia_portal_restante: float = 0.0

@export var portal_a: Node3D
@export var portal_b: Node3D

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var raycast: RayCast3D = $CameraPivot/Camera3D/PortalRayCast

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_desativar_portais()

func _unhandled_input(event: InputEvent) -> void:
	# Movimentação da câmera com o mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# Pausar/Liberar Mouse com ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Tecla R: Desativa e esconde ambos os portais
	if event.is_action_pressed("limpar_portais"):
		_desativar_portais()

	# Disparo da Portal Gun (Botão Esquerdo = Portal A | Botão Direito = Portal B)
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_atirar_portal(portal_a)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_atirar_portal(portal_b)

func _desativar_portais() -> void:
	if portal_a:
		portal_a.visible = false
	if portal_b:
		portal_b.visible = false

func _atirar_portal(portal_alvo: Node3D) -> void:
	if not portal_alvo or not raycast.is_colliding():
		return

	var ponto_impacto: Vector3 = raycast.get_collision_point()
	var normal_parede: Vector3 = raycast.get_collision_normal()

	portal_alvo.visible = true
	
	# Evita que a base do portal afunde no chão
	if abs(normal_parede.y) < 0.5:
		ponto_impacto.y = max(ponto_impacto.y, 1.75)

	portal_alvo.global_position = ponto_impacto + (normal_parede * 0.05)

	if normal_parede.is_equal_approx(Vector3.UP) or normal_parede.is_equal_approx(Vector3.DOWN):
		var frente_jogador: Vector3 = -global_transform.basis.z
		portal_alvo.look_at(portal_alvo.global_position - normal_parede, frente_jogador)
	else:
		portal_alvo.look_at(portal_alvo.global_position - normal_parede, Vector3.UP)

func preservar_inercia_portal() -> void:
	# Impede que o controle WASD apague imediatamente a velocidade de saída.
	inercia_portal_restante = TEMPO_INERCIA_PORTAL

func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pulo (Espaço)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Durante 0,25 s após a travessia, mantém a componente horizontal
	# transformada pelo portal, mas continua aplicando gravidade e colisões.
	if inercia_portal_restante > 0.0:
		inercia_portal_restante = maxf(0.0, inercia_portal_restante - delta)
	else:
		# Movimentação usando as ações WASD configuradas no Input Map
		var input_dir := Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
