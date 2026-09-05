AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Inspection Cargo"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "CaseID")
	self:NetworkVar("String", 1, "CargoLabel")
	self:NetworkVar("Int", 0, "CargoIndex")
	self:NetworkVar("Bool", 0, "Searched")
	self:NetworkVar("Bool", 1, "Seized")
end

if SERVER then
	function ENT:Initialize()
		if not util.IsValidModel(self:GetModel()) then
			self:SetModel("models/props_junk/wood_crate001a.mdl")
		end
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Inspections and MilBase.Inspections.OpenDatapad then
			MilBase.Inspections.OpenDatapad(activator, self:GetCaseID(), "cargo", self:GetCargoIndex())
		end
	end
	return
end

function ENT:Draw()
	self:DrawModel()
	local ui = MilBase.UI
	local accent = self:GetSeized() and Color(235, 175, 70)
		or self:GetSearched() and Color(90, 210, 135)
		or (ui and ui.accent or Color(80, 160, 240))
	local text = ui and ui.text or color_white
	local pos = self:WorldSpaceCenter() + Vector(0, 0, 30)
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
	cam.Start3D2D(pos, ang, 0.065)
		surface.SetDrawColor(3, 9, 16, 215)
		surface.DrawRect(-118, -23, 236, 46)
		surface.SetDrawColor(accent)
		surface.DrawOutlinedRect(-118, -23, 236, 46, 1)
		draw.SimpleText(string.upper(self:GetCargoLabel()), ui and "MB.Tiny" or "DermaDefaultBold",
			0, -3, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(self:GetSeized() and "SEIZED" or self:GetSearched() and "SEARCHED" or "PRESS E: INSPECT",
			ui and "MB.Tiny" or "DermaDefault", 0, 13, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
