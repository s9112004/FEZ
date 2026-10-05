extends CanvasLayer
var world: Node3D
var stats: Label
var health: ProgressBar
var battle_status: Label
var target_info: Label
var result: Label
var restart_button: Button
var base_bars: Array[ProgressBar] = []
var skill_label: Label
var dodge_label: Label
var attack_label: Label

func _ready() -> void:
	var map := preload("res://scripts/ui/battle_minimap.gd").new()
	map.world = world
	map.position = Vector2(18, 18)
	map.size = Vector2(164, 164)
	add_child(map)
	var map_title := Label.new()
	map_title.text = "MISTFRONT / NORTH UP"
	map_title.position = Vector2(18, 186)
	map_title.add_theme_font_size_override("font_size", 12)
	add_child(map_title)
	var top := _panel(Control.PRESET_CENTER_TOP, Vector2(-240, 18), Vector2(480, 110))
	battle_status = Label.new()
	battle_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(battle_status)
	for team in range(2):
		var bar := _bar(Color(0.18, 0.53, 0.85) if team == 0 else Color(0.8, 0.22, 0.12))
		bar.max_value = world.bases[team].max_hp
		top.add_child(bar)
		base_bars.append(bar)
	var bottom := _panel(Control.PRESET_BOTTOM_LEFT, Vector2(18, -132), Vector2(330, 110))
	stats = Label.new()
	bottom.add_child(stats)
	health = _bar(Color(0.25, 0.65, 0.4))
	health.max_value = world.player.max_hp
	bottom.add_child(health)
	target_info = Label.new()
	bottom.add_child(target_info)
	var cards := _panel(Control.PRESET_CENTER_BOTTOM, Vector2(-170, -128), Vector2(340, 110))
	attack_label = Label.new()
	skill_label = Label.new()
	dodge_label = Label.new()
	cards.add_child(attack_label)
	cards.add_child(skill_label)
	cards.add_child(dodge_label)
	var help := Label.new()
	help.position = Vector2(18, 218)
	help.add_theme_font_size_override("font_size", 13)
	help.text = "WASD Move / Mouse Orbit / Wheel Zoom\nTab Target / Esc Release / R Restart\nBlue allies, red enemies. Destroy red base."
	add_child(help)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	center.add_child(column)
	result = Label.new()
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 36)
	column.add_child(result)
	restart_button = Button.new()
	restart_button.text = "Restart battle (R)"
	restart_button.pressed.connect(world.restart)
	column.add_child(restart_button)
	add_child(center)

func _panel(preset: int, offset: Vector2, panel_size: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(preset)
	panel.offset_left = offset.x
	panel.offset_top = offset.y
	panel.offset_right = offset.x + panel_size.x
	panel.offset_bottom = offset.y + panel_size.y
	panel.custom_minimum_size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.08, 0.9)
	style.border_color = Color(0.35, 0.45, 0.5)
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	panel.add_child(column)
	add_child(panel)
	return column

func _bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 20
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.1, 0.13, 0.16)
	bar.add_theme_stylebox_override("background", background)
	return bar

func _process(_delta: float) -> void:
	var player: UnitBody = world.player
	stats.text = "AZURE SENTINEL   HP %d / %d" % [player.hp, player.max_hp]
	health.value = player.hp
	battle_status.text = "AZURE %d    vs    EMBER %d   |   %.0fs" % [world.alive_count(0), world.alive_count(1), world.elapsed]
	for team in range(2):
		base_bars[team].value = world.bases[team].hp
	target_info.text = "Target: none (Tab)"
	if is_instance_valid(world.locked_target) and world.locked_target.is_alive:
		target_info.text = "Enemy #%d   HP %d / %d" % [world.locked_target.unit_id, world.locked_target.hp, world.locked_target.max_hp]
	_ready_text(attack_label, "LMB   SWORD", player.attack_remaining)
	_ready_text(skill_label, "Q   SHOCKWAVE", player.skill_remaining)
	_ready_text(dodge_label, "SPACE   EVADE", player.dodge_cooldown)
	if player.spawn_guard > 0:
		target_info.text = "Respawn shield %.1fs (ends on attack)" % player.spawn_guard
	result.text = ""
	if not player.is_alive:
		result.text = "Respawning in %.1fs" % player.respawn_remaining
	if world.match_over:
		result.text = "VICTORY — AZURE" if world.winner == 0 else "DEFEAT — EMBER"
	restart_button.visible = world.match_over

func _ready_text(label: Label, title: String, cooldown: float) -> void:
	label.text = title + ("   READY" if cooldown <= 0 else "   %.1fs" % cooldown)
	label.modulate = Color(0.65, 0.9, 1) if cooldown <= 0 else Color(0.55, 0.58, 0.62)
