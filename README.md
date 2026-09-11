# PGUI for Usagi Engine

**v1.0.0**

An Immediate Mode GUI Library I originally developed for Picotron, now fully ported and improved for games and creative coding in the Usagi Engine.

![Preview](/imgs/pguiclip.gif)

## General Usage

Because this GUI library follows the Immediate Mode pattern, all GUI components are updated and rendered each frame in the program. The code execution is divided in two parts, following the game loop used in Usagi: an update part, where most calculations for the GUI are made and you get return values from the components, and a draw part, where the graphical elements of the components are rendered.

For pgui to work, you have to put two basic functions:

1. `pgui:refresh(dt)` at the beginning of your `_update(dt)` function. This will restart the list of components to render, compute dynamic font heights, and process native OS key-repeats.
2. `pgui:draw()` in your `_draw(dt)` function. This will render the components. If you pass a function as an argument, it will call it before rendering layer 4 (usually not necessary).

Additionally, in `_update`, after the refresh function, you put all the components that are part of your desired GUI.

All components are created by using the component function. The first argument is the name of component, and the second is a table containing options and values:
`pgui:component(NAME, {OPTIONS})`

Components return values that you can use as you like in your code. In most cases, you have to feed the return value back into a particular option of the component so it can keep track of its state.

This is a simple example of a slider controlling the size of a circle:

```lua
require("imports.pgui")

function _init()
  slidervalue = 10
end

function _update(dt)
  pgui:refresh(dt)
  -- Create slider and capture its return value to maintain state
  slidervalue = pgui:component("hslider", {pos=vec(190,20), value=slidervalue})
end

function _draw(dt)
  gfx.clear(gfx.COLOR_DARK_BLUE)
  -- Use the slider state to drive native Usagi graphics
  gfx.circ_fill(240,140,slidervalue,gfx.COLOR_WHITE)
  pgui:draw()
end


```

## List of components

This is the detailed list of components available in the library, their options with default values and return values.

**NOTE 1:** If you want to use default values, you can omit them in the options table you pass to the component function.
**NOTE 2:** Some components need to store persistent information. To achieve this, an internal dictionary keeps track of the state of the component. For these components you need to include a unique `label` in the options so the library can differentiate between them.
**NOTE 3:** There are a couple of options that ALL components have:

