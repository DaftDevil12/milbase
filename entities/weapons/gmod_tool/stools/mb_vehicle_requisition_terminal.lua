TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.mb_vehicle_requisition_terminal.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
	terminal_name = "Vehicle Requisition Console",
	active = "1",
}

if CLIENT then
	language.Add("tool.mb_vehicle_requisition_terminal.name", "Vehicle Requisition Console")
	language.Add("tool.mb_vehicle_requisition_terminal.desc", "Place persistent Vehicle Requisition consoles.")
	language.Add("tool.mb_vehicle_requisition_terminal.0", "Left-click adds a console. Right-click updates the nearest console. Reload removes the nearest console.")
end

local function trim(s)
	return string.Trim(tostring(s or ""))
end

local function canUseTool(ply)
	if game.SinglePlayer() then return true end
	if not IsValid(ply) then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
	return MilBase and MilBase.VehicleReq and MilBase.VehicleReq.CanStaffConfigure and MilBase.VehicleReq.CanStaffConfigure(ply)
end

local function opts(tool)
	return {
		name = trim(tool:GetClientInfo("terminal_name")) ~= "" and tool:GetClientInfo("terminal_name") or "Vehicle Requisition Console",
		active = tool:GetClientNumber("active") > 0,
	}
end

local function consolePos(trace)
	return trace.HitPos + trace.HitNormal * 2
end

local function consoleAng(ply)
	local a = ply:EyeAngles()
	return Angle(0, a.y + 180, 0)
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	return MilBase.VehicleReq.AddTerminal(ply, consolePos(trace), consoleAng(ply), opts(self)) == true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	return MilBase.VehicleReq.UpdateNearestTerminal(ply, consolePos(trace), consoleAng(ply), opts(self)) == true
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end
	local pos = trace.HitPos
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "mb_vehicle_requisition_terminal" then pos = trace.Entity:GetPos() end
	return MilBase.VehicleReq.RemoveNearestTerminal(ply, pos, 300) == true
end

function TOOL:DrawToolScreen(w, h)
	if not CLIENT then return end
	surface.SetDrawColor(18, 24, 32, 255)
	surface.DrawRect(0, 0, w, h)
	draw.SimpleText("VEHICLE", "DermaLarge", w / 2, 38, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("REQ CONSOLE", "DermaLarge", w / 2, 72, Color(255, 198, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("LMB add", "DermaDefaultBold", w / 2, 126, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("RMB update", "DermaDefaultBold", w / 2, 150, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("R reload remove", "DermaDefaultBold", w / 2, 174, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("Saved per-map", "DermaDefault", w / 2, 206, Color(255, 218, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function TOOL.BuildCPanel(panel)
	panel:Help("Place persistent Vehicle Requisition consoles. Consoles save to the current map and respawn after restart/cleanup.")
	panel:TextEntry("Console name", "mb_vehicle_requisition_terminal_terminal_name")
	panel:CheckBox("Active", "mb_vehicle_requisition_terminal_active")
	panel:Help("Left-click: add. Right-click: update nearest. Reload: delete nearest.")
end
