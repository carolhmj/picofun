pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

Turtle = {}

function Turtle:new(d, m)
	local newTurtle = {x = 0, y = 0, a = 0, d = d, m = m}
	self.__index = self
	return setmetatable(newTurtle, self)
end

function Turtle:process(rule)
	local draw = true
	local prevState = {x = self.x, y = self.y}

	if rule == 'F' then
		self:moveForward()	
	elseif rule == 'f' then
		draw = false
		self:moveForward()
	elseif rule == '+' then
		self:rotate(true)
	elseif rule == '-' then
		self:rotate(false)
	end

	if draw then
		self:draw(prevState)
	end	 
end

function Turtle:moveForward()
	self.x = self.x + self.d*cos(self.a)
	self.y = self.y + self.d*sin(self.a)
end

function Turtle:rotate(positive)
	local sign = positive and 1 or -1
	self.a = self.a + sign*self.m 
end

function Turtle:draw(prevState)
	draw_raster(prevState, self)
end	 	

function draw_raster(p0,p1)
	local raster0 = raster(p0)
	local raster1 = raster(p1)
	line(raster0.x, raster0.y, raster1.x, raster1.y)
end	  

function point(x,y)
	return {x = x, y = y}
end

function raster(t) 
	local norm_x = (t.x + WIDTH/2) / WIDTH
	local norm_y = (t.y + HEIGHT/2) / HEIGHT
	local raster_x = ceil(norm_x*WIDTH)
	local raster_y = ceil((1-norm_y)*HEIGHT)
	return point(raster_x, raster_y)   
end

function _init()
	WIDTH = 128
	HEIGHT = 128
	turtle = Turtle:new(10, 0.1)
end

function _draw()
	cls()
	turtle:process('F')
	-- turtle:process('+')
	-- turtle:process('F')
end	