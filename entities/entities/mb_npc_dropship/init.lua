AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local fallbackEngineSound = "ambient/machines/thumper_amb.wav"

local function validModel(model)
	return isstring(model) and model ~= "" and util.IsValidModel(model)
end

function ENT:Initialize()
	local requested = self:GetVehicleModel()
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
		self.EngineLoop:PlayEx(0.68, 94)
	end
end

function ENT:DropNPCs()
	if self:GetNPCsDropped() then return end

	self:SetNPCsDropped(true)

	local spawned = 0
	if isfunction(self.mb_dropCallback) then
		local callback = self.mb_dropCallback
		self.mb_dropCallback = nil
		local ok, result = pcall(callback, self)
		if ok then
			spawned = math.max(0, math.floor(tonumber(result) or 0))
		else
			ErrorNoHalt("[MilBase] Dropship deployment callback failed: "
				.. tostring(result) .. "\n")
		end
	else
		spawned = MilBase.SpawnDropshipNPCs and MilBase.SpawnDropshipNPCs(self) or 0
	end
	local drop = self:GetDropPos()

	local fx = EffectData()
	fx:SetOrigin(drop + Vector(0, 0, 20))
	fx:SetScale(0.6)
	util.Effect("ThumperDust", fx, true, true)

	self:EmitSound("npc/combine_soldier/gear" .. math.random(1, 6) .. ".wav", 78, 95, 0.8)

	local owner = self:GetCreator()
	if IsValid(owner) and owner:IsPlayer() and MilBase.Notify then
		MilBase.Notify(owner, "Dropship deployed " .. spawned .. " unit(s).", spawned > 0 and "ok" or "warn")
	end
end

function ENT:Think()
	local now = CurTime()
	local pos, ang = self:GetFlightTransform(now)
	self:SetPos(pos)
	self:SetAngles(ang)

	local phase, _, elapsed = self:GetDropPhase(now)
	local dropAt = self:GetApproachDuration() + self:GetDropDelay()

	if not self:GetNPCsDropped() and elapsed >= dropAt then
		self:DropNPCs()
	end

	if phase == "finished" then
		self:Remove()
		return
	end

	if self.EngineLoop then
		local pitch = phase == "landed" and 82 or 102
		self.EngineLoop:ChangePitch(pitch, 0.2)
	end

	self:NextThink(now)
	return true
end

function ENT:OnRemove()
	if not self:GetNPCsDropped() and isfunction(self.mb_dropCancelledCallback) then
		local callback = self.mb_dropCancelledCallback
		self.mb_dropCancelledCallback = nil
		pcall(callback, self)
	end
	if self.EngineLoop then
		self.EngineLoop:Stop()
	end
end
