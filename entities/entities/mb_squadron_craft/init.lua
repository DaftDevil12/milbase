AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local FALLBACK_MODEL = "models/blu/laat.mdl"
local FALLBACK_SOUND = "ambient/machines/thumper_amb.wav"

function ENT:Initialize()
	if not util.IsValidModel(self:GetModel()) then self:SetModel(FALLBACK_MODEL) end
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:DrawShadow(false)
	self:SetVisualScale(math.max(0.001, tonumber(self:GetVisualScale()) or 1))
	self:SetModelScale(self:GetVisualScale(), 0.000001)
	self:SetMotionSpeed(0)
	self.mb_lastThink = CurTime()
	self.mb_routeIndex = 1
	self.mb_flightSpeed = 0

	local soundName = file.Exists("sound/lvs/vehicles/laat/loop.wav", "GAME")
		and "lvs/vehicles/laat/loop.wav" or FALLBACK_SOUND
	self.EngineLoop = CreateSound(self, soundName)
	if self.EngineLoop then self.EngineLoop:PlayEx(0.34, 102) end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end

function ENT:SetFlightRoute(points, options)
	if not istable(points) then return false end
	local clean = {}
	for _, point in ipairs(points) do
		if isvector(point) then
			clean[#clean + 1] = Vector(point)
		elseif istable(point) and isvector(point.pos) then
			clean[#clean + 1] = Vector(point.pos)
		end
	end
	if #clean < 2 then return false end
	self.mb_route = clean
	self.mb_routeIndex = 2
	self.mb_routeOptions = options or {}
	self:SetPos(clean[1])
	local direction = clean[2] - clean[1]
	if direction:LengthSqr() > 0.001 then self:SetAngles(direction:Angle()) end
	return true
end

local function finishRoute(self)
	if self.mb_routeFinished then return end
	self.mb_routeFinished = true
	self:SetMotionSpeed(0)
	local callback = self.mb_routeOptions and self.mb_routeOptions.onComplete
	if isfunction(callback) then
		local ok, err = pcall(callback, self)
		if not ok then
			ErrorNoHalt("[MilBase Squadron] route completion failed: "
				.. tostring(err) .. "\n")
		end
	end
	if IsValid(self) then self:Remove() end
end

function ENT:Think()
	local now = CurTime()
	local dt = math.Clamp(now - (self.mb_lastThink or now), 0, 0.1)
	self.mb_lastThink = now
	local route = self.mb_route
	local target = route and route[self.mb_routeIndex or 1]
	if not isvector(target) then
		if route then finishRoute(self) end
		self:NextThink(now + 0.05)
		return true
	end

	local options = self.mb_routeOptions or {}
	local delta = target - self:GetPos()
	local distance = delta:Length()
	local arrival = math.max(8, tonumber(options.arrivalRadius) or 28)
	if distance <= arrival then
		self.mb_routeIndex = (self.mb_routeIndex or 1) + 1
		target = route[self.mb_routeIndex]
		if not isvector(target) then
			finishRoute(self)
			return true
		end
		delta = target - self:GetPos()
		distance = delta:Length()
	end

	if distance > 0.001 then
		local desiredDirection = delta / distance
		local cruise = math.max(80, tonumber(options.speed) or 520)
		local acceleration = math.max(40, tonumber(options.acceleration) or 260)
		local finalPoint = (self.mb_routeIndex or 1) >= #route
		local desiredSpeed = finalPoint
			and math.min(cruise, math.max(90, distance * 1.25)) or cruise
		self.mb_flightSpeed = math.Approach(tonumber(self.mb_flightSpeed) or 0,
			desiredSpeed, acceleration * dt)
		self:SetMotionSpeed(self.mb_flightSpeed)
		self:SetPos(self:GetPos() + desiredDirection
			* math.min(distance, self.mb_flightSpeed * dt))

		local desiredAngle = desiredDirection:Angle()
		local current = self:GetAngles()
		local yawDelta = math.AngleDifference(desiredAngle.y, current.y)
		desiredAngle.r = math.Clamp(-yawDelta * 0.42, -28, 28)
		local turn = math.Clamp(dt * math.max(0.2,
			tonumber(options.turnRate) or 2.6), 0, 1)
		self:SetAngles(LerpAngle(turn, current, desiredAngle))
	end

	if self.EngineLoop then
		self.EngineLoop:ChangePitch(92
			+ math.Clamp(self:GetMotionSpeed() / 26, 0, 24), 0.15)
	end
	self:NextThink(now + 0.02)
	return true
end

function ENT:OnRemove()
	if self.EngineLoop then self.EngineLoop:Stop() end
end
