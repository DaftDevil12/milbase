AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Quartermaster"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

if SERVER then
	function ENT:Initialize()
		local cfg = MilBase.Config or {}
		local model = cfg.QuartermasterNPCModel or "models/Humans/Group03/male_07.mdl"
		if not util.IsValidModel(model) then
			model = cfg.QuartermasterNPCFallbackModel or "models/Humans/Group03/male_07.mdl"
		end
		if not util.IsValidModel(model) then model = "models/Humans/Group03/male_07.mdl" end

		self:SetModel(model)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
		self:SetUseType(SIMPLE_USE)
		self:DropToFloor()

		local seq = self:LookupSequence("idle_all_01")
		if seq < 0 then seq = self:LookupSequence("idle") end
		if seq >= 0 then self:ResetSequence(seq) end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase and MilBase.QuartermasterClaim then
			MilBase.QuartermasterClaim(activator, self)
		else
			MilBase.Notify(activator, "Quartermaster module is not loaded.")
		end
	end

	return
end

function ENT:Draw()
	self:DrawModel()

	local ui = MilBase and MilBase.UI
	local accent = ui and ui.accent or Color(80, 190, 255)
	local text = ui and ui.text or color_white
	local dim = ui and ui.dim or Color(180, 180, 180)
	local fontTitle = ui and "MB.Small" or "DermaDefaultBold"
	local fontTiny = ui and "MB.Tiny" or "DermaDefault"

	local pos = self:GetPos() + Vector(0, 0, 84)
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

	cam.Start3D2D(pos, ang, 0.08)
		surface.SetFont(fontTitle)
		local tw = surface.GetTextSize("QUARTERMASTER")
		local w = math.max(170, tw + 28)

		surface.SetDrawColor(0, 0, 0, 185)
		surface.DrawRect(-w / 2, -24, w, 48)
		surface.SetDrawColor(accent.r, accent.g, accent.b, 165)
		surface.DrawOutlinedRect(-w / 2, -24, w, 48, 1)
		draw.SimpleText("QUARTERMASTER", fontTitle, 0, -6, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("PRESS E: BASIC GEAR", fontTiny, 0, 12, dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
