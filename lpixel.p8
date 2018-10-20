pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

cos1 = cos function cos(angle) return cos1(angle/360) end
sin1 = sin function sin(angle) return sin1(-angle/360) end

-- * lsystem production module * --
function lystem_deriv(initial, rules)
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
	return {x = x, y = y, a = a, draw = draw}
end

function lsystem_interp(initial, d, m) 
	return {
		d = d,
		m = m,
		states = {initial}
	}
end

function push_state(lsystem_interp, new_state) 
	lsystem_interp.states[#lsystem_interp.states+1] = new_state
end	

function process(lsystem_interp, rule)
	local last_state = lsystem_interp.states[#lsystem_interp.states]
	local new_state = {}
	if rule == 'F' then
		new_state = moveForward(last_state, lsystem_interp.d, true)	
	elseif rule == 'G' then
		new_state = moveForward(last_state, lsystem_interp.d, false)
	elseif rule == '+' then
		new_state = rotate(last_state, lsystem_interp.m, true)
	elseif rule == '-' then
		new_state = rotate(last_state, lsystem_interp.m, false)
	end

	push_state(lsystem_interp, new_state)
end

function moveForward(turtle, dist, draw)
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

function draw(lsystem_interp)
	for i=1,#lsystem_interp.states do
		-- print('x '..lsystem_interp.states[i].x..
		-- 	  ' y '..lsystem_interp.states[i].y..
		-- 	  ' a '..lsystem_interp.states[i].a)
		-- check if there is a next state
		if i+1 <= #lsystem_interp.states and 
		   lsystem_interp.states[i+1].draw == true then
			draw_raster(lsystem_interp.states[i], lsystem_interp.states[i+1])   
		end
	end	
end	 	

-- * graphics *--
function point(x,y)
	return {x = x, y = y}
end

function draw_raster(p0,p1)
	local raster0 = raster(p0)
	local raster1 = raster(p1)
	line(raster0.x, raster0.y, raster1.x, raster1.y)
end	 

function raster(t)
	local centroid = find_centroid(geom_system.states)
	local cx = t.x-centroid.x
	local cy = t.y-centroid.y 
	local norm_x = (cx + WIDTH/2) / WIDTH
	local norm_y = (cy + HEIGHT/2) / HEIGHT
	local raster_x = ceil(norm_x*WIDTH)
	local raster_y = ceil((1-norm_y)*HEIGHT)
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

function _init()
	WIDTH = 128
	HEIGHT = 128
	local rules = {
		['F'] = 'F-F+F+FF-F-F+F'
		-- ["F"] = "F+G-FF+F+FF+FG+FF-G+FF-F-FF-FG-FFF",
		-- ["G"] = "GGGGGG"
	}
	prod_system = lystem_deriv('F+F+F+F', rules)
	result = produce(prod_system, 2) 
	geom_system = lsystem_interp(turtle(0,0,0), 3, 90)
	for i=1,#result do
	-- 	print(i)
		process(geom_system, sub(result,i,i))	
	end
end

function _draw()
	cls()
	draw(geom_system)
	print(result)
	-- local centroid = find_centroid(geom_system.states)
	-- print(centroid.x..' '..centroid.y)
end	