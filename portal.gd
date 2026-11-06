extends Node3D

@export var target_portal: Node3D
@export var player_camera: Camera3D

@onready var portal_mesh: MeshInstance3D = $PortalMesh
@onready var portal_viewport: SubViewport = $PortalViewport
@onready var portal_camera: Camera3D = $PortalViewport/PortalCamera

var _material_setup_done: bool = false

func _ready() -> void:
	if not portal_viewport or not portal_mesh or not portal_camera:
		set_process(false)
		return

	await get_tree().process_frame

func _setup_target_material() -> void:
	if not is_instance_valid(target_portal):
		return

	var target_mesh: MeshInstance3D = target_portal.get_node_or_null("PortalMesh")
	if target_mesh:
		# Duplica o material para isolar as superfícies dos dois portais
		var mat = target_mesh.get_active_material(0)
		if mat is ShaderMaterial:
			var local_mat = mat.duplicate() as ShaderMaterial
			target_mesh.set_surface_override_material(0, local_mat)
			# Envia a imagem gerada por ESTE viewport para o portal de DESTINO
			local_mat.set_shader_parameter("target_texture", portal_viewport.get_texture())
			_material_setup_done = true

func _process(_delta: float) -> void:
	if not _material_setup_done and is_instance_valid(target_portal):
		_setup_target_material()

	if not is_instance_valid(player_camera):
		player_camera = get_viewport().get_camera_3d()
		if not is_instance_valid(player_camera):
			return

	if not is_instance_valid(target_portal):
		return

	# 1. Sincroniza FOV e far da câmera do jogador
	portal_camera.fov = player_camera.fov
	portal_camera.far = player_camera.far

	# --- MATEMÁTICA PARA A CÂMERA ACOMPANHAR A ROTAÇÃO DO PORTAL ---
	var in_transform: Transform3D = global_transform
	var out_transform: Transform3D = target_portal.global_transform
	var player_gt: Transform3D = player_camera.global_transform

	# A) Descobre onde o jogador está em relação ao portal de ENTRADA (espaço local)
	var player_local: Transform3D = in_transform.affine_inverse() * player_gt

	# B) Calcula a nova posição e rotação GLOBAL da câmera no portal de SAÍDA.
	# A rotação do nó target_portal (out_transform) vai girar automaticamente a PortalCamera!
	var new_camera_transform: Transform3D = out_transform * player_local

	# C) Aplica a transformação global calculada na câmera do portal
	portal_camera.global_transform = new_camera_transform

	# --- AJUSTE DO NEAR PLANE PARA NÃO CORTAR A PAREDE ---
	var out_pos: Vector3 = out_transform.origin
	var out_normal: Vector3 = out_transform.basis.z.normalized()
	var dist_to_plane: float = (portal_camera.global_position - out_pos).dot(out_normal)

	portal_camera.near = max(0.01, dist_to_plane)
