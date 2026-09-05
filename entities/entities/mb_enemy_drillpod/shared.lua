ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Enemy Drill Pod"
ENT.Author = "MilBase"
ENT.Category = "Star Wars RP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "TargetPos")

	self:NetworkVar("Float", 0, "StartTime")
	self:NetworkVar("Float", 1, "DropDuration")
	self:NetworkVar("Float", 2, "DrillDuration")
	self:NetworkVar("Float", 3, "SpawnRadius")

	self:NetworkVar("Int", 0, "MaxActive")

	self:NetworkVar("Bool", 0, "SpawnEnabled")

	self:NetworkVar("String", 0, "SpawnID")
	self:NetworkVar("String", 1, "SpawnName")
	self:NetworkVar("String", 2, "SpawnStatus")
end

function ENT:SpawnLabel()
	local name = self:GetSpawnName()
	return name ~= "" and name or "Drill Pod"
end
