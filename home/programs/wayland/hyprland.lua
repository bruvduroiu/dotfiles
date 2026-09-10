-- Hyprland config — plain Lua, the native 0.55+ format.
--
-- Wiring: hyprland.nix prepends a `host` table (stylix border colours) and
-- ships this file verbatim as ~/.config/hypr/hyprland.lua via home-manager's
-- extraConfig. Everything else lives here, in real Lua.
--
-- Editing: .luarc.json beside this file points lua-language-server at
-- Hyprland's hl.* stubs (/run/current-system/sw/share/hypr/stubs).
-- Poke a live session with `hyprctl eval '<lua>'` (0.56 REPL).
--
-- framework13-first: monitors/device/per-ws-monitor pins live here for now;
-- generalise to per-host fragments when phantom/iso migrate.

-- ----- variables ------------------------------------------------------
local mod = "SUPER"
local menu = "noctalia msg panel-toggle launcher"
local terminal = "uwsm app -- ghostty"
local fileManager = "uwsm app -- yazi"
local browser = "uwsm app -- firefox"
local workBrowser = "uwsm app -- firefox -P work --no-remote" -- -P matches HM profile name; --no-remote = separate instance alongside personal
local hardBrowser = "uwsm app -- mullvad-browser" -- ghost: Tor-Browser-minus-Tor, blends into the anti-fingerprint crowd
local webapp = browser .. " --new-tab"

-- framework13 touchpad accel + scroll curve
local accelpoints =
	"0.000 0.391 1.375 3.422 7.000 12.578 20.625 31.609 46.000 64.266 86.875 114.297 146.000 185.453 230.125 281.484 340.000 406.141 480.375 563.172"

-- ----- env ------------------------------------------------------------
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "24")

-- ----- monitors + per-device (framework13) ----------------------------
hl.monitor({ output = "DP-4", mode = "3840x2160@60.00", position = "0x0", scale = 1, vrr = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "3840x0", scale = 1.3333, vrr = 1 })

hl.device({
	name = "pixa3854:00-093a:0274-touchpad",
	accel_profile = "custom " .. accelpoints,
	scroll_points = accelpoints,
	natural_scroll = true,
})

-- ----- autostart ------------------------------------------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm finalize")
	-- fcitx5 is owned by the NixOS i18n.inputMethod XDG-autostart systemd
	-- unit (app-org.fcitx.Fcitx5@autostart.service). Launching it again
	-- here raced that unit via --replace and left the survivor with an
	-- empty IM group: apps connected over wayland_v2 but Ctrl+Space (and
	-- even dbus -o) toggled nothing. Let systemd own the single instance.
	hl.exec_cmd("[workspace 1 silent] uwsm app -- firefox")
	hl.exec_cmd("[workspace 1 silent] uwsm app -- obsidian")
end)

