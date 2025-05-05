extends Node2D

@onready var sprite_upload: FileDialog = %SpriteUpload
@onready var save_spritesheet: FileDialog = %SaveSpritesheet
@onready var alert_dialog: AcceptDialog = %AlertDialog
@onready var save_success_dialog: AcceptDialog = %SaveSuccessDialog

@onready var generate_btn: Button = %GenerateBtn
@onready var save_btn: Button = %SaveBtn
@onready var upload_btn: Button = %UploadBtn
@onready var input_texture: TextureRect = %InputTexture
@onready var input_image_size_label: Label = %InputImageSizeLabel
@onready var output_sprite: Sprite2D = %OutputSprite
@onready var output_texture: TextureRect = %OutputTexture
@onready var output_animated_sprite: Sprite2D = %OutputAnimatedSprite
@onready var output_animated_texture: TextureRect = %OutputAnimatedTexture
@onready var canvas_generator: Node2D = %CanvasGenerator

@onready var subregion_checkbox: CheckBox = %SubregionCheckbox
@onready var spinbox_x1: SpinBox = %SpinBoxX1
@onready var spinbox_y1: SpinBox = %SpinBoxY1
@onready var spinbox_x2: SpinBox = %SpinBoxX2
@onready var spinbox_y2: SpinBox = %SpinBoxY2

@onready var effect_option_button: OptionButton = %EffectOptionButton

# Linear smear components
@onready var linear_smear_container: GridContainer = %LinearSmearContainer
@onready var direction_input: SpinBox = %DirectionInput
@onready var smear_length_input: SpinBox = %SmearLengthInput
@onready var frame_count_input: SpinBox = %FrameCountInput
# TODO: Implement trail frames for linear smear?
@onready var linear_trail_frames_input: SpinBox = %LinearTrailFramesInput

# Rotation smear components
@onready var rotation_smear_container: GridContainer = %RotationSmearContainer
@onready var rotation_direction_option: OptionButton = %RotationDirectionOption
@onready var rotation_degrees_input: SpinBox = %RotationDegreesInput
@onready var rotation_frames_input: SpinBox = %RotationFramesInput
@onready var rotation_trail_frames_input: SpinBox = %RotationTrailFramesInput

var original_sprite: Texture2D = null
@onready var anim_timer: float = 0

func _ready():
	save_btn.pressed.connect(func():
		if !original_sprite:
			alert_dialog.size = Vector2(130, 70)
			alert_dialog.show()
			alert_dialog.dialog_text = "Missing input image!"
			return
		if !output_texture.texture:
			alert_dialog.size = Vector2(130, 70)
			alert_dialog.show()
			alert_dialog.dialog_text = "Spritesheet output is empty."
			return
		save_spritesheet.visible = !save_spritesheet.visible
	)
	generate_btn.pressed.connect(generate_spritesheet)
	sprite_upload.file_selected.connect(on_sprite_uploaded)
	save_spritesheet.file_selected.connect(_save_spritesheet)
	upload_btn.pressed.connect(func():
		sprite_upload.visible = !sprite_upload.visible
	)
	effect_option_button.item_selected.connect(_on_effect_selected)
	input_texture.texture = null
	
	# Ensure that (x1, y1) is positioned before (x2, y2)
	spinbox_x1.value_changed.connect(func(value: int):
		spinbox_x2.value = clampi(spinbox_x2.value, value, spinbox_x2.max_value)
		update_subregion_rect()
	)
	spinbox_y1.value_changed.connect(func(value: int):
		spinbox_y2.value = clampi(spinbox_y2.value, value, spinbox_y2.max_value)
		update_subregion_rect()
	)
	spinbox_x2.value_changed.connect(func(value: int):
		spinbox_x1.value = clampi(spinbox_x1.value, 0, value)
		update_subregion_rect()
	)
	spinbox_y2.value_changed.connect(func(value: int):
		spinbox_y1.value = clampi(spinbox_y1.value, 0, value)
		update_subregion_rect()
	)
	
	# Subregion rectangle toggle
	subregion_checkbox.toggled.connect(func(toggled_on: bool):
		update_subregion_rect()
	)

func _on_effect_selected(index: int) -> void:
	if index == 0:
		linear_smear_container.show()
		rotation_smear_container.hide()
	elif index == 1:
		linear_smear_container.hide()
		rotation_smear_container.show()

func _save_spritesheet(path: String) -> void:
	var img = output_texture.texture.get_image()
	var error = img.save_png(path)
	if error == OK:
		save_success_dialog.dialog_text = "Saved to:\n%s" % path
		save_success_dialog.show()
	else:
		alert_dialog.size = Vector2(130, 84)
		alert_dialog.show()
		alert_dialog.dialog_text = "Error %s - Failed to save spritesheet." % error

func _process(delta: float) -> void:
	# Preview animation
	anim_timer += delta
	if anim_timer >= 0.1:
		anim_timer -= 0.1
		output_animated_sprite.frame = (output_animated_sprite.frame + 1) % output_animated_sprite.hframes

func update_subregion_rect() -> void:
	if input_texture == null: return
	
	input_texture.set_subregion_corners(Vector2(spinbox_x1.value, spinbox_y1.value), Vector2(spinbox_x2.value, spinbox_y2.value))
	input_texture.toggle_subregion(subregion_checkbox.button_pressed)

func update_subregion_parameters() -> void:
	if input_texture.texture == null: return
	
	_clamp_subregion_parameters()
	spinbox_x1.value = 0
	spinbox_y1.value = 0
	spinbox_x2.value = input_texture.texture.get_width()
	spinbox_y2.value = input_texture.texture.get_height()

