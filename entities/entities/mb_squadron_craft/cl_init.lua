include("shared.lua")

local glow = Material("sprites/light_glow02_add")

local function litModel(ent)
	render.SuppressEngineLighting(true)
	render.ResetModelLighting(0.25, 0.28, 0.34)
	render.SetModelLighting(BOX_TOP, 0.9, 0.9, 0.86)
	render.SetModelLighting(BOX_FRONT, 0.68, 0.74, 0.86)
	render.SetModelLighting(BOX_RIGHT, 0.48, 0.56, 0.7)
	render.SetModelLighting(BOX_LEFT, 0.24, 0.3, 0.4)
	render.SetModelLighting(BOX_BACK, 0.2, 0.24, 0.34)
	render.SetModelLighting(BOX_BOTTOM, 0.12, 0.15, 0.22)
	ent:DrawModel()
	render.SuppressEngineLighting(false)
end

function ENT:Draw()
	litModel(self)
	if self:GetMotionSpeed() <= 2 then return end
	local scale = math.max(0.001, self:GetVisualScale())
	local mins, maxs = self:GetModelRenderBounds()
	local radius = isvector(mins) and isvector(maxs)
		and math.max(mins:Length(), maxs:Length()) * scale or 48
	local size = math.Clamp(radius * 0.075, 3, 22)
	local exhaust = self:GetPos() - self:GetForward() * radius * 0.85
	render.SetMaterial(glow)
	render.DrawSprite(exhaust, size, size, Color(105, 185, 255, 195))
end
