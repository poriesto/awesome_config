--[[            
  Licensed under GNU General Public License v2 
   * (c) 2013-2014, Yauheni Kirylau             
--]]

local string		= { format = string.format }
local setmetatable	= setmetatable

local naughty		= require("naughty")

local helpers		= require("actionless.helpers")
local newtimer		= helpers.newtimer
local font		= helpers.font
local beautiful		 = require("beautiful")
local mono_preset	= helpers.mono_preset
local common_widget	= require("actionless.widgets.common").widget
local markup		= require("actionless.markup")
local parse		= require("actionless.parse")
local async		= require("actionless.async")


local netctl = {
  widget = common_widget()
}
--netctl.widget:connect_signal(
--  "mouse::enter", function () netctl.show_notification() end)
--netctl.widget:connect_signal(
--  "mouse::leave", function () netctl.hide_notification() end)

local function worker(args)
  local args = args or {}
  local update_interval = args.update_interval or 5
  local font = args.font or beautiful.tasklist_font or beautiful.font
  netctl.timeout = args.timeout or 0
  netctl.font = args.font or font

  netctl.preset = args.preset or 'bond' -- or netctl or netctl-auto
  netctl.wireless_if = args.wireless_if or 'wlan0'
  netctl.wired_if = args.wired_if or 'eth0'

  function netctl.hide_notification()
    if netctl.id ~= nil then
      naughty.destroy(netctl.id)
      netctl.id = nil
    end
  end

  function netctl.show_notification()
    netctl.hide_notification()
    netctl.id = naughty.notify({
      text = 'not implemented yet',
      timeout = netctl.timeout,
      preset = mono_preset
    })
  end

  function netctl.update()
    if netctl.preset == 'bond' then
      netctl.update_bond()
    elseif netctl.preset == 'netctl-auto' then
      netctl.netctl_auto_update()
    elseif netctl.preset == 'netctl' then
      netctl.netctl_update()
    end
  end

  function netctl.update_bond()
    netctl.interface = parse.find_in_file(
      "/proc/net/bonding/bond0",
      "Currently Active Slave: (.*)"
    ) or 'bndng.err'
    if netctl.interface == netctl.wired_if then
      netctl.update_widget('ethernet')
    elseif netctl.interface == netctl.wireless_if then
      netctl.netctl_auto_update()
    elseif netctl.interface == "None" then
      netctl.update_widget("bndng...")
    else
      netctl.update_widget(netctl.interface)
    end
  end

  function netctl.netctl_auto_update()
    async.execute(
      'netctl-auto current',
      function(str)
        netctl.update_widget(str or 'nctl-a...')
      end)
  end

  function netctl.netctl_update()
    async.execute(
      "systemctl list-unit-files 'netctl@*'",
      function(str)
        netctl.update_widget(
          str:match("netctl@(.*)%.service.*enabled"
          ) or 'nctl...')
      end)
  end

  function netctl.update_widget(network_name)
    netctl.widget:set_markup(
      markup.font(
        font,
        string.format("%-6s", network_name)))
    if netctl.interface == netctl.wired_if then
      netctl.widget:set_image(beautiful.widget_net_wired)
    elseif netctl.interface == netctl.wireless_if then
      netctl.widget:set_image(beautiful.widget_net_wireless)
    else
      netctl.widget:set_image(beautiful.widget_net_searching)
    end
  end

  newtimer("netctl", update_interval, netctl.update)

  return setmetatable(
    netctl,
    { __index = netctl.widget })
end

return setmetatable(
  netctl,
  { __call = function(_, ...)
    return worker(...)
  end }
)
