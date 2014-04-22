local widgets = {
	-- my own widgets
	netctl			= require("widgets.netctl"),
	bat				= require("widgets.bat"),
	systray_toggle	= require("widgets.systray_toggle"),
	random_pic		= require("widgets.random_pic"),
	-- awesome addons
	menu_addon		= require("widgets.menu_addon"),
	-- awesome forks
	tasklist		= require("widgets.tasklist"),
	common			= require("widgets.common"),
	naughty			= require("widgets.naughty"),
	-- lain forks
	markup			= require("widgets.markup"),
	helpers			= require("widgets.helpers"),
	mpd				= require("widgets.mpd"),
	cpu				= require("widgets.cpu"),
	mem				= require("widgets.mem"),
	calendar		= require("widgets.calendar"),
	alsa			= require("widgets.alsa"),
	temp			= require("widgets.temp"),
	-- misc
	settings		= require("widgets.settings"),
	asyncshell		= require("widgets.asyncshell"),
}

return widgets
