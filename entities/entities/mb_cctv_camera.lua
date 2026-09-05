--[[
	CCTV camera. A placeable security camera whose feed can be viewed on the
	CCTV Monitor SWEP (mb_cctv). Aim it with the physgun; the feed looks down
	the camera's forward. Admin-spawnable. Feed/monitor logic in
	modules/sh_cctv.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "CCTV Camera"
ENT.Category = "MilBase"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "CamName")
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		-- A little red "recording" light so people can spot the camera.
		local dlight = DynamicLight(self:EntIndex())
		if dlight then
			dlight.pos = self:GetPos() + self:GetForward() * 4
			dlight.r, dlight.g, dlight.b = 255, 40, 40
			dlight.brightness = 1
			dlight.decay = 1000
			dlight.size = 32
			dlight.dietime = CurTime() + 0.1
		end
	end
	return
end

function ENT:Initialize()
	self:SetModel("models/tobadforyou/surveillance_camera.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end

	if self:GetCamName() == "" then
		self:SetCamName("CAM-" .. self:EntIndex())
	end
end

-- The lens position/angles the feed renders from.
function ENT:GetViewPos()
	return self:GetPos() + self:GetForward() * 6 + self:GetUp() * 1
end
