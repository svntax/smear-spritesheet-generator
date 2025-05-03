extends Node2D

@export var input_texture: Texture2D

@onready var frame_count: int = 4
@onready var rotation_trail_frames: int = 2
@onready var total_rotation: int = 90
@onready var direction: int = 1
@onready var subregion_p1 := Vector2()
@onready var subregion_p2 := Vector2()
@onready var subregion_enabled := false
@onready var debug_draw: bool = true

func _process(_delta: float) -> void:
	queue_redraw()

func set_params(params: Dictionary) -> void:
	input_texture = params.get("input_texture")
	frame_count = params.get("frame_count")
	rotation_trail_frames = params.get("rotation_trail_frames")
	total_rotation = params.get("total_rotation")
	direction = params.get("direction")
	subregion_p1 = params.get("subregion_p1", Vector2())
	subregion_p2 = params.get("subregion_p2", input_texture.get_size())
	subregion_enabled = params.get("subregion_enabled", false)
	debug_draw = params.get("debug_draw", false)

func _draw() -> void:
	if input_texture == null:
		return
	
	var frame_width = input_texture.get_width()
	var frame_height = input_texture.get_height()
	var pivot := Vector2(-frame_width / 2, -frame_height / 2)
	var total_frames = frame_count + rotation_trail_frames
	var rotation_step = total_rotation / max((frame_count - 1), 1)
	var clockwise = direction >= 0
	
	for frame in range(total_frames):
		var start_rotation = max(0, frame - rotation_trail_frames) * rotation_step
		var end_rotation = min(frame, frame_count - 1) * rotation_step
		var copies = ceil(abs(end_rotation - start_rotation) / 1) + 1

		for i in range(copies):
			var angle = end_rotation * (1 if clockwise else -1)
			if copies > 1:
				var t = float(i) / (copies - 1)
				angle = (start_rotation + (end_rotation - start_rotation) * t) * (1 if clockwise else -1)
			
			var pos = Vector2(frame * frame_width, 0)
			if debug_draw:
				draw_set_transform(Vector2(), 0)
				draw_rect(Rect2((frame)*frame_width-frame_width/2, pos.y-frame_height/2, frame_width, frame_height), Color.MAGENTA, false)
			
			draw_set_transform(pos, deg_to_rad(angle), Vector2.ONE)
			if subregion_enabled:
				var trail_region = Rect2(subregion_p1, subregion_p2 - subregion_p1)
				draw_texture_rect_region(input_texture, Rect2(pivot + trail_region.position, trail_region.size), trail_region)
			else:
				draw_texture(input_texture, pivot)
		
		if subregion_enabled:
			draw_texture_rect_region(input_texture, Rect2(pivot, Vector2(frame_width,frame_height)), Rect2(0,0,frame_width,frame_height))
