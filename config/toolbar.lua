local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")

local screen = screen
local client = client
local mouse = mouse

local actionless = require("actionless")
local widgets = actionless.widgets
local custom_tasklist = actionless.tasklist
--local rpic = widgets.random_pic


local toolbar = {}


function toolbar.init(status)
local modkey = status.modkey

-- CLOSE button
status.widgets.close_button = widgets.manage_client()

-- ALSA volume
status.widgets.volume = widgets.alsa({
  update_interval = 5,
  channel = 'Master',
  channels_toggle = {'Master', 'Speaker', 'Headphone'},
})

-- Battery
local batwidget = widgets.bat({
  update_interval = 30,
})

-- CPU
local cpuwidget = widgets.cpu({
  update_interval = 5,
  list_length = 20,
})

-- MEM
local memwidget = widgets.mem({
  update_interval = 10,
  list_length = 20,
})

-- MUSIC
status.widgets.music = widgets.music.widget({
  update_interval = 5,
  backend = 'mpd',
  music_dir = '/media/terik/jessie/music/',
})

-- NetCtl
local netctlwidget = widgets.netctl({
  update_interval = 5,
  preset = 'bond',
  wireless_if = 'wlp12s0',
  wired_if = 'enp0s25'
})

-- Temperature sensor
local tempwidget = widgets.temp({
  update_interval = 10,
  sensor = "Core 0",
  warning = 75
})

-- Textclock
-- mytextclock = awful.widget.textclock(" %a %d %b  %H:%M")
local mytextclock = awful.widget.textclock(" %H:%M")
-- calendar
widgets.calendar:attach(mytextclock)


-- systray_toggle
status.widgets.systray_toggle = widgets.systray_toggle({
  screen = 1
})

-- Separators
local separator = wibox.widget.textbox(' ')
--arrl = wibox.widget.imagebox()
--arrl:set_image(beautiful.arrl)

-- Create a wibox for each screen and add it
local mywibox = {}
status.widgets.promptbox = {}
local mylayoutbox = {}
local mytaglist = {}
mytaglist.buttons = awful.util.table.join(
  awful.button({		}, 1, awful.tag.viewonly),
  awful.button({ modkey		}, 1, awful.client.movetotag),
  awful.button({		}, 3, awful.tag.viewtoggle),
  awful.button({ modkey		}, 3, awful.client.toggletag),
  awful.button({		}, 5, function(t)
    awful.tag.viewnext(awful.tag.getscreen(t)) end),
  awful.button({		}, 4, function(t)
    awful.tag.viewprev(awful.tag.getscreen(t)) end)
)
local mycurrenttask = {}
local mytasklist = {}
mytasklist.buttons = awful.util.table.join(
  awful.button({ }, 1, function (c)
    if c == client.focus then
      c.minimized = true
    else
      -- Without this, the following
      -- :isvisible() makes no sense
      c.minimized = false
      if not c:isvisible() then
        awful.tag.viewonly(c:tags()[1])
      end
      -- This will also un-minimize
      -- the client, if needed
      client.focus = c
      c:raise()
    end
  end),
  awful.button({ }, 3, function ()
    if status.menu.instance then
      status.menu.instance:hide()
      status.menu.instance = nil
    else
      status.menu.instance = awful.menu.clients({
        theme = {width=screen[mouse.screen].workarea.width},
        coords = {x=0, y=18}})
    end
  end),
  awful.button({ }, 4, function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
  end),
  awful.button({ }, 5, function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
  end))

for s = 1, screen.count() do
  local i = beautiful.screen_margin
  awful.screen.padding( screen[s], {top = i, bottom = i, left = i, right = i} )
  -- Create a promptbox for each screen
  status.widgets.promptbox[s] = awful.widget.prompt()
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  mylayoutbox[s] = awful.widget.layoutbox(s)
  mylayoutbox[s]:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
      awful.layout.inc(awful.layout.layouts, 1) end),
    awful.button({ }, 3, function ()
      awful.layout.inc(awful.layout.layouts, -1) end),
    awful.button({ }, 5, function ()
      awful.layout.inc(awful.layout.layouts, 1) end),
    awful.button({ }, 4, function ()
      awful.layout.inc(awful.layout.layouts, -1) end)))
  -- Create a taglist widget
  mytaglist[s] = awful.widget.taglist(
    s, awful.widget.taglist.filter.all, mytaglist.buttons)

  -- Create a tasklist widget
  mytasklist[s] = custom_tasklist(
    s, custom_tasklist.filter.focused_and_minimized_current_tags, mytasklist.buttons)

  -- Create the wibox
  mywibox[s] = awful.wibox({ position = "top", screen = s, height = 18 })

  -- Widgets that are aligned to the left
  local left_layout = wibox.layout.fixed.horizontal()
  left_layout:add(separator)
  left_layout:add(mytaglist[s])
  left_layout:add(status.widgets.close_button)
  left_layout:add(status.widgets.promptbox[s])
  left_layout:add(separator)

  -- Widgets that are aligned to the right
  local right_layout = wibox.layout.fixed.horizontal()
  right_layout:add(separator)
  right_layout:add(separator)
  right_layout:add(netctlwidget)
  right_layout:add(separator)
  right_layout:add(status.widgets.music)
  right_layout:add(separator)
  right_layout:add(status.widgets.volume)
  if s == 1 then right_layout:add(status.widgets.systray_toggle) end
  right_layout:add(separator)
  right_layout:add(memwidget)
  right_layout:add(separator)
  right_layout:add(cpuwidget)
  right_layout:add(tempwidget)
  right_layout:add(separator)
  --right_layout:add(fswidgetbg)
  --right_layout:add(arrl)
  right_layout:add(batwidget)
  right_layout:add(mytextclock)
  right_layout:add(separator)
--  right_layout:add(arrl_ld)
  right_layout:add(mylayoutbox[s])

  -- Now bring it all together (with the tasklist in the middle)
  local layout = wibox.layout.align.horizontal()
  layout:set_left(left_layout)
  layout:set_middle(mytasklist[s])
  layout:set_right(right_layout)

  mywibox[s]:set_widget(layout)
  mywibox[s].opacity = beautiful.panel_opacity
end


end
return toolbar
