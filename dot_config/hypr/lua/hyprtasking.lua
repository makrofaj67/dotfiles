local MainMod = "SUPER"
hl.bind("SUPER + tab", function()
	hl.plugin.hyprtasking.toggle("cursor")
end)

hl.bind("SUPER + space", function()
	hl.plugin.hyprtasking.toggle("all")
end)

-- NOT: escape tuşunun hedeflediği argüman yapısına göre uyarlanmıştır
hl.bind("escape", function()
	hl.plugin.hyprtasking.if_active("hyprtasking:toggle cursor")
end)

hl.bind("SUPER + X", function()
	hl.plugin.hyprtasking.killhovered()
end)

hl.bind("SUPER + H", function()
	hl.plugin.hyprtasking.move("left")
end)

hl.bind("SUPER + J", function()
	hl.plugin.hyprtasking.move("down")
end)

hl.bind("SUPER + K", function()
	hl.plugin.hyprtasking.move("up")
end)

hl.bind("SUPER + L", function()
	hl.plugin.hyprtasking.move("right")
end)

hl.bind("SUPER + A", function()
	hl.plugin.hyprtasking.move("out")
end)

hl.bind("SUPER + SHIFT + A", function()
	hl.plugin.hyprtasking.movewindow("out")
end)

hl.bind("SUPER + CTRL + 1", function()
	hl.plugin.hyprtasking.setlayer(1)
end)

hl.bind("SUPER + CTRL + 2", function()
	hl.plugin.hyprtasking.setlayer(2)
end)


-------------------------------
---- hyprtasking plugin -------
--------------------------------
---- hyprtasking plugin -------
-------------------------------

-- Tablo düzleştirme (table flattening) hatasını aşmak için
-- değişkenleri Hyprland'in beklediği tam namespace formatında (iki nokta ile) veriyoruz:

hl.config({
	["plugin:hyprtasking:layout"] = "grid",

	["plugin:hyprtasking:gap_size"] = 20,
	["plugin:hyprtasking:bg_color"] = "0xff26233a",
	["plugin:hyprtasking:border_size"] = 4,
	["plugin:hyprtasking:exit_on_hovered"] = false,
	["plugin:hyprtasking:warp_on_move_window"] = 1,
	["plugin:hyprtasking:close_overview_on_reload"] = true,

	["plugin:hyprtasking:drag_button"] = "0x110",
	["plugin:hyprtasking:select_button"] = "0x111",

	["plugin:hyprtasking:gestures:enabled"] = true,
	["plugin:hyprtasking:gestures:move_fingers"] = 3,
	["plugin:hyprtasking:gestures:move_distance"] = 300,
	["plugin:hyprtasking:gestures:open_fingers"] = 4,
	["plugin:hyprtasking:gestures:open_distance"] = 300,
	["plugin:hyprtasking:gestures:open_positive"] = true,

	["plugin:hyprtasking:grid:rows"] = 3,
	["plugin:hyprtasking:grid:cols"] = 3,
	["plugin:hyprtasking:grid:loop"] = false,
	["plugin:hyprtasking:grid:layers"] = 2,
	["plugin:hyprtasking:grid:loop_layers"] = true,
	["plugin:hyprtasking:grid:gaps_use_aspect_ratio"] = false,

	["plugin:hyprtasking:linear:top"] = false,
	["plugin:hyprtasking:linear:height"] = 400,
	["plugin:hyprtasking:linear:scroll_speed"] = 1.0,
	["plugin:hyprtasking:linear:blur"] = false,
}) ------------------------------
