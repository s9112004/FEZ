class_name Stronghold
extends Node3D
signal destroyed(base: Stronghold)
var team: int = 0
var max_hp: float = 3600.0
var hp: float = 3600.0
var is_alive: bool = true
var health_label: Label3D

func _ready() -> void:
	health_label = Label3D.new()
	health_label.position.y = 6
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 48
	health_label.pixel_size = 0.015
	health_label.modulate = Color(0.3, 0.7, 1) if team == 0 else Color(1, 0.35, 0.2)
	add_child(health_label)
	_refresh_label()

func take_damage(amount: float, source_team: int) -> void:
	if not is_alive or source_team == team or amount <= 0:
		return
	hp = maxf(0, hp - amount)
	_refresh_label()
	if hp == 0:
		is_alive = false
		destroyed.emit(self)

func _refresh_label() -> void:
	if health_label:
		health_label.text = ("AZURE" if team == 0 else "EMBER") + " BASE " + str(int(hp))
