extends Node3D

@export var outro_portal: Node3D 

@onready var tela_portal: MeshInstance3D = $TelaPortal
@onready var sub_viewport: SubViewport = $SubViewport
@onready var minha_camera: Camera3D = $SubViewport/CameraDoPortal

var camera_do_jogador: Camera3D
var recem_teletransportado: bool = false 
var material_portal: ShaderMaterial

func _ready() -> void:
	sub_viewport.size = get_viewport().size
	get_viewport().size_changed.connect(func(): sub_viewport.size = get_viewport().size)
	
	# Pega a referência do ShaderMaterial (seja no Material Override ou Overlay)
	if tela_portal.material_override is ShaderMaterial:
		material_portal = tela_portal.material_override
	elif tela_portal.material_overlay is ShaderMaterial:
		material_portal = tela_portal.material_overlay
	else:
		material_portal = tela_portal.get_active_material(0) as ShaderMaterial

func _process(_delta: float) -> void:
	# Verifica se ESTE portal e o OUTRO portal estão abertos ao mesmo tempo
	var par_completo: bool = visible and outro_portal != null and outro_portal.visible
	
	# Alterna entre a imagem em tempo real e a cor cinza no Shader
	if material_portal:
		material_portal.set_shader_parameter("portal_ativo", par_completo)
	
	# Se o par não estiver completo, não precisa calcular a câmera nem gastar processamento
	if not par_completo:
		return

	if not camera_do_jogador:
		camera_do_jogador = get_viewport().get_camera_3d()
		return

	_atualizar_perspectiva_portal()

func _atualizar_perspectiva_portal() -> void:
	var transform_local: Transform3D = global_transform.affine_inverse() * camera_do_jogador.global_transform
	var transform_saida: Transform3D = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO) * transform_local

	minha_camera.global_transform = outro_portal.global_transform * transform_saida
	minha_camera.fov = camera_do_jogador.fov
	minha_camera.far = camera_do_jogador.far

	var vetor_ate_portal: Vector3 = outro_portal.global_position - minha_camera.global_position
	var normal_outro_portal: Vector3 = outro_portal.global_transform.basis.z
	var distancia_perpendicular: float = abs(vetor_ate_portal.dot(normal_outro_portal))
	
	minha_camera.near = max(0.05, distancia_perpendicular - 0.05)


func _on_area_travessia_body_entered(_body: Node3D) -> void:
	# A entrada na área não deve causar teletransporte imediato.
	pass

func _physics_process(_delta: float) -> void:
	if not visible or not is_instance_valid(outro_portal):
		return

	if not outro_portal.visible or recem_teletransportado:
		return

	var normal_portal: Vector3 = global_transform.basis.z.normalized()

	for corpo in $AreaTravessia.get_overlapping_bodies():
		if corpo is CharacterBody3D:
			var pos_local: Vector3 = to_local(corpo.global_position)

			# Deve estar na frente e próximo ao plano do portal.
			if pos_local.z <= 0.0 or pos_local.z > 0.70:
				continue

			# Deve estar suficientemente centralizado na abertura.
			if absf(pos_local.x) > 0.55:
				continue
			if absf(pos_local.y) > 0.85:
				continue

			# Deve estar se movendo em direção ao portal.
			if corpo.velocity.dot(normal_portal) >= -0.2:
				continue

			_teletransportar_jogador(corpo)
			break

func _teletransportar_jogador(jogador: CharacterBody3D) -> void:
	outro_portal.recem_teletransportado = true
	
	var local_transform: Transform3D = global_transform.affine_inverse() * jogador.global_transform
	var transform_saida: Transform3D = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO) * local_transform
	jogador.global_transform = outro_portal.global_transform * transform_saida
	
	jogador.rotation.x = 0
	jogador.rotation.z = 0
	jogador.global_position += outro_portal.global_transform.basis.z * 0.5
	
	var velocidade_local: Vector3 = global_transform.basis.inverse() * jogador.velocity
	velocidade_local = velocidade_local.rotated(Vector3.UP, PI)
	jogador.velocity = outro_portal.global_transform.basis * velocidade_local

	await get_tree().create_timer(0.15).timeout
	outro_portal.recem_teletransportado = false