-- ----- keyword config -------------------------------------------------
hl.config({
	general = {
		gaps_in = 1,
		gaps_out = 0,
		border_size = 1,
		col = { active_border = host.active, inactive_border = host.inactive },
		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},
	decoration = {
		rounding = 0,
		shadow = { enabled = false, range = 4, render_power = 3, color = "rgba(00000055)" },
		blur = {
			enabled = false,
			size = 6,
			passes = 1,
			ignore_opacity = true,
			new_optimizations = true,
			special = true,
			popups = true,
			vibrancy = 0.1696,
		},
	},
	cursor = { no_hardware_cursors = false, hide_on_key_press = true },
	master = {
		mfact = 0.60,
		new_status = "slave",
		new_on_top = false,
		allow_small_split = true,
		-- master on the RIGHT, stack on the left — better on the narrow laptop
		-- panel than center-master. (slave_count/fallback only apply if you
		-- cycle back to center via SUPER+CTRL+i.)
		orientation = "right",
		slave_count_for_center_master = 2,
		center_master_fallback = "left",
	},
	dwindle = {
		preserve_split = true, -- keep split orientation as windows come/go
		force_split = 2, -- always split to the right / below (predictable)
		smart_split = false, -- deterministic (not cursor-position based)
		default_split_ratio = 1.0, -- even 50/50 splits
	},
	scrolling = {
		column_width = 0.5,
		fullscreen_on_one_column = true,
		follow_focus = true,
		wrap_focus = true,
		explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
	},
	misc = { force_default_wallpaper = 0, enable_swallow = true, swallow_regex = "^(com.mitchellh.ghostty)$", vrr = 1 },
	input = {
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = { natural_scroll = true, disable_while_typing = true },
	},
	group = {
		auto_group = false,
		groupbar = {
			enabled = true,
			font_size = 10,
			height = 18,
			rounding = 0,
			render_titles = true,
			scrolling = true,
			-- gradients stay off (default), so col.* paints only the indicator
			-- strip and tabs keep no background fill — titles sit on the desktop.
			col = {
				active = host.active,
				inactive = host.inactive,
				locked_active = host.active,
				locked_inactive = host.inactive,
			},
			-- Hyprland defaults these to a hardcoded white, unreadable on a light
			-- wallpaper; base05/base04 track polarity (see hyprland.nix).
			text_color = host.bar_text,
			text_color_inactive = host.bar_text_inactive,
			text_color_locked_active = host.bar_text,
			text_color_locked_inactive = host.bar_text_inactive,
		},
		col = {
			border_active = host.active,
			border_inactive = host.inactive,
			border_locked_active = host.active,
			border_locked_inactive = host.inactive,
		},
	},
	binds = { window_direction_monitor_fallback = false, allow_workspace_cycles = true },
	animations = { enabled = false },
})

-- ----- gestures -------------------------------------------------------
hl.gesture({
	fingers = 3,
	direction = "left",
	action = function()
		hl.dispatch(hl.dsp.layout("move +col"))
	end,
})
hl.gesture({
	fingers = 3,
	direction = "right",
	action = function()
		hl.dispatch(hl.dsp.layout("move -col"))
	end,
})
-- 4-finger vertical: pull the comms scratchpads up/down
hl.gesture({
	fingers = 4,
	direction = "up",
	action = function()
		hl.dispatch(hl.dsp.workspace.toggle_special("chat"))
	end,
})
hl.gesture({
	fingers = 4,
	direction = "down",
	action = function()
		hl.dispatch(hl.dsp.workspace.toggle_special("work"))
	end,
})

-- ----- helpers --------------------------------------------------------
-- place() drives the `place` submap: float the active window, then size +
-- position it as fractions of the focused monitor. Monitor width/height are
-- PHYSICAL px, but exact move/resize work in LOGICAL space, so divide by
-- scale (x/y are already logical).
local function place(fw, fh, fx, fy)
	local m = hl.get_active_monitor()
	local w = m.width / m.scale
	local h = m.height / m.scale
	hl.dispatch(hl.dsp.window.float({ action = "enable" }))
	hl.dispatch(hl.dsp.window.resize({ x = math.floor(w * fw), y = math.floor(h * fh), exact = true }))
	hl.dispatch(hl.dsp.window.move({ x = math.floor(m.x + w * fx), y = math.floor(m.y + h * fy), exact = true }))
end

-- Position of the active window inside its own group, 1-based, plus the group
-- size. group.current_index exists too but its base isn't pinned down by the
-- stubs, so walk members and match on address instead. Returns nil when the
-- window is ungrouped or members isn't a usable list.
local function group_pos(w)
	local g = w and w.group
	local m = g and g.members
	if type(m) ~= "table" then
		return nil
	end
	for i, x in ipairs(m) do
		if x and x.address == w.address then
			return i, #m
		end
	end
	return nil
end

