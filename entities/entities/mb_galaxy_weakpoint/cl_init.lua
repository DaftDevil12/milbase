include("shared.lua")

local glow = Material("sprites/light_glow02_add")

function ENT:DrawTranslucent()
	local radius = math.max(10, self:GetHitRadius())
	local disabled = self:GetDisabled()
	local hit = self:GetHitUntil() > CurTime()
	local color = disabled and Color(70, 75, 80, 55)
		or hit and Color(255, 245, 180, 245) or Color(255, 78, 54, 215)

	render.SetMaterial(glow)
	render.DrawSprite(self:WorldSpaceCenter(), radius * (hit and 1.8 or 1.25),
		radius * (hit and 1.8 or 1.25), color)
	render.SetColorMaterial()
	render.DrawWireframeSphere(self:WorldSpaceCenter(), radius, 10, 7, color, true)
end
