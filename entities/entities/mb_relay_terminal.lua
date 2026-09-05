--[[
	Encryption Relay terminal. High Command presses E here to run the decrypt
	minigame (needs a working antenna, mb_relay_dish) and temporarily tap the
	Encrypted channel. Destructible + engineer-repairable. Inherits the shared
	behaviour from mb_relay_dish; only the model / name differ.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "mb_relay_dish"
ENT.PrintName = "Encryption Relay Terminal"
ENT.Spawnable = false

if CLIENT then return end

function ENT:Initialize()
	self:SetModel(MilBase.Config.RelayTerminalModel or "models/props_lab/monitor01b.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetMoveType(MOVETYPE_NONE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end

	self.mb_hp = MilBase.Config.RelayHealth or 300
end
