--[[
	Security console (placed with /engspot hackconsole). A saboteur presses E
	to slice it (see modules/sh_shipsabotage.lua), which softly knocks the
	engines AND hyperdrive fully offline. An engineer presses E to type a
	recovery code and restore both. No physical damage.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Security Console"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Hacked")
end

if not SERVER then
	function ENT:Draw()
		self:DrawModel()
	end
	return
end

function ENT:Initialize()
	self:SetModel(MilBase.Config.HackConsoleModel or "models/props_lab/servers.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end
end

function ENT:Hack(by)
	if self:GetHacked() then return end
	self:SetHacked(true)
	self:SetColor(Color(120, 220, 140))
	self:EmitSound("ambient/levels/labs/electric_explosion" .. math.random(1, 5) .. ".wav", 75)

	if MilBase.OnConsoleHacked then MilBase.OnConsoleHacked(self, by) end
	if MilBase.RefreshShipSystems then MilBase.RefreshShipSystems() end
end

function ENT:Unhack(by)
	if not self:GetHacked() then return end
	self:SetHacked(false)
	self:SetColor(color_white)
	self:EmitSound("items/suitchargeok1.wav", 72)

	if MilBase.RefreshShipSystems then MilBase.RefreshShipSystems() end
end

-- /engspot break test hook.
function ENT:Break()
	self:Hack()
end

-- E opens the right minigame client-side (slice for saboteurs, code for
-- engineers); the result is validated again server-side in sh_shipsabotage.
function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	local isSab = activator:MBHasCert("saboteur") or activator:IsAdmin()
	local isEng = activator:MBHasCert("engineer") or activator:IsAdmin()

	if self:GetHacked() then
		if not isEng then
			MilBase.Notify(activator, "Security console HACKED — an engineer must reset it.")
			return
		end
	else
		if not isSab then
			MilBase.Notify(activator, "Security console — only a saboteur can slice this.")
			return
		end
	end

	activator.mb_hackOpen = CurTime()
	net.Start("MilBase_HackConsoleGame")
		net.WriteEntity(self)
		net.WriteBool(self:GetHacked()) -- true = engineer fix, false = saboteur hack
	net.Send(activator)
end

function ENT:Think()
	if self:GetHacked() and (self.mb_nextSpark or 0) < CurTime() then
		self.mb_nextSpark = CurTime() + math.Rand(1.5, 3.5)
		local fx = EffectData()
		fx:SetOrigin(self:GetPos() + self:GetUp() * 8)
		fx:SetMagnitude(1)
		fx:SetScale(1)
		fx:SetRadius(2)
		util.Effect("Sparks", fx)
	end

	self:NextThink(CurTime() + 0.5)
	return true
end