-- cycle_win() walks the workspace's windows *and* group tabs as one sequence:
-- inside a group it steps the groupbar (group.next/prev), and once it runs off
-- the last tab (or before the first, going back) it hands over to the layout
-- cycle so focus leaves the group instead of wrapping inside it. Entering the
-- next group lands on its active tab, so the sequence stays continuous.
-- HL.Window.group is nil for ungrouped windows, so this is a plain field read
-- at press time -- only possible because lua binds take a function instead of
-- a fixed dispatcher.
--
-- The tail is layout-dependent: cycle_next({ next = false, tiled = true }) is
-- broken on monocle/master -- upstream routes it to layoutMessage("cyclenext,
-- b") (ConfigActions.cpp), which neither layout parses (monocle wants exactly
-- "cycleprev", master only knows a "noloop" arg). Use the layoutmsg path
-- there; generic window cycle everywhere else.
local function cycle_win(next)
	local w = hl.get_active_window()
	if w and w.group then
		local i, n = group_pos(w)
		-- unknown position -> stay in the group (old behaviour); otherwise
		-- only tab while there's a tab left in the direction of travel.
		if not i or (next and i < n) or (not next and i > 1) then
			hl.dispatch(next and hl.dsp.group.next() or hl.dsp.group.prev())
			return
		end
	end
	local ws = hl.get_active_workspace()
	local l = ws and ws.tiled_layout or ""
	if l == "monocle" or l == "master" then
		hl.dispatch(hl.dsp.layout(next and "cyclenext" or "cycleprev"))
	else
		hl.dispatch(hl.dsp.window.cycle_next({ tiled = true, next = next }))
	end
end

-- ----- keybinds -------------------------------------------------------
-- mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + ALT + mouse:272", hl.dsp.window.resize(), { mouse = true })

-- compositor
hl.bind(mod .. " + CTRL + ALT + Q", hl.dsp.exit())
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(mod .. " + SHIFT + CTRL + ESCAPE", hl.dsp.exec_cmd("systemctl poweroff"))

-- tiling control
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + G", hl.dsp.group.toggle())
hl.bind(mod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + T", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + SHIFT + C", hl.dsp.window.center())
hl.bind(mod .. " + P", hl.dsp.window.pin({ action = "toggle" }))
hl.bind(mod .. " + D", hl.dsp.focus({ urgent_or_last = true }))

-- window / group-tab cycling — cycle_win() treats group tabs as part of the
-- window sequence: tab through the group, then step out to the next window
-- (see helpers; it also branches per layout, since the generic cycle_next
-- reverse is broken upstream on monocle/master).
hl.bind(mod .. " + TAB", function()
	cycle_win(true)
end)
hl.bind(mod .. " + SHIFT + TAB", function()
	cycle_win(false)
end)
hl.bind(mod .. " + CTRL + G", hl.dsp.window.move({ out_of_group = true }))
hl.bind(mod .. " + ALT + G", hl.dsp.exec_cmd("hyprctl dispatch lockgroups toggle"))

-- utilities
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + y", hl.dsp.exec_cmd(fileManager))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + CTRL + Q", hl.dsp.exec_cmd("noctalia msg session lock"))

