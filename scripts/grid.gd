extends Node2D

# state machine
enum {wait, move}
var state
# Grid variables
export (int) var width
export (int) var height
export (int) var x_start
export (int) var y_start
export (int) var offset
export (int) var y_offset

# obstacle stuff
export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_spaces
export (PoolVector2Array) var lock_spaces
export (PoolVector2Array) var concrete_spaces
# obstacle signals
signal damage_ice
signal make_ice
signal damage_lock
signal make_lock
signal damage_concrete
signal make_concrete

# piece array
var possible_pieces = [
preload("res://scenes/blue_piece.tscn"),
preload("res://scenes/green_piece.tscn"),
preload("res://scenes/lightgreen_piece.tscn"),
preload("res://scenes/orange_piece.tscn"),
preload("res://scenes/pink_piece.tscn"),
preload("res://scenes/yellow_piece.tscn")
]

# current pieces in the scene
var all_pieces = []

# swap back variables
var piece_1 = null
var piece_2 = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# touch variables
var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)
var controlling = false

# Called when the node enters the scene tree for the first time.
func _ready():
	state = move
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	spawn_ice()
	spawn_locks()
	spawn_concrete()

func restricted_fill(place: Vector2):
	if is_in_array(empty_spaces, place):
		return true
	if is_in_array(concrete_spaces, place):
		return true
	return false

func restricted_move(place: Vector2):
	#check lock pieces
	return is_in_array(lock_spaces, place)
	
func is_in_array(array, item):
	for i in array.size():
		if array[i] == item:
			return true
	return false
	 
func remove_from_array(new_array, place):
	for i in range(new_array.size()-1, -1, -1):
		if new_array[i] == place:
	   		new_array.remove(i)
	return new_array

	
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)			
	return array

func spawn_pieces():
	for i in width:
		for j in height:
			if not restricted_fill(Vector2(i,j)):
				if all_pieces[i][j] == null:
					#choose a random number
					var rand = floor(rand_range(0,possible_pieces.size()))
					var piece = possible_pieces[rand].instance()
					var loops = 0
					while(match_at(i, j, piece.color) and loops < 100):
						rand = floor(rand_range(0,possible_pieces.size()))
						loops += 1
						piece = possible_pieces[rand].instance()
					
					add_child(piece)
					# this makes it so that they fall, it doesn't affect the first draw of the board
					# since it happens at init, still we could make a varioable to keep track if it's the first time
					# this func is run and turn it off
					piece.position = grid_to_pixel(i, j-y_offset) 
					piece.move(grid_to_pixel(i, j))
					all_pieces[i][j] = piece
	after_spawn()

func after_spawn():
	"""
	Will cycle through all of the pieces checking for newly created matches
	"""		
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i, j, all_pieces[i][j].color):
					find_matches()
					get_parent().get_node("destroy_timer").start()
					return
	state = move
	move_checked = false

func spawn_ice():
	for i in ice_spaces.size():
		
		emit_signal("make_ice", ice_spaces[i])

func spawn_locks():
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])
		
func spawn_concrete():
	for i in concrete_spaces.size():
		emit_signal("make_concrete", concrete_spaces[i])
			
func match_at(column, row, color):
	if	column > 1:
		if all_pieces[column -1][row] != null && all_pieces[column -2][row] != null:
			if all_pieces[column -1][row].color == color && all_pieces[column -2][row].color == color:
				return true
				
	if row > 1:
		if all_pieces[column][row -1] != null && all_pieces[column][row -2] != null:
			if all_pieces[column][row -1].color == color && all_pieces[column][row -2].color == color:
				return true
			
			
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start +  -offset * row
	return Vector2(new_x, new_y)
	
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)

func is_in_grid(grid_position: Vector2):
	if grid_position.x >= 0 && grid_position.x < width:
		if grid_position.y >= 0 && grid_position.y < height:
			return true
	return false
	
func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			controlling = true
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
		
		
	if Input.is_action_just_released("ui_touch"):
		
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)) and controlling:
			controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			var grid_position = pixel_to_grid(final_touch.x, final_touch.y)
			touch_difference(first_touch, final_touch) # grid position is the same
			
			

func swap_pieces(column:int, row:int, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece != null and other_piece != null:
		if not restricted_move(Vector2(column, row)) and not restricted_move(Vector2(column, row) + direction):
			store_last_pieces(first_piece, other_piece, Vector2(column, row) , direction)
			state = wait
			all_pieces[column][row] = other_piece
			all_pieces[column + direction.x][row + direction.y] = first_piece
			first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
			other_piece.move(grid_to_pixel(column, row))
			if !move_checked:
				find_matches()

func store_last_pieces(first_piece, other_piece, place, direction):
	piece_1 = first_piece
	piece_2 = other_piece
	last_place = place
	last_direction = direction
	
func swap_back():
	# move the previously swaped pieces to their previosu position
	if piece_1 != null and piece_2 !=null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false
	
func touch_difference(grid_1: Vector2, grid_2: Vector2):
	# we substract vectors
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		# check if have to move left or right
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1,0)) #right
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y , Vector2(-1,0)) #left
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,1)) # up
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y , Vector2(0,-1)) # down
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == move:
		touch_input()
	
#	pass

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i > 0 and i < width -1:
					if not is_piece_null(i-1,j) and not is_piece_null(i+1,j):
						if all_pieces[i-1][j].color == current_color and all_pieces[i+1][j].color == current_color:
							match_and_dim_many([
												all_pieces[i-1][j],
												all_pieces[i][j],
												all_pieces[i+1][j]
												])
							
				if j > 0 and j < height -1:
					if not is_piece_null(i,j-1) and not is_piece_null(i,j+1):
						if all_pieces[i][j-1].color == current_color and all_pieces[i][j+1].color == current_color:
							match_and_dim_many([
											all_pieces[i][j-1],
											all_pieces[i][j],
											all_pieces[i][j+1]
												])
							
	get_parent().get_node("destroy_timer").start()

func is_piece_null(column, row):
	return all_pieces[column][row] == null

func match_and_dim_many(pieces):
	for piece in pieces:
		match_and_dim(piece)
		
func match_and_dim(item):
	item.matched = true
	item.dim()
	
func destroy_matched():
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
					damage_special(i, j)
					
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()


func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column,row))
	emit_signal("damage_lock", Vector2(column,row))
	check_concrete(column, row)

func check_concrete(column, row):
	# check right
	if column < width -1:
		emit_signal("damage_concrete", Vector2(column +1, row))
	# check left
	if column > 0:
		emit_signal("damage_concrete", Vector2(column -1, row))
	# check up
	if row  < height -1:
		emit_signal("damage_concrete", Vector2(column, row +1))
	# check down
	if row > 0:
		emit_signal("damage_concrete", Vector2(column, row -1))

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_fill(Vector2(i,j)):
				for k in range(j +1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()
						
						
func _on_destroy_timer_timeout():
	destroy_matched()
	
func _on_collapse_timer_timeout():
	collapse_columns()


			
func _on_refill_timer_timeout():
	spawn_pieces()


func _on_lock_holder_remove_lock(place):
	lock_spaces = remove_from_array(lock_spaces, place)
	

func _on_concrete_holder_remove_concrete(place):
	concrete_spaces = remove_from_array(concrete_spaces, place)
