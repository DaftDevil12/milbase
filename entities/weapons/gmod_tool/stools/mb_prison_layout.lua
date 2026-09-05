TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.mb_prison_layout.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
	marker_type = "cell_origin",
	cell_id = "cell_1",
	point_name = "",
	capacity = "2",
	security = "general",
	zone = "cellblock",
	route_index = "1",
	camera_range = "1100",
	camera_fov = "78",
	cell_wizard = "1",
}

-- One guided pass creates every marker needed for a complete two-prisoner cell.
-- The order keeps each prisoner's standing, sleeping and sitting positions together.
local CELL_WIZARD = {
	"cell_origin",
	"cell_corner_a",
	"cell_corner_b",
	"cell_spawn_1",
	"cell_bed_1",
	"cell_sit_1",
	"cell_spawn_2",
	"cell_bed_2",
	"cell_sit_2",
	"cell_toilet",
	"cell_food",
	"cell_water",
	"cell_search",
	"cell_observe",
	"cell_door",
}
local CELL_WIZARD_INDEX = {}
for index, markerKind in ipairs(CELL_WIZARD) do CELL_WIZARD_INDEX[markerKind] = index end

if CLIENT then
	language.Add("tool.mb_prison_layout.name", "Prison Layout Tool")
	language.Add("tool.mb_prison_layout.desc", "Build complete two-person cells and mark prison facilities.")
	language.Add("tool.mb_prison_layout.0", "Guided cell mode: left-click places the current step and automatically advances.")
end

local function canUse(ply)
	return MilBase and MilBase.Prison and MilBase.Prison.CanConfigure and MilBase.Prison.CanConfigure(ply)
end
local function clean(value, fallback)
	if MilBase and MilBase.Prison and MilBase.Prison.CleanID then return MilBase.Prison.CleanID(value, fallback) end
	return string.lower(string.Trim(tostring(value or fallback or "")))
end
local function kind(tool) return clean(tool:GetClientInfo("marker_type"), "intake") end
local function group(tool, markerKind)
	if string.StartWith(markerKind, "cell_") then return clean(tool:GetClientInfo("cell_id"), "cell_1") end
	if string.StartWith(markerKind, "takeover_") then return "takeover" end
	return "facility"
end
local function pointName(tool, markerKind)
	local value = string.Trim(tool:GetClientInfo("point_name") or "")
	if value ~= "" then return value end
	return tostring(((MilBase.Config.Prison or {}).LayoutLabels or {})[markerKind] or markerKind)
end
local function pointData(tool, markerKind)
	local data = {
		index = math.max(1, tonumber(tool:GetClientInfo("route_index")) or 1),
		zone = clean(tool:GetClientInfo("zone"), "cellblock"),
	}
	if markerKind == "cell_origin" then
		data.capacity = math.Clamp(tonumber(tool:GetClientInfo("capacity")) or 2, 1, 2)
		data.security = clean(tool:GetClientInfo("security"), "general")
	elseif markerKind == "camera" then
		data.range = math.Clamp(tonumber(tool:GetClientInfo("camera_range")) or 1100, 300, 3000)
		data.fov = math.Clamp(tonumber(tool:GetClientInfo("camera_fov")) or 78, 30, 140)
	end
	return data
end
local function markerPosition(trace)
	return trace.HitPos + trace.HitNormal * 4
end
local function markerAngle(ply, markerKind)
	local a = ply:EyeAngles()
	return Angle(markerKind == "camera" and math.Clamp(-a.p, -60, 60) or 0, a.y + 180, 0)
end
local function linkedEntity(markerKind, trace)
	if markerKind ~= "cell_door" and markerKind ~= "route_door" and markerKind ~= "alarm" then return nil end
	if IsValid(trace.Entity) and not trace.Entity:IsWorld() and not trace.Entity:IsPlayer() then return trace.Entity end
	return nil
end
local function wizardEnabled(tool)
	return tool:GetClientNumber("cell_wizard", 1) ~= 0
end
local function nextCellID(value)
	value = clean(value, "cell_1")
	local prefix, number = string.match(value, "^(.-)(%d+)$")
	if prefix and number then return prefix .. tostring((tonumber(number) or 0) + 1) end
	return value .. "_2"
end
local function setClientConVar(ply, name, value)
	if not IsValid(ply) then return end
	value = tostring(value or "")
	-- IDs and marker names are cleaned before reaching this function.
	ply:ConCommand(name .. " " .. value)
