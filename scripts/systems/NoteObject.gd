extends StaticBody3D

@export var note_id      : String = "note_01"
@export var note_title   : String = "Запись пациента"
@export_multiline var note_content : String = "..."
@export var interact_text: String = "Прочитать записку"

func interact(p: Node) -> void:
	GameManager.find_note(note_id, note_content)
	if p.has_method("restore_sanity"): p.restore_sanity(6.0)
	if p.has_node("HUD"): p.get_node("HUD").show_note(note_title, note_content)
