AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local FALLBACK_MODEL = "models/hunter/blocks/cube025x025x025.mdl"

function ENT:Initialize()
	self:SetModel(FALLBACK_MODEL)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:DrawShadow(false)
	self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
	if self:GetWeakpointID() == "" then self:SetWeakpointID("subsystem") end
	if self:GetWeakpointName() == "" then self:SetWeakpointName("SUBSYSTEM") end
	if self:GetMaxIntegrity() <= 0 then self:SetMaxIntegrity(500) end
	if self:GetIntegrity() <= 0 then self:SetIntegrity(self:GetMaxIntegrity()) end
	local radius = math.max(10, self:GetHitRadius())
	self:SetHitRadius(radius)
	self:SetCollisionBounds(Vector(-radius, -radius, -radius),
		Vector(radius, radius, radius))
	self:SetModelScale(math.Clamp(radius / 12, 0.45, 5), 0)
end

function ENT:ApplyWeakpointDamage(dmg)
	if self:GetDisabled() then return end
	local ship = self:GetParentShip()
	if not IsValid(ship) or ship:GetClass() ~= "mb_galaxy_ship" then
		self:Remove()
		return
	end
	local amount = math.max(0, dmg:GetDamage())
	if amount <= 0 then return end
	local G = MilBase and MilBase.Galaxy
	if ship:GetShield() > 0 and G and G.DamageShipShield then
		local hitPosition = dmg:GetDamagePosition()
		if not isvector(hitPosition) or hitPosition == vector_origin then
			hitPosition = self:WorldSpaceCenter()
		end
		G.DamageShipShield(ship, amount, dmg:GetAttacker(), hitPosition)
		return
	end
	if ship:GetShield() > 0 then return end

	self:SetIntegrity(math.max(0, self:GetIntegrity() - math.ceil(amount)))
	self:SetHitUntil(CurTime() + 0.22)
	if G and G.EmitImpact then G.EmitImpact(self:WorldSpaceCenter()) end
	if self:GetIntegrity() > 0 then return end

	self:SetDisabled(true)
	self:SetSolid(SOLID_NONE)
	if G and G.OnGalaxyWeakpointDestroyed then
		G.OnGalaxyWeakpointDestroyed(ship, self,
			IsValid(dmg:GetAttacker()) and dmg:GetAttacker() or game.GetWorld())
	end
end

function ENT:OnTakeDamage(dmg)
	self:ApplyWeakpointDamage(dmg)
end

function ENT:OnRemove()
	local ship = self:GetParentShip()
	if IsValid(ship) and ship.mb_galaxyWeakpoints then
		for index = #ship.mb_galaxyWeakpoints, 1, -1 do
			if ship.mb_galaxyWeakpoints[index] == self then
				table.remove(ship.mb_galaxyWeakpoints, index)
			end
		end
	end
end
