--[[
	Encryption Relay antenna. Sits outside the base; must be intact for High
	Command to slice the relay terminal and tap the Encrypted channel. Take it
	out (sabotage charges / weapons) to keep the encrypted net secret; engineers
	repair it. Logic in modules/sh_relay.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Encryption Relay Antenna"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Broken")
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
	return
end

function ENT:Initialize()
	self:SetModel(MilBase.Config.RelayDishModel or "models/props_combine/combine_interface001.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetMoveType(MOVETYPE_NONE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end

	self.mb_hp = MilBase.Config.RelayHealth or 300
end

function ENT:Break()
	if self:GetBroken() then return end
	self:SetBroken(true)
	self:SetColor(Color(110, 110, 110))
	self:EmitSound("ambient/energy/spark6.wav", 80)
end

function ENT:Repair()
	self:SetBroken(false)
	self:SetColor(color_white)
	self.mb_hp = MilBase.Config.RelayHealth or 300
	self:EmitSound("items/suitchargeok1.wav", 75)
end

function ENT:Use(activator)
	if MilBase.RelayUse then MilBase.RelayUse(self, activator) end
end

function ENT:Think()
	if self:GetBroken() and (self.mb_nextSpark or 0) < CurTime() then
		self.mb_nextSpark = CurTime() + math.Rand(1.5, 3.5)
		local fx = EffectData()
		fx:SetOrigin(self:GetPos() + self:GetUp() * 20)
		fx:SetScale(1)
		util.Effect("Sparks", fx)
	end
	self:NextThink(CurTime() + 0.5)
	return true
end
