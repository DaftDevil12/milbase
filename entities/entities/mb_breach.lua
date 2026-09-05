--[[
	Hull breach: an invisible spot (placed with /engspot breach) that can
	rupture. While breached it vents sparks and steam. You seal it by
	*welding the seam* with the LVS repair tool (weapon_lvsrepair): a row
	of weld nodes appears over the breach and you sweep your aim across
	them, holding MOUSE1 - like tracing a weld. The pattern logic lives in
	modules/sh_engevents.lua; this entity just holds the state and the
	server-side weld method.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Hull Breach"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Breached")
	self:NetworkVar("Float", 0, "Weld")
end

if not SERVER then
	function ENT:Draw() end -- invisible; the HUD draws the markers
	return
end

function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate025x025.mdl")
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetTrigger(false)
end

function ENT:Break()
	self:SetBreached(true)
	self:SetWeld(0)
	self:EmitSound("ambient/machines/steam_release_2.wav", 80)
end

local function sparks(pos, big)
	local fx = EffectData()
	fx:SetOrigin(pos)
	fx:SetMagnitude(big and 2 or 1)
	fx:SetScale(1)
	fx:SetRadius(big and 3 or 2)
	util.Effect("Sparks", fx)
end

-- Advance the weld seam by `amount` (0-1). Called from the breach-weld
-- net handler as the welder completes each seam node. Seals at 1.
function ENT:AddWeld(amount, welder)
	if not self:GetBreached() then return end

	self:SetWeld(math.min(1, self:GetWeld() + amount))

	sparks(self:GetPos(), true)
	self:EmitSound("ambient/energy/newspark0" .. math.random(4, 6) .. ".wav",
		70, math.random(95, 110), 0.5)

	if self:GetWeld() >= 0.999 then
		self:SetBreached(false)
		self:SetWeld(0)
		self:EmitSound("items/suitchargeok1.wav", 75)

		if MilBase.EngIncidentFixed and IsValid(welder) then
			MilBase.EngIncidentFixed(welder, "welded a hull breach shut")
		end
	end
end

function ENT:Think()
	-- Just the venting ambience; welding is driven by the net handler.
	if self:GetBreached() and (self.mb_nextAmbient or 0) < CurTime() then
		self.mb_nextAmbient = CurTime() + math.Rand(1.5, 3)
		sparks(self:GetPos())
		self:EmitSound("ambient/gas/steam2.wav", 65, math.random(95, 110), 0.4)
	end

	self:NextThink(CurTime() + 0.5)
	return true
end
