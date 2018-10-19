pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

function _init()
	WIDTH = 128
	HEIGHT = 128
	angle = 0
end

function _update()
	angle = angle+0.02
	if angle > 360 then
		angle = 0
	end	
end

function _draw()
	cls()
	local center = point(0,0)
	local len = point(10,0)
	local rot_len = rotate(len, angle)

	draw_raster(center, rot_len)
end

function draw_raster(p0,p1)
	local raster0 = raster(p0)
	local raster1 = raster(p1)
	line(raster0.x, raster0.y, raster1.x, raster1.y)
end	  

function point(x,y)
	return {x = x, y = y}
end

function raster(p) 
	local norm_x = (p.x + WIDTH/2) / WIDTH
	local norm_y = (p.y + HEIGHT/2) / HEIGHT
	local raster_x = ceil(norm_x*WIDTH)
	local raster_y = ceil((1-norm_y)*HEIGHT)
	return point(raster_x, raster_y)   
end

function rotate(p,a)
	local rot_x = p.x*cos(a) - p.y*sin(a)
	local rot_y = p.x*sin(a) + p.y*cos(a)
	return point(rot_x,rot_y)
end	