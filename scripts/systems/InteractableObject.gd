## InteractableObject.gd — Base class for all interactable items
extends StaticBody3D
class_name InteractableObject

@export var interact_text  : String = "[E] Examine"
@export var object_type    : String = "generic"  # note/door/item/switch/drawer
@export var object_id      : String = ""
@export var is_one_shot    : bool   = true
@export var requires_item  : String = ""

var has_been_used : bool = false

signal interacted(player: Node)

func interact(player: Node) -> void:
	if is_one_shot and has_been_used: return
	if requires_item != "" and not GameManager.has_item(requires_item):
		_show_locked_message(player)
		return
	has_been_used = is_one_shot
	interacted.emit(player)
	_do_interact(player)

func _do_interact(player: Node) -> void:
	pass  # Override in subclasses

func _show_locked_message(player: Node) -> void:
	pass
