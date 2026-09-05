ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Galaxy Ship Weak Point"
ENT.Author = "MilBase"
ENT.Category = "Star Wars RP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "ParentShip")
	self:NetworkVar("String", 0, "WeakpointID")
	self:NetworkVar("String", 1, "WeakpointName")
	self:NetworkVar("Int", 0, "Integrity")
	self:NetworkVar("Int", 1, "MaxIntegrity")
	self:NetworkVar("Float", 0, "HitRadius")
	self:NetworkVar("Float", 1, "HitUntil")
	self:NetworkVar("Bool", 0, "Disabled")
end

function ENT:GetIntegrityFraction()
	return math.Clamp(self:GetIntegrity() / math.max(1, self:GetMaxIntegrity()), 0, 1)
end
