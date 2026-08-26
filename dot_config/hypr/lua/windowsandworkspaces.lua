--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- 1. Dual Monitor Workspace Rules (Sanal Masaüstü Eşlemeleri)
-- HDMI-A-1 (Sol Ana Ekran): Workspace 1..9
for i = 1, 9 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "HDMI-A-1",
		default = (i == 1),
	})
end

-- eDP-1 (Sağ Laptop Ekranı): Workspace 11..19
for i = 1, 9 do
	hl.workspace_rule({
		workspace = tostring(10 + i),
		monitor = "eDP-1",
		default = (i == 1),
	})
end

-- 2. Window Rules
local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps.
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Layer rules
local overlayLayerRule = hl.layer_rule({
	name = "no-anim-overlay",
	match = { namespace = "^my-overlay$" },
	no_anim = true,
})
overlayLayerRule:set_enabled(true)

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "copyq-floating-cursor",
	match = { class = "^(com.github.hluk.copyq)$" },
	float = true,
	size = "450 550",
	move = "cursor -50% -50%",
})
