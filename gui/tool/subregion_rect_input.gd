extends CanvasItem

@onready var point1 := Vector2()
@onready var point2 := Vector2()
@onready var subregion_toggled := false

func set_subregion_corners(p1: Vector2, p2: Vector2) -> void:
	point1 = Vector2(p1)
	point2 = Vector2(p2)

func toggle_subregion(toggle: bool) -> void:
	subregion_toggled = toggle
	queue_redraw()

func _draw() -> void:
	if subregion_toggled:
		draw_rect(Rect2(point1.x+1, point1.y+1, point2.x-point1.x, point2.y-point1.y), Color.GREEN, false)
