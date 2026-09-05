AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Vehicle Requisition Terminal"
ENT.Category = "MilBase"
ENT.Spawnable = true
ENT.AdminOnly = true

if SERVER then
	function ENT:Initialize()
		local model = (MilBase.Config and MilBase.Config.VehicleReqTerminalModel) or "models/lordtrilobite/starwars/isd/imp_console_medium03.mdl"
		if not util.IsValidModel(model) then model = "models/lordtrilobite/starwars/isd/imp_console_medium03.mdl" end
		if not util.IsValidModel(model) then model = "models/props_lab/monitor01b.mdl" end

		self:SetModel(model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase and MilBase.VehicleReq and MilBase.VehicleReq.OpenTerminal then
			MilBase.VehicleReq.OpenTerminal(activator, self)
		else
			MilBase.Notify(activator, "Vehicle requisition module is not loaded.")
		end
	end

	return
end

local function screenAngles(ent)
	local ang = ent:GetAngles()
	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)
	return ang
end

function ENT:Draw()
	self:DrawModel()

	local U = MilBase and MilBase.UI or {}
	local text = U.text or color_white
	local accent = U.accent or Color(255, 198, 60)
	local dim = U.dim or Color(170, 170, 170)
	local fontSmall = U.text and "MB.Small" or "DermaDefaultBold"
	local fontTiny = U.text and "MB.Tiny" or "DermaDefault"

	local pos = self:GetPos() + self:GetUp() * 18 + self:GetForward() * 4
	local ang = screenAngles(self)

	cam.Start3D2D(pos, ang, 0.08)
		surface.SetDrawColor(3, 8, 10, 238)
		surface.DrawRect(-152, -82, 304, 164)
		surface.SetDrawColor(accent.r, accent.g, accent.b, 175)
		surface.DrawOutlinedRect(-152, -82, 304, 164, 2)
		surface.DrawLine(-132, -42, 132, -42)

		local terminalName = string.upper(GetGlobalString("mb_vreq_terminal_name", "VEHICLE REQUISITION"))
		local terminalHelp = string.upper(GetGlobalString("mb_vreq_terminal_help", "SELECT VEHICLE / SPAWN / REASON"))
		draw.SimpleText(string.sub(terminalName, 1, 28), fontSmall, 0, -62, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("PRESS E TO REQUEST", fontTiny, 0, -16, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(string.sub(terminalHelp, 1, 34), fontTiny, 0, 10, dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local pulse = 90 + math.sin(CurTime() * 4) * 45
		surface.SetDrawColor(accent.r, accent.g, accent.b, pulse)
		for i = 0, 4 do surface.DrawLine(-120 + i * 60, 48, -96 + i * 60, 48) end
	cam.End3D2D()
end
