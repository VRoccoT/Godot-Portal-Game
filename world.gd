extends Node3D

@onready var portal1: Node3D = $Portal1
@onready var portal2: Node3D = $Portal2

func _ready() -> void:
	if is_instance_valid(portal1) and is_instance_valid(portal2):
		portal1.set("target_portal", portal2)
		portal2.set("target_portal", portal1)
