-- Compatibility wrapper: old Records Datapad now opens the unified RP Datapad.
if SERVER then AddCSLuaFile() SWEP.HoldType = "slam" end
if CLIENT then
	SWEP.PrintName = "Records Datapad (Legacy)"
	SWEP.Author = "MilBase"
	SWEP.Purpose = "Legacy wrapper for mb_datapad."
	SWEP.Instructions = "Use mb_datapad instead. Primary opens Criminal Records."
	SWEP.Slot = 1
	SWEP.SlotPos = 2
	SWEP.DrawAmmo = false
end
SWEP.Category = "MilBase"
SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false
SWEP.ViewModelFOV = 50
SWEP.ViewModel = "models/swcw_items/sw_datapad_v.mdl"
SWEP.WorldModel = "models/swcw_items/sw_datapad.mdl"
SWEP.UseHands = true
SWEP.HoldType = "slam"
SWEP.DrawCrosshair = false
SWEP.DrawAmmo = false
SWEP.Base = "weapon_base"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
function SWEP:Initialize() self:SetWeaponHoldType("slam") end
local function open(owner) if SERVER and IsValid(owner) and MilBase and MilBase.DatapadOpen then MilBase.DatapadOpen(owner, "criminal_records") elseif SERVER and IsValid(owner) and MilBase and MilBase.JailOpenRecords then MilBase.JailOpenRecords(owner) end end
function SWEP:PrimaryAttack() self:SetNextPrimaryFire(CurTime() + 0.6); open(self:GetOwner()) end
function SWEP:SecondaryAttack() self:SetNextSecondaryFire(CurTime() + 0.6); open(self:GetOwner()) end
function SWEP:Reload() if (self.mb_nextReload or 0) > CurTime() then return end self.mb_nextReload = CurTime() + 0.8; open(self:GetOwner()) end
