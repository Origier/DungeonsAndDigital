@tool

extends Control

# Exports - Paths to images to render for inventory slots
@export var default_inventory_slot_path : String = ""
@export var hover_inventory_slot_path : String = ""
@export var max_columns := 12		# Number of inventory slots per row
@export var max_rows := 6			# Number of rows in the whole inventory
@export var hbox_rows : Array[HBoxContainer] = []

# Variables for managing dragging an item
var item_offset := Vector2.ZERO
var item_held := false
var item_rendered := false
var item_rect_held : TextureRect = null
var item_id_held := -1
var item_held_index := -1

# Empty slot defaults
var default_inventory_slot : CompressedTexture2D = null
var hover_inventory_slot : CompressedTexture2D = null

# Contains either 0 or the path to a inventory icon
var inventory_slots = []

# Contains all of the items in the inventory
# Format:
# { key: Item ID
#		value: {
#			item: Item Object
#			quantity: Number of that item in the stack
#			}}
var inventory_items = {}

# Contains key value pairs for showing the items in the inventory
# Format:
#	{ key: Item ID
#		value: {
#			base: path_to_whole_icon
#			icons: [array of all the icons]
#			}}
var inventory_icons_dict = {}
# Increments for each item added
var next_item_id = 1

# function for testing the inventory environment - adds an item to the inventory
func test_inv():
	add_new_item("res://Scenes/long_sword.tscn", 30)

# Loading image resources to populate the inventory
func _ready():
	if not Engine.is_editor_hint():
		if default_inventory_slot_path != "":
			default_inventory_slot = load(default_inventory_slot_path)
		
		if hover_inventory_slot_path != "":
			hover_inventory_slot = load(hover_inventory_slot_path)
		
		# Setting the inventory to the default state - no items
		inventory_slots.resize(max_columns * max_rows)
		inventory_slots.fill(null)
		
		test_inv()
		render_inventory()

# These three functions are ordered in the sequence that occurs when dropping an item
# Firstly the left mouse release is registered by the _input function
func _input(event):
	if event is InputEventMouseButton:
		# Left mouse click release - item dropped
		if event.button_index == 1 and event.pressed == false and item_held:
			$".".remove_child(item_rect_held)
			item_rendered = false
			item_rect_held.queue_free()
			item_offset = Vector2.ZERO

# Secondly, the next frame renders, attempting to redraw the item on the players mouse
# Updates the position of any items currently being dragged
func _process(_delta):
	if item_rendered:
		item_rect_held.position = get_viewport().get_mouse_position() - item_offset

# Lastly, the mouse cursor is immediately detected as having moved into the new cell
# triggering this _gui_event to occur, capturing the spot the user had intended to drop the item
func _on_item_slot_gui_event(event, index):
	# Left mouse click release - item dropped
	if event is InputEventMouseMotion:
		if event.button_mask == 0 and event.pressure == 0.0 and item_held:
			item_held = false
			move_item(item_id_held, index, item_held_index)
			item_id_held = -1
			render_inventory()

# Updates the editor if there is something invalid
func _notification(_what):
	if Engine.is_editor_hint():
		update_configuration_warnings()
	
func _get_configuration_warnings():
	if hbox_rows.size() > max_rows:
		return ["Hbox Rows should only contain up to the max number of rows"]
	return []

# Moves the item in the inventory - doesn't instantiate the item since it is assumed to already exist
# Uses the old index to search for the remainder of the old version - setting any values there back to null
func move_item(item_id : int, index : int, old_index : int):
	var item = inventory_items[item_id]["item"]
	var slots_used = item.inv_icon_pieces.size()
	# Getting the first inventory slot
	# Divide the slots by 2 since half of the slots will be above this position
	var slots_above = slots_used / 2
	# Since the inventory items array is flat then we subtract max_columns to line it up correctly
	var starting_index = index - slots_above * max_columns
	# Do nothing if it is out of bounds, the item can't be placed there
	if starting_index < 0:
		return
	if (starting_index + max_columns * (slots_used - 1)) >= (max_columns * max_rows):
		return
	# Check each slot that would be used to ensure it is empty - if not do nothing
	var next_index = starting_index
	for i in slots_used:
		if inventory_slots[next_index] != null:
			return
		else:
			next_index += max_columns
	# With the move confirmed, remove the old icons from the inventory
	# Start by searching up the array
	next_index = old_index
	while next_index >= 0:
		inventory_slots[next_index] = null
		next_index -= max_columns
	
	# Repeat down the array
	next_index = old_index
	while next_index < max_columns * max_rows:
		inventory_slots[next_index] = null
		next_index += max_columns
	
	# Finally update the new slots with the item
	next_index = starting_index
	for i in slots_used:
		inventory_slots[next_index] = {"id" : item_id, "icon_index" : i}
		next_index += max_columns
	
