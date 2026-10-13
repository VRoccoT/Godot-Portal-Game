extends Node3D

@export var target_portal: Node3D # Arraste o outro portal no Inspector
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
		# Duplica o material no Portal de Destino para garantir independência de textura
		var mat = target_mesh.get_active_material(0)
		if mat is ShaderMaterial:
			var local_mat = mat.duplicate() as ShaderMaterial
			target_mesh.set_surface_override_material(0, local_mat)
			# Passa a textura gerada por ESTE viewport para o portal de destino
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

	# Sincroniza projeção da câmera principal
	portal_camera.fov = player_camera.fov
	portal_camera.far = player_camera.far

	# --- MATEMÁTICA DE PORTAL 3D COMPLETA ---
	# Matriz de transformação global deste portal (A) e do portal de destino (B)
	var in_transform: Transform3D = global_transform
	var out_transform: Transform3D = target_portal.global_transform

	# Transformação relativa do jogador em relação a este portal (A)
	var player_gt: Transform3D = player_camera.global_transform
	var relative_to_in: Transform3D = in_transform.affine_inverse() * player_gt

	# Matriz de inversão de 180° no eixo Y local (girar para olhar para fora da saída)
	var flip_y := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	
	# Matriz da câmera do portal de saída (B)
	var out_camera_gt: Transform3D = out_transform * flip_y * relative_to_in
	
	# Aplica a transformação exata à câmera interna do portal
	portal_camera.global_transform = out_camera_gt

	# --- CORTE DINÂMICO DE PAREDE (NEAR PLANE OBLÍQUO) ---
	var out_pos: Vector3 = out_transform.origin
	var out_normal: Vector3 = out_transform.basis.z.normalized()
	var dist_to_plane: float = (out_camera_gt.origin - out_pos).dot(out_normal)

	# Evita que a câmera renderize a estrutura/parede atrás do portal de destino
	portal_camera.near = max(0.01, dist_to_plane)
