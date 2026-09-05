--[[
	Physical engine / hyperdrive part (placed with /engspot shippart <system>).
	Only a saboteur's planted charge can destroy it (immune to gunfire). A
	destroyed part is repaired in three in-world stages:
	  1 WELD     - sweep the repair tool across the seam (like a hull breach)
	  2 RE-WIRE  - press E: reconnect the control lines minigame
	  3 CIRCUITS - press E: alignment-sequence minigame
	Logic in modules/sh_shipsabotage.lua; consequence counting (multiple parts
	per system, fraction offline) in modules/sh_shipsystems.lua.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Ship Part"
ENT.Spawnable = false

-- Stage: 0 operational, 1 WELD, 2 RE-WIRE, 3 CIRCUITS.
function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Destroyed")
	self:NetworkVar("Int", 0, "Stage")
	self:NetworkVar("Float", 0, "Weld")
end

if not SERVER then
	function ENT:Draw() end -- invisible; the HUD draws its markers/weld seam
	return
end

function ENT:Initialize()
	local models = MilBase.Config.ShipPartModels or {}
	local model = (self.mb_assigned and models[string.lower(self.mb_assigned)])
		or MilBase.Config.ShipPartModel or "models/props_combine/combine_generator01.mdl"

	self:SetModel(model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	-- Invisible: the collision model stays (so [E] repair still traces to it
	-- and OBB-centre positioning works) but nothing renders. The saboteur's
	-- "CRITICAL PART" marker and the weld seam are HUD-drawn.
	self:SetNoDraw(true)
	self:DrawShadow(false)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end
end

-- Bomb-only: ignore all weapon/explosion damage. Destruction happens solely
-- through Destroy(), called by a saboteur's charge (mb_charge:Detonate).
function ENT:OnTakeDamage() end

-- Detonated on by a saboteur's charge (see mb_charge:Detonate). Bomb-only.
function ENT:Destroy()
	if self:GetDestroyed() then return end
	self:SetDestroyed(true)
	self:SetStage(1) -- WELD first
	self:SetWeld(0)
	self:SetColor(Color(90, 90, 90))

	local fx = EffectData()
	fx:SetOrigin(self:LocalToWorld(self:OBBCenter()))
	fx:SetScale(2)
	util.Effect("Explosion", fx)
	util.Effect("HelicopterMegaBomb", fx)
	self:EmitSound("ambient/explosions/explode_4.wav", 90)

	if MilBase.OnShipPartDestroyed then MilBase.OnShipPartDestroyed(self) end
	if MilBase.RefreshShipSystems then MilBase.RefreshShipSystems() end
end

-- Stage 1: welded through the shared breach-weld handler in sh_engevents.
function ENT:AddWeld(amount, welder)
	if self:GetStage() ~= 1 then return end
	self:SetWeld(math.min(1, self:GetWeld() + amount))

	local fx = EffectData()
	fx:SetOrigin(self:LocalToWorld(self:OBBCenter()))
	fx:SetMagnitude(2)
	fx:SetScale(1)
	fx:SetRadius(3)
	util.Effect("Sparks", fx)
	self:EmitSound("ambient/energy/newspark0" .. math.random(4, 6) .. ".wav",
		70, math.random(95, 110), 0.5)

	if self:GetWeld() >= 0.999 then
		self:SetStage(2) -- advance to RE-WIRE
		self:SetWeld(0)
		self:EmitSound("items/suitchargeok1.wav", 72)
		if IsValid(welder) then
			MilBase.Notify(welder, "Plating sealed — now RE-WIRE the part (press E).")
		end
	end
end

-- /engspot break test hook.
function ENT:Break()
	self:Destroy()
end

-- Stages 2 & 3 are screen minigames opened from Use.
function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	if not self:GetDestroyed() then
		MilBase.Notify(activator, "Part operational.")
		return
	end
	if not (activator:MBHasCert("engineer") or activator:IsAdmin()) then
		MilBase.Notify(activator, "This part needs an engineer to repair.")
		return
	end
	if self:GetStage() == 1 then
		MilBase.Notify(activator, "Weld the ruptured plating first (equip the repair tool).")
		return
	end

	activator.mb_partOpen = CurTime()
	net.Start("MilBase_ShipPartGame")
		net.WriteEntity(self)
	net.Send(activator)
end

function ENT:Think()
	if self:GetDestroyed() and (self.mb_nextSpark or 0) < CurTime() then
		self.mb_nextSpark = CurTime() + math.Rand(1.2, 2.8)
		local fx = EffectData()
		fx:SetOrigin(self:LocalToWorld(self:OBBCenter()) + self:GetUp() * 10)
		fx:SetMagnitude(1)
		fx:SetScale(1)
		fx:SetRadius(3)
		util.Effect("Sparks", fx)
		self:EmitSound("ambient/gas/steam2.wav", 62, math.random(90, 110), 0.4)
	end

	self:NextThink(CurTime() + 0.5)
	return true
end