# Adds an item to the inventory centered on the index provided
func add_new_item(path : String, index : int):
	var item_resource = load(path)
	var item = item_resource.instantiate()
	# Centering the item along the index provided
	var slots_used = item.inv_icon_pieces.size()
	# Getting the first inventory slot
	# Divide the slots by 2 since half of the slots will be above this position
	var slots_above = slots_used / 2
	# Since the inventory items array is flat then we subtract max_columns to line it up correctly
	var starting_index = index - slots_above * max_columns
	# Do nothing if it is out of bounds, the item can't be placed there
	if starting_index < 0:
		item.queue_free()
		return
	if (starting_index + max_columns * (slots_used - 1)) >= (max_columns * max_rows):
		item.queue_free()
		return
	# Check each slot that would be used to ensure it is empty - if not do nothing
	var next_index = starting_index
	for i in slots_used:
		if inventory_slots[next_index] != null:
			item.queue_free()
			return
		else:
			next_index += max_columns
			
	# Finally, add the item into the item dictionary and inventory slots to be rendered
	inventory_items[next_item_id] = {
		"item": item,
		"quantity": 1
	}
	inventory_icons_dict[next_item_id] = {
		"base" : item.full_inv_icon_path,
		"icons" : []
	}
	
	for i in item.inv_icon_pieces.size():
		inventory_icons_dict[next_item_id]["icons"].append(item.inv_icon_pieces[i])
	
	next_index = starting_index
	for i in slots_used:
		inventory_slots[next_index] = {"id" : next_item_id, "icon_index" : i}
		next_index += max_columns
	
	next_item_id += 1

# Renders the inventory
# Null - Means that there is no item there so render an empty slot
# Dictionary - There is an item there, render the item based on the icons dict
func render_inventory():
	# Clear the old inventory
	for i in max_rows:
		var row = hbox_rows[i]
		if row.get_child_count() == 0:
			continue
		# Removing each cell of the inventory row
		for j in max_columns:
			var child = row.get_child(0)
			row.remove_child(child)
			child.queue_free()
	
	# Repopulate the inventory with new item
	for i in (max_columns * max_rows):
		var row = hbox_rows[i / max_columns]
		# Generate the new inventory slot
		var new_slot = TextureButton.new()
		if inventory_slots[i] == null:
			new_slot.texture_normal = default_inventory_slot
			new_slot.texture_hover = hover_inventory_slot
			new_slot.z_index = 2
		else:
			var item_dict = inventory_icons_dict[inventory_slots[i]["id"]]
			var item_icon = item_dict["icons"][inventory_slots[i]["icon_index"]]
			new_slot.texture_normal = load(item_icon)
			new_slot.connect("button_down", _on_item_button_down.bind(inventory_slots[i]["id"], i))
			new_slot.z_index = 2
		# Finally adding the slot to the inventory
		row.add_child(new_slot)
		new_slot.connect("gui_input", _on_item_slot_gui_event.bind(i))

# Creates a full item image under the cursor to allow the player to drag the item to a new slot
func _on_item_button_down(id, index):
	item_rect_held = TextureRect.new()
	var new_texture = load(inventory_icons_dict[id]["base"])
	item_rect_held.texture = new_texture
	item_rect_held.z_index = 3
	item_offset = Vector2(new_texture.get_size().x / 2, new_texture.get_size().y / 2)
	$".".add_child(item_rect_held)
	item_rect_held.position = get_viewport().get_mouse_position() - item_offset
	item_held = true
	item_rendered = true
	item_id_held = id
	item_held_index = index
