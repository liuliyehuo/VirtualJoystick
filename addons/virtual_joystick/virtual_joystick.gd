@tool
class_name GodotStick extends Control

signal stick_move(value: Vector2, distance: float, angle: float, angle_clockwise: float, angle_not_clockwise: float)
signal angle_change(angle: float, angle_clockwise: float, angle_not_clockwise: float)
signal value_change(value: Vector2)
signal distance_change(distance: float)

var joystick_radius: float = 100
var joystick_border_widht = 10
var joystick_start_position: Vector2 = Vector2(joystick_radius + joystick_border_widht, joystick_radius + joystick_border_widht)
var stick_radius: float = 45
var stick_border_width = -1
var stick_start_position: Vector2 = Vector2(joystick_radius + joystick_border_widht, joystick_radius + joystick_border_widht)

var dragging: bool = false
var drag_started_inside: bool = false
var click_in: bool = false

@export_category("Joystick")
@export_color_no_alpha() var joystick_color: Color = Color.WHITE:
	set(value):
		joystick_color = value
		joystick.color = value
		joystick.opacity = joystick_opacity
		queue_redraw()
@export_range(0, 1) var joystick_opacity: float = 0.8:
	set(value):
		joystick_opacity = value
		joystick.opacity = value
		queue_redraw()
@export var joystick_border: float = 10:
	set(value):
		joystick_border = value
		joystick.width = value
		joystick_border_widht = value
		joystick_start_position = Vector2(joystick_radius + joystick_border_widht, joystick_radius + joystick_border_widht)
		joystick.position = joystick_start_position
		stick_start_position = Vector2(joystick_radius + joystick_border_widht, joystick_radius + joystick_border_widht)
		stick.position = stick_start_position
		queue_redraw()
@export_category("Stick")
@export_color_no_alpha() var stick_color: Color = Color.WHITE:
	set(value):
		stick_color = value
		stick.color = value
		stick.opacity = stick_opacity
		queue_redraw()
@export_range(0, 1) var stick_opacity: float = 0.8:
	set(value):
		stick_opacity = value
		stick.opacity = value
		queue_redraw()
@export_category("All")
@export var scale_factor: float = 1:
	set(value):
		scale_factor = value
		scale = Vector2(scale_factor, scale_factor)
		queue_redraw()

var joystick: VirtualJoystickCircle = VirtualJoystickCircle.new(joystick_start_position, joystick_radius, joystick_border_widht, false, joystick_color, joystick_opacity)
var stick: VirtualJoystickCircle = VirtualJoystickCircle.new(stick_start_position, stick_radius, stick_border_width, true, stick_color, stick_opacity)

func _ready() -> void:
	set_size(Vector2(joystick_radius * 2 + joystick_border_widht * 2, joystick_radius * 2 + joystick_border_widht * 2))
	pass


func _draw() -> void:
	joystick.draw(self, false)
	stick.draw(self, false)
	scale = Vector2(scale_factor, scale_factor)
	set_size(Vector2((joystick_radius * 2) + (joystick_border_widht * 2), (joystick_radius * 2) + (joystick_border_widht * 2)))
	
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var distance = event.position.distance_to(joystick.position)
			drag_started_inside = distance <= joystick.radius + joystick.width / 2
			if drag_started_inside:
				click_in = true
				move_stick(event.position)
		else:
			stick.position = stick_start_position
			if click_in:
				queue_redraw()
				process_joystick_input(Vector2.ZERO)
			click_in = false
	elif event is InputEventScreenDrag:
		if drag_started_inside:
			move_stick(event.position)
		

func move_stick(position: Vector2) -> void:
	var delta = position - stick_start_position
	if delta.length() > joystick.radius:
		delta = delta.normalized() * joystick.radius
	stick.position = stick_start_position + delta
	queue_redraw()
	process_joystick_input(delta)


func get_angle(delta: Vector2, continuos: bool, clockwise: bool) -> float:
	var angle_degress = 0
	if continuos and not clockwise:
		angle_degress = rad_to_deg(atan2(-delta.y, delta.x))
	else:
		angle_degress = rad_to_deg(atan2(delta.y, delta.x))
	if continuos and angle_degress < 0:
		angle_degress += 360
	return angle_degress
	
	
func get_value(delta: Vector2) -> Vector2:
	return delta / joystick.radius
	
	
func get_distance(delta: Vector2) -> float:
	return get_value(delta).length()
	

func process_joystick_input(input_vector: Vector2) -> void:
	emit_signal("stick_move", get_value(input_vector), get_distance(input_vector), get_angle(input_vector, false, false), get_angle(input_vector, true, true), get_angle(input_vector, true, false))
	emit_signal("angle_change", get_angle(input_vector, false, false), get_angle(input_vector, true, true), get_angle(input_vector, true, false))
	emit_signal("value_change", get_value(input_vector))
	emit_signal("distance_change", get_distance(input_vector))
	pass
	
#*********************************************************************

class VirtualJoystickCircle extends RefCounted:
	var position: Vector2
	var radius: float
	var color: Color
	var width: float
	var filled: bool
	var antialiased: bool
	var opacity: float:
		set(value):
			opacity = value
			self.color.a = opacity

	func _init(
			position: Vector2,
			radius: float,
			width: float = -1.0,
			filled: bool = true,
			color: Color = Color(255, 255, 255, 1),
			opacity: float = 1,
			antialiased: bool = true
		):
		self.position = position
		self.radius = radius
		self.color = color
		self.width = width
		self.filled = filled
		self.antialiased = antialiased
		self.opacity = opacity
		self.color.a = opacity

	func draw(canvas_item: CanvasItem, offset: bool) -> void:
		if self.filled:
			if offset:
				canvas_item.draw_circle(self.position + Vector2(self.radius, self.radius), self.radius, self.color, self.filled, -1, self.antialiased)
			else:
				canvas_item.draw_circle(self.position, self.radius, self.color, self.filled, -1, self.antialiased)
		else:
			if offset:
				canvas_item.draw_circle(self.position + Vector2(self.radius, self.radius), self.radius, self.color, self.filled, self.width, self.antialiased)
			else:
				canvas_item.draw_circle(self.position, self.radius, self.color, self.filled, self.width, self.antialiased)
