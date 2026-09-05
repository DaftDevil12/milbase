AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Naval Power Distribution Console"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Operator")
	self:NetworkVar("Float", 0, "ScreenScale")
end

if SERVER then
	function ENT:Initialize()
		local naval = MilBase.Config.NavalOperations or {}
		self:SetModel("models/props_junk/PopCan01a.mdl")
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionBounds(Vector(-5, -10, -10), Vector(5, 10, 10))
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetUseType(SIMPLE_USE)
		self:SetOperator(NULL)
		if self:GetScreenScale() <= 0 then
			self:SetScreenScale(tonumber(naval.PowerConsoleScale) or 0.105)
		end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Naval and MilBase.Naval.UsePowerConsole then
			MilBase.Naval.UsePowerConsole(activator, self)
		end
	end

	function ENT:OnRemove()
		if MilBase.Naval and MilBase.Naval.ReleasePowerConsole then
			MilBase.Naval.ReleasePowerConsole(self)
		end
	end
	return
end

function ENT:Initialize()
	self:SetRenderBounds(Vector(-360, -360, -360), Vector(360, 360, 360))
end

function ENT:Draw()
	if not MilBase.Naval or not MilBase.Naval.DrawPowerConsole then return end
	if self:GetPos():DistToSqr(EyePos()) > 4500 * 4500 then return end
	local naval = MilBase.Config.NavalOperations or {}
	local scale = math.Clamp(self:GetScreenScale() > 0 and self:GetScreenScale()
		or tonumber(naval.PowerConsoleScale) or 0.105,
		tonumber(naval.PowerConsoleMinimumScale) or 0.025,
		tonumber(naval.PowerConsoleMaximumScale) or 0.3)
	local centreTransform = Matrix()
	centreTransform:Translate(Vector(-512, -310, 0))
	cam.Start3D2D(self:GetPos(), self:GetAngles(), scale)
		cam.PushModelMatrix(centreTransform, true)
			MilBase.Naval.DrawPowerConsole(self:GetOperator())
		cam.PopModelMatrix()
	cam.End3D2D()
end
