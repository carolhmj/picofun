pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

cos1 = cos function cos(angle) return cos1(angle/360) end
sin1 = sin function sin(angle) return sin1(-angle/360) end

-- * lsystem production module * --
function lsystem_grammar(initial, rules)
	return {
		initial = initial,
		rules = rules
	}
end

function produce(lsystem, steps)
	local string = lsystem.initial
	for i=1,steps do
		string = derive(string, lsystem.rules)
	end
	return string
end

function derive(string, rules)
	local deriv_string = ""
	for i=1,#string do
		local r = sub(string, i, i)
		deriv_string = deriv_string..(rules[r] and rules[r] or r)
	end
	return deriv_string
end	

-- * lsystem geometric module *--
function turtle(x, y, a, draw)
	local vdraw = draw or false
	return {x = x, y = y, a = a, draw = vdraw}
end

function lsystem_geom(initial, d, m) 
	return {
		d = d,
		m = m,
		states = {initial}
	}
end

function push_state(lsystem_geom, new_state) 
	lsystem_geom.states[#lsystem_geom.states+1] = new_state
end	

function process(lsystem_geom, rule)
	local last_state = lsystem_geom.states[#lsystem_geom.states]
	local new_state = {}
	local valid = true
	if rule == 'f' then
		new_state = moveforward(last_state, lsystem_geom.d, true)	
	elseif rule == 'g' then
		new_state = moveforward(last_state, lsystem_geom.d, false)
	elseif rule == '+' then
		new_state = rotate(last_state, lsystem_geom.m, true)
	elseif rule == '-' then
		new_state = rotate(last_state, lsystem_geom.m, false)
	else
		valid = false 
	end
	if valid then
		push_state(lsystem_geom, new_state)
	end	
end

function moveforward(turtle, dist, draw)
	local new_state = {
		x = turtle.x + dist*cos(turtle.a),
		y = turtle.y + dist*sin(turtle.a),
		a = turtle.a,
		draw = draw
	}
	return new_state
end

function rotate(turtle, angle, positive)
	local sign = positive and 1 or -1
	local new_state = {
		x = turtle.x,
		y = turtle.y,
		a = turtle.a + sign*angle,
		draw = false
	}
	return new_state 
end

function draw(lsystem_geom, centroid)
	for i=1,#lsystem_geom.states do
		if i+1 <= #lsystem_geom.states and 
		   lsystem_geom.states[i+1].draw == true then
			draw_line(lsystem_geom.states[i], 
						lsystem_geom.states[i+1],
						centroid)   
		end
	end	
end	 	

-- * graphics *--
function point(x, y)
	return {x = x, y = y}
end

function draw_line(p0, p1, centroid)
	-- selects colors based in the distance of the median between the
	-- points and the object centroid
	local medium_point = median(p0, p1)
	local dist = dist(medium_point, centroid)
	local color = select_color(dist)

	-- translates line to the center of the screen --
	local center0 = to_center(p0, centroid)
	local center1 = to_center(p1, centroid)
	
	-- converts from world coordinates to screen coordinates --
	local raster0 = to_raster(center0, centroid)
	local raster1 = to_raster(center1, centroid)

	--draws the line -- 
	line(raster0.x, raster0.y, raster1.x, raster1.y, color)
end

function select_color(dist)
	if (flr(dist) % 2 == 0) then 
		return 12
	elseif (flr(dist) % 3 == 0) then 
		return 8
	elseif (flr(dist) % 5 == 0) then 
		return 10
	else
		return 11
	end				
end

function median(p0, p1)
	return point((p0.x+p1.x)/2, (p0.y+p1.y)/2)	
end

function dist(p0, p1)
	return sqrt((p1.x-p0.x)^2 + (p1.y-p0.y)^2)
end

function to_center(p, centroid)
	return point(p.x-centroid.x, p.y-centroid.y)
end	 

function to_raster(t, centroid)
	local norm_x = (t.x + width/2) / width
	local norm_y = (t.y + height/2) / height

	local raster_x = ceil(norm_x*width)
	local raster_y = ceil((1-norm_y)*height)
	
	return point(raster_x, raster_y)   
end

function find_centroid(states) 
	local centroid = point(0,0)
	local n = 0
	for state in all(states) do
		if state.draw then
			centroid = point(centroid.x + state.x, 
							 centroid.y + state.y)
			n = n + 1
		end
	end
	return point(centroid.x/n, centroid.y/n)	
end 

--* keeps both lsystem interpretations together *--
function lsystem(grammar, geometric, n_deriv) 
	return {
		grammar = grammar,
		geometric = geometric,
		n_deriv = n_deriv
	}
end

function produce_lsystem(lsystem)
	lsystem.result = produce(lsystem.grammar, lsystem.n_deriv)
	for i=1,#lsystem.result do
		process(lsystem.geometric, sub(lsystem.result,i,i))
	end
	lsystem.centroid = find_centroid(lsystem.geometric.states)
end	

function draw_lsystem(lsystem) 
	draw(lsystem.geometric, lsystem.centroid)
end		

-- * demo systems *--
demos = {
	sierpinski = lsystem(
		lsystem_grammar("yf",
						{["x"] = "yf+xf+y", ["y"] = "xf-yf-x"}),
		lsystem_geom(turtle(0,0,0), 3, 60), 
		5),
	koch = lsystem(
		lsystem_grammar("f-f-f-f",
						{["f"] = "f-f+f+ff-f-f+f"}),
		lsystem_geom(turtle(0,0,0), 4, 90),
		2),
	snowflake = lsystem(
		lsystem_grammar("f++f++f",
						{["f"]="f-f++f-f"}),
		lsystem_geom(turtle(0,0,0), 0.9, 60),
		4),
	triangle = lsystem(
		lsystem_grammar("f+f+f",
						{["f"]="f-f+f"}),
		lsystem_geom(turtle(0,0,0), 10, 120),
		4
		),
	gosper = lsystem(
		lsystem_grammar("-yf",
						{["x"]="xfx-yf-yf+fx+fx-yf-yffx+yf+fxfxyf-fx+yf+fxfx+yf-fxyf-yf-fx+fx+yfyf-",
						 ["y"]="+fxfx-yf-yf+fx+fxyf+fx-yfyf-fx-yf+fxyfyf-fx-yffx+fx+yf-yf-fx+fx+yfy"}),
		lsystem_geom(turtle(0,0,0), 4, 90),
		2
		),
	square_sierpinski = lsystem(
		lsystem_grammar("f+xf+f+xf",
						{["x"]="xf-f+f-xf+f+xf-f+f-x"}),
		lsystem_geom(turtle(0,0,0), 4, 90),
		3
		),
	peano = lsystem(
		lsystem_grammar("x",
						{["x"]="xfyfx+f+yfxfy-f-xfyfx",
						 ["y"]="yfxfy-f-xfyfx+f+yfxfy"}),
		lsystem_geom(turtle(0,0,0), 3, 90),
		3
		),
	hexa_gosper = lsystem(
		lsystem_grammar("xf",
						{["x"]="x+yf++yf-fx--fxfx-yf+",
						 ["y"]="-fx+yfyf++yf+fx--fx-y"}),
		lsystem_geom(turtle(0,0,0), 4, 60),
		3
		)
}

demo_states = {"sierpinski", "koch", "snowflake",
"triangle", "gosper", "square_sierpinski", "peano", "hexa_gosper"}

function _init()
	width = 128
	height = 128
	for k,v in pairs(demos) do
		produce_lsystem(v)
	end
	curr = 1
	last_status_change = 0
	first_press = false  	
end

function _draw()
	cls()
	if not first_press then
		-- print('cool lsystems demo')
		spr(1, 20, 20)
		spr(2, 28, 20)
		spr(3, 36, 20)
		spr(4, 44, 20)
		spr(5, 53, 20)
		spr(1, 61, 20)
		spr(6, 69, 20)
	else 	
		print(demo_states[curr], 40, 0, 7 + curr)
	end	
	draw_lsystem(demos[demo_states[curr]])
end

function _update()
	last_status_change = last_status_change + 1

	if last_status_change > 10 then 
		-- check for button presses
		if btn(0) then -- left button
			demos_to_left()
			last_status_change = 0		
		elseif btn(1) then -- right button
			demos_to_right()
			last_status_change = 0	
		end
	end

	if not first_press then
		if btn(0) or btn(1) then -- first button was pressed
			first_press = true
		end
	end				
end

function demos_to_left()
	curr = curr - 1
	if curr < 1 then
		curr = #demo_states
	end
end

function demos_to_right()
	curr = curr + 1
	if curr > #demo_states then
		curr = 1
	end
end			
__gfx__
00000000077000000777777000077000770000770777777007777700000000000000000000000000000000000000000000000000000000000000000000000000
00000000077000000777777000000000777007770777777007777700000000000000000000000000000000000000000000000000000000000000000000000000
00700700077000000770077000077000077777700770000007700000000000000000000000000000000000000000000000000000000000000000000000000000
00077000077000000770077000077000007777000777777007777700000000000000000000000000000000000000000000000000000000000000000000000000
00077000077000000777777000077000007777000777777000777770000000000000000000000000000000000000000000000000000000000000000000000000
00700700077000000777777000077000077777700770000000000770000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700770000000077000777007770777777007777770000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700770000000077000770000770777777007777700000000000000000000000000000000000000000000000000000000000000000000000000
