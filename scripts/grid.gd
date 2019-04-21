extends Node2D

# Grid variables
export (int) var width
export (int) var height
export (int) var x_start
export (int) var y_start
export (int) var offset
export (int) var y_offset

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

# touch variables
var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)
var controlling = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()


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
				piece.position = grid_to_pixel(i, j)
				all_pieces[i][j] = piece
			
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
		all_pieces[column][row] = other_piece
		all_pieces[column + direction.x][row + direction.y] = first_piece
		first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_piece.move(grid_to_pixel(column, row))
		find_matches()
	
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
	touch_input()
	
#	pass

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i > 0 and i < width -1:
					if all_pieces[i-1][j] != null and all_pieces[i+1][j] != null:
						if all_pieces[i-1][j].color == current_color and all_pieces[i+1][j].color == current_color:
							all_pieces[i-1][j].matched = true
							all_pieces[i-1][j].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i+1][j].matched = true
							all_pieces[i+1][j].dim()
				if j > 0 and j < height -1:
					if all_pieces[i][j-1] != null and all_pieces[i][j+1] != null:
						if all_pieces[i][j-1].color == current_color and all_pieces[i][j+1].color == current_color:
							all_pieces[i][j-1].matched = true
							all_pieces[i][j-1].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i][j+1].matched = true
							all_pieces[i][j+1].dim()
	get_parent().get_node("destroy_timer").start()
	
func destroy_matched():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	get_parent().get_node("collapse_timer").start()

func _on_destroy_timer_timeout():
	destroy_matched()
	


func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				for k in range(j +1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()
						
func _on_collapse_timer_timeout():
	collapse_columns()


			
func _on_refill_timer_timeout():
	spawn_pieces()