-- Noctalia panels
hl.bind(mod .. " + CTRL + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("noctalia msg window-switcher"))
hl.bind(mod .. " + CTRL + period", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher /emo "))

-- notifications
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("noctalia msg notification-dnd-toggle"))
hl.bind(mod .. " + CTRL + D", hl.dsp.exec_cmd("noctalia msg panel-open control-center notifications"))

-- move focus
hl.bind(mod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + j", hl.dsp.focus({ direction = "down" }))

-- group tab cycling, unconditional (SUPER+TAB only tabs when grouped)
hl.bind("ALT + TAB", hl.dsp.group.next())
hl.bind("ALT + SHIFT + TAB", hl.dsp.group.prev())

-- move window or group
hl.bind(mod .. " + SHIFT + h", hl.dsp.window.move({ direction = "l", group_aware = true }))
hl.bind(mod .. " + SHIFT + l", hl.dsp.window.move({ direction = "r", group_aware = true }))
hl.bind(mod .. " + SHIFT + k", hl.dsp.window.move({ direction = "u", group_aware = true }))
hl.bind(mod .. " + SHIFT + j", hl.dsp.window.move({ direction = "d", group_aware = true }))

-- cycle workspaces
hl.bind(mod .. " + bracketleft", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mod .. " + bracketright", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mod .. " + ESCAPE", hl.dsp.focus({ workspace = "previous" }))

-- cycle monitors
hl.bind(mod .. " + SHIFT + bracketleft", hl.dsp.focus({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + bracketright", hl.dsp.focus({ monitor = "r" }))

-- send workspace to monitor
hl.bind(mod .. " + SHIFT + ALT + bracketleft", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + ALT + bracketright", hl.dsp.workspace.move({ monitor = "r" }))

-- master: promote to master
hl.bind(mod .. " + CTRL + RETURN", hl.dsp.layout("swapwithmaster master"))

-- column resize (scrolling)
hl.bind(mod .. " + equal", hl.dsp.layout("colresize +conf"))
hl.bind(mod .. " + minus", hl.dsp.layout("colresize -conf"))
hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.layout("orientationnext"))
hl.bind(mod .. " + CTRL + SHIFT + SPACE", hl.dsp.layout("orientationprev"))

-- scroll layout
hl.bind(mod .. " + c", hl.dsp.layout("fit active"))
hl.bind(mod .. " + SHIFT + c", hl.dsp.layout("fit visible"))
hl.bind(mod .. " + CTRL + c", hl.dsp.layout("fit all"))
hl.bind(mod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mod .. " + comma", hl.dsp.layout("move -col"))

-- theme toggle
hl.bind(mod .. " + F5", hl.dsp.exec_cmd("noctalia msg theme-mode-toggle"))

-- screenshot
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("screenshot area"))
hl.bind("Print", hl.dsp.exec_cmd("screenshot full"))

-- screen recording
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("wf-recorder-toggle"))
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("wf-recorder-toggle area"))

-- special workspaces (chat-toggle retired -> plain toggle)
hl.bind(mod .. " + M", hl.dsp.workspace.toggle_special("chat"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special:chat" }))
hl.bind(mod .. " + B", hl.dsp.workspace.toggle_special("work"))
hl.bind(mod .. " + SHIFT + B", hl.dsp.window.move({ workspace = "special:work" }))

-- z-order for floating windows
hl.bind(mod .. " + ALT + k", hl.dsp.window.alter_zorder({ mode = "top" }))
hl.bind(mod .. " + ALT + j", hl.dsp.window.alter_zorder({ mode = "bottom" }))

-- submap entries
hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.bind(mod .. " + X", hl.dsp.submap("launch"))
hl.bind(mod .. " + V", hl.dsp.submap("place"))
hl.bind(mod .. " + N", hl.dsp.submap("mark"))
hl.bind(mod .. " + apostrophe", hl.dsp.submap("jump"))

-- dynamic layout control --------------------------------------------
-- scrolling tape (ws1/3/5 + specials): swap columns / promote / recentre.
-- (consume/expel dropped — SUPER+SHIFT+h/l already moves windows between
-- columns. layoutmsg is layout-scoped, so these no-op off scrolling.)
hl.bind(mod .. " + SHIFT + u", hl.dsp.layout("swapcol l"))
hl.bind(mod .. " + SHIFT + o", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + CTRL + u", hl.dsp.layout("promote"))
hl.bind(mod .. " + CTRL + o", hl.dsp.layout("center"))
-- master stack (ws2 coding): add/remove a master window, cycle orientation
hl.bind(mod .. " + i", hl.dsp.layout("addmaster"))
hl.bind(mod .. " + SHIFT + i", hl.dsp.layout("removemaster"))
hl.bind(mod .. " + CTRL + i", hl.dsp.layout("orientationcycle"))

-- locked / repeating media + brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl -c backlight s 10%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl -c backlight s 10%-"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- workspaces 1..10: switch / move / move-silent (key 10 -> "0")
for i = 1, 10 do
	local key = tostring(i % 10)
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
	hl.bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

-- ----- submaps --------------------------------------------------------
-- resize: sticky, repeatable; exit with escape/return
hl.define_submap("resize", function()
	hl.bind("h", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
	hl.bind("l", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
	hl.bind("k", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
	hl.bind("j", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("RETURN", hl.dsp.submap("reset"))
end)

-- launch: auto-resets to global after each action
hl.define_submap("launch", "reset", function()
	hl.bind("A", hl.dsp.exec_cmd(webapp .. " https://openrouter.ai/chat"))
	hl.bind("B", hl.dsp.exec_cmd(browser))
	hl.bind("W", hl.dsp.exec_cmd(workBrowser))
	hl.bind("H", hl.dsp.exec_cmd(hardBrowser))
	hl.bind("O", hl.dsp.exec_cmd("uwsm app -- obsidian"))
	hl.bind("R", hl.dsp.exec_cmd(terminal .. " -e newsboat"))
	hl.bind("slash", hl.dsp.exec_cmd("uwsm app -- keepassxc"))
	hl.bind("escape", hl.dsp.submap("reset"))
end)

-- place: snap floating windows to zones; stays active for multiple placements
hl.define_submap("place", function()
	-- halves — place(width, height, x, y) as monitor fractions
	hl.bind("h", function()
		place(0.5, 1.0, 0.0, 0.0)
	end)
	hl.bind("l", function()
		place(0.5, 1.0, 0.5, 0.0)
	end)
	hl.bind("k", function()
		place(1.0, 0.5, 0.0, 0.0)
	end)
	hl.bind("j", function()
		place(1.0, 0.5, 0.0, 0.5)
	end)
	-- center variants (centred = equal margins: x = (1 - w) / 2)
	hl.bind("c", function()
		place(0.7, 0.7, 0.15, 0.15)
	end)
	hl.bind("f", function()
		place(0.95, 0.95, 0.025, 0.025)
	end)
	hl.bind("m", function()
		place(0.5, 0.5, 0.25, 0.25)
	end)
	-- quadrants
	hl.bind("1", function()
		place(0.5, 0.5, 0.0, 0.0)
	end)
	hl.bind("2", function()
		place(0.5, 0.5, 0.5, 0.0)
	end)
	hl.bind("3", function()
		place(0.5, 0.5, 0.0, 0.5)
	end)
	hl.bind("4", function()
		place(0.5, 0.5, 0.5, 0.5)
	end)
	-- thirds (4K panel): u/i/o = left/middle/right column
	hl.bind("u", function()
		place(0.333, 1.0, 0.0, 0.0)
	end)
	hl.bind("i", function()
		place(0.334, 1.0, 0.333, 0.0)
	end)
	hl.bind("o", function()
		place(0.333, 1.0, 0.667, 0.0)
	end)
	-- two-thirds: SHIFT+u = left, SHIFT+o = right
	hl.bind("SHIFT + u", function()
		place(0.667, 1.0, 0.0, 0.0)
	end)
	hl.bind("SHIFT + o", function()
		place(0.667, 1.0, 0.333, 0.0)
	end)
	-- t = back to tiling and out of the submap
	hl.bind("t", function()
		hl.dispatch(hl.dsp.window.float({ action = "disable" }))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	-- incremental move (repeatable)
	hl.bind("SHIFT + h", hl.dsp.window.move({ x = -40, y = 0, relative = true }), { repeating = true })
	hl.bind("SHIFT + l", hl.dsp.window.move({ x = 40, y = 0, relative = true }), { repeating = true })
	hl.bind("SHIFT + k", hl.dsp.window.move({ x = 0, y = -40, relative = true }), { repeating = true })
	hl.bind("SHIFT + j", hl.dsp.window.move({ x = 0, y = 40, relative = true }), { repeating = true })
	-- incremental resize (repeatable)
	hl.bind("equal", hl.dsp.window.resize({ x = 40, y = 40, relative = true }), { repeating = true })
	hl.bind("minus", hl.dsp.window.resize({ x = -40, y = -40, relative = true }), { repeating = true })
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("RETURN", hl.dsp.submap("reset"))
end)

-- vim marks: set / jump, auto-reset after each letter
local function mark_binds(action)
	for letter in ("abcdefghijklmnopqrstuvwxyz"):gmatch("%a") do
		hl.bind(letter, hl.dsp.exec_cmd("hypr-mark " .. action .. " " .. letter))
	end
	hl.bind("escape", hl.dsp.submap("reset"))
end
hl.define_submap("mark", "reset", function()
	mark_binds("set")
end)
hl.define_submap("jump", "reset", function()
	mark_binds("jump")
end)

-- ----- window rules ---------------------------------------------------
-- tags
hl.window_rule({
	match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },
	tag = "+browser",
})
hl.window_rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Cc]hromium)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Cc]hromium-browser)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(com.mitchellh.ghostty)$" }, tag = "+terminal" })
hl.window_rule({ match = { class = "^([Tt]hunderbird)$" }, tag = "+im-work" })
hl.window_rule({ match = { class = "^([Ss]lack)$" }, tag = "+im-work" })
hl.window_rule({ match = { class = "^([Mm]attermost\\.[Dd]esktop)$" }, tag = "+im-work" })
hl.window_rule({ match = { class = "^([Dd]iscord).*$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(org.telegram.desktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ss]ignal)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus)$" }, tag = "+file-manager" })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, tag = "+pip" })
hl.window_rule({ match = { class = "^(org.keepassxc.KeePassXC)$" }, tag = "+passwd" })

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

-- opacity
hl.window_rule({ match = { class = ".*" }, opacity = "1.0 0.97" })
hl.window_rule({ match = { tag = "file-manager" }, opacity = "0.97 0.8" })

hl.window_rule({ match = { tag = "im-work" }, workspace = "special:work" })
hl.window_rule({ match = { tag = "im" }, workspace = "special:chat" })

-- notes = obsidian beside firefox on ws1
hl.window_rule({ match = { tag = "browser" }, workspace = "1" })
hl.window_rule({ match = { class = "^(obsidian)$" }, workspace = "1" })

hl.window_rule({ match = { title = "^(Grayjay)$" }, float = false })
hl.window_rule({ match = { title = "^(Grayjay)$" }, workspace = "4" })

-- workspace 3 = floating (no float layout in hypr; float every window)
hl.window_rule({ match = { workspace = "3" }, float = true })

-- picture-in-picture
hl.window_rule({ match = { initial_title = "^Picture-in-Picture$" }, opacity = "1 1" })
hl.window_rule({ match = { tag = "pip" }, float = true })
hl.window_rule({ match = { tag = "pip" }, pin = true })
hl.window_rule({ match = { tag = "pip" }, no_focus = true })
hl.window_rule({ match = { tag = "pip" }, size = "300 169" })
hl.window_rule({ match = { tag = "pip" }, move = "100%-320 100%-190" })
hl.window_rule({ match = { tag = "pip" }, keep_aspect_ratio = true })

-- keepassxc
hl.window_rule({ match = { tag = "passwd" }, float = true })
hl.window_rule({ match = { tag = "passwd" }, center = true })
hl.window_rule({ match = { tag = "passwd" }, size = "60% 70%" })

hl.window_rule({ match = { tag = "terminal" }, tile = true })

-- scrolling layout column widths
hl.window_rule({ match = { class = "^(obsidian)$" }, scrolling_width = 0.333 })
hl.window_rule({ match = { tag = "terminal" }, scrolling_width = 0.5 })
hl.window_rule({ match = { tag = "browser" }, scrolling_width = 0.667 })
hl.window_rule({ match = { tag = "im-work" }, scrolling_width = 0.333 })
hl.window_rule({ match = { tag = "im" }, scrolling_width = 0.5 })

-- screen sharing
hl.window_rule({ match = { tag = "im" }, no_screen_share = true })
hl.window_rule({ match = { tag = "im-work" }, no_screen_share = true })
hl.window_rule({ match = { tag = "passwd" }, no_screen_share = true })

hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, center = true })

-- satty annotation editor
hl.window_rule({ match = { class = "^(com.gabm.satty)$" }, float = true })
hl.window_rule({ match = { class = "^(com.gabm.satty)$" }, size = "80% 80%" })
hl.window_rule({ match = { class = "^(com.gabm.satty)$" }, center = true })

-- smart borders
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, rounding = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]" }, rounding = 0 })

