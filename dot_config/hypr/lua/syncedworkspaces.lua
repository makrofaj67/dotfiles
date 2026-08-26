local M = {}

M.current_vdesk = 1

-- 1. DRM Sysfs check for HDMI connectivity (card0, card1, card2)
function M.is_dual_monitor()
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

local is_syncing = false

-- 2. Switch both monitors synchronously to Virtual Desktop V (1..9)
function M.switch_vdesk(vdeskId)
	local v = tonumber(vdeskId) or 1
	M.current_vdesk = v
	if M.is_dual_monitor() then
		local hdmi_ws = v
		local edp_ws = 10 + v

		is_syncing = true
		-- Focus laptop workspace first (eDP-1 switches to 10+V)
		hl.dispatch(hl.dsp.focus({ workspace = edp_ws }))
		-- Focus HDMI workspace next (HDMI switches to V and gains active focus)
		hl.dispatch(hl.dsp.focus({ workspace = hdmi_ws }))
		is_syncing = false
	else
		-- Single screen: standard workspace V
		hl.dispatch(hl.dsp.focus({ workspace = v }))
	end
end

-- 3. Cycle Virtual Desktops (Next / Previous)
function M.cycle_vdesk(step)
	local cur = M.current_vdesk or 1
	local next_v = cur + step
	if next_v < 1 then next_v = 9 end
	if next_v > 9 then next_v = 1 end
	M.switch_vdesk(next_v)
end

-- 4. Focus specific window and ensure its entire Virtual Desktop is active
function M.focus_window_and_vdesk(address, wsId)
	local w = tonumber(wsId) or 1
	if M.is_dual_monitor() then
		local v = (w > 10) and (w - 10) or w
		M.switch_vdesk(v)
	else
		hl.dispatch(hl.dsp.focus({ workspace = w }))
	end
	hl.dispatch(hl.dsp.focus({ window = "address:" .. tostring(address) }))
end

-- 5. Move active window to Virtual Desktop V
function M.move_to_vdesk(vdeskId)
	local v = tonumber(vdeskId) or 1
	if M.is_dual_monitor() then
		local mon = hl.get_focused_monitor and hl.get_focused_monitor() or nil
		local is_edp = false
		if mon and mon.name == "eDP-1" then
			is_edp = true
		end

		if is_edp then
			hl.dispatch(hl.dsp.window.move({ workspace = 10 + v }))
		else
			hl.dispatch(hl.dsp.window.move({ workspace = v }))
		end
	else
		hl.dispatch(hl.dsp.window.move({ workspace = v }))
	end
end

-- 6. Auto-sync on workspace switch events
hl.on("workspace.active", function(data)
	if is_syncing or not M.is_dual_monitor() then return end
	local wsId = nil
	if type(data) == "table" then
		wsId = tonumber(data.id or data.name or (data.workspace and data.workspace.id))
	elseif type(data) == "number" or type(data) == "string" then
		wsId = tonumber(data)
	end

	if not wsId or wsId <= 0 or wsId > 20 then return end

	local target_v = (wsId > 10) and (wsId - 10) or wsId
	M.current_vdesk = target_v
	local hdmi_ws = target_v
	local edp_ws = 10 + target_v

	is_syncing = true
	if wsId > 10 then
		hl.dispatch(hl.dsp.focus({ workspace = hdmi_ws }))
		hl.dispatch(hl.dsp.focus({ workspace = wsId }))
	else
		hl.dispatch(hl.dsp.focus({ workspace = edp_ws }))
		hl.dispatch(hl.dsp.focus({ workspace = wsId }))
	end
	is_syncing = false
end)

return M