* **pos**. vector. The position of the component relative to its container (or to the app's window if it has no container). Default: `pos=vec(0,0)`.
* **color**. table. The color palette used. Default: the global `pgui.stats.palette`. See the palette section below.
* **layer**. number. Order of rendering. Default: `layer=0`. Higher numbers draw on top. Dropdowns automatically elevate their contents.

---

## Basic components

### Box

Just a filled rectangle with a border.
`pgui:component("box",{size=vec(16,16),stroke=true,active=false,hover=false})`

Options:

* **size**. vector. Size of the component in width and height.
* **stroke**. boolean. Show border or not.
* **active**. boolean. Change color when clicked.
* **hover**. boolean. Change color when hovered on.

Returns: `"box"`. string.

### Text

Displays dynamic text. Automatically measures Usagi's active font to perfectly scale heights and alignments.
`pgui:component("text",{text="TEXT",size=vec(0,7),wrap=0})`

Options:

* **text**. string. Text to display. Use `\n` for multiline text.
* **wrap**. number. If > 0, auto-injects line breaks when text exceeds this pixel width.

Returns: text. string.

### Text box

A box with text inside.
`pgui:component("text_box",{text="TEXTBOX",margin=2,stroke=true,active=false,hover=false,wrap=0})`

Options:

* **text**. string. Text inside the box. Use `\n` for multiline text.
* **margin**. number. Margin separating text from border from all sides.
* **stroke**. boolean. Show border or not.
* **active**. boolean. Change color when clicked.
* **hover**. boolean. Change color when hovered on.
* **wrap**. number. If > 0, auto-injects line breaks when text exceeds this pixel width.

Returns: text. string.

### Sprite box

A box with a sprite inside.
`pgui:component("sprite_box",{sprite=1,margin=2,stroke=true,active=false,hover=false,fn=function() end})`

Options:

* **sprite**. number. Number of sprite in spritesheet.
* **margin**. number. Margin separating sprite from border from all sides.
* **stroke**. boolean. Show border or not.
* **active**. boolean. Change color of box when clicked.
* **hover**. boolean. Change color of box when hovered on.
* **fn**. function. Function to run before drawing the sprite (e.g., to set transparency).

Returns: if was clicked. boolean.

### Input

A text input box with a cursor and native OS key-repeat.
`pgui:component("input",{label="input",text="INPUT",margin=2,charlen=16})`

Options:

* **label**. string. REQUIRED. Unique name for keeping internal state.
* **text**. string. Text inside the box.
* **margin**. number. Margin separating text from border from all sides.
* **charlen**. number. Maximum characters allowed.

Returns: text. string.

### Button

A button.
`pgui:component("button",{text="BUTTON",margin=2,stroke=true,disable=false})`

Options:

* **text**. string. Text inside the box.
* **margin**. number. Margin separating text from border from all sides.
* **stroke**. boolean. Show border or not.
* **disable**. boolean. Disable clicking.

Returns: if was clicked. boolean. *(Note: returns true for just one frame!)*

### Horizontal slider

A horizontal slider.
`pgui:component("hslider",{min=0,max=100,value=50,size=vec(100,10),stroke=true,format=function(v) return string.format("%.2f", v) end,flr=false})`

Options:

* **min**. number. Minimum value allowed.
* **max**. number. Maximum value allowed.
* **value**. number. Current value of slider.
* **size**. vector. Size of the component. Width and minimum height.
* **format**. function. Function to format the value display inside the slider.
* **flr**. boolean. floor / snap value to an integer.

Returns: value. number.

### Knob

A rotary dial that acts as a radial alternative to the horizontal slider.
`pgui:component("knob",{label="knob",min=0,max=100,value=50,r=10,stroke=true,flr=false,sensibility=1})`

Options:

* **label**. string. REQUIRED. Unique name for keeping internal drag state.
* **min**. number. Minimum value allowed.
* **max**. number. Maximum value allowed.
* **value**. number. Current value of the knob.
* **r**. number. Radius of the circular knob.
* **stroke**. boolean. Show circular border or not.
* **flr**. boolean. floor / snap value to an integer.
* **sensibility**. number. Drag speed multiplier.

Returns: value. number.

### XY Pad

A 2D selection box that outputs normalized coordinates.
`pgui:component("xypad",{size=vec(64,64), x_val=0.5, y_val=0.5, stroke=true})`

Options:

* **size**. vector. Size of the component in width and height.
* **x_val**. number. Current X value mapped between 0.0 and 1.0.
* **y_val**. number. Current Y value mapped between 0.0 and 1.0.
* **stroke**. boolean. Show border or not.

Returns: table. A table containing the coordinates formatted as `{x = number, y = number}`.

### Radio buttons

Radio buttons for selecting one of multiple options in a list.
`pgui:component("radio",{gap=3,r=3,sep=4,selected=1,options={}})`

Options:

* **gap**. number. Vertical gap between options.
* **r**. number. Radius of selector.
* **sep**. number. Separation between selector and option text.
* **selected**. number. Index of currently selected option.
* **options**. table of strings. Text for each one of the options.

Returns: selected. number.

### Multiple selection buttons

Buttons for selecting multiple options in a list.
`pgui:component("multi_select",{gap=3,box_size=7,sep=4,options={},selected={}})`

Options:

* **gap**. number. Vertical gap between options.
* **box_size**. number. Size of selector button. Just one number for width and height because it's a square.
* **sep**. number. Separation between selector and option text.
* **options**. table of strings. Text for each one of the options.
* **selected**. table of booleans. For each option, true indicates it is selected, false indicates it is not.

Returns: selected. table of booleans.

### Checkbox

A toggle button with text.
`pgui:component("checkbox",{text="CHECKBOX",box_size=8,sep=4,value=false})`

Options:

* **text**. string. Descriptive text for the checkbox.
* **box_size**. number. Size of selector button.
* **sep**. number. Separation between selector and option text.
* **value**. boolean. If the checkbox is activated or not.

Returns: value. boolean.

### Palette

Shows selectable sample boxes from a list of colors.
`pgui:component("palette",{columns=4,gap=3,box_size=10,colors={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},selected=1})`

Options:

* **columns**. numbers. Max number of samples per rows.
* **gap**. number. Vertical and horizontal gap between samples.
* **box_size**. number. Size of each sample.
* **colors**. table of numbers. Indexes of colors to include in the palette.
* **selected**. number. Number code of currently selected color.

Returns: selected. number.

---

## Layout components

Layout components are used to group and organize basic components or other layout components.

### Tooltip

A metadata overlay that draws a floating text box when the user hovers over a component. *Note: Tooltips must be placed immediately after the component they attach to in a stack array.*
`pgui:component("tooltip",{text="Tooltip", delay=0.5})`

Options:

* **text**. string. The descriptive text to display inside the tooltip.
* **delay**. number. Time in seconds the mouse must remain perfectly still over the target component before the tooltip appears.

Returns: nil.

### Horizontal stack

Groups a list of components horizontally. Its size will adapt to the size of the stacked contents.
`pgui:component("hstack",{stroke=true,width=0,margin=3,gap=3,box=true,contents={}})`

Options:

* **stroke**. boolean. Show border or not.
* **width**. number. If 0, the width of the stack will adapt to its contents, if > 0 it will be set to the value specified.
* **margin**. number. Margin separating contents from border from all sides.
* **gap**. number. Horizontal gap between components.
* **box**. boolean. Draw containing box.
* **contents**. list of tables. A list of tables, each subtable represents a component to put inside the stack and must contain: `{NAME_OF_COMPONENT, {OPTIONS_OF_COMPONENT}}`

Returns: Table containing the return values of the contained components, in order. table.

### Top menu bar

A convenient horizontal stack formatted as a top menu bar. It will be positioned in vec(0,0).
`pgui:component("topbar",{width=usagi.GAME_W,gap=3,contents={}})`

Options:

* **width**. number. If 0, the width of the stack will adapt to its contents, if > 0 it will be set to the value specified.
* **gap**. number. Horizontal gap between components.
* **contents**. list of tables. A list of tables, each subtable represents a component to put inside the stack.

Returns: Table containing the return values of the contained components, in order. table.

### Vertical stack

Groups a list of components vertically. Its size will adapt to the size of the stacked contents.
`pgui:component("vstack",{stroke=true,height=0,margin=3,gap=3,box=true,contents={}})`

Options:

* **stroke**. boolean. Show border or not.
* **height**. number. If 0, the height of the stack will adapt to its contents, if > 0 it will be set to the value specified.
* **margin**. number. Margin separating contents from border from all sides.
* **gap**. number. Vertical gap between components.
* **box**. boolean. Draw containing box.
* **contents**. list of tables. A list of tables, each subtable represents a component to put inside the stack.

Returns: Table containing the return values of the contained components, in order. table.

### Dropdown

A vertical stack with a button that toggles the display of its contents.
`pgui:component("dropdown",{label="dd",text="DROPDOWN",stroke=true,margin=2,gap=3,contents={},disable=false})`

Options:

* **label**. string. REQUIRED. Unique name for keeping internal state.
* **text**. string. Text inside the button.
* **stroke**. boolean. Show border or not.
* **margin**. number. Margin separating contents from border from all sides.
* **gap**. number. Vertical gap between components in vstack.
* **contents**. list of tables. A list of tables, each subtable represents a component to put inside the vstack.
* **disable**. boolean. Disable dropdown button.

Returns: Table containing the return values of the contained components in its stack, in order. table.
**NOTE:** If you want to close the dropdown with code, you can use `pgui:close_dropdown(LABEL_OF_DROPDOWN)`.

### Scrollable

A container box that can be scrolled with the mousewheel or a trackpad gesture. *Note: As Usagi currently lacks a native rendering mask, content bounds are tracked mathematically but will not visually clip off-screen.*
`pgui:component("scrollable",{label="scrll",scroll_x=false,scroll_y=true,size=vec(50,50),sensibility=15,content={"text_box",{text="scrollable",margin=50}}})`

Options:

* **label**. string. REQUIRED. Unique name for keeping internal state.
* **size**. vector. Desired size of scrollable area.
* **scroll_x**. boolean. Allow x axis scrolling.
* **scroll_y**. boolean. Allow y axis scrolling.
* **sensibility**. number. Multiplier for the smooth lerp scrolling speed.
* **content**. table. A table representing the data of a component to put inside the scrollable area.

Returns: Return value of content component.

### Line

There's also a line component that can be used as a separator in stacks.
`pgui:component("line",{size=vec(100,0)})`

Options:

* **size**. vector. x and y positions with respect to pos.

---

## Color Palette

pgui uses a table to store a color palette of four colors utilizing Usagi's native `gfx` constants. This palette is used in all of the components by default.

| Index in table | Used for | Usagi Default |
| --- | --- | --- |
| 1 | fill color for boxes, buttons, etc. | `gfx.COLOR_WHITE` |
| 2 | on hover fill for buttons | `gfx.COLOR_LIGHT_GRAY` |
| 3 | active color for buttons, checkboxes, sliders, etc. | `gfx.COLOR_BLUE` |
| 4 | stroke colors for borders and text | `gfx.COLOR_BLACK` |

You can set a new table for your general palette with the function `pgui:set_palette({colors})`.

## Limitations

**Engine Level Clipping**: the clipping logic within the scrollable component is a holdover from the original Picotron version of pgui. Because Usagi currently lacks a Lua-exposed bounding mask (gfx.clip), this component calculates interaction bounds perfectly, but it will not visually hide elements spilling outside its box until a clip function is natively supported by the engine.

## Support my work!

This library was made by Sergio Rodríguez Gómez.
If you like this library please consider supporting my work!
You can use this Ko-fi button:
[Ko-fi: srsergior](https://ko-fi.com/srsergior)

Or go to my Buy me a coffee page: [buymeacoffee.com/srsergior](https://buymeacoffee.com/srsergior)

You can also check some of my other work on itch or in this github account, like my Pico-8 games or bebop, a music generator for games and video soundtracks.