AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Naval CIC Live Screen"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Page")
	self:NetworkVar("Float", 0, "ScreenScale")
end

if SERVER then
	function ENT:Initialize()
		local naval = MilBase.Config.NavalOperations or {}
		-- A tiny invisible anchor supplies networking and an E-use target. The
		-- actual display is projected onto the map prop at this origin.
		self:SetModel("models/props_junk/PopCan01a.mdl")
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionBounds(Vector(-5, -10, -10), Vector(5, 10, 10))
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetUseType(SIMPLE_USE)
		self:SetPage(0)
		if self:GetScreenScale() <= 0 then
			self:SetScreenScale(tonumber(naval.ScreenScale) or 0.135)
		end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Naval and MilBase.Naval.UseCICScreen then
			MilBase.Naval.UseCICScreen(activator, self)
			return
		end
		if (self.mb_nextUse or 0) > CurTime() then return end
		self.mb_nextUse = CurTime() + 0.35
		self:SetPage((self:GetPage() + 1) % 6)
		self:EmitSound("buttons/lightswitch2.wav", 55, 105, 0.45)
	end
	return
end

function ENT:Initialize()
	-- The projected panel is much larger than the invisible anchor model.
	self:SetRenderBounds(Vector(-320, -320, -320), Vector(320, 320, 320))
end

function ENT:Draw()
	if not MilBase.Naval or not MilBase.Naval.DrawCIC then return end
	if self:GetPos():DistToSqr(EyePos()) > 4500 * 4500 then return end
	local naval = MilBase.Config.NavalOperations or {}
	local scale = math.Clamp(self:GetScreenScale() > 0 and self:GetScreenScale()
		or tonumber(naval.ScreenScale) or 0.135,
		tonumber(naval.ScreenMinimumScale) or 0.025,
		tonumber(naval.ScreenMaximumScale) or 0.4)
	local centreTransform = Matrix()
	centreTransform:Translate(Vector(-512, -310, 0))
	cam.Start3D2D(self:GetPos(), self:GetAngles(), scale)
		cam.PushModelMatrix(centreTransform, true)
			MilBase.Naval.DrawCIC(self:GetPage())
		cam.PopModelMatrix()
	cam.End3D2D()
end
