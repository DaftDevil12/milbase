if SERVER then
	AddCSLuaFile()
	SWEP.HoldType = "slam"
end

if CLIENT then
	SWEP.PrintName = "RP Datapad"
	SWEP.Author = "MilBase"
	SWEP.Purpose = "Access records, CCTV, medical files, warrants, reports, and slicing overrides."
	SWEP.Instructions = "Primary/secondary/reload opens the datapad. CCTV controls work while the CCTV app is selected."
	SWEP.Slot = 1
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
end

SWEP.Category = "MilBase"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false
SWEP.ViewModelFOV = 50
SWEP.ViewModel = "models/swcw_items/sw_datapad_v.mdl"
SWEP.WorldModel = "models/swcw_items/sw_datapad.mdl"
SWEP.ViewModelFlip = false
SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false
SWEP.UseHands = true
SWEP.HoldType = "slam"
SWEP.FiresUnderwater = true
SWEP.DrawCrosshair = false
SWEP.DrawAmmo = false
SWEP.Base = "weapon_base"

SWEP.Primary.Damage = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.Delay = 0
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Damage = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
	self:SetWeaponHoldType("slam")
end

local function open(owner, preferred)
	if SERVER and IsValid(owner) and MilBase and MilBase.DatapadOpen then
		MilBase.DatapadOpen(owner, preferred)
	end
end

function SWEP:Deploy()
	return true
end

function SWEP:Holster()
	if CLIENT and MilBase.CCTVSetActive then MilBase.CCTVSetActive(false) end
	return true
end

function SWEP:OnRemove()
	if CLIENT and MilBase.CCTVSetActive then MilBase.CCTVSetActive(false) end
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.35)
	if CLIENT and IsFirstTimePredicted() and MilBase.CCTVCycle then MilBase.CCTVCycle(1) end
	open(self:GetOwner())
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.35)
	if CLIENT and IsFirstTimePredicted() and MilBase.CCTVCycle then MilBase.CCTVCycle(-1) end
	open(self:GetOwner())
end

function SWEP:Reload()
	if (self.mb_nextReload or 0) > CurTime() then return end
	self.mb_nextReload = CurTime() + 0.6
	if CLIENT and MilBase.CCTVToggleFull then MilBase.CCTVToggleFull() end
	open(self:GetOwner())
end
