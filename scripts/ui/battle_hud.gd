extends CanvasLayer
var world: Node3D
var stats: Label
var health: ProgressBar
var battle_status: Label
var target_info: Label
var help: Label
var result: Label
var restart_button: Button

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(410, 165)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	stats = Label.new()
	column.add_child(stats)
	health = ProgressBar.new()
	health.max_value = 100
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.13, 0.5, 0.85)
	health.add_theme_stylebox_override("fill", fill)
	health.custom_minimum_size.y = 22
	column.add_child(health)
	battle_status = Label.new()
	column.add_child(battle_status)
	target_info = Label.new()
	column.add_child(target_info)
	add_child(panel)
	help = Label.new()
	help.position = Vector2(18, 210)
	help.text = "WASD Move | Mouse Orbit | Wheel Zoom\nLMB Attack | Q Shockwave | Tab Cycle target\nEsc Release mouse | Click Capture | R Restart\nDestroy EMBER base to win. Blue allies / Red enemies."
	add_child(help)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column_center := VBoxContainer.new()
	center.add_child(column_center)
	result = Label.new()
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 36)
	column_center.add_child(result)
	restart_button = Button.new()
	restart_button.text = "Restart battle (R)"
	restart_button.pressed.connect(world.restart)
	column_center.add_child(restart_button)
	add_child(center)

func _process(_delta: float) -> void:
	var player: UnitBody = world.player
	stats.text = "MISTFRONT | AZURE GUARD | HP %d / %d" % [player.hp, player.max_hp]
	health.value = player.hp
	battle_status.text = "AZURE base %d | EMBER base %d\nAlive: %d vs %d | Shockwave %.1fs | Attack %.1fs" % [world.bases[0].hp, world.bases[1].hp, world.alive_count(0), world.alive_count(1), player.skill_remaining, player.attack_remaining]
	target_info.text = "Target: none (Tab to lock)"
	if is_instance_valid(world.locked_target) and world.locked_target.is_alive:
		target_info.text = "Target: Enemy #%d | HP %d" % [world.locked_target.unit_id, world.locked_target.hp]
	result.text = ""
	if not player.is_alive:
		result.text = "Respawning in %.1fs" % player.respawn_remaining
	if world.match_over:
		result.text = "VICTORY — AZURE" if world.winner == 0 else "DEFEAT — EMBER"
	restart_button.visible = world.match_over
