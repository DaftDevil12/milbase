AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Arrest Terminal"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true

if SERVER then
	function ENT:Initialize()
		local cfg = MilBase.Config or {}
		local model = cfg.JailArrestTerminalModel or "models/lordtrilobite/starwars/isd/imp_console_large01.mdl"
		if not util.IsValidModel(model) then model = cfg.JailTerminalFallbackModel or "models/lordtrilobite/starwars/isd/imp_console_large01.mdl" end
		if not util.IsValidModel(model) then model = "models/props_lab/monitor01b.mdl" end

		self:SetModel(model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase and MilBase.JailOpenArrestTerminal then
			MilBase.JailOpenArrestTerminal(activator, self)
		else
			MilBase.Notify(activator, "Jail module is not loaded.")
		end
	end

	return
end

function ENT:Draw()
	self:DrawModel()

	local ui = MilBase and MilBase.UI
	local accent = ui and ui.warn or Color(255, 198, 60)
	local text = ui and ui.text or color_white
	local dim = ui and ui.dim or Color(180, 180, 180)
	local fontTitle = ui and "MB.Small" or "DermaDefaultBold"
	local fontTiny = ui and "MB.Tiny" or "DermaDefault"
	local name = self.MBJailName or "ARREST TERMINAL"

	local pos = self:WorldSpaceCenter() + Vector(0, 0, 42)
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

	cam.Start3D2D(pos, ang, 0.075)
		surface.SetFont(fontTitle)
		local tw = surface.GetTextSize(name)
		local w = math.max(190, tw + 30)
		surface.SetDrawColor(0, 0, 0, 190)
		surface.DrawRect(-w / 2, -25, w, 50)
		surface.SetDrawColor(accent.r, accent.g, accent.b, 175)
		surface.DrawOutlinedRect(-w / 2, -25, w, 50, 1)
		draw.SimpleText(string.upper(name), fontTitle, 0, -7, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("PRESS E: PROCESS CHARGES", fontTiny, 0, 12, dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
