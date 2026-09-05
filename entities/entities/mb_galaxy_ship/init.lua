AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local FALLBACK_MODEL = "models/hunter/blocks/cube2x2x2.mdl"

local function explosion(pos, scale)
	local fx = EffectData()
	fx:SetOrigin(pos)
	fx:SetScale(scale or 1)
	fx:SetMagnitude(scale or 1)
	util.Effect("Explosion", fx, true, true)
	util.Effect("HelicopterMegaBomb", fx, true, true)
end

-- Galaxy contacts live in the SWU 3D skybox, which may sit outside a player's
-- normal map PVS. Always transmit these lightweight actors so a ship cannot
-- hail the crew while its physical model is invisible to them.
function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:RefreshCombatCollision(useModelCollision)
	local mins, maxs = self:GetModelRenderBounds()
	local scale = math.max(0.005, tonumber(self:GetModelSize()) or 0.1)
	if isvector(mins) and isvector(maxs) then
		self:SetCollisionBounds(mins * scale, maxs * scale)
	end

	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_OBB)
	self.mb_usingModelCollision = false
	self:SetNW2Bool("MBGalaxyModelCollision", false)
	if not useModelCollision then return false end

	self:SetModelScale(scale, 0.000001)
	self:PhysicsInit(SOLID_VPHYSICS)
	local physics = self:GetPhysicsObject()
	if not IsValid(physics) then
		self:SetSolid(SOLID_OBB)
		return false
	end
	local config = MilBase and MilBase.Config and MilBase.Config.GalaxyDirector or {}
	local ok, convexes = pcall(physics.GetMeshConvexes, physics)
	if ok and istable(convexes) then
		local vertices = 0
		for _, convex in ipairs(convexes) do
			vertices = vertices + (istable(convex) and #convex or 0)
		end
		if #convexes > math.max(1, tonumber(config.CISMaximumCollisionConvexes) or 64)
		or vertices > math.max(100, tonumber(config.CISMaximumCollisionVertices) or 4000) then
			self:PhysicsDestroy()
			self:SetSolid(SOLID_OBB)
			return false
		end
	end
	self:Activate()
	physics = self:GetPhysicsObject()
	if not IsValid(physics) then
		self:PhysicsDestroy()
		self:SetSolid(SOLID_OBB)
		return false
	end
	physics:EnableMotion(false)
	physics:EnableGravity(false)
	physics:EnableCollisions(true)
	physics:Sleep()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self.mb_usingModelCollision = true
	self:SetNW2Bool("MBGalaxyModelCollision", true)
	return true
end

function ENT:Initialize()
	if not util.IsValidModel(self:GetModel()) then self:SetModel(FALLBACK_MODEL) end

	self:SetMoveType(MOVETYPE_NONE)
	-- Hostile ships upgrade to their model collision mesh after their final
	-- scale is applied. OBB remains a reliable fallback for Workshop models
	-- that do not include a usable physics mesh.
	self:SetSolid(SOLID_OBB)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:DrawShadow(false)
	self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)

	if self:GetShipName() == "" then self:SetShipName("Unknown Contact") end
	if self:GetFaction() == "" then self:SetFaction("neutral") end
	if self:GetRole() == "" then self:SetRole("ambient") end
	if self:GetSizeClass() == "" then self:SetSizeClass("light") end
	if self:GetShipState() == "" then self:SetShipState("cruising") end
	if self:GetModelSize() <= 0 then self:SetModelSize(0.1) end
	if self:GetMaxHull() <= 0 then self:SetMaxHull(1000) end
	if self:GetHull() <= 0 then self:SetHull(self:GetMaxHull()) end
	if self:GetMaxShield() <= 0 then
		self:SetMaxShield(0)
		self:SetShield(0)
	end

	self:SetModelScale(self:GetModelSize(), 0)
	self:RefreshCombatCollision(false)
	if self:GetCombatRadius() <= 0 then
		self:SetCombatRadius(math.max(20,
			self:BoundingRadius() * math.max(self:GetModelSize(), 0.01)))
	end
	self.mb_lastThink = CurTime()
	self.mb_nextShot = CurTime() + math.Rand(1.5, 3)
