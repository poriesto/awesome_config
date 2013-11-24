
--[[
												  
	 Licensed under GNU General Public License v2 
	  * (c) 2013, Luke Bonham					 
	  * (c) 2010, Adrian C. <anrxc@sysphere.org>  
												  
--]]

local helpers	  = require("lain.helpers")

local awful		= require("awful")
local escape_f	 = require("awful.util").escape
local naughty	  = require("naughty")
local wibox		= require("wibox")

local io		   = { popen	= io.popen }
local os		   = { execute  = os.execute,
					   getenv   = os.getenv }
local string	   = { format   = string.format,
					   gmatch   = string.gmatch }
local asyncshell  = require("widgets.asyncshell")
local setmetatable = setmetatable

-- MPD infos
-- lain.widgets.mpd
local mpd = {id=nil}

local function worker(args)
	local args		= args or {}
	local timeout	 = args.timeout or 2
	local password	= args.password or "\"\""
	local host		= args.host or "127.0.0.1"
	local port		= args.port or "6600"
	local music_dir   = args.music_dir or os.getenv("HOME") .. "/Music"
	local cover_size  = args.cover_size or 100
	local default_art = args.default_art or ""
	local settings	= args.settings or function() end

	local mpdcover = helpers.scripts_dir .. "mpdcover"
	local mpdh = "telnet://" .. host .. ":" .. port
	--local echo = "echo 'password " .. password .. "\nstatus\ncurrentsong\nclose'"
	local echo = "echo 'status\ncurrentsong'"

	mpd.widget = wibox.widget.textbox('')

	helpers.set_map("current mpd track", nil)

	function mpd.hide_notification()
		if mpd.id ~= nil then
			naughty.destroy(mpd.id)
			mpd.id = nil
		end
	end

	function mpd.show_notification()
		mpd.hide_notification()
		mpd.id = naughty.notify({
			icon = "/tmp/mpdcover.png" ,
			title   = "Now playing",
			text = string.format("%s (%s) - %s\n%s", mpd_now.artist, mpd_now.album, mpd_now.date, mpd_now.title),
			timeout = 6
				})
	end


	function mpd.update()
		asyncshell.request(echo .. " | curl --connect-timeout 1 -fsm 1 " .. mpdh, function(f) mpd.post_update(f) end)
	end

	function mpd.toggle()
		awful.util.spawn_with_shell("mpc toggle || ncmpcpp toggle || ncmpc toggle || pms toggle")
		mpd.update()
	end

	function mpd.next_song()
		awful.util.spawn_with_shell("mpc next || ncmpcpp next || ncmpc next || pms next")
		mpd.update()
	end

	function mpd.prev_song()
		awful.util.spawn_with_shell("mpc prev || ncmpcpp prev || ncmpc prev || pms prev")
		mpd.update()
	end

	mpd.widget:connect_signal("mouse::enter", function () mpd.show_notification() end)
	mpd.widget:connect_signal("mouse::leave", function () mpd.hide_notification() end)
	mpd.widget:buttons(awful.util.table.join(
		awful.button({ }, 1, mpd.toggle),
		awful.button({ }, 5, mpd.next_song),
		awful.button({ }, 4, mpd.prev_song)
	))

	function mpd.post_update(f)
		mpd_now = {
			state  = "N/A",
			file   = "N/A",
			artist = "N/A",
			title  = "N/A",
			album  = "N/A",
			date   = "N/A"
		}

		--local f = io.popen(echo .. " | curl --connect-timeout 1 -fsm 1 " .. mpdh)

		for line in f:lines() do
			for k, v in string.gmatch(line, "([%w]+):[%s](.*)$") do
				if	 k == "state"  then mpd_now.state  = v
				elseif k == "file"   then mpd_now.file   = v
				elseif k == "Artist" then mpd_now.artist = escape_f(v)
				elseif k == "Title"  then mpd_now.title  = escape_f(v)
				elseif k == "Album"  then mpd_now.album  = escape_f(v)
				elseif k == "Date"   then mpd_now.date   = escape_f(v)
				end
			end
		end
		if mpd_now.artist == "N/A" then
			mpd_now.artist = escape_f(mpd_now.file:match("^(.*) [-] .*")) or "N/A"
		end
		if mpd_now.title == "N/A" then
			mpd_now.title = escape_f(mpd_now.file:match("^.* [-] (.*)")) or escape_f(mpd_now.file)
		end

		f:close()

		widget = mpd.widget
		settings()

		if mpd_now.state == "play"
		then
			if mpd_now.title ~= helpers.get_map("current mpd track")
			then
				helpers.set_map("current mpd track", mpd_now.title)

				os.execute(string.format("%s %q %q %d %q", mpdcover, music_dir, mpd_now.file, cover_size, default_art))

				mpd.show_notification()
			end
		elseif mpd_now.state ~= "pause"
		then
			helpers.set_map("current mpd track", nil)
		end
	end

	helpers.newtimer("mpd", timeout, mpd.update)

	return setmetatable(mpd, { __index = mpd.widget })
end

return setmetatable(mpd, { __call = function(_, ...) return worker(...) end })
