-- Compatibility wrapper: old CCTV Datapad now opens the unified RP Datapad CCTV app.
if SERVER then AddCSLuaFile() SWEP.HoldType = "slam" end
if CLIENT then
	SWEP.PrintName = "CCTV Datapad (Legacy)"
	SWEP.Author = "MilBase"
	SWEP.Purpose = "Legacy wrapper for mb_datapad."
	SWEP.Instructions = "Use mb_datapad instead. Primary opens CCTV."
	SWEP.Slot = 1
	SWEP.SlotPos = 1
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
function SWEP:Holster() if CLIENT and MilBase.CCTVSetActive then MilBase.CCTVSetActive(false) end return true end
function SWEP:OnRemove() if CLIENT and MilBase.CCTVSetActive then MilBase.CCTVSetActive(false) end end
local function open(owner) if SERVER and IsValid(owner) and MilBase and MilBase.DatapadOpen then MilBase.DatapadOpen(owner, "cctv") end end
function SWEP:PrimaryAttack() self:SetNextPrimaryFire(CurTime() + 0.35); if CLIENT and IsFirstTimePredicted() and MilBase.CCTVCycle then MilBase.CCTVCycle(1) end; open(self:GetOwner()) end
function SWEP:SecondaryAttack() self:SetNextSecondaryFire(CurTime() + 0.35); if CLIENT and IsFirstTimePredicted() and MilBase.CCTVCycle then MilBase.CCTVCycle(-1) end; open(self:GetOwner()) end
function SWEP:Reload() if (self.mb_nextReload or 0) > CurTime() then return end self.mb_nextReload = CurTime() + 0.6; if CLIENT and MilBase.CCTVToggleFull then MilBase.CCTVToggleFull() end; open(self:GetOwner()) end