-- dialog windows: float + center per title
local dialog_titles =
	{ "Open File", "Select a File", "Choose wallpaper", "Open Folder", "Save As", "Library", "File Upload" }
for _, t in ipairs(dialog_titles) do
	hl.window_rule({ match = { title = "^(" .. t .. ")(.*)$" }, float = true })
	hl.window_rule({ match = { title = "^(" .. t .. ")(.*)$" }, center = true })
end

-- ----- workspace rules ------------------------------------------------
-- per-workspace layouts
hl.workspace_rule({ workspace = "1", layout = "scrolling" })
hl.workspace_rule({ workspace = "2", layout = "master" })
hl.workspace_rule({ workspace = "3", layout = "scrolling" })
hl.workspace_rule({ workspace = "4", layout = "monocle" })
hl.workspace_rule({ workspace = "5", layout = "scrolling" })
hl.workspace_rule({ workspace = "special:work", layout = "scrolling" })
hl.workspace_rule({ workspace = "special:chat", layout = "scrolling" })

hl.workspace_rule({ workspace = "special:work", gaps_out = 40, gaps_in = 10 })
hl.workspace_rule({ workspace = "special:chat", gaps_out = 40, gaps_in = 10 })

-- smart gaps
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

-- per-workspace monitor pins (framework13)
hl.workspace_rule({ workspace = "1", monitor = "DP-4", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-4" })
hl.workspace_rule({ workspace = "3", monitor = "DP-4" })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "5", monitor = "eDP-1" })