# Update the subregion parameters to match the current texture
func _clamp_subregion_parameters() -> void:
	if input_texture.texture == null: return
	
	spinbox_x1.max_value = input_texture.texture.get_width()
	spinbox_y1.max_value = input_texture.texture.get_height()
	spinbox_x2.max_value = input_texture.texture.get_width()
	spinbox_y2.max_value = input_texture.texture.get_height()

func on_sprite_uploaded(file_path: String):
	var image = Image.new()
	image.load(file_path)
	original_sprite = ImageTexture.create_from_image(image)
	input_texture.texture = original_sprite
	input_image_size_label.text = "%d x %d" % [original_sprite.get_width(), original_sprite.get_height()]
	update_subregion_parameters()

func generate_spritesheet():
	if !original_sprite:
		alert_dialog.size = Vector2(130, 70)
		alert_dialog.show()
		alert_dialog.dialog_text = "Missing input sprite!"
		return

	var frame_width = input_texture.texture.get_size().x
	var frame_height = input_texture.texture.get_size().y
	var effect_name = effect_option_button.get_item_text(effect_option_button.selected).to_upper()
	var generated_texture: Texture2D

	generate_btn.disabled = true
	if effect_name == "LINEAR SMEAR":
		var direction = direction_input.value
		var smear_length = smear_length_input.value
		var frame_count = int(frame_count_input.value)
		generated_texture = generate_linear_smear(direction, smear_length, frame_count, frame_width, frame_height)
		output_sprite.texture = generated_texture
		output_texture.texture = generated_texture
		output_animated_sprite.texture = generated_texture
		output_animated_sprite.hframes = frame_count
		output_animated_texture.custom_minimum_size = Vector2(frame_width, frame_height)
	elif effect_name == "ROTATION SMEAR":
		var rotation_direction = (1 if rotation_direction_option.selected == 0 else -1)
		var total_rotation = rotation_degrees_input.value
		var frame_count = rotation_frames_input.value
		var rotation_trail_frames = int(rotation_trail_frames_input.value)
		var total_frames: int = frame_count + rotation_trail_frames
		generated_texture = await generate_rotation_smear_fast(rotation_direction, total_rotation, frame_count, rotation_trail_frames, total_frames, frame_width, frame_height)
		output_sprite.texture = generated_texture
		output_texture.texture = generated_texture
		output_animated_sprite.texture = generated_texture
		output_animated_sprite.hframes = total_frames
		output_animated_texture.custom_minimum_size = Vector2(frame_width, frame_height)

	generate_btn.disabled = false
	return generated_texture

func generate_linear_smear(direction: float, smear_length: float, frame_count: int, frame_width: int, frame_height: int) -> Texture2D:
	var output_image = Image.new()
	output_image = Image.create(frame_width * frame_count, frame_height, false, Image.FORMAT_RGBA8)

	for frame in range(frame_count):
		var progress = float(frame) / (frame_count - 1)
		var end_x = cos(deg_to_rad(direction)) * smear_length
		var end_y = sin(deg_to_rad(direction)) * smear_length
		var copies = ceil(max(abs(end_x), abs(end_y)) / 1) + 1

		for i in range(copies):
			var t = float(i) / (copies - 1)
			var x = int(frame * frame_width + t * end_x * progress)
			var y = int(t * end_y * progress)
			output_image.blend_rect(original_sprite.get_image(), Rect2(0, 0, frame_width, frame_height), Vector2(x, y))

	return ImageTexture.create_from_image(output_image)

func generate_rotation_smear_fast(direction: float, total_rotation: float, frame_count: int, start_rotation_trail: int, total_frames: int, frame_width: int, frame_height: int) -> Texture2D:
	var output_image = Image.new()
	output_image = Image.create(frame_width * total_frames, frame_height, false, Image.FORMAT_RGBA8)

	# Create a temporary viewport to render the rotated sprite
	var viewport = SubViewport.new()
	viewport.size = Vector2(frame_width * total_frames, frame_height)
	viewport.transparent_bg = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	add_child(viewport)
	
	# Debug
	$SubViewport.size = viewport.size

	var params = {
		"input_texture": input_texture.texture,
		"frame_count": frame_count,
		"rotation_trail_frames": start_rotation_trail,
		"total_rotation": total_rotation,
		"direction": sign(direction),
		"subregion_enabled": subregion_checkbox.button_pressed,
		"subregion_p1": Vector2(spinbox_x1.value, spinbox_y1.value),
		"subregion_p2": Vector2(spinbox_x2.value, spinbox_y2.value)
	}
	# Update the main canvas generator
	canvas_generator.set_params(params)
	await get_tree().process_frame
	# Create a new canvas item to render the input sprite with transformations
	var canvas_node = canvas_generator.duplicate(DuplicateFlags.DUPLICATE_USE_INSTANTIATION + DuplicateFlags.DUPLICATE_SCRIPTS)
	canvas_node.position = Vector2(frame_width / 2, frame_height / 2)
	viewport.add_child(canvas_node)
	canvas_node.set_params(params)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	
	var rotated_image: Image = viewport.get_texture().get_image()

	# Calculate the position to blit the rotated image into the output image
	var blit_position = Vector2(0, 0)
	output_image.blend_rect(rotated_image, Rect2(0, 0, rotated_image.get_width(), rotated_image.get_height()), blit_position)

	# Clean up
	viewport.queue_free()

	return ImageTexture.create_from_image(output_image)
