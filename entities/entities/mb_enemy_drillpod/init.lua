AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local FALLBACK_MODEL = "models/props_combine/headcrabcannister01a.mdl"

local function effectAt(pos, name, scale)
	local fx = EffectData()
	fx:SetOrigin(pos)
	fx:SetScale(scale or 1)
	util.Effect(name, fx, true, true)
end

function ENT:Initialize()
	local requested = tostring(self.mb_requestedModel
		or MilBase and MilBase.Config and MilBase.Config.EventEnemyDrillPodModel or "")
	local model = util.IsValidModel(requested) and requested or FALLBACK_MODEL
	self:SetModel(util.IsValidModel(model) and model or "models/props_junk/PopCan01a.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:DrawShadow(true)
	self:SetUseType(SIMPLE_USE)
	self:SetHealth(650)
	self:SetMaxHealth(650)

	if self:GetSpawnID() == "" then
		self:SetSpawnID("pod_" .. os.time() .. "_" .. math.random(100, 999))
	end
	if self:GetSpawnName() == "" then self:SetSpawnName("Drill Pod") end
	if self:GetSpawnStatus() == "" then self:SetSpawnStatus("incoming") end
	if self:GetStartTime() <= 0 then self:SetStartTime(CurTime()) end
	if self:GetDropDuration() <= 0 then self:SetDropDuration(3) end
	if self:GetDrillDuration() < 0 then self:SetDrillDuration(0) end
	if self:GetSpawnRadius() <= 0 then self:SetSpawnRadius(110) end
	if self:GetTargetPos() == vector_origin then self:SetTargetPos(self:GetPos()) end

	self.mb_startPos = self.mb_startPos or self:GetPos()
end

function ENT:SettleActivation(activated)
	if self.mb_activationSettled then return end
	self.mb_activationSettled = true
	local callback = activated and self.mb_activateCallback
		or self.mb_activationCancelledCallback
	self.mb_activateCallback = nil
	self.mb_activationCancelledCallback = nil
	if not isfunction(callback) then return end
	local ok, err = pcall(callback, self)
	if not ok then
		ErrorNoHalt("[MilBase] Drill-pod deployment callback failed: "
			.. tostring(err) .. "\n")
	end
end

function ENT:ActivateSpawn(silent)
	self:SetPos(self:GetTargetPos() + Vector(0, 0, 8))
	self:SetSpawnStatus("active")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:PhysicsInitSphere(34, "metal_bouncy")

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	if MilBase and MilBase.RegisterEventEnemySpawn then
		MilBase.RegisterEventEnemySpawn({
			id = self:GetSpawnID(),
			name = self:GetSpawnName(),
			type = "drill",
			pos = self:GetPos(),
			enabled = self:GetSpawnEnabled(),
			status = "active",
			radius = self:GetSpawnRadius(),
			maxActive = self:GetMaxActive(),
			classes = self.mb_spawnClasses or {},
			ent = self,
		})
	end
	self:SettleActivation(true)

	if not silent then
		effectAt(self:GetPos(), "ThumperDust", 0.8)
		self:EmitSound("ambient/machines/thumper_hit.wav", 85, 85, 0.9)
	end
end

function ENT:Think()
	local status = self:GetSpawnStatus()
	local now = CurTime()

	if status == "incoming" then
		local dur = math.max(self:GetDropDuration(), 0.01)
		local t = math.Clamp((now - self:GetStartTime()) / dur, 0, 1)
		local pos = LerpVector(t, self.mb_startPos or self:GetPos(), self:GetTargetPos() + Vector(0, 0, 8))
		self:SetPos(pos)
		self:SetAngles(Angle(90 + t * 270, self:GetAngles().y + FrameTime() * 120, 0))

		if t >= 1 then
			self:SetSpawnStatus("drilling")
			self.mb_drillEnd = now + math.max(self:GetDrillDuration(), 0)
			self:EmitSound("ambient/machines/thumper_startup1.wav", 85, 90, 0.9)
			effectAt(self:GetTargetPos(), "ThumperDust", 1)
		end
	elseif status == "drilling" then
		self:SetPos(self:GetTargetPos() + Vector(0, 0, 8 + math.sin(now * 28) * 1.4))
		self:SetAngles(Angle(0, self:GetAngles().y + FrameTime() * 260, 0))
		if (self.mb_nextDust or 0) < now then
			self.mb_nextDust = now + 0.45
			effectAt(self:GetPos(), "ThumperDust", 0.35)
			self:EmitSound("ambient/machines/thumper_top.wav", 72, math.random(92, 105), 0.55)
		end
		if now >= (self.mb_drillEnd or now) then
			self:ActivateSpawn()
		end
	elseif status == "active" then
		local spawn = MilBase and MilBase.EventEnemySpawns and MilBase.EventEnemySpawns[self:GetSpawnID()]
		if spawn then
			if spawn.enabled ~= self:GetSpawnEnabled() then spawn.enabled = self:GetSpawnEnabled() end
			spawn.pos = self:GetPos()
		end
	end

	self:NextThink(now)
	return true
end

function ENT:OnTakeDamage(dmg)
	if self:GetSpawnStatus() == "destroyed" then return end
	self:SetHealth(self:Health() - dmg:GetDamage())
	if self:Health() > 0 then return end

	self:SetSpawnStatus("destroyed")
	self:SetSpawnEnabled(false)
	if MilBase and MilBase.RemoveEventEnemySpawn then
		self.mb_keepAfterUnregister = true
		self.mb_skipSpawnUnregister = true
		MilBase.RemoveEventEnemySpawn(self:GetSpawnID())
	end
	self:SettleActivation(false)
	effectAt(self:GetPos(), "Explosion", 0.6)
	self:EmitSound("ambient/explosions/explode_4.wav", 85, 95, 0.9)
	SafeRemoveEntityDelayed(self, 4)
end

function ENT:OnRemove()
	self:SettleActivation(false)
	if self.mb_skipSpawnUnregister then return end
	if MilBase and MilBase.EventEnemySpawns
	and MilBase.EventEnemySpawns[self:GetSpawnID()]
	and MilBase.UnregisterEventEnemySpawn then
		MilBase.UnregisterEventEnemySpawn(self:GetSpawnID())
	end
end
