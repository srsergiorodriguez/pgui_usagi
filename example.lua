
-- This is an example on how to use pgui usagi version, an immediate mode gui library
-- By Sergio Rodríguez Gómez

-- Note: To allow full keyboard typing without triggering the pause screen,
-- ensure you set `pause_menu = false` in your project's usagi.conf file.

require("imports.pgui")

function _init()
  t = 0
  speed = 0.5
  sides_options = {3, 4, 5, 6, 7, 8, 9, 10}
  shape_selected = 2 -- 1 for polygon, 2 for star
  size = 100
  color_selected = 10
  sides = 5
  pts = {}
  shape_text = "STAR"
  posx = 230 
  posy = 100
end

-- Helper to find which button in the hstack was clicked
function btn_index(tbl)
  if not tbl then return nil end
  for i = 1, #tbl do
    if tbl[i] then return tonumber(i) end
  end
  return nil
end

function _update(dt)
  -- Refresh pgui state and caches
  pgui:refresh(dt)
  
  -- Build scrollable sidebar
  local sides_buttons = {}
  for s in all(sides_options) do
    add(sides_buttons, {"button", {text=tostring(s), stroke=(sides==s)}})
  end
  
  local stack_contents = {
    {"text", {text="Scrollable sidebar"}},
    {"text", {text="type:"}},
    {"radio", {options={"polygon", "star"}, selected=shape_selected}},
    {"text", {text=({"sides", "points"})[shape_selected]}},
    {"hstack", {stroke=false, margin=0, contents=sides_buttons}},
    {"text", {text="size:"}},
    {"hslider", {min=50, max=120, value=size, flr=true}},
    {"text", {text="fill"}},
    {"palette", {selected=color_selected, columns=8}},
    {"text", {text="speed:"}},
    {"hslider", {max=2.0, value=speed}},
    {"text", {text="label:"}},
    {"input", {label="shape_input", text=shape_text, charlen=10}}
  }
  
  -- Positioned at y=20 to clear the Topbar
  local stack = pgui:component("scrollable", {
    pos = vec(5, 20),
    size = vec(150, 150),
    content = {"vstack", {gap=5, contents=stack_contents}}
  })
  
  -- Re-assign returned state variables
  shape_selected = stack[3] or shape_selected
  sides = sides_options[btn_index(stack[5])] or sides
  size = stack[7] or size
  color_selected = stack[9] or color_selected
  speed = stack[11] or speed
  shape_text = stack[13] or shape_text

  -- Calculate the geometry of the test triangle/polygon
  local vertex = shape_selected == 1 and sides or sides * 2
  local div = (math.pi * 2) / vertex
  local r = size / 2
  local ir = shape_selected == 1 and r or r / 2

  pts = {}
  for i = 0, vertex do
    local _r = i % 2 == 0 and r or ir
    local x = math.floor(posx + (math.cos((i * div) + t) * _r))
    local y = math.floor(posy - (math.sin((i * div) + t) * _r)) 
    add(pts, {x, y})
  end
  
  t = t + (speed * dt)

  -- Build topbar
  local topbar_options = {
    {"dropdown", {label="file_menu", text="File", stroke=false, contents={
        {"button", {text="New", stroke=false}},
        {"button", {text="Save Pattern", stroke=false}}
    }}},
    {"dropdown", {label="edit_menu", text="Edit", stroke=false, contents={
        {"button", {text="Reset Defaults", stroke=false}}
    }}}
  }
  
  local topbar = pgui:component("topbar", {layer=10, contents=topbar_options})
  
  -- Example of trapping a topbar click event
  if topbar[2] and topbar[2][1] then
    shape_selected = 2
    sides = 5
    size = 100
    speed = 0.5
    shape_text = "STAR"
    color_selected = 10
    pgui:close_dropdown("edit_menu")
  end
end

function _draw(dt)
  gfx.clear(gfx.COLOR_DARK_BLUE)
  
  -- Draw the generated shape
  fill_poly(pts, color_selected)
  
  -- Center the text input inside the shape
  local tw, th = usagi.measure_text(shape_text)
  gfx.text(shape_text, posx - (tw / 2), posy - (th / 2), gfx.COLOR_WHITE)
  
  -- Draw all pgui elements based on their zindex layers
  pgui:draw()
end

function stroke_poly(points, col)
  for i = 1, #points do
    local j = i % #points + 1
    gfx.line(points[i][1], points[i][2], points[j][1], points[j][2], col)
  end
end

function fill_poly(points, col)
  local min_y, max_y = 999, 0
  for i = 1, #points do
    min_y = math.min(min_y, points[i][2])
    max_y = math.max(max_y, points[i][2])
  end

  for y = min_y, max_y do
    local nodes = {}
    for i = 1, #points do
      local j = i % #points + 1
      local x1, y1 = points[i][1], points[i][2]
      local x2, y2 = points[j][1], points[j][2]

      if (y1 < y2 and y >= y1 and y < y2) or (y1 > y2 and y >= y2 and y < y1) then
        local dy = y2 - y1
        if dy ~= 0 then
          local dx = x2 - x1
          local node_x = x1 + (y - y1) * dx / dy
          table.insert(nodes, math.floor(node_x + 0.5))
        end
      end
    end

    table.sort(nodes)
    
    for i = 1, #nodes, 2 do
      if nodes[i+1] then
        for x = nodes[i], nodes[i+1] do
          gfx.px(x, y, col)
        end
      end
    end
  end
end