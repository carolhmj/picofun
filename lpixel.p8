pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

cos1 = cos function cos(angle) return cos1(angle/360) end
sin1 = sin function sin(angle) return sin1(-angle/360) end

-- * lsystem production module * --
function lsystem_deriv(initial, rules)
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
	local valid = true
	if rule == 'F' then
		new_state = moveForward(last_state, lsystem_interp.d, true)	
	elseif rule == 'G' then
		new_state = moveForward(last_state, lsystem_interp.d, false)
	elseif rule == '+' then
		new_state = rotate(last_state, lsystem_interp.m, true)
	elseif rule == '-' then
		new_state = rotate(last_state, lsystem_interp.m, false)
	else
		valid = false 
	end
	if valid then
		push_state(lsystem_interp, new_state)
	end	
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

function draw(lsystem_interp, centroid)
	for i=1,#lsystem_interp.states do
		if i+1 <= #lsystem_interp.states and 
		   lsystem_interp.states[i+1].draw == true then
			draw_raster(lsystem_interp.states[i], 
						lsystem_interp.states[i+1],
						centroid)   
		end
	end	
end	 	

-- * graphics *--
function point(x, y)
	return {x = x, y = y}
end

function draw_raster(p0, p1, centroid)
	local medium_point = median(p0, p1)
	local dist = dist(medium_point, centroid)

	local color = select_color(dist)

	local center0 = center(p0, centroid)
	local center1 = center(p1, centroid)
	
	local raster0 = raster(center0, centroid)
	local raster1 = raster(center1, centroid)
	line(raster0.x, raster0.y, raster1.x, raster1.y, color)
end

function select_color(dist)
	if (flr(dist) % 2 == 0) then 
		return 1
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

function center(p,centroid)
	return point(p.x-centroid.x, p.y-centroid.y)
end	 

function raster(t, centroid)
	local norm_x = (t.x + WIDTH/2) / WIDTH
	local norm_y = (t.y + HEIGHT/2) / HEIGHT

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
		["X"] = "YF+XF+Y",
		["Y"] = "XF-YF-X"
	}
	prod_system = lsystem_deriv('YF', rules)
	result = produce(prod_system, 5) 
	geom_system = lsystem_interp(turtle(0,0,0), 3, 60)
	for i=1,#result do
		process(geom_system, sub(result,i,i))	
	end
	geom_system_centroid = find_centroid(geom_system.states)
end

function _draw()
	cls()
	draw(geom_system, geom_system_centroid)
	print(result)
	print(geom_system_centroid.x..' '..geom_system_centroid.y)
end	