end
local function advanceWizard(tool, ply, markerKind)
	if not wizardEnabled(tool) then return end
	local index = CELL_WIZARD_INDEX[markerKind]
	if not index then return end
	if index < #CELL_WIZARD then
		local nextKind = CELL_WIZARD[index + 1]
		setClientConVar(ply, "mb_prison_layout_marker_type", nextKind)
		local label = ((MilBase.Config.Prison or {}).LayoutLabels or {})[nextKind] or nextKind
		MilBase.Notify(ply, string.format("Cell %s: step %d/%d — place %s.", string.upper(group(tool, markerKind)), index + 1, #CELL_WIZARD, label), "info")
		return
	end
	local finished = group(tool, markerKind)
	local following = nextCellID(tool:GetClientInfo("cell_id"))
	setClientConVar(ply, "mb_prison_layout_cell_id", following)
	setClientConVar(ply, "mb_prison_layout_marker_type", CELL_WIZARD[1])
	MilBase.Notify(ply, string.format("Cell %s complete. Wizard advanced to %s, step 1/%d.", string.upper(finished), string.upper(following), #CELL_WIZARD), "ok")
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUse(ply) or not trace.Hit then return false end
	local markerKind = kind(self)
	if (markerKind == "cell_door" or markerKind == "route_door")
	and not linkedEntity(markerKind, trace) then
		MilBase.Notify(ply, "Aim directly at the map door entity to link it.", "warn")
		return false
	end
	local ok, message = MilBase.Prison.AddLayoutMarker(ply, markerKind, markerPosition(trace), markerAngle(ply, markerKind),
		group(self, markerKind), pointName(self, markerKind), pointData(self, markerKind), linkedEntity(markerKind, trace))
	if message then MilBase.Notify(ply, message, ok and "ok" or "warn") end
	if ok then advanceWizard(self, ply, markerKind) end
	return ok == true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUse(ply) or not trace.Hit then return false end
	local markerKind = kind(self)
	if (markerKind == "cell_door" or markerKind == "route_door")
	and not linkedEntity(markerKind, trace) then
		MilBase.Notify(ply, "Aim directly at the map door entity to relink it.", "warn")
		return false
	end
	local ok, message = MilBase.Prison.UpdateNearestLayout(ply, markerKind, markerPosition(trace), markerAngle(ply, markerKind),
		group(self, markerKind), pointName(self, markerKind), pointData(self, markerKind), linkedEntity(markerKind, trace))
	if message then MilBase.Notify(ply, message, ok and "ok" or "warn") end
	return ok == true
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUse(ply) then return false end
	local markerKind = kind(self)
	local pos = trace.HitPos
	if IsValid(trace.Entity) and not trace.Entity:IsWorld() then pos = trace.Entity:GetPos() end
	local ok, message = MilBase.Prison.RemoveNearestLayout(ply, markerKind, pos, group(self, markerKind))
	if message then MilBase.Notify(ply, message, ok and "ok" or "warn") end
	return ok == true
end

function TOOL:DrawToolScreen(w, h)
	if not CLIENT then return end
	local markerKind = kind(self)
	local upperKind = string.upper(markerKind)
	local wizardIndex = CELL_WIZARD_INDEX[markerKind]
	surface.SetDrawColor(8, 12, 18, 255); surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(255, 198, 60); surface.DrawOutlinedRect(5, 5, w - 10, h - 10, 2)
	draw.SimpleText("PRISON LAYOUT", "DermaLarge", w / 2, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	if wizardEnabled(self) and wizardIndex then
		draw.SimpleText("CELL WIZARD " .. wizardIndex .. "/" .. #CELL_WIZARD, "DermaDefaultBold", w / 2, 66, Color(255, 198, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		draw.SimpleText("MANUAL MARKER", "DermaDefaultBold", w / 2, 66, Color(255, 198, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	draw.SimpleText(upperKind, "DermaDefaultBold", w / 2, 94, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(string.StartWith(markerKind, "cell_") and string.upper(self:GetClientInfo("cell_id")) or "FACILITY",
		"DermaDefault", w / 2, 118, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("LMB PLACE  •  RMB UPDATE", "DermaDefaultBold", w / 2, 158, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("RELOAD REMOVE", "DermaDefaultBold", w / 2, 182, Color(235, 175, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

if CLIENT then
	local requested = false
	local function markerColor(markerKind)
		if string.StartWith(markerKind, "cell_") then return Color(80, 170, 255, 220) end
		if string.StartWith(markerKind, "takeover_") then return Color(235, 90, 75, 220) end
		if markerKind == "transfer" then return Color(130, 215, 140, 220) end
		return Color(255, 198, 60, 220)
	end
	function TOOL:DrawHUD()
		if not requested then
			requested = true
			net.Start("MilBase_Prison_LayoutRequest"); net.SendToServer()
		end
		local ply = LocalPlayer(); if not IsValid(ply) then return end
		cam.Start3D(EyePos(), EyeAngles())
		for _, row in ipairs((MilBase.Prison and MilBase.Prison.ClientLayout) or {}) do
			if row.pos and EyePos():DistToSqr(row.pos) <= ((MilBase.Config.Prison or {}).LayoutMarkerDrawDistance or 3500)^2 then
				local col = markerColor(row.kind or "")
				render.SetColorMaterial(); render.DrawWireframeBox(row.pos, row.ang or angle_zero, Vector(-10,-10,0), Vector(10,10,44), col, true)
			end
		end
		local tr = ply:GetEyeTrace()
		if tr and tr.Hit then
			local col = markerColor(kind(self)); render.SetColorMaterial()
			render.DrawWireframeBox(markerPosition(tr), markerAngle(ply, kind(self)), Vector(-12,-12,0), Vector(12,12,48), col, true)
		end
		cam.End3D()
		local markerKind = kind(self)
		local index = CELL_WIZARD_INDEX[markerKind]
		if wizardEnabled(self) and index then
			local label = ((MilBase.Config.Prison or {}).LayoutLabels or {})[markerKind] or markerKind
			draw.SimpleTextOutlined(string.format("%s — STEP %d/%d: %s", string.upper(self:GetClientInfo("cell_id")), index, #CELL_WIZARD, string.upper(label)),
				"DermaDefaultBold", ScrW() * 0.5, ScrH() * 0.76, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			if markerKind == "cell_door" then
				draw.SimpleTextOutlined("AIM DIRECTLY AT THE CELL DOOR ENTITY", "DermaDefaultBold", ScrW() * 0.5, ScrH() * 0.76 + 22,
					Color(255,198,60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			end
		end
	end
end

function TOOL.BuildCPanel(panel)
	panel:Help("Persistent Shipboard Prison Layout")
	panel:Help("Guided mode builds a complete two-person cell in one continuous sequence.")
	panel:CheckBox("Guided full-cell setup", "mb_prison_layout_cell_wizard")
	panel:TextEntry("Cell ID", "mb_prison_layout_cell_id")
	panel:TextEntry("Prison zone", "mb_prison_layout_zone")
	panel:NumSlider("Cell capacity (maximum 2)", "mb_prison_layout_capacity", 1, 2, 0)
	local security = panel:ComboBox("Cell security", "mb_prison_layout_security")
	security:AddChoice("General population", "general")
	security:AddChoice("High security", "high")
	security:AddChoice("Isolation", "isolation")
	security:AddChoice("Medical observation", "medical")
	security:AddChoice("Protective custody", "protective")
	local startWizard = panel:Button("START / RESET CURRENT CELL")
	startWizard.DoClick = function()
		RunConsoleCommand("mb_prison_layout_cell_wizard", "1")
		RunConsoleCommand("mb_prison_layout_marker_type", "cell_origin")
	end
	panel:Help("Left-click each prompted position. After the linked door is placed, the tool automatically starts the next numbered cell.")
	panel:Help("Cell sequence: centre, volume corners, prisoner 1 position/bed/seat, prisoner 2 position/bed/seat, toilet, food, water, search, observation and linked door.")

	local combo = panel:ComboBox("Manual marker type", "mb_prison_layout_marker_type")
	for _, markerKind in ipairs((MilBase.Config.Prison or {}).LayoutKinds or {}) do
		combo:AddChoice(((MilBase.Config.Prison or {}).LayoutLabels or {})[markerKind] or markerKind, markerKind)
	end
	panel:TextEntry("Custom label", "mb_prison_layout_point_name")
	panel:NumSlider("Route / objective order", "mb_prison_layout_route_index", 1, 32, 0)
	panel:NumSlider("Camera range", "mb_prison_layout_camera_range", 300, 3000, 0)
	panel:NumSlider("Camera field of view", "mb_prison_layout_camera_fov", 30, 140, 0)
	panel:Help("Disable guided mode to place individual facility or cell markers manually.")
	panel:Help("PATH NODE markers provide corner and stair routing on maps without a navigation mesh.")
	panel:Help("ROUTE DOOR links locked corridor doors that prisoners are authorised to open while moving.")
	panel:Help("TAKEOVER markers define the armory, engineering, communications and bridge objectives.")
	panel:Help("TRANSFER LAAT marks the landed aircraft. TRANSFER BOARDING marks its ramp entrance.")
	panel:Help("CAMERA markers face away from the wall you aim at and use the configured range and field of view.")
	panel:Help("Aim directly at the map door when placing or updating CELL DOOR.")
	panel:Help("Aim directly at a usable map panel when placing ALARM to link a physical alarm toggle.")
end
