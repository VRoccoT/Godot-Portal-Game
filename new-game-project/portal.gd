extends Node3D

@export var outro_portal: Node3D 

@onready var sub_viewport: SubViewport = $SubViewport
@onready var minha_camera: Camera3D = $SubViewport/CameraDoPortal

var camera_do_jogador: Camera3D
# Cooldown simples para evitar loops infinitos de teletransporte imediato
var recem_teletransportado: bool = false 

func _ready() -> void:
	sub_viewport.size = Vector2i(1080, 1890)

func _process(_delta: float) -> void:
	if not outro_portal:
		return

	if not camera_do_jogador:
		camera_do_jogador = get_viewport().get_camera_3d()
		return

	_atualizar_perspectiva_portal()

func _atualizar_perspectiva_portal() -> void:
	var transform_relativa: Transform3D = global_transform.affine_inverse() * camera_do_jogador.global_transform
	var transform_saida: Transform3D = transform_relativa.rotated(Vector3.UP, PI)

	minha_camera.global_transform = outro_portal.global_transform * transform_saida
	minha_camera.fov = camera_do_jogador.fov

	var distancia_jogador: float = global_transform.origin.distance_to(camera_do_jogador.global_transform.origin)
	minha_camera.near = clamp(distancia_jogador * 0.05, 0.01, 0.5)
	minha_camera.far = camera_do_jogador.far

## Chamado quando algo (como o Jogador) entra na AreaTravessia
func _on_area_travessia_body_entered(body: Node3D) -> void:
	if recem_teletransportado or not outro_portal:
		return

	# Verifica se o objeto que entrou é um personagem físico (CharacterBody3D)
	if body is CharacterBody3D:
		_teletransportar_jogador(body)

func _teletransportar_jogador(jogador: CharacterBody3D) -> void:
	# 1. Trava temporariamente o portal de destino para não re-teletransportar instantaneamente
	outro_portal.recem_teletransportado = true
	
	# 2. Transforma a posição global do jogador para a saída do outro portal
	var local_transform: Transform3D = global_transform.affine_inverse() * jogador.global_transform
	var transform_saida: Transform3D = local_transform.rotated(Vector3.UP, PI)
	jogador.global_transform = outro_portal.global_transform * transform_saida
	
	# 3. Converte a velocidade linear (momento) para sair na direção certa do novo portal
	var velocidade_local: Vector3 = global_transform.basis.inverse() * jogador.velocity
	velocidade_local = velocidade_local.rotated(Vector3.UP, PI)
	jogador.velocity = outro_portal.global_transform.basis * velocidade_local

	# 4. Libera a trava após o jogador se afastar um pouco (0.1 segundos)
	await get_tree().create_timer(0.1).timeout
	outro_portal.recem_teletransportado = false