end

function ENT:SetCombatTarget(target, damage, interval)
	self.mb_combatTarget = target
	self.mb_combatDamage = math.max(0, tonumber(damage) or 0)
	self.mb_combatInterval = math.max(0.5, tonumber(interval) or 4)
	self:SetCombat(IsValid(target))
end

function ENT:ClearCombatTarget()
	self.mb_combatTarget = nil
	self:SetCombat(false)
end

function ENT:DestroyShip(attacker)
	if self.mb_destroyed then return end
	self.mb_destroyed = true
	self:SetShipState("destroyed")
	self:SetHull(0)
	self:SetFlightVelocity(vector_origin)

	local sizeClass = string.lower(self:GetSizeClass() or "")
	local scale = self:GetCapital() and 2.5
		or sizeClass == "fighter" and 0.48
		or sizeClass == "shuttle" and 0.72
		or sizeClass == "light" and 0.95
		or 1.2
	explosion(self:WorldSpaceCenter(), scale)
	local burstCount = self:GetCapital() and 6
		or sizeClass == "fighter" and 1
		or sizeClass == "shuttle" and 2
		or 3
	for i = 1, burstCount do
		timer.Simple(i * 0.16, function()
			if not IsValid(self) then return end
			local radius = math.max(self:GetCombatRadius(),
				self:BoundingRadius() * math.max(self:GetModelSize(), 0.05))
			explosion(self:WorldSpaceCenter() + VectorRand() * radius, math.Rand(0.5, 1.4))
		end)
	end

	if MilBase and MilBase.Galaxy and MilBase.Galaxy.OnShipDestroyed then
		MilBase.Galaxy.OnShipDestroyed(self, attacker)
	end

	SafeRemoveEntityDelayed(self, 1.4)
end

function ENT:OnTakeDamage(dmg)
	if self:GetInvulnerable() or self.mb_destroyed then return end
	local amount = math.max(0, dmg:GetDamage())
	if amount <= 0 then return end
	if MilBase and MilBase.Galaxy and MilBase.Galaxy.HandleGalaxyShipDamage
	then
		local handled, hullDamage = MilBase.Galaxy.HandleGalaxyShipDamage(self, dmg)
		if handled then return end
		amount = math.max(0, tonumber(hullDamage) or amount)
		if amount <= 0 then return end
	end

	self:SetHull(math.max(0, self:GetHull() - math.ceil(amount)))
	if MilBase and MilBase.Galaxy and MilBase.Galaxy.OnGalaxyHullDamaged then
		MilBase.Galaxy.OnGalaxyHullDamaged(self, dmg)
	end
	if MilBase and MilBase.Galaxy and MilBase.Galaxy.EmitImpact then
		local hitPosition = dmg:GetDamagePosition()
		if not isvector(hitPosition) or hitPosition == vector_origin then
			hitPosition = self:WorldSpaceCenter()
		end
		MilBase.Galaxy.EmitImpact(self:NearestPoint(hitPosition))
	end

	if self:GetHull() <= 0 then
		self:DestroyShip(IsValid(dmg:GetAttacker()) and dmg:GetAttacker() or game.GetWorld())
	end
end

