--[[
	Bio-Analyzer console (placed with /engspot analyzer). Medics use it to
	analyze bio samples and synthesize cures - all logic in modules/sh_biolab.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Bio-Analyzer"
ENT.Spawnable = false

if not SERVER then
	function ENT:Draw()
		self:DrawModel()
	end
	return
end

function ENT:Initialize()
	self:SetModel("models/props_lab/servers.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if MilBase.AnalyzerUse then MilBase.AnalyzerUse(activator, self) end
end
