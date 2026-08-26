------------------
---- MONITORS ----
------------------

-- 1. DRM / Sysfs üzerinden HDMI bağlantısını anında ve kilitsiz (zero-deadlock) sorgula
local function is_hdmi_plugged()
	local f = io.open("/sys/class/drm/card1-HDMI-A-1/status", "r")
		or io.open("/sys/class/drm/card0-HDMI-A-1/status", "r")
		or io.open("/sys/class/drm/card2-HDMI-A-1/status", "r")
	if f then
		local status = f:read("*l")
		f:close()
		return status == "connected"
	end
	return false
end

local has_hdmi = is_hdmi_plugged()

-- 2. Duruma göre tek blokta yapılandır
if has_hdmi then
	-- HDMI Bağlı: HDMI Ana Ekran (0x0), Laptop Sağ Yan Ekran (1920x0)
	hl.monitor({
		output = "HDMI-A-1",
		mode = "1920x1080@100",
		position = "0x0",
		scale = "1",
	})
	hl.monitor({
		output = "eDP-1",
		mode = "1920x1080@120",
		position = "1920x0",
		scale = "1",
	})
else
	-- Sadece Laptop: eDP-1 Ana Ekran (0x0)
	hl.monitor({
		output = "eDP-1",
		mode = "1920x1080@120",
		position = "0x0",
		scale = "1",
	})
end

-- Bilinmeyen/Harici diğer ekranlar için genel kural
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1",
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- Cursor Theming
hl.env("XCURSOR_THEME", "Bibata-Modern-Amber")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Amber")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Multi-GPU (AMD iGPU Primary + NVIDIA dGPU Secondary for HDMI)
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- XDG Specifications
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkit Backends & Wayland Native Flags
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_STYLE_OVERRIDE", "Darkly")

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- XWayland Zero Scaling
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})