function ENT:Think()
	local now = CurTime()
	local dt = math.Clamp(now - (self.mb_lastThink or now), 0, 0.2)
	self.mb_lastThink = now
	if MilBase and MilBase.Galaxy and MilBase.Galaxy.UpdateShipDefense then
		MilBase.Galaxy.UpdateShipDefense(self, now, dt)
	end
	if MilBase and MilBase.Galaxy and MilBase.Galaxy.UpdateShipDamageEffects then
		MilBase.Galaxy.UpdateShipDamageEffects(self, now)
	end

	if not self.mb_galaxyPilotControlled then
		if MilBase and MilBase.Galaxy and MilBase.Galaxy.EnsureAutonomousShipMotion then
			MilBase.Galaxy.EnsureAutonomousShipMotion(self, now)
		end
		if MilBase and MilBase.Galaxy and MilBase.Galaxy.UpdateShipFlightRoute then
			MilBase.Galaxy.UpdateShipFlightRoute(self)
		end
	end
	local velocity = self:GetFlightVelocity()
	local transformed = not self.mb_galaxyMapSpace
		and MilBase and MilBase.Galaxy
		and MilBase.Galaxy.UpdateShipSWUTransform
		and MilBase.Galaxy.UpdateShipSWUTransform(self, velocity, dt)
	if not transformed and MilBase and MilBase.Galaxy
	and MilBase.Galaxy.UpdateShipLocalTransform then
		transformed = MilBase.Galaxy.UpdateShipLocalTransform(self, velocity, dt)
	end
	if not transformed and velocity:LengthSqr() > 0 then
		self:SetPos(self:GetPos() + velocity * dt)
	end
	if now >= (self.mb_nextMotionSpeedNetworkAt or 0) then
		self.mb_nextMotionSpeedNetworkAt = now + 0.15
		local actualVelocity = self.mb_galaxyActualWorldVelocity
		local motionSpeed = isvector(actualVelocity)
			and actualVelocity:Length() or velocity:Length()
		if math.abs(self:GetMotionSpeed() - motionSpeed) >= 0.5 then
			self:SetMotionSpeed(motionSpeed)
		end
	end

	if self:GetDieAt() > 0 and now >= self:GetDieAt() then
		self:Remove()
		return
	end

	local target = self.mb_combatTarget
	local combatReady = not self.mb_galaxyCombatPrepared or self:GetCombatReady()
	local ionDisabled = (self.mb_galaxyIonDisabledUntil or 0) > now
	if self.mb_galaxyIonDisabledUntil and not ionDisabled then
		self.mb_galaxyIonDisabledUntil = nil
		if self:GetShipState() == "ion systems disrupted" then
			self:SetShipState(self:GetCombat() and "attacking" or "cruising")
		end
	end
	if self:GetCombat() and combatReady and not ionDisabled and IsValid(target)
	and now >= (self.mb_nextShot or 0) then
		self.mb_nextShot = now + (self.mb_combatInterval or 4)
			* math.max(1, tonumber(self.mb_galaxyWeaponIntervalMultiplier) or 1)
			* math.Rand(0.8, 1.2)
		if MilBase and MilBase.Galaxy and MilBase.Galaxy.ShipFire then
			MilBase.Galaxy.ShipFire(self, target, self.mb_combatDamage or 0)
		end
	elseif self:GetCombat() and not IsValid(target) then
		self:ClearCombatTarget()
	end

	local config = MilBase and MilBase.Config
		and MilBase.Config.GalaxyDirector or {}
	local playerShipMoving = MilBase and MilBase.Galaxy
		and MilBase.Galaxy.PlayerShipIsMoving
		and MilBase.Galaxy.PlayerShipIsMoving() or false
	local actualMoving = isvector(self.mb_galaxyActualWorldVelocity)
		and self.mb_galaxyActualWorldVelocity:LengthSqr() > 0.001
	local interval
	if self:GetCombat() or self.mb_galaxyCombatIngress or self.mb_galaxyMapSpace then
		interval = math.max(0.015,
			tonumber(config.GalaxyShipCombatThinkInterval) or 0.03)
	elseif velocity:LengthSqr() > 0.001 or actualMoving or playerShipMoving then
		interval = math.max(0.025,
			tonumber(config.GalaxyShipMovingThinkInterval) or 0.05)
	else
		interval = math.max(0.05,
			tonumber(config.GalaxyShipIdleThinkInterval) or 0.15)
	end
	self:NextThink(now + interval)
	return true
end

function ENT:OnRemove()
	if MilBase and MilBase.Galaxy and MilBase.Galaxy.OnShipRemoved then
		MilBase.Galaxy.OnShipRemoved(self)
	end
end
