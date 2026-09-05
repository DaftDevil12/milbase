ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Galaxy Director Ship"
ENT.Author = "MilBase"
ENT.Category = "Star Wars RP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "ShipName")
	self:NetworkVar("String", 1, "Faction")
	self:NetworkVar("String", 2, "Role")
	self:NetworkVar("String", 3, "EncounterID")
	self:NetworkVar("String", 4, "ShipState")
	self:NetworkVar("String", 5, "SizeClass")

	self:NetworkVar("Vector", 0, "FlightVelocity")
	self:NetworkVar("Vector", 1, "ShieldHitPosition")

	self:NetworkVar("Float", 0, "DieAt")
	self:NetworkVar("Float", 1, "ModelSize")
	self:NetworkVar("Float", 2, "ShieldHitUntil")
	self:NetworkVar("Float", 3, "CombatRadius")
	self:NetworkVar("Float", 4, "MotionSpeed")

	self:NetworkVar("Int", 0, "Hull")
	self:NetworkVar("Int", 1, "MaxHull")
	self:NetworkVar("Int", 2, "Shield")
	self:NetworkVar("Int", 3, "MaxShield")

	self:NetworkVar("Bool", 0, "Hostile")
	self:NetworkVar("Bool", 1, "Capital")
	self:NetworkVar("Bool", 2, "Combat")
	self:NetworkVar("Bool", 3, "Invulnerable")
	self:NetworkVar("Bool", 4, "CombatReady")
end

function ENT:GetHullFraction()
	local maxHull = math.max(self:GetMaxHull(), 1)
	return math.Clamp(self:GetHull() / maxHull, 0, 1)
end

function ENT:GetShieldFraction()
	local maximum = math.max(self:GetMaxShield(), 1)
	return math.Clamp(self:GetShield() / maximum, 0, 1)
end
