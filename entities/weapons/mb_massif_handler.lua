AddCSLuaFile()

SWEP.PrintName = "CG Massif Handler"
SWEP.Author = "MilBase"
SWEP.Instructions = "Reload: deploy/recall | Left-click: mark scent only | Right-click: choose an order"
SWEP.Category = "Star Wars RP"
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel = "models/props_lab/huladoll.mdl"
SWEP.HoldType = "normal"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:CanUseHandler()
	local owner = self:GetOwner()
	return IsValid(owner) and MilBase.PlayerCanHandleMassif and MilBase.PlayerCanHandleMassif(owner)
end

function SWEP:Deploy()
	if SERVER and not self:CanUseHandler() then
		timer.Simple(0, function()
			local owner = self:GetOwner()
			if IsValid(owner) then owner:StripWeapon(self:GetClass()) end
		end)
		return false
	end
	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.35)
	if CLIENT then return end
	if not self:CanUseHandler() then return end
	local owner = self:GetOwner()
	if IsValid(owner:GetNWEntity("mb_massif_control")) then return end
	local tr = owner:GetEyeTrace()
	if not IsValid(tr.Entity) or (not tr.Entity:IsPlayer() and not tr.Entity:IsNPC() and not tr.Entity:IsNextBot()) then
		if MilBase.Notify then MilBase.Notify(owner, "Aim at a player or hostile NPC to mark their scent.", "warn") end
		return
	end
	MilBase.SetMassifTarget(owner, tr.Entity)
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.45)
	local owner = self:GetOwner()
	if IsValid(owner) and IsValid(owner:GetNWEntity("mb_massif_control")) then return end
	if CLIENT and IsFirstTimePredicted() and MilBase.OpenMassifWheel then
		MilBase.OpenMassifWheel()
	end
end

function SWEP:Reload()
	if CurTime() < (self.NextHandlerReload or 0) then return end
	self.NextHandlerReload = CurTime() + 0.7
	if CLIENT then return end
	if not self:CanUseHandler() then return end
	local owner = self:GetOwner()
	if IsValid(owner:GetNWEntity("mb_massif_control")) then return end
	local ent = MilBase.GetPlayerMassif(owner)
	if IsValid(ent) then
		MilBase.DismissMassif(owner, ent:GetMassifName() .. " recalled.")
	else
		MilBase.DeployMassif(owner)
	end
end

function SWEP:Holster()
	local owner = self:GetOwner()
	return not IsValid(owner) or not IsValid(owner:GetNWEntity("mb_massif_control"))
end

function SWEP:OnRemove()
	if SERVER then
		local owner = self:GetOwner()
		if IsValid(owner) and IsValid(owner:GetNWEntity("mb_massif_control")) and MilBase.EndMassifControl then
			MilBase.EndMassifControl(owner, "Massif control tool removed.")
		end
	end
end
