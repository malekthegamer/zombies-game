extends Control

@export var player : FPSController
@export var weapon_manager : WeaponManager
@export var show_crosshair : bool = true

const SWITCH_COOLDOWN_DURATION := 0.15
var switch_cooldown := 0.0

func get_all_weapons_ordered() -> Array[WeaponResource]:
	var weapons = weapon_manager.equipped_weapons.slice(0)
	weapons.sort_custom(func(w1, w2):
		if w1.slot != w2.slot:
			return w1.slot < w2.slot
		var diff = w1.slot_priority - w2.slot_priority
		return w1.get_rid().get_id() < w2.get_rid().get_id() if diff == 0 else diff < 0)
	return weapons

func get_weapons_in_slot(slot : int) -> Array[WeaponResource]:
	return get_all_weapons_ordered().filter(func(w): return w.slot == slot)

func _can_switch_weapon() -> bool:
	return switch_cooldown <= 0.0

func _apply_weapon_switch(new_weapon : WeaponResource) -> void:
	if not new_weapon:
		return
	if weapon_manager.current_weapon:
		weapon_manager.current_weapon.trigger_down = false
	weapon_manager.current_weapon = new_weapon
	switch_cooldown = SWITCH_COOLDOWN_DURATION

func switch_weapon_relative(amount : int) -> void:
	if not _can_switch_weapon():
		return
	var all_weapons = get_all_weapons_ordered()
	if len(all_weapons) == 0:
		return
	var cur_index = all_weapons.find(weapon_manager.current_weapon)
	if cur_index < 0:
		cur_index = 0
	var new_index = (cur_index + amount + len(all_weapons)) % len(all_weapons)
	_apply_weapon_switch(all_weapons[new_index])

func switch_to_slot(slot : int) -> void:
	if not _can_switch_weapon():
		return
	var weapons_in_slot = get_weapons_in_slot(slot)
	if weapons_in_slot.is_empty():
		return

	var new_weapon = weapons_in_slot[0]
	if weapon_manager.current_weapon and weapon_manager.current_weapon.slot == slot:
		var weapon_index_in_slot = weapons_in_slot.find(weapon_manager.current_weapon)
		if weapon_index_in_slot < 0:
			weapon_index_in_slot = 0
		new_weapon = weapons_in_slot[(weapon_index_in_slot + 1) % weapons_in_slot.size()]

	_apply_weapon_switch(new_weapon)

func _unhandled_input(event):
	if event is InputEventKey and not event.is_echo() and event.is_pressed():
		var slot_num := -1
		match event.keycode:
			KEY_1: slot_num = 1
			KEY_2: slot_num = 2
			KEY_3: slot_num = 3
			KEY_4: slot_num = 4
			KEY_5: slot_num = 5
			KEY_6: slot_num = 6
			KEY_7: slot_num = 7
			KEY_8: slot_num = 8
			KEY_9: slot_num = 9
		if slot_num != -1:
			switch_to_slot(slot_num)

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			switch_weapon_relative(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			switch_weapon_relative(1)

func _ready() -> void:
	weapon_manager.allow_shoot = true

func _process(delta: float) -> void:
	switch_cooldown = maxf(0.0, switch_cooldown - delta)
	weapon_manager.allow_shoot = true
	%CrosshairCenterContainer.visible = show_crosshair and player.camera_style == FPSController.CameraStyle.FIRST_PERSON

	if not weapon_manager.current_weapon or weapon_manager.current_weapon.current_ammo == INF:
		%AmmoPanel.visible = false
		return

	%AmmoPanel.visible = true
	%ClipAmmoLabel.text = str(weapon_manager.current_weapon.current_ammo)
	if weapon_manager.current_weapon.reserve_ammo == INF:
		%ReserveAmmoLabel.text = "INF"
	else:
		%ReserveAmmoLabel.text = str(weapon_manager.current_weapon.reserve_ammo)
	%ReserveAmmoLabel.visible = weapon_manager.current_weapon.max_reserve_ammo > 0
	%WeaponNameLabel.text = weapon_manager.current_weapon.name.to_upper()
