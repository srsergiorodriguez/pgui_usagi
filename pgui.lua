--[[
	pgui for Usagi - Immediate Mode GUI library
	v1.0.0 By Sergio Rodríguez Gómez
]]--

local vec_meta = {
	__add = function(a, b) return vec(a.x + b.x, a.y + b.y) end,
	__sub = function(a, b) return vec(a.x - b.x, a.y - b.y) end,
	__mul = function(a, b) if type(b) == "number" then return vec(a.x * b, a.y * b) else return vec(a.x * b.x, a.y * b.y) end end
}
vec_meta.__index = vec_meta
function vec_meta:copy() return vec(self.x, self.y) end
function vec(x, y) return setmetatable({x = x or 0, y = y or 0}, vec_meta) end

function all(t) local i = 0; local n = #t; return function() i = i + 1; if i <= n then return t[i] end end end
function add(t, v) table.insert(t, v) end
function sub(s, i, j) return string.sub(s, i, j) end
function rnd() return math.random() end
function flr(v) return math.floor(v) end
function ceil(v) return math.ceil(v) end
function mid(lo, v, hi) return util.clamp(v, lo, hi) end
function max(a, b) return math.max(a, b) end

local function split(s, delimiter)
	local result = {}
	if delimiter == "" then for i = 1, #s do add(result, s:sub(i,i)) end return result end
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do add(result, match) end
	return result
end

pgui_components = {}

pgui_components.unknown = {fns={}, data={text="?",_id="unknown"}}
pgui_components.unknown.fns.draw = function(self) gfx.text("[?]", self.pos.x, self.pos.y, gfx.COLOR_WHITE) end

pgui_components.placeholder = {fns={}, data={_id="placeholder",visible=false}}
pgui_components.placeholder.fns.draw = function(self) if (self.visible) then gfx.text("[x]", self.pos.x, self.pos.y, gfx.COLOR_WHITE) end end

