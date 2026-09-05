--[[
	Engineering terminal (placed with /engspot terminal). When it
	malfunctions it sparks and glows red; press E to open the power
	conduit repair minigame (see modules/sh_engevents.lua).
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Engineering Terminal"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Broken")
end

if not SERVER then
	function ENT:Draw()
		self:DrawModel()
	end
	return
end

function ENT:Initialize()
	self:SetModel("models/props_lab/monitor01b.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end
end

function ENT:Break()
	self:SetBroken(true)
	self:SetColor(Color(255, 120, 120))
	self:EmitSound("ambient/energy/zap1.wav", 75)
end

function ENT:Fix()
	self:SetBroken(false)
	self:SetColor(color_white)
	self:EmitSound("items/suitchargeok1.wav", 70)
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	if not self:GetBroken() then
		MilBase.Notify(activator, "Terminal operational.")
		return
	end

	-- Open the repair minigame (validated again on completion).
	activator.mb_termOpen = CurTime()
	net.Start("MilBase_TerminalGame")
		net.WriteEntity(self)
	net.Send(activator)
end

function ENT:Think()
	if self:GetBroken() and (self.mb_nextSpark or 0) < CurTime() then
		self.mb_nextSpark = CurTime() + math.Rand(1.5, 3.5)

		local fx = EffectData()
		fx:SetOrigin(self:GetPos() + self:GetUp() * 8)
		fx:SetMagnitude(1)
		fx:SetScale(1)
		fx:SetRadius(2)
		util.Effect("Sparks", fx)

		if math.random(3) == 1 then
			self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav",
				65, math.random(95, 110), 0.5)
		end
	end

	self:NextThink(CurTime() + 0.5)
	return true
end
