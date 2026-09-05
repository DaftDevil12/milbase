AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local fallbackEngineSound = "ambient/machines/thumper_amb.wav"

local function validModel(model)
	return isstring(model) and model ~= "" and util.IsValidModel(model)
end

function ENT:Initialize()
	local requested = self:GetCarrierModel()
	local model = MilBase.ResolveDropshipModel and MilBase.ResolveDropshipModel(requested)
		or requested

	if not validModel(model) then
		model = MilBase.Dropship and MilBase.Dropship.FallbackModel or "models/combine_helicopter.mdl"
	end

	self:SetModel(model)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:DrawShadow(true)
	self:SetUseType(SIMPLE_USE)

	local idle = self:LookupSequence("idle")
	if idle and idle >= 0 then
		self:ResetSequence(idle)
	end

	local engineSound = file.Exists("sound/lvs/vehicles/laat/loop.wav", "GAME")
		and "lvs/vehicles/laat/loop.wav"
		or fallbackEngineSound

	self.EngineLoop = CreateSound(self, engineSound)
	if self.EngineLoop then
		self.EngineLoop:PlayEx(0.7, 92)
	end
end

function ENT:DropVehicle()
	if self:GetVehicleDropped() then return end

	self:SetVehicleDropped(true)

	local ent = MilBase.SpawnDropshipVehicle and MilBase.SpawnDropshipVehicle(self)
	local drop = self:GetDropPos()

	local fx = EffectData()
	fx:SetOrigin(drop + Vector(0, 0, 24))
	fx:SetScale(1)
	util.Effect("ThumperDust", fx, true, true)

	self:EmitSound("vehicles/v8/vehicle_impact_heavy" .. math.random(1, 4) .. ".wav", 82, 82, 0.65)

	return ent
end

function ENT:Think()
	local now = CurTime()
	local pos, ang = self:GetFlightTransform(now)
	self:SetPos(pos)
	self:SetAngles(ang)

	local phase, _, elapsed = self:GetDropPhase(now)
	local dropAt = self:GetApproachDuration() + self:GetDropDelay()

	if not self:GetVehicleDropped() and elapsed >= dropAt then
		self:DropVehicle()
	end

	if phase == "finished" then
		self:Remove()
		return
	end

	if self.EngineLoop then
		local pitch = phase == "landed" and 80 or 100
		self.EngineLoop:ChangePitch(pitch, 0.2)
	end

	self:NextThink(now)
	return true
end

function ENT:OnRemove()
	if self.EngineLoop then
		self.EngineLoop:Stop()
	end
end