pgui_components.text = {fns={}, data={_id="text",text="TEXT",size=vec(0,7),wrap=0}}
pgui_components.text.fns.update = function(self) 
	if self.wrap > 0 then self.text = pgui:wrap_text(self.text, self.wrap) end
	local text_width = pgui:get_text_width(self.text)
	local lines_count = max(1, #split(tostring(self.text), "\n"))
	self.size = vec(text_width, pgui.stats.font_h * lines_count)
	return self.text 
end
pgui_components.text.fns.draw = function(self) pgui:_text(self.text,self,self.color[4]) end

pgui_components.rect = {fns={}, data={_id="rect",size=vec(16,16)}}
pgui_components.rect.fns.draw = function(self)
	pgui:_rect(self.pos.x+self.offset.x,self.pos.y+self.offset.y,self.size.x,self.size.y,self.color[4],false)
end

pgui_components.line = {fns={}, data={_id="line",size=vec(16,16)}}
pgui_components.line.fns.draw = function(self)
	local x, y = self.pos.x+self.offset.x, self.pos.y+self.offset.y
	gfx.rect_fill(x, y, max(1, self.size.x), max(1, self.size.y), self.color[4])
end

pgui_components.radiocircle = {fns={}, data={_id="radiocircle",r=4,on=false}}
pgui_components.radiocircle.fns.update = function(self) self.size = vec(self.r*2,self.r*2) end
pgui_components.radiocircle.fns.draw = function(self) pgui:_radiocirc(self,self.r,self.color[3],self.color[4],self.on) end

pgui_components.multibox = {fns={}, data={_id="multibox",size=vec(8,8),on=false}}
pgui_components.multibox.fns.draw = function(self)
	local pos = self.pos+self.offset
	if (self.on) then pgui:_rect(pos.x,pos.y,self.size.x,self.size.y,self.color[3],true) end
	pgui:_rect(pos.x,pos.y,self.size.x,self.size.y,self.color[4],false)
end

pgui_components.box = {fns={}, data={_id="box",size=vec(16,16),stroke=true,active=false,hover=false}}
pgui_components.box.fns.draw = function(self)
	local fill = self.color[1]
	local mouse_events = pgui:mouse_events(self)
	if (mouse_events.over and self.hover) then fill = self.color[2] end
	if (mouse_events.left_btn and self.active) then fill = self.color[3] end
	local stroke = self.stroke and self.color[4] or fill
	pgui:_box(self, self.size.x, self.size.y, fill, stroke)
end

pgui_components.text_box = {fns={}, data={_id="text_box",text="TEXTBOX",margin=2,stroke=true,active=false,hover=false,wrap=0}}
pgui_components.text_box.fns.update = function(self)
	if self.wrap > 0 then self.text = pgui:wrap_text(self.text, self.wrap) end
	local text_width = pgui:get_text_width(self.text)
	local lines_count = max(1, #split(tostring(self.text), "\n"))
	
	self.size = vec(text_width+(self.margin*2), (self.margin*2)+(pgui.stats.font_h * lines_count))
	
	pgui:component("box",{size=self.size,hover=self.hover,active=self.active,stroke=self.stroke}, self)
	pgui:component("text",{pos=vec(self.margin,self.margin),active=self.active,text=self.text}, self)
	return self.text
end

pgui_components.sprite = {fns={}, data={_id="sprite",sprite=1,size=vec(0,7),fn=function() end}}
pgui_components.sprite.fns.draw = function(self)
	self.fn()
	pgui:_sprite(self.sprite,self)
end

pgui_components.sprite_box = {fns={}, data={_id="sprite_box",sprite=1,margin=2,stroke=true,active=false,hover=false,fn=function() end}}
pgui_components.sprite_box.fns.update = function(self)
	local sprite_size = usagi.SPRITE_SIZE
	self.size = vec(sprite_size+(self.margin*2),(self.margin*2)+sprite_size)
	local box = pgui:precomponent("box",{size=self.size,hover=self.hover,active=self.active,stroke=self.stroke},self)
	box:_update()
	pgui:component("sprite",{pos=vec(self.margin,self.margin),active=self.active,sprite=self.sprite,p=self.p},self)
	return pgui:mouse_events(box).clicked
end

pgui_components.input = {fns={}, data={label="input",_id="input",text="INPUT",charlen=16,margin=2}}
pgui_components.input.fns.update = function(self)
	if (pgui:get_store(self.label,true) == nil) then
		pgui:set_store(self.label,{ cursor_pos = self.margin+pgui:get_text_width(self.text), cursor_idx = 0, active = false },true)
	end
	
	local text_box = pgui:precomponent("text_box",{text=self.text,margin=self.margin},self)
	text_box:_update()
	
	local char_w = pgui:get_text_width("A")
	text_box.size.x = (char_w * self.charlen) + (self.margin * 2) 
	self.size = text_box.size:copy()
	
	local mouse_events = pgui:mouse_events(text_box)
	local store = pgui:get_store(self.label,true)
	
	if mouse_events.clicked then
		local cursor_pos = pgui:get_cursor_pos(self.margin,self.text,mouse_events.rel_pos.x)
		store.cursor_pos, store.cursor_idx, store.cursor_line, store.active = cursor_pos[1], cursor_pos[2], 0, true
	elseif pgui:get_mouse().mb == 1 and not mouse_events.left_btn then
		store.active = false
	end
	
	if store.active then
		if pgui.stats.blink then
			pgui:component("box",{pos=vec(store.cursor_pos, self.margin + (store.cursor_line*pgui.stats.font_h)), size=vec(1,pgui.stats.font_h), color={self.color[3],0,0,self.color[3]}},self)
		end
		
		if pgui:key_repeat(input.KEY_BACKSPACE) and store.cursor_idx > 0 then
			local removed = sub(self.text,store.cursor_idx,store.cursor_idx)
			self.text = sub(self.text,0,store.cursor_idx-1)..sub(self.text,store.cursor_idx+1)
			store.cursor_pos = store.cursor_pos - pgui:get_text_width(removed)
			store.cursor_idx = store.cursor_idx - 1
		elseif pgui:key_repeat(input.KEY_LEFT) and store.cursor_idx > 0 then
			store.cursor_pos = store.cursor_pos - pgui:get_text_width(sub(self.text,store.cursor_idx,store.cursor_idx))
			store.cursor_idx = store.cursor_idx - 1
		elseif pgui:key_repeat(input.KEY_RIGHT) and store.cursor_idx < #self.text then
			store.cursor_pos = store.cursor_pos + pgui:get_text_width(sub(self.text,store.cursor_idx+1,store.cursor_idx+1))
			store.cursor_idx = store.cursor_idx + 1
		end
		
		local is_shift = input.key_held(input.KEY_LSHIFT) or input.key_held(input.KEY_RSHIFT)
		for _, mapped_key in ipairs(pgui.stats.scancodes) do
			if pgui:key_repeat(mapped_key.key) and self.charlen > #self.text then
				local str = is_shift and mapped_key.upper or mapped_key.char
				if str ~= "" then
					self.text = sub(self.text,0,store.cursor_idx)..str..sub(self.text,store.cursor_idx+1)
					store.cursor_pos = store.cursor_pos + pgui:get_text_width(str)
					store.cursor_idx = store.cursor_idx + 1
				end
			end
		end
		store.cursor_pos = max(0,store.cursor_pos)
		store.cursor_idx = max(0,store.cursor_idx)
	end
	return self.text
end

pgui_components.button = {fns={}, data={_id="button",text="BUTTON",margin=2,stroke=true,disable=false}}
pgui_components.button.fns.update = function(self)
	local text_box = pgui:precomponent("text_box",{text=self.text,hover=not self.disable,active=not self.disable,stroke=self.stroke,margin=self.margin},self)
	text_box:_update()
	self.size = text_box.size:copy()
	return pgui:mouse_events(text_box).clicked
end

pgui_components.vstack = {fns={}, data={_id="vstack",stroke=true,height=0,margin=3,gap=3,contents={},box=true}}
pgui_components.vstack.fns.update = function(self)
	self.size = vec(0,self.margin*2)
	local y = self.margin
	if (self.box) then pgui:component("box",{size=self.size,stroke=self.stroke},self) end
	local upds = {}
	local prev_com = nil
	
	for content in all(self.contents) do
		local com = pgui:precomponent(content[1],content[2],self)
		com.pos = vec(self.margin+com.pos.x,y+com.pos.y)
		if (com._id == "dropdown") then com.grow = true end
		
		-- Pass exact logical bounds to the tooltip
		if com._id == "tooltip" and prev_com then
			com.target_bounds = { pos = prev_com.pos + prev_com.offset, size = prev_com.size:copy() }
		end
		
		add(upds, com:_update())
		
		if com._id ~= "tooltip" then
			self.size.x = max(self.size.x, com.size.x + com.pos.x)
			self.size.y = self.size.y + com.size.y + self.gap
			y = y + com.size.y + self.gap
			prev_com = com
		end
	end
	self.size.x = self.size.x + self.margin*2
	self.size.y = self.height ~= 0 and self.height or self.size.y - self.gap
	return upds	
end

pgui_components.hstack = {fns={}, data={_id="hstack",stroke=true,width=0,margin=3,gap=3,contents={},box=true}}
pgui_components.hstack.fns.update = function(self)
	self.size = vec(self.margin*2,0)
	local x = self.margin
	if (self.box) then pgui:component("box",{size=self.size,stroke=self.stroke}, self) end
	local upds = {}
	local prev_com = nil
	
	for content in all(self.contents) do
		local com = pgui:precomponent(content[1],content[2],self)
		com.pos = vec(x+com.pos.x,self.margin+com.pos.y)
		if (com._id == "dropdown") then com.grow = false end
		
		if com._id == "tooltip" and prev_com then
			com.target_bounds = { pos = prev_com.pos + prev_com.offset, size = prev_com.size:copy() }
		end
		
		add(upds, com:_update())
		
		if com._id ~= "tooltip" then
			self.size.y = max(self.size.y, com.size.y + com.pos.y)
			self.size.x = self.size.x + com.size.x + self.gap
			x = x + com.size.x + self.gap
			prev_com = com
		end
	end
	self.size.y = self.size.y + self.margin*2
	self.size.x = self.width > 0 and self.width or self.size.x - self.gap
	return upds
end

pgui_components.topbar = {fns={}, data={_id="topbar",width=usagi.GAME_W,gap=3,contents={}}}
pgui_components.topbar.fns.update = function(self)
	return pgui:component("hstack",{gap=self.gap,width=self.width,stroke=false,margin=0,contents=self.contents},self)
end

pgui_components.dropdown = {fns={}, data={label="dd",_id="dropdown",grow=false,text="DROPDOWN",stroke=true,margin=2,gap=3,contents={},disable=false}}
pgui_components.dropdown.fns.update = function(self)
	if (pgui:get_store(self.label,true) == nil) then pgui:set_store(self.label,false,true) end
	local button = pgui:precomponent("button",{size=self.size,stroke=self.stroke,text=self.text,margin=self.margin,disable=self.disable},self)
	local clicked = button:_update()
	self.size = button.size:copy()
	
	pgui:component("line",{pos=vec(0,button.size.y - 1),size=vec(self.size.x,0)},self)
	
	if clicked and not self.disable then pgui:set_store(self.label, not pgui:get_store(self.label,true), true) end
	if pgui:get_store(self.label,true) then
		local vstack = pgui:precomponent("vstack",{layer=self.layer+1,pos=vec(0,button.size.y),margin=self.margin,gap=self.gap,contents=self.contents},self)
		local upd = vstack:_update()
		if (self.grow) then self.size.y = self.size.y + vstack.size.y end
		return upd
	end
	return {}
end

pgui_components.scrollable = {fns={}, data={label="scrll",_id="scrollable",scroll_x=false,scroll_y=true,size=vec(50,50),sensibility=4,content={"text_box",{text="scrollable",margin=50}}}}
pgui_components.scrollable.fns.update = function(self)
	if (pgui:get_store(self.label,true) == nil) then pgui:set_store(self.label,{scrolling = vec(0,0)},true) end
	local store = pgui:get_store(self.label,true)
	local com = pgui:precomponent(self.content[1],self.content[2],self)
	
	com.pos = store.scrolling
	com.clip = {self.pos.x+self.offset.x,self.pos.y+self.offset.y,self.size.x,self.size.y}
	local upd = com:_update()
	if (not self.scroll_x or (com.size.x < self.size.x)) then self.size.x = com.size.x end
	if (not self.scroll_y or (com.size.y < self.size.y)) then self.size.y = com.size.y end
			
	local function limit(c, scroller)
		if c.size.y - scroller.size.y + c.pos.y <= 0 then c.pos.y = scroller.size.y - c.size.y
		elseif c.pos.y > 0 then c.pos.y = 0 end
		if c.size.x - scroller.size.x + c.pos.x <= 0 then c.pos.x = scroller.size.x - c.size.x
		elseif c.pos.x > 0 then c.pos.x = 0 end
	end	

	local mouse_events = pgui:mouse_events(self)
	if mouse_events.over then
		if (self.scroll_y) then store.scrolling.y = store.scrolling.y + (mouse_events.vs*self.sensibility) end
		limit(com,self)
	end
	return upd
end

pgui_components.hslider = {fns={}, data={_id="hslider",format=function(v) return string.format("%.2f", v) end,min=0,max=100,value=50,size=vec(100,10),stroke=true,flr=false}}
pgui_components.hslider.fns.update = function(self)
	local text_str = self.format(self.value)
	local lines_count = max(1, #split(tostring(self.text), "\n"))
	self.size.y = max(self.size.y, (pgui.stats.font_h * lines_count) + 2)
	
	local box = pgui:precomponent("box",{size=self.size,stroke=self.stroke},self)
	box:_update()
	local mouse_events = pgui:mouse_events(box)
	local range = self.max - self.min
	if mouse_events.left_btn then self.value = self.min + (mouse_events.rel_pos.x / self.size.x) * range end
	self.value = mid(self.min, self.value, self.max)
	local width = ((self.value - self.min) / range)*self.size.x
	if (self.flr) then self.value = flr(self.value) end
	if (width > 0) then pgui:component("box",{size=vec(width,self.size.y),stroke=self.stroke,color={self.color[3],0,0,self.color[4]}},self) end
	
	local text_y = (self.size.y - (pgui.stats.font_h * lines_count)) / 2
	pgui:component("text",{text=text_str,pos=vec(2, text_y)},self)
	return self.value
end

pgui_components.knob = {fns={}, data={label="knob",_id="knob",min=0,max=100,value=50,r=10,stroke=true,flr=false,sensibility=1}}
pgui_components.knob.fns.update = function(self)
	if pgui:get_store(self.label, true) == nil then pgui:set_store(self.label, {dragging=false, start_val=self.value, start_y=0}, true) end
	local store = pgui:get_store(self.label, true)
	self.size = vec(self.r * 2, self.r * 2)
	
	local mouse_events = pgui:mouse_events(self)

	if mouse_events.clicked then
		store.dragging = true
		store.start_y = pgui.stats.mouse.my
		store.start_val = self.value
	elseif pgui.stats.mouse.mb == 0 then
		store.dragging = false
	end

	if store.dragging then
		local dy = store.start_y - pgui.stats.mouse.my
		local range = self.max - self.min
		self.value = store.start_val + (dy / 100) * range * self.sensibility
		self.value = mid(self.min, self.value, self.max)
	end
	
	if self.flr then self.value = flr(self.value) end
	return self.value
end
pgui_components.knob.fns.draw = function(self)
	local cx = self.pos.x + self.offset.x + self.r
	local cy = self.pos.y + self.offset.y + self.r
	
	gfx.circ_fill(cx, cy, self.r, self.color[1])
	if self.stroke then gfx.circ(cx, cy, self.r, self.color[4]) end

	local pct = (self.value - self.min) / (self.max - self.min)
	local start_a, end_a = math.pi * 0.75, math.pi * 2.25
	local a = start_a + (end_a - start_a) * pct
	local nx = cx + math.cos(a) * (self.r - 2)
	local ny = cy + math.sin(a) * (self.r - 2)
	gfx.line(cx, cy, nx, ny, self.color[3])
end

pgui_components.xypad = {fns={}, data={_id="xypad", size=vec(64,64), x_val=0.5, y_val=0.5, stroke=true}}
pgui_components.xypad.fns.update = function(self)
	local mouse_events = pgui:mouse_events(self)
	if mouse_events.left_btn then
		self.x_val = mid(0, mouse_events.rel_pos.x / self.size.x, 1)
		self.y_val = mid(0, mouse_events.rel_pos.y / self.size.y, 1)
	end
	return {x=self.x_val, y=self.y_val}
end
pgui_components.xypad.fns.draw = function(self)
	pgui:_box(self, self.size.x, self.size.y, self.color[1], self.stroke and self.color[4] or self.color[1])
	local cx = self.pos.x + self.offset.x + (self.x_val * self.size.x)
	local cy = self.pos.y + self.offset.y + (self.y_val * self.size.y)
	gfx.line(self.pos.x + self.offset.x, cy, self.pos.x + self.offset.x + self.size.x, cy, self.color[2])
	gfx.line(cx, self.pos.y + self.offset.y, cx, self.pos.y + self.offset.y + self.size.y, self.color[2])
	gfx.circ_fill(cx, cy, 2, self.color[3])
end

pgui_components.tooltip = {fns={}, data={_id="tooltip", text="Tooltip", delay=0.5}}
pgui_components.tooltip.fns.update = function(self)
	self.size = vec(0,0) 
	if not self.target_bounds then return end
	
	local mx, my = pgui.stats.mouse.mx, pgui.stats.mouse.my
	local over = pgui:rect_collision(self.target_bounds.pos, {x=mx,y=my}, self.target_bounds.size, {x=1,y=1})

	if over and pgui.stats.tooltip_timer > self.delay then
		pgui:component("text_box", {
			text=self.text, layer=100, 
			pos=vec(mx + 5, my + 5),
			color={self.color[4], self.color[4], self.color[4], self.color[1]}
		})
	end
end

pgui_components.radio = {fns={}, data={_id="radio",gap=3,r=3,sep=4,selected=1,options={}}}
pgui_components.radio.fns.update = function(self)
	local y, i, d, tw = 0, 1, self.r * 2, 0
	for opt in all(self.options) do
		local text_width = pgui:get_text_width(opt)
		local lines_count = max(1, #split(tostring(opt), "\n"))
		tw = max(tw, text_width)
		
		local pos = vec(0, y)
		local radiocircle = pgui:precomponent("radiocircle",{pos=pos,r=self.r,on=(self.selected == i)},self)
		radiocircle:_update()
		
		local text_y = (d - (pgui.stats.font_h * lines_count)) / 2
		pgui:component("text",{text=opt,pos=pos+vec(d+self.sep, text_y)},self)
		y = y + d + self.gap
		if (pgui:mouse_events(radiocircle).clicked) then self.selected = i end
		i = i + 1
	end	
	self.size = vec(tw + self.sep + d,y - self.gap)
	return self.selected
end

pgui_components.multi_select = {fns={}, data={_id="multi_select",gap=3,box_size=7,sep=4,selected={},options={}}}
pgui_components.multi_select.fns.update = function(self)
	local y, i, d, tw = 0, 1, self.box_size, 0
	local selected = pgui:copy_table(self.selected)
	for opt in all(self.options) do
		local text_width = pgui:get_text_width(opt)
		local lines_count = max(1, #split(tostring(opt), "\n"))
		tw = max(tw, text_width)
		
		local pos = vec(0, y)
		local multibox = pgui:precomponent("multibox",{pos=pos,size=vec(d,d),on=selected[i]},self)
		multibox:_update()
		
		local text_y = (d - (pgui.stats.font_h * lines_count)) / 2
		pgui:component("text",{text=opt,pos=pos+vec(d+self.sep, text_y)},self)
		y = y + d + self.gap
		if (pgui:mouse_events(multibox).clicked) then selected[i] = not selected[i] end
		i = i + 1
	end	
	self.size = vec(tw + self.sep + d,y - self.gap)
	return selected
end

pgui_components.checkbox = {fns={}, data={_id="checkbox",text="CHECKBOX",value=false,box_size=8,sep=4}}
pgui_components.checkbox.fns.update = function(self)
	local select = pgui:precomponent("multi_select",{sep=self.sep,selected={self.value},options={self.text},box_size=self.box_size},self)
	local upd = select:_update()
	self.size = select.size
	return upd[1]
end

pgui_components.palette = {fns={}, data={_id="palette",columns=4,gap=3,box_size=10,colors={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},selected=1}}
pgui_components.palette.fns.update = function(self)
	local i = 0
	local memo_code = self.columns.."_"..self.box_size.."_"..self.gap
	if pgui.stats.memos.palette_pos[memo_code] == nil then pgui.stats.memos.palette_pos[memo_code] = {} end
	local pos = pgui.stats.memos.palette_pos[memo_code]
	
	for col in all(self.colors) do
		local new_palette = pgui:copy_table(self.color)
		new_palette[1] = col
		new_palette[4] = self.selected == col and new_palette[3] or new_palette[4]
		if pos[i] == nil then pos[i] = vec((i % self.columns), flr(i / self.columns)) * (self.box_size+self.gap) end
		local box = pgui:precomponent("box",{pos=pos[i],size=vec(self.box_size,self.box_size),stroke=true,color=new_palette},self)
		box:_update()
		if (pgui:mouse_events(box).clicked) then self.selected = col end
		i = i + 1
	end
	
	self.size = vec(((self.box_size + self.gap)*self.columns)-self.gap, ((self.box_size+self.gap)*ceil(#self.colors / self.columns))-self.gap)
	return self.selected
end

------ end of components -------

pgui_methods = {}

function pgui_methods:refresh(dt)
	self.components = {}
	self.stats.dt = dt or 0.016
	self.stats.t = self.stats.t + self.stats.dt
	self.stats.blink = math.floor(self.stats.t * 2) % 2 == 0
	
	self.stats.prev_mouse = self:copy_table(self.stats.mouse)
	self.stats.mouse = self:get_mouse()
	
	-- Global tooltip timer management
	if self.stats.mouse.mx ~= self.stats.prev_mouse.mx or self.stats.mouse.my ~= self.stats.prev_mouse.my then
		self.stats.tooltip_timer = 0
	else
		self.stats.tooltip_timer = self.stats.tooltip_timer + self.stats.dt
	end
	
	local _, fh = usagi.measure_text("A")
	self.stats.font_h = fh
	
	for _, mapped in ipairs(self.stats.scancodes) do
		if input.key_held(mapped.key) then self.stats.keys_held[mapped.key] = (self.stats.keys_held[mapped.key] or 0) + self.stats.dt else self.stats.keys_held[mapped.key] = 0 end
	end
	for _, k in ipairs({input.KEY_BACKSPACE, input.KEY_LEFT, input.KEY_RIGHT}) do
		if input.key_held(k) then self.stats.keys_held[k] = (self.stats.keys_held[k] or 0) + self.stats.dt else self.stats.keys_held[k] = 0 end
	end
end

function pgui_methods:key_repeat(key)
	if input.key_pressed(key) then return true end
	if input.key_held(key) then
		local t = self.stats.keys_held[key] or 0
		if t > 0.4 then
			self.stats.keys_held[key] = 0.35
			return true
		end
	end
	return false
end

function pgui_methods:wrap_text(text, max_w)
	if max_w <= 0 then return text end
	local wrapped, line = "", ""
	for word in text:gmatch("%S+") do
		local test_line = line == "" and word or line .. " " .. word
		local w, _ = usagi.measure_text(test_line)
		if w > max_w then
			wrapped = wrapped .. (wrapped == "" and "" or "\n") .. line
			line = word
		else
			line = test_line
		end
	end
	return wrapped .. (wrapped == "" and "" or "\n") .. line
end

function pgui_methods:draw(callback)
	callback = callback or function() end
	self:sort_table(self.components,"layer")
	for component in all(self.components) do
		if component.layer == 4 then callback() end
		component:draw()
	end	
end

function pgui_methods:component(name, opts, parent_opts)
	local template = pgui_components[name] or pgui_components["unknown"]
	local component = self:new_component(template, opts, parent_opts)
	return component:_update()
end

function pgui_methods:precomponent(name, opts, parent_opts)
	return self:new_component(pgui_components[name], opts, parent_opts)
end

function pgui_methods:new_component(template, opts, parent_opts)
	local base_data = {pos=vec(0,0),size=vec(0,0),offset=vec(0,0),color=pgui_methods:copy_table(self.stats.palette),clip={},layer=0}
	local data = {}
	for k,v in pairs(base_data) do
		local value = v
		if parent_opts then
			if (k == "layer") then value = parent_opts.layer end
			if (k == "clip") then value = parent_opts.clip end
			if (k == "color") then value = parent_opts.color end
			if (k == "offset") then value = parent_opts.children_offset end
		end
		if (opts[k] ~= nil) then value = opts[k] end
		data[k] = value
	end
	for k,v in pairs(template.data) do
		if opts[k] ~= nil then
			data[k] = opts[k]
		else
			data[k] = v
		end
	end
			
	local fns = template.fns
	function fns:_update()
		if (self.draw) then 
			self._insert_index = #pgui.components + 1
			add(pgui.components, self) 
		end
		if (self.update) then
			self.children_offset = self.pos + self.offset
			local upd = self:update(self.children_offset)
			return upd == nil and self._id or upd
		else
			return self._id
		end
	end
		
	return setmetatable(data, {__index=template.fns})	
end

function pgui_methods:close_dropdown(label) self:set_store(label,false,true) end

function pgui_methods:get_mouse()
	local mx, my = input.mouse()
	local mb = 0
	if input.mouse_held(input.MOUSE_LEFT) then mb = 1
	elseif input.mouse_held(input.MOUSE_RIGHT) then mb = 2 end
	return {mx=mx, my=my, mb=mb, hs=0, vs=input.mouse_scroll()}
end

function pgui_methods:get_text_width(str)
	local max_w = 0
	for _, l in ipairs(split(tostring(str), "\n")) do
		local w, _ = usagi.measure_text(l ~= "" and l or "A")
		max_w = max(max_w, w)
	end
	return max_w
end

function pgui_methods:get_cursor_pos(margin,text,relx)
	local sum, i = margin, 0
	for ch in all(split(text, "")) do
		local v, _ = usagi.measure_text(ch)
		if (sum + v > relx) then return {sum,i} end
		sum = sum + v
		i = i + 1
	end
	return {sum,i}
end

function pgui_methods:get_scancodes()
	return {
		{key=input.KEY_SPACE, char=" ", upper=" "}, {key=input.KEY_A, char="a", upper="A"},
		{key=input.KEY_B, char="b", upper="B"}, {key=input.KEY_C, char="c", upper="C"},
		{key=input.KEY_D, char="d", upper="D"}, {key=input.KEY_E, char="e", upper="E"},
		{key=input.KEY_F, char="f", upper="F"}, {key=input.KEY_G, char="g", upper="G"},
		{key=input.KEY_H, char="h", upper="H"}, {key=input.KEY_I, char="i", upper="I"},
		{key=input.KEY_J, char="j", upper="J"}, {key=input.KEY_K, char="k", upper="K"},
		{key=input.KEY_L, char="l", upper="L"}, {key=input.KEY_M, char="m", upper="M"},
		{key=input.KEY_N, char="n", upper="N"}, {key=input.KEY_O, char="o", upper="O"},
		{key=input.KEY_P, char="p", upper="P"}, {key=input.KEY_Q, char="q", upper="Q"},
		{key=input.KEY_R, char="r", upper="R"}, {key=input.KEY_S, char="s", upper="S"},
		{key=input.KEY_T, char="t", upper="T"}, {key=input.KEY_U, char="u", upper="U"},
		{key=input.KEY_V, char="v", upper="V"}, {key=input.KEY_W, char="w", upper="W"},
		{key=input.KEY_X, char="x", upper="X"}, {key=input.KEY_Y, char="y", upper="Y"},
		{key=input.KEY_Z, char="z", upper="Z"}, {key=input.KEY_0, char="0", upper=")"},
		{key=input.KEY_1, char="1", upper="!"}, {key=input.KEY_2, char="2", upper="@"},
		{key=input.KEY_3, char="3", upper="#"}, {key=input.KEY_4, char="4", upper="$"},
		{key=input.KEY_5, char="5", upper="%"}, {key=input.KEY_6, char="6", upper="^"},
		{key=input.KEY_7, char="7", upper="&"}, {key=input.KEY_8, char="8", upper="*"},
		{key=input.KEY_9, char="9", upper="("}
	}
end

function pgui_methods:copy_table(table)
	local new_table = {}
	for k,v in pairs(table) do
		if type(v) == "table" then new_table[k] = self:copy_table(v) else new_table[k] = v end
	end
	return new_table
end

function pgui_methods:mouse_events(data)
	local mx, my, mb, pmb = self.stats.mouse.mx, self.stats.mouse.my, self.stats.mouse.mb, self.stats.prev_mouse.mb
	local colrect, colsize = data.pos+data.offset, data.size:copy()
	
	local collision = self:rect_collision(colrect,{x=mx,y=my},colsize,{x=1,y=1})
	return {
		over=collision, left_btn=(collision and mb == 1), right_btn=(collision and mb == 2),
		clicked=(pmb == 0 and collision and mb == 1), released=(pmb == 1 and collision and mb == 0),
		rel_pos=vec(mx,my)-data.offset-data.pos, hs=0, vs=self.stats.mouse.vs
	}
end

function pgui_methods:rect_collision(apos, bpos, as, bs)
	return not (apos.x + as.x < bpos.x or apos.x > bpos.x + bs.x or apos.y + as.y < bpos.y or apos.y > bpos.y + bs.y)
end

function pgui_methods:set_palette(palette) self.stats.palette = palette end

function pgui_methods:_text(text, com, col) 
	local lines = split(tostring(text), "\n")
	local cx, cy = com.pos.x + com.offset.x, com.pos.y + com.offset.y
	for i, l in ipairs(lines) do
		gfx.text(l, cx, cy + ((i - 1) * pgui.stats.font_h), col)
	end
end

function pgui_methods:_rect(x, y, w, h, c, f)
	if w < 3 or h < 3 then 
		gfx.rect_fill(x, y, max(1, w), max(1, h), c)
		return
	end
	if f then
		gfx.rect_fill(x + 1, y, w - 2, h, c)
		gfx.rect_fill(x, y + 1, w, h - 2, c)
	else
		gfx.rect_fill(x + 1, y, w - 2, 1, c)             
		gfx.rect_fill(x + 1, y + h - 1, w - 2, 1, c)     
		gfx.rect_fill(x, y + 1, 1, h - 2, c)             
		gfx.rect_fill(x + w - 1, y + 1, 1, h - 2, c)     
	end
end

function pgui_methods:_box(com,w,h,fill,stroke)
	local x, y = com.pos.x+com.offset.x, com.pos.y+com.offset.y
	self:_rect(x,y,w,h,fill,true)
	self:_rect(x,y,w,h,stroke,false)
end

function pgui_methods:_radiocirc(com,r,fill,stroke,f)
	local x, y = com.pos.x+com.offset.x+r, com.pos.y+com.offset.y+r
	if (f) then gfx.circ_fill(x,y,r,fill) end
	gfx.circ(x,y,r,stroke)
end

function pgui_methods:_sprite(sprite,com)
	gfx.spr(sprite, com.pos.x+com.offset.x, com.pos.y+com.offset.y)
end

function pgui_methods:uid()
	local uid = split(os.date(), " ")
	return table.concat(split(uid[1],"-"),"")..table.concat(split(uid[2] or "00:00",":"),"")..sub(tostring(rnd() * 1000),0,3)
end

function pgui_methods:set_store(id,data,alt) if not alt then self.store[id] = data else self.alt_store[id] = data end end
function pgui_methods:get_store(id,alt) return not alt and self.store[id] or self.alt_store[id] end

function pgui_methods:sort_table(tbl, key)
	table.sort(tbl, function(a, b) 
		local valA, valB = a[key] or 0, b[key] or 0
		if valA == valB then return (a._insert_index or 0) < (b._insert_index or 0) end
		return valA < valB 
	end)
end

pgui = setmetatable({
	components={}, store={}, alt_store={},
	stats={
		t = 0, dt = 0.016, blink = false, font_h = 0, clipping = false, tooltip_timer = 0,
		palette = {gfx.COLOR_WHITE, gfx.COLOR_LIGHT_GRAY, gfx.COLOR_BLUE, gfx.COLOR_BLACK},
		memos = {palette_pos={}},
		scancodes=pgui_methods:get_scancodes(), keys_held={},
		mouse={mx=0, my=0, mb=0, hs=0, vs=0}, prev_mouse={mx=0, my=0, mb=0, hs=0, vs=0}
	}
}, {__index=pgui_methods})