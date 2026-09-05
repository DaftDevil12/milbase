TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.mb_jail.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
	point_type = "cell",
	point_name = "Prison Cell",
}

if CLIENT then
	language.Add("tool.mb_jail.name", "Jail System")
	language.Add("tool.mb_jail.desc", "Place prison cells, arrest terminals, and records terminals.")
	language.Add("tool.mb_jail.0", "Left-click adds. Right-click updates nearest matching point. Reload removes nearest matching point.")
end

local function canUseTool(ply)
	if game.SinglePlayer() then return true end
	if not IsValid(ply) then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
	return MilBase and MilBase.JailCanConfigure and MilBase.JailCanConfigure(ply)
end

local function cleanType(t)
	t = string.lower(tostring(t or "cell"))
	if t == "arrest" or t == "records" then return t end
	return "cell"
end

local function pointPos(trace)
	return trace.HitPos + trace.HitNormal * 6
end

local function pointAng(ply)
	local a = ply:EyeAngles()
	return Angle(0, a.y + 180, 0)
end

local function pointName(tool, kind)
	local name = string.Trim(tool:GetClientInfo("point_name") or "")
	if name ~= "" then return name end
	if kind == "arrest" then return "Arrest Terminal" end
	if kind == "records" then return "Records Terminal" end
	return "Prison Cell"
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	local kind = cleanType(self:GetClientInfo("point_type"))
	return MilBase.JailAddPoint(ply, kind, pointPos(trace), pointAng(ply), pointName(self, kind)) == true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	local kind = cleanType(self:GetClientInfo("point_type"))
	return MilBase.JailUpdateNearest(ply, kind, pointPos(trace), pointAng(ply), pointName(self, kind)) == true
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end
	local kind = cleanType(self:GetClientInfo("point_type"))
	local pos = trace.HitPos
	if IsValid(trace.Entity) then pos = trace.Entity:GetPos() end
	return MilBase.JailRemoveNearest(ply, kind, pos, 360) == true
end

function TOOL:DrawToolScreen(w, h)
	if not CLIENT then return end
	local kind = string.upper(cleanType(self:GetClientInfo("point_type")))
	surface.SetDrawColor(18, 18, 20, 255)
	surface.DrawRect(0, 0, w, h)
	draw.SimpleText("JAIL", "DermaLarge", w / 2, 46, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(kind, "DermaLarge", w / 2, 82, Color(255, 198, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("LMB add", "DermaDefaultBold", w / 2, 132, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("RMB update", "DermaDefaultBold", w / 2, 156, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("R remove", "DermaDefaultBold", w / 2, 180, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

if CLIENT then
	local function drawMarker(pos, kind)
		local col = kind == "cell" and Color(80, 180, 255, 230)
			or (kind == "records" and Color(120, 220, 140, 230) or Color(255, 198, 60, 230))
		render.SetColorMaterial()
		render.DrawWireframeBox(pos, angle_zero, Vector(-18, -18, 0), Vector(18, 18, kind == "cell" and 72 or 48), col, true)
	end

	function TOOL:DrawHUD()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local tr = ply:GetEyeTrace()
		if not tr or not tr.Hit then return end
		cam.Start3D(EyePos(), EyeAngles())
			drawMarker(pointPos(tr), cleanType(self:GetClientInfo("point_type")))
		cam.End3D()
	end
end

function TOOL.BuildCPanel(panel)
	panel:Help("Jail System")
	panel:Help("Use this tool to define prison cells and place persistent terminals.")
	panel:TextEntry("Point name", "mb_jail_point_name")

	local combo = vgui.Create("DComboBox")
	combo:SetValue("Prison Cell")
	combo:AddChoice("Prison Cell", "cell")
	combo:AddChoice("Arrest Terminal", "arrest")
	combo:AddChoice("Records Terminal", "records")
	combo.OnSelect = function(_, _, _, data)
		RunConsoleCommand("mb_jail_point_type", tostring(data or "cell"))
		local curName = GetConVar("mb_jail_point_name") and GetConVar("mb_jail_point_name"):GetString() or ""
		if string.Trim(curName) == "" or curName == "Prison Cell" or curName == "Arrest Terminal" or curName == "Records Terminal" then
			local label = data == "arrest" and "Arrest Terminal" or (data == "records" and "Records Terminal" or "Prison Cell")
			RunConsoleCommand("mb_jail_point_name", label)
		end
	end
	panel:AddItem(combo)

	panel:Help("Left-click: add the selected point type. Right-click: update nearest matching point. Reload: remove nearest matching point.")
	panel:Help("Arrests require a cuffed target near an Arrest Terminal. Jailed players are sent to one of the Prison Cell points.")
end