-- Noctalia panels and actions (shared mnemonic keys with Niri).
hl.bind(mod .. " + CTRL + SPACE", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mod .. " + CTRL + A", hl.dsp.exec_cmd("noctalia msg panel-open control-center audio"))
hl.bind(mod .. " + CTRL + B", hl.dsp.exec_cmd("noctalia msg panel-open control-center bluetooth"))
hl.bind(mod .. " + CTRL + N", hl.dsp.exec_cmd("noctalia msg panel-open control-center network"))
hl.bind(mod .. " + CTRL + M", hl.dsp.exec_cmd("noctalia msg panel-open control-center media"))
hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd("noctalia msg panel-open control-center power"))
hl.bind(mod .. " + CTRL + T", hl.dsp.exec_cmd("noctalia msg panel-open control-center calendar"))
hl.bind(mod .. " + CTRL + W", hl.dsp.exec_cmd("noctalia msg panel-open control-center weather"))
hl.bind(mod .. " + CTRL + I", hl.dsp.exec_cmd("noctalia msg panel-open control-center system"))
hl.bind(mod .. " + CTRL + F5", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"))
hl.bind(mod .. " + CTRL + Comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(mod .. " + CTRL + SHIFT + Q", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind(mod .. " + CTRL + SHIFT + I", hl.dsp.exec_cmd("noctalia msg caffeine-toggle"))
hl.bind(mod .. " + CTRL + SHIFT + D", hl.dsp.exec_cmd("noctalia msg notification-invoke-latest"))
hl.bind(mod .. " + CTRL + SHIFT + BackSpace", hl.dsp.exec_cmd("noctalia msg notification-clear-active"))
