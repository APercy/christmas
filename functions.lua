local function xplayer(player)
	if not player:is_player() then
		return
	end
	local name = player:get_player_name() 
	return christmas.players[name]
end

function christmas.get_present_formspec(pos)--Taken from default chest
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local formspec =
		"size[8,9]" ..
		"list[nodemeta:" .. spos .. ";main;3.5,2.5;1,1;]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]" 
	return formspec
end

function christmas.to_time(time)
  local remaining = time % 86400
  remaining = remaining % 3600
  local minutes = math.floor(remaining/60)
  remaining = remaining % 60
  local seconds = remaining
  if (minutes < 10) then
    minutes = "0" .. tostring(minutes)
  end
  if (seconds < 10) then
    seconds = "0" .. tostring(seconds)
  end
  answer = minutes..':'..seconds
  return answer
end

function christmas.register_reward(item, quantity, rarity)
	table.insert(christmas.rewards, {item=item, quantity=quantity, rarity=rarity})
end

function christmas.random_reward()--Adapted from Dungeontest room selection "dungeon_rooms.random_roomdata"
	local pool = christmas.rewards
	
	local candidates = {}
	local raresum = 0

	for i=1, #pool do
		local reward = pool[i]
		table.insert(candidates, pool)
		raresum = raresum + reward.rarity
	end

	local rarepick = math.random() * raresum
	local rarecount = 0

	for c=1, #candidates do
		local rewards = candidates[c]
		rarecount = rarecount + christmas.rewards[c].rarity
		local q = christmas.rewards[c].quantity
		local quantity = math.random(q.min, q.max)
		if rarecount >= rarepick then
			--return christmas.rewards[c].item
			return ItemStack(christmas.rewards[c].item.." "..quantity)
		end
	end
end

function christmas.eat_candy(hp_change, replace_with_item)
    return function(itemstack, user, pointed_thing) 
	    local name = user:get_player_name()
		local p = xplayer(user)
		christmas.players[name].candy = p.candy +1
		
		if p.candy == 8 then
			p.time = 60
			p.hud.ui = user:hud_add({
				hud_elem_type = "image",
				position  = {x = 0.2, y = 0.2},
			    offset    = {x = 0, y = 0},
			    text      = "christmas_powerup_ui.png",
			    scale     = { x = 10, y = 10},
			    alignment = { x = 0, y = 0 },
			})
			p.hud.icon = user:hud_add({
				hud_elem_type = "image",
				position  = {x = 0.2, y = 0.2},
			    offset    = {x = 0, y = 0},
			    text      = "christmas_candy_cane.png",
			    scale     = { x = 10, y = 10},
			    alignment = { x = 0, y = 0 },
			})
			p.hud.time = user:hud_add({
				hud_elem_type = "text",
				position  = {x = 0.2, y = 0.2},
			    offset    = {x = 0, y = 0},
			    text      = "SUGAR RUSH!!\n"..christmas.to_time (p.time),
				number = 0xffffff,
			    scale     = { x = 10, y = 10},
			    alignment = { x = 0, y = 0 },
			})
		end
		if p.time > 0 then
			p.time = p.time + 3
		end
        return minetest.do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
    end
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	christmas.players[name] = {}
	christmas.players[name].candy = 0
	christmas.players[name].hud = {}
	christmas.players[name].time = 0
end)

local t = 0
minetest.register_globalstep (function(dtime)
	t = t + dtime
	if t > 1 then 
		t = 0
	end
	for _, player in ipairs(minetest.get_connected_players()) do
		local p = xplayer(player)
		if p.time > 0 and t > 1-dtime then
			p.time = p.time - 1
			player:hud_change(p.hud.time, "text", "SUGAR RUSH!!\n~~"..christmas.to_time(p.time).."~~")
		elseif math.floor(p.time) == 1 then
			p.candy = 0
		end
		if p.time > 0 then
            --commented to avoid bug behaviour against hbsprint
		    --[[player:set_physics_override({
			    speed = 2.5,
		    })]]--
		end
		--minetest.chat_send_all(p.candy)
		if p.time == 0 then
            --commented to avoid bug behaviour against hbsprint
		    --[[player:set_physics_override({
			    speed = 1,
		    })]]--
			if p.hud.ui then
				player:hud_remove(p.hud.ui)
			end
			if p.hud.icon then
				player:hud_remove(p.hud.icon)
			end
			if p.hud.time then
				player:hud_remove(p.hud.time)
			end
		end
	end
end)
