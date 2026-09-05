ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "CG Trained Massif"
ENT.Author = "MilBase"
ENT.Category = "Star Wars RP"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true -- player activities still need scripted-entity frame advancement

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Handler")
	self:NetworkVar("Entity", 1, "MarkedTarget")
	self:NetworkVar("String", 0, "MassifName")
	self:NetworkVar("String", 1, "CommandState")
	self:NetworkVar("Bool", 0, "Controlled")
	self:NetworkVar("Bool", 1, "Incapacitated")
	self:NetworkVar("Int", 0, "MassifHealth")
	self:NetworkVar("Int", 1, "MassifMaxHealth")
	self:NetworkVar("Float", 0, "PossessionEnds")
	self:NetworkVar("Float", 1, "ScentPulseEnds")
	self:NetworkVar("Vector", 0, "GuardPosition")
end
