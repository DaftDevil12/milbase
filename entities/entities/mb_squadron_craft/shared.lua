ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Naval Squadron Flight"
ENT.Author = "MilBase"
ENT.Category = "Star Wars RP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "SquadronID")
	self:NetworkVar("String", 1, "CraftName")
	self:NetworkVar("String", 2, "FlightMode")
	self:NetworkVar("Float", 0, "VisualScale")
	self:NetworkVar("Float", 1, "MotionSpeed")
end
