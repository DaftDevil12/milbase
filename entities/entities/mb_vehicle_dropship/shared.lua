ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Vehicle Dropship"
ENT.Author = "MilBase"
ENT.Category = "Star Wars RP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "RouteStart")
	self:NetworkVar("Vector", 1, "RouteLand")
	self:NetworkVar("Vector", 2, "RouteDepart")
	self:NetworkVar("Vector", 3, "DropPos")
	self:NetworkVar("Vector", 4, "CarryOffset")

	self:NetworkVar("Angle", 0, "RouteStartAngle")
	self:NetworkVar("Angle", 1, "RouteLandAngle")
	self:NetworkVar("Angle", 2, "DepartAngle")

	self:NetworkVar("Float", 0, "SequenceStarted")
	self:NetworkVar("Float", 1, "ApproachDuration")
	self:NetworkVar("Float", 2, "HoldDuration")
	self:NetworkVar("Float", 3, "DepartureDuration")
	self:NetworkVar("Float", 4, "DropDelay")

	self:NetworkVar("Bool", 0, "VehicleDropped")

	self:NetworkVar("String", 0, "CarrierModel")
	self:NetworkVar("String", 1, "VehicleClass")
	self:NetworkVar("String", 2, "CarriedModel")
	self:NetworkVar("String", 3, "VehicleTeam")
end

local function smoothStep(value)
	local t = math.Clamp(value, 0, 1)
	return t * t * (3 - 2 * t)
end

local function smootherStep(value)
	local t = math.Clamp(value, 0, 1)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function cubicBezier(p0, p1, p2, p3, t)
	local inv = 1 - t
	return p0 * (inv * inv * inv)
		+ p1 * (3 * inv * inv * t)
		+ p2 * (3 * inv * t * t)
		+ p3 * (t * t * t)
end

local function cubicBezierDerivative(p0, p1, p2, p3, t)
	local inv = 1 - t
	return (p1 - p0) * (3 * inv * inv)
		+ (p2 - p1) * (6 * inv * t)
		+ (p3 - p2) * (3 * t * t)
end

local function pathAngle(p0, p1, p2, p3, t, fallback)
	local tangent = cubicBezierDerivative(p0, p1, p2, p3, math.Clamp(t, 0.001, 0.999))
	if tangent:LengthSqr() < 1 then return fallback or angle_zero end

	local ang = tangent:Angle()
	ang.p = math.Clamp(ang.p, -18, 18)
	ang.r = 0
	return ang
end

function ENT:GetDropPhase(atTime)
	local elapsed = (atTime or CurTime()) - self:GetSequenceStarted()
	local approach = math.max(self:GetApproachDuration(), 0.01)
	local hold = math.max(self:GetHoldDuration(), 0.01)
	local departure = math.max(self:GetDepartureDuration(), 0.01)

	if elapsed < approach then
		return "approach", math.Clamp(elapsed / approach, 0, 1), elapsed
	end

	if elapsed < approach + hold then
		return "landed", math.Clamp((elapsed - approach) / hold, 0, 1), elapsed
	end

	if elapsed < approach + hold + departure then
		return "departure", math.Clamp((elapsed - approach - hold) / departure, 0, 1), elapsed
	end

	return "finished", 1, elapsed
end

function ENT:GetFlightTransform(atTime)
	local phase, raw = self:GetDropPhase(atTime)
	local startPos = self:GetRouteStart()
	local landPos = self:GetRouteLand()
	local departPos = self:GetRouteDepart()
	local startAng = self:GetRouteStartAngle()
	local landAng = self:GetRouteLandAngle()
	local departAng = self:GetDepartAngle()

	if phase == "approach" then
		local t = smootherStep(raw)
		local distance = startPos:Distance(landPos)
		local lift = math.Clamp(distance * 0.08, 120, 420)
		local p1 = startPos + startAng:Forward() * math.Clamp(distance * 0.28, 400, 1600)
		local p2 = landPos - landAng:Forward() * math.Clamp(distance * 0.2, 320, 1200)
			+ Vector(0, 0, lift)
		local pos = cubicBezier(startPos, p1, p2, landPos, t)
		local ang = pathAngle(startPos, p1, p2, landPos, t, startAng)
		local settle = smoothStep((raw - 0.72) / 0.28)

		ang = LerpAngle(settle, ang, landAng)
		ang.p = ang.p - math.sin(raw * math.pi) * 2
		ang.r = math.sin(raw * math.pi * 2) * 5 * (1 - settle)
		return pos, ang
	end

	if phase == "landed" then
		local turn = smoothStep(raw)
		local wobble = math.sin((atTime or CurTime()) * 2.8) * 1.6
		local pos = landPos + Vector(0, 0, math.sin((atTime or CurTime()) * 3.4) * 3)
		local ang = LerpAngle(turn, landAng, departAng)
		ang.r = wobble
		return pos, ang
	end

	if phase == "departure" or phase == "finished" then
		local t = smootherStep(raw)
		local distance = landPos:Distance(departPos)
		local p1 = landPos + departAng:Forward() * math.Clamp(distance * 0.22, 360, 1300)
			+ Vector(0, 0, 80)
		local p2 = departPos - departAng:Forward() * math.Clamp(distance * 0.18, 320, 1200)
			+ Vector(0, 0, math.Clamp(distance * 0.06, 120, 420))
		local pos = cubicBezier(landPos, p1, p2, departPos, t)
		local ang = pathAngle(landPos, p1, p2, departPos, t, departAng)

		ang.p = ang.p - math.sin(raw * math.pi) * 5
		ang.r = -math.sin(raw * math.pi) * 8
		return pos, ang
	end

	return landPos, landAng
end
