extends Node

signal list_changed
signal item_destroyed(item_name: String)   # sabotage only (this is what Mom notices)
signal game_won
signal game_lost(reason: String)
signal mom_stamina_changed(value: float, max_value: float)
signal mom_chase_changed(active: bool)
signal ammo_changed(ammo: int)

signal security_called
signal player_captured(pos: Vector3)
signal struggle_changed(count: int, needed: int)
signal struggle_ended

enum ItemState { INTACT, SABOTAGED, COLLECTED }

var items: Dictionary = {}                 # name -> ItemState
var destroyed_positions: Dictionary = {}   # name -> where YOU sabotaged it
var needed_to_win: int = -1                # -1 means all items
var game_over: bool = false

func register_item(item_name: String) -> void:
	items[item_name] = ItemState.INTACT
	list_changed.emit()

func sabotage_item(item_name: String, pos: Vector3) -> void:
	if not _resolve(item_name, ItemState.SABOTAGED):
		return
	destroyed_positions[item_name] = pos
	item_destroyed.emit(item_name)
	_check_end()

func collect_item(item_name: String) -> void:
	if _resolve(item_name, ItemState.COLLECTED):
		_check_end()

func _resolve(item_name: String, new_state: ItemState) -> bool:
	if items.get(item_name, -1) != ItemState.INTACT:
		return false   # unknown, or already resolved by someone
	items[item_name] = new_state
	list_changed.emit()
	return true

func count(state: ItemState) -> int:
	return items.values().count(state)

func _check_end() -> void:
	var target := items.size() if needed_to_win < 0 else needed_to_win
	var sabotaged := count(ItemState.SABOTAGED)
	var intact := count(ItemState.INTACT)
	if sabotaged >= target:
		win()
	elif sabotaged + intact < target:
		lose("Mom took too much!")

func win() -> void:
	_end(true, "")

func lose(reason: String = "Mom caught you!") -> void:
	_end(false, reason)

func _end(won: bool, reason: String) -> void:
	if game_over:
		return
	game_over = true
	if won:
		game_won.emit()
	else:
		game_lost.emit(reason)

func restart() -> void:
	items.clear()
	destroyed_positions.clear()
	Inventory.items.clear()
	game_over = false
	get_tree().paused = false
	get_tree().reload_current_scene()
