---------------------
---- KEYBINDINGS ----
---------------------

local synced = require("lua.syncedworkspaces")

hl.bind(MainMod .. " + Q", hl.dsp.exec_cmd("kitty sh -c 'zellij'"))
local closeWindowBind = hl.bind(MainMod .. " + C", hl.dsp.window.close())

-- Window switcher with Alt+Tab
hl.bind("ALT + Tab", hl.dsp.exec_cmd("qs -c /home/rakman/.config/quickshell/ ipc call windowSwitcher toggleVisibility"))

hl.bind(
	MainMod .. " + Space",
	hl.dsp.exec_cmd("qs -c /home/rakman/.config/quickshell/ ipc call topBar toggleVisibility")
)

hl.bind(MainMod .. " + T", hl.dsp.exec_cmd("thunar"))
hl.bind(MainMod .. " + Z", hl.dsp.exec_cmd(Browser))
hl.bind(MainMod .. " + E", hl.dsp.exec_cmd(FileManager))
hl.bind(MainMod .. " + V", hl.dsp.exec_cmd("copyq toggle"))
hl.bind(MainMod .. " + R", hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind(MainMod .. " + N", hl.dsp.exec_cmd("quickshell ipc call notifications toggle"))

hl.bind(MainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(MainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(MainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))

-- Move focus with MainMod + arrow keys
hl.bind(MainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(MainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(MainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(MainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Monitörler arası hızlı odak ve pencere taşıma
hl.bind(MainMod .. " + bracketleft", hl.dsp.focus({ monitor = "-1" }))
hl.bind(MainMod .. " + bracketright", hl.dsp.focus({ monitor = "+1" }))
hl.bind(MainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ monitor = "-1" }))
hl.bind(MainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ monitor = "+1" }))

-- Virtual Desktop Switching (Dinamik Senkronize Sanal Masaüstü)
for i = 1, 9 do
	hl.bind(MainMod .. " + " .. i, function()
		synced.switch_vdesk(i)
	end)
	hl.bind(MainMod .. " + SHIFT + " .. i, function()
		synced.move_to_vdesk(i)
	end)
end

-- Example special workspace (scratchpad)
hl.bind(MainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(MainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through Virtual Desktops with MainMod + scroll
hl.bind(MainMod .. " + mouse_down", function()
	synced.cycle_vdesk(1)
end)
hl.bind(MainMod .. " + mouse_up", function()
	synced.cycle_vdesk(-1)
end)

-- Move/resize windows with MainMod + LMB/RMB and dragging
hl.bind(MainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(MainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
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
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("SUPER + SHIFT + X", function()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end)
