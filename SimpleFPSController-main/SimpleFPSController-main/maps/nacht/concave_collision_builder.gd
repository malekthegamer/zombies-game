@tool
extends StaticBody3D

@export var source_root : NodePath = NodePath("..")

func _ready() -> void:
	_rebuild_collision_shape()

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_rebuild_collision_shape")

func _rebuild_collision_shape() -> void:
	var root = get_node_or_null(source_root) as Node3D
	var collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if root == null or collision_shape == null:
		return

	var merged_faces := PackedVector3Array()
	var root_inv = root.global_transform.affine_inverse()

	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null:
			continue
		var mesh = mesh_instance.mesh
		if mesh == null:
			continue
		var to_root_space : Transform3D = root_inv * mesh_instance.global_transform
		for vertex in mesh.get_faces():
			merged_faces.append(to_root_space * vertex)

	if merged_faces.is_empty():
		return

	var concave_shape := ConcavePolygonShape3D.new()
	concave_shape.set_faces(merged_faces)
	collision_shape.shape = concave_shape
