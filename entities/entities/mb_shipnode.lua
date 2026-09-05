--[[
	Ship-system console: binds to a nearby Star Wars Universe terminal
	(placed with /engspot shipnode). Take it out with weapons or a saboteur's
	charge and the bound ship system goes offline (see modules/sh_shipsystems.lua)
	until an engineer holds E for the code-repair minigame.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Ship System Console"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Broken")
	self:NetworkVar("String", 0, "SystemName")
end

if not SERVER then
	function ENT:Draw() end -- invisible; the HUD draws its markers when broken
	return
end

function ENT:Initialize()
	self:SetModel(MilBase.Config.ShipNodeModel or "models/props_lab/monitor01b.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetSystemName("SHIP SYSTEM")

	-- Invisible: the collision model stays (so you can still aim [E] to repair
	-- it and it still takes sabotage/command damage) but nothing renders.
	self:SetNoDraw(true)
	self:DrawShadow(false)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end

	self.mb_hp = MilBase.Config.ShipNodeHealth or 150
end

-- Combat weapons AND saboteur charges (util.BlastDamage) both land here.
function ENT:OnTakeDamage(dmg)
	if self:GetBroken() or MilBase.Config.ShipSystemsEnabled == false then return end

	self.mb_hp = (self.mb_hp or 150) - dmg:GetDamage()
	if self.mb_hp <= 0 then
		self:Break(dmg:GetAttacker())
	else
		self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 65, math.random(90, 105))
	end
end

function ENT:Break(attacker)
	if self:GetBroken() then return end
	self:SetBroken(true)
	self:SetColor(Color(255, 120, 120))
	self:EmitSound("ambient/energy/zap1.wav", 78)

	local fx = EffectData()
	fx:SetOrigin(self:GetPos() + self:GetUp() * 6)
	fx:SetMagnitude(2)
	fx:SetScale(1)
	util.Effect("cball_explode", fx)

	if MilBase.OnShipNodeBroken then MilBase.OnShipNodeBroken(self, attacker) end
	if MilBase.RefreshShipSystems then MilBase.RefreshShipSystems() end
end

function ENT:Fix()
	self:SetBroken(false)
	self:SetColor(color_white)
	self:EmitSound("items/suitchargeok1.wav", 72)
	self.mb_hp = MilBase.Config.ShipNodeHealth or 150

	if MilBase.RefreshShipSystems then MilBase.RefreshShipSystems() end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	if not self:GetBroken() then
		MilBase.Notify(activator, (self:GetSystemName() or "System") .. " console operational.")
		return
	end

	activator.mb_shipnodeOpen = CurTime()
	net.Start("MilBase_ShipNodeGame")
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
				62, math.random(95, 110), 0.5)
		end
	end

	self:NextThink(CurTime() + 0.5)
	return true
end
