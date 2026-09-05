include("shared.lua")

local glow = Material("sprites/light_glow02_add")
local flame = Material("sprites/flamelet1")

local function visualRadius(ent)
	local scale = math.max(ent:GetModelSize(), 0.005)
	local mins, maxs = ent:GetModelRenderBounds()
	if isvector(mins) and isvector(maxs) then
		return math.max(0.01, math.max(mins:Length(), maxs:Length()) * scale)
	end
	return math.max(0.01, ent:BoundingRadius() * scale)
end

local function lightVisibility(ent, radius)
	local distance = EyePos():Distance(ent:WorldSpaceCenter())
	if distance <= 1 then return 1 end

	-- The previous fixed minimum sprite sizes left bright dots behind after
	-- the hull had become too small to see. Fade the fittings with the actual
	-- rendered hull instead of the larger combat/collision radius.
	local apparentSize = radius / distance
	return math.Clamp((apparentSize - 0.0025) / 0.0125, 0, 1)
end

local function drawWreckageFire(ent)
	local radius = math.max(ent:GetCombatRadius(),
		visualRadius(ent))
	local center = ent:WorldSpaceCenter()
	local now = CurTime()
	render.SetMaterial(flame)
	for index = 1, 3 do
		local phase = now * (5.5 + index * 0.6) + ent:EntIndex() * 0.37 + index * 2.1
		local position = center
			+ ent:GetForward() * math.sin(phase * 0.43) * radius * 0.28
			+ ent:GetRight() * math.cos(phase * 0.61) * radius * 0.34
			+ ent:GetUp() * math.sin(phase * 0.79) * radius * 0.2
		local size = math.Clamp(radius * (0.12 + index * 0.025)
			* (0.82 + math.sin(phase) * 0.18), 8, 105)
		render.DrawSprite(position, size, size * 1.35,
			Color(255, 105 + index * 18, 28, 210))
	end
	render.SetMaterial(glow)
	local pulse = 0.72 + math.sin(now * 8 + ent:EntIndex()) * 0.18
	render.DrawSprite(center, math.Clamp(radius * 0.34 * pulse, 18, 180),
		math.Clamp(radius * 0.34 * pulse, 18, 180), Color(255, 75, 22, 95))
end

local function drawIlluminatedModel(ent)
	-- Skyboxes frequently have no usable model light samples. A restrained
	-- six-sided light rig keeps the hull readable without creating dynamic
	-- lights for every ambient ship.
	render.SuppressEngineLighting(true)
	render.ResetModelLighting(0.24, 0.26, 0.3)
	render.SetModelLighting(BOX_TOP, 0.9, 0.88, 0.82)
	render.SetModelLighting(BOX_FRONT, 0.68, 0.72, 0.8)
	render.SetModelLighting(BOX_RIGHT, 0.48, 0.52, 0.62)
	render.SetModelLighting(BOX_LEFT, 0.22, 0.24, 0.3)
	render.SetModelLighting(BOX_BACK, 0.2, 0.22, 0.28)
	render.SetModelLighting(BOX_BOTTOM, 0.1, 0.12, 0.16)
	ent:DrawModel()
	render.SuppressEngineLighting(false)
end

function ENT:Draw()
	drawIlluminatedModel(self)

	-- RENDERGROUP_BOTH can visit an entity in more than one render pass.
	-- Models may need that, but additive fittings must only be submitted once.
	local frame = FrameNumber()
	if self.mb_galaxyEffectsFrame == frame then return end
	self.mb_galaxyEffectsFrame = frame

	if self:GetNW2Bool("MBGalaxyWreckage", false) then
		drawWreckageFire(self)
		return
	end
	if self:GetShipState() == "destroyed" then return end
	local hullRadius = visualRadius(self)
	local combatRadius = math.max(self:GetCombatRadius(),
		hullRadius)
	-- Shields remain mechanically active but do not surround ships with a
	-- permanent sphere. Only the exact impact point flashes briefly.
	if self:GetMaxShield() > 0 and self:GetShield() > 0
	and self:GetShieldHitUntil() > CurTime() then
		local position = self:GetShieldHitPosition()
		if not isvector(position) or position == vector_origin then
			position = self:WorldSpaceCenter()
		end
		local hitSize = math.Clamp(hullRadius * 0.08, 5, 48)
		render.SetMaterial(glow)
		render.DrawSprite(position, hitSize, hitSize,
			Color(125, 225, 255, 210))
	end
	local col = MilBase and MilBase.Galaxy and MilBase.Galaxy.AllegianceColor(self:GetFaction())
		or Color(180, 200, 255)
	local speed = math.max(0, self:GetMotionSpeed())
	if speed <= 0 then speed = self:GetFlightVelocity():Length() end
	local visibility = lightVisibility(self, hullRadius)
	if visibility <= 0 then return end
	local thrust = math.Clamp(speed / 65, 0, 1)
	local engineActive = speed > 2
	local radius = math.Clamp(hullRadius * (0.035 + thrust * 0.055), 0.5, 22)
	local exhaust = self:GetPos() - self:GetForward() * hullRadius * 0.9

	render.SetMaterial(glow)
	if engineActive then
		render.DrawSprite(exhaust, radius, radius, Color(col.r, col.g, col.b,
			math.floor((45 + thrust * 145) * visibility)))
	end
	if thrust > 0.18 then
		local trail = math.Clamp(hullRadius * (0.12 + thrust * 0.42), 2, 120)
		render.DrawSprite(exhaust - self:GetForward() * trail * 0.46,
			radius * (0.5 + thrust * 0.24), radius * (0.5 + thrust * 0.24),
			Color(col.r, col.g, col.b,
				math.floor((18 + thrust * 58) * visibility)))
	end

	-- Large combat ships already have engine detail in their models. Generic
	-- red/green fittings made a multi-coloured cloud around raid formations.
	if self:GetCapital() or self:GetNW2Bool("MBGalaxyRaidCapital", false)
	or visibility < 0.35 then return end
	local pulse = 0.5 + math.sin(CurTime() * 4 + self:EntIndex()) * 0.5
	local navOffset = math.Clamp(hullRadius * 0.48, 2, 120)
	local navSize = math.Clamp(hullRadius * 0.018, 0.4, 5)
	render.DrawSprite(self:WorldSpaceCenter() + self:GetRight() * navOffset,
		navSize, navSize, Color(80, 255, 110,
			math.floor((35 + pulse * 85) * visibility)))
	render.DrawSprite(self:WorldSpaceCenter() - self:GetRight() * navOffset,
		navSize, navSize, Color(255, 70, 70,
			math.floor((35 + (1 - pulse) * 85) * visibility)))
end

function ENT:Think()
	if not self:GetNW2Bool("MBGalaxyWreckage", false)
	or CurTime() < (self.mb_nextWreckSparkAt or 0) then return end
	self.mb_nextWreckSparkAt = CurTime() + math.Rand(0.28, 0.7)
	local radius = math.max(self:GetCombatRadius(),
		visualRadius(self))
	local normal = VectorRand()
	if normal:LengthSqr() <= 0.001 then normal = vector_up end
	normal:Normalize()
	local effect = EffectData()
	effect:SetOrigin(self:WorldSpaceCenter() + VectorRand() * radius * 0.36)
	effect:SetNormal(normal)
	effect:SetMagnitude(math.Clamp(radius * 0.035, 1, 12))
	effect:SetScale(math.Clamp(radius * 0.012, 0.5, 5))
	util.Effect("ManhackSparks", effect)
end
