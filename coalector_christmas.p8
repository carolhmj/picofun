pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
game_states = {
	title_screen = 0,
	main_loop = 1,
	end_screen = 2
}

function init_vars()
	-- horizontal position
	santa_pos = 0
	
	-- speed
	santa_speed = 2
	
	-- state of walk cycle
	-- lua "arrays" are indexed @ 1
	walk_cycle = 1
	
	-- number of spirtes on cycle
	walk_cycle_size = 3
	
	-- direction
	direction = "left"
	
	-- walk cycle sequence
	walk_seq = {
		left = {0, 1, 2},
		right = {0, 2, 1}
	}
	
	-- array of coals on scene
	coals = {}
	
	-- coal speed
	coal_speed = 1
	
	-- max number of coals on scene
	max_coals = 10
	
	-- frames until the next coal
	-- can spawn
	frames_until_spawn = 30
	-- default value for frames
	-- until spawn
	new_frames_until_spawn = 60
	-- level multiplier for this
	-- spawn rate
	lvl_mult_spawn = -5
	-- smaller amount of frames
	-- until the spawn
	min_frames_until_spawn = 10
	
	-- store previous spawn pos
	-- to avoid spawning coals
	-- that are too far away
	prev_spawn_pos = 0
	
	-- score and lives
	score = 0
	lives = 7
	
	dance_frames = 2
end

function _init()
	state = game_states.title_screen
	init_vars()
end

function _draw()
	cls()
	if state == game_states.title_screen then
		draw_title_screen()
	elseif state == game_states.main_loop then
		draw_main_loop()
	elseif state == game_states.end_screen then
		draw_end_screen()
	end 
end

function draw_title_screen()
	title = "santa the coalector!" 
	print(title, 64-(#title/2)*4, 32)
	subtitle = "press 🅾️/❎ to continue" 
	print(subtitle, 64-(#subtitle/2)*4, 48)
end

function draw_main_loop()
	draw_santa()
	draw_coals()
	draw_score_lives()
end

function draw_score_lives()
	score_str = "\x92 " .. score 
	print(score_str, 128-8*4, 4)
	lives_str = "\x87 " .. lives
	print(lives_str, 128-8*4, 12) 
end

function draw_coals()
	for i=1,#coals do
		coal = coals[i]
		spr(4, coal[1], coal[2])
	end
end

function draw_santa()
	-- draw hat
	spr(1, santa_pos, 128-24)
	-- draw head sprite
	spr(17, santa_pos, 128-16)
	-- draw body sprite
	walk_sprite = walk_seq[direction][walk_cycle]
	spr(33+walk_sprite, santa_pos, 128-8)
end

function draw_end_screen()
	text = "game over!"
	spr(1, 60, 60-32)
	spr(18, 60, 60-24)
	walk_sprite = walk_seq[direction][walk_cycle]
	spr(33+walk_sprite, 60, 60-16)
	print(text, 64 - (#text/2)*4, 60)
	text = "you collected"
	print(text, 64 - (#text/2)*4, 68) 
	text	= tostr(score)
	print(text, 64 - (#text/2)*4, 76)
	text = "coals for naughty children"
	print(text, 64 - (#text/2)*4, 84)
	text = "happy holidays!"
	print(text, 64 - (#text/2)*4, 92)
	text = "press ❎/🅾️ to play again"
	print(text, 64 - (#text/2)*4, 100)
end

function _update()
	if state == game_states.title_screen then
		update_title_screen()
	elseif state == game_states.main_loop then
		update_main_loop()
	elseif state == game_states.end_screen then
		update_end_screen()
	end
end

function update_title_screen()
	if btn(4) or btn(5) then
		state = game_states.main_loop
	end
end

function update_main_loop()
	santa_movement()
	coal_update()
	check_lives_and_score()	
end

function update_end_screen()
	if btn(4) or btn(5) then
		state = game_states.main_loop
		init_vars()
	end
	dance_frames -= 1
	if dance_frames == 0 then
		adv_walk_cycle()
		dance_frames = 2
	end	
end

function check_lives_and_score()
	if lives <= 0 then
		state = game_states.end_screen
	end
	level = flr(score/10)
end

function coal_update()
	coal_spawn()
	coal_movement()
	coalision() 
end

function coalision()
	despawn_list = {}
	for j=1,#coals do
		coal = coals[j]
		-- collision with amman
		-- gives points
		if coal[1] > santa_pos - 4 and
					coal[1] < santa_pos + 12 and
					coal[2] > 128 - 24 then
			score += 1
			add(despawn_list, coal)
		elseif coal[2] > 128-4 then
		-- collision with btn screen
		-- takes lives
			lives -= 1
			add(despawn_list, coal)			
		end
	end
	
	for j=1,#despawn_list do
		to_despawn = despawn_list[j]
		del(coals, to_despawn)
	end 
end

function coal_movement()
	for i=1,#coals do
		coal = coals[i]
		coal[2] += coal_speed
	end
end

function coal_spawn()
	if frames_until_spawn > 0 then
		frames_until_spawn -= 1
	end
	-- spawn one coal per frame
	-- until we have the max
	if #coals < max_coals and
				frames_until_spawn == 0 then
		add(coals, create_coal())
		frames_until_spawn 
			= max(
						new_frames_until_spawn 
						+ lvl_mult_spawn * level,
						min_frames_until_spawn)
	end
end

function create_coal()
	-- coal spawns in a random
	-- x pos at top of screen
	width = 100
	hwidth = width/2
	anchor = max(prev_spawn_pos, hwidth)
	anchor = min(anchor, 120-hwidth)
	
	spawn_pos = anchor - hwidth + rnd(width)
	
	prev_spawn_pos = spawn_pos
	return {spawn_pos, 0}
end

function santa_movement()
	if btn(1) then --move right
		if santa_pos < 128-8 then
			santa_pos = santa_pos + santa_speed
		end
		adv_expected_direction(direction, "right")
		direction = "right"
	elseif btn(0) then -- move left
		if santa_pos > 0 then
			santa_pos = santa_pos - santa_speed
		end
		adv_expected_direction(direction, "left")
		direction = "left"
	end
end

function adv_expected_direction(direction, exp_direction)
	if direction == exp_direction then
		adv_walk_cycle()
	else
		reset_walk_cycle()
	end
end

function reset_walk_cycle()
	walk_cycle = 1
end

function adv_walk_cycle()
	walk_cycle = walk_cycle + 1
	if walk_cycle > walk_cycle_size then
		reset_walk_cycle()
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000770000000000000000000005555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000880000000000000000000055050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000008888000000000000000000050505500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700088888800000000000000000005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000006fffff006fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000006fcfcf006f8f8f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000006fffff006fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066fff60066fff6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066666600666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088666800886668000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000084444800844448008444480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008f44f8008f44f8008f44f80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000084444800844448008444480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000084444800844448008444480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088880000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800888880000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800888880000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ff00ff00ff0ff0000ff0ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
