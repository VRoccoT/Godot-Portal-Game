extends Node3D

@export var player_camera: Camera3D

@onready var mirror_mesh: MeshInstance3D = $MirrorMesh
@onready var mirror_viewport: SubViewport = $MirrorViewport
@onready var mirror_camera: Camera3D = $MirrorViewport/MirrorCamera

func _ready() -> void:
	if not mirror_viewport or not mirror_mesh or not mirror_camera:
		set_process(false)
		return

	await get_tree().process_frame

	var viewport_texture: ViewportTexture = mirror_viewport.get_texture()
	var material = mirror_mesh.get_active_material(0)

	if material is ShaderMaterial:
		material.set_shader_parameter("reflection_texture", viewport_texture)

func _process(_delta: float) -> void:
	if not is_instance_valid(player_camera):
		player_camera = get_viewport().get_camera_3d()
		if not is_instance_valid(player_camera):
			return

	# Copia a projeção da câmera principal
	mirror_camera.fov = player_camera.fov
	mirror_camera.far = player_camera.far

	# Posição e orientação global do espelho
	var mirror_gt: Transform3D = mirror_mesh.global_transform
	var mirror_pos: Vector3 = mirror_gt.origin
	var mirror_normal: Vector3 = mirror_gt.basis.z.normalized()

	# Posição global do jogador
	var player_pos: Vector3 = player_camera.global_position
	var dist: float = (player_pos - mirror_pos).dot(mirror_normal)

	# Se o jogador estiver atrás da face do espelho, interrompe a atualização
	if dist <= 0.001:
		return

	# Ajusta o Near Plane para coincidir exatamente com a superfície do espelho
	mirror_camera.near = max(0.01, dist)

	# Calcula a posição refletida sem sair dos limites do mapa
	var reflected_pos: Vector3 = player_pos - 2.0 * dist * mirror_normal
	mirror_camera.global_position = reflected_pos

	# Orienta a rotação refletida
	var player_gt: Transform3D = player_camera.global_transform
	var forward: Vector3 = -player_gt.basis.z
	var up: Vector3 = player_gt.basis.y

	var ref_forward: Vector3 = forward - 2.0 * forward.dot(mirror_normal) * mirror_normal
	var ref_up: Vector3 = up - 2.0 * up.dot(mirror_normal) * mirror_normal

	if ref_forward.length_squared() > 0.001:
		mirror_camera.look_at(reflected_pos + ref_forward, ref_up)
