--[[
	Keycard weapon. Issued automatically to soldiers whose rank grants a
	keycard tier (see modules/sh_keycards.lua). Primary fire "swipes" the
	keypad you're aiming at; the HUD shows your current clearance.

	It carries no ammo and never takes a weapon slot (MilBase treats
	clipless weapons as exempt).
]]

AddCSLuaFile()

SWEP.Base = "weapon_base"

SWEP.PrintName = "Keycard"
SWEP.Author = "MilBase"
SWEP.Purpose = "Swipe keypads to open doors you're cleared for."
SWEP.Instructions = "Aim at a keypad and LEFT CLICK to swipe. RIGHT CLICK checks your clearance."

SWEP.Spawnable = false
SWEP.Category = "MilBase"

SWEP.Slot = 1
SWEP.SlotPos = 9
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.UseHands = false

SWEP.Primary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.75)

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	owner:SetAnimation(PLAYER_ATTACK1)
	self:EmitSound("buttons/lever7.wav", 60, 110)

	if not SERVER then return end

	local tr = owner:GetEyeTrace()
	local ent = tr.Entity
	if owner:EyePos():DistToSqr(tr.HitPos) < 110 * 110 then
		if IsValid(ent) and ent:GetClass() == "mb_keypad" then
			ent:TryAccess(owner)
			return
		elseif MilBase.IsReaderButton and MilBase.IsReaderButton(ent) and IsValid(ent.mb_keypad) then
			ent.mb_keypad:TryAccess(owner)
			return
		end
	end
	MilBase.Notify(owner, "Aim at a keypad or keycard-enabled button to swipe your card.")
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.75)
	if not SERVER then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local lvl = MilBase.PlayerKeycardLevel(owner)
	if lvl > 0 then
		MilBase.Notify(owner, "Your clearance: " .. MilBase.KeycardTierName(lvl), "ok")
	else
		MilBase.Notify(owner, "You have no keycard clearance.", "warn")
	end
end

function SWEP:Reload() end

--------------------------------------------------------------------------
-- HUD: the card itself
--------------------------------------------------------------------------

if CLIENT then
	function SWEP:DrawHUD()
		local lp = LocalPlayer()
		if not IsValid(lp) then return end

		local lvl = MilBase.PlayerKeycardLevel(lp)
		local col = lvl > 0 and MilBase.KeycardTierColor(lvl) or Color(150, 150, 150)
		local name = lvl > 0 and MilBase.KeycardTierName(lvl) or "NO CLEARANCE"

		local w, h = 240, 60
		local x, y = ScrW() / 2 - w / 2, ScrH() - h - 90

		if MilBase.DrawPanelBF2 then
			MilBase.DrawPanelBF2(x, y, w, h, {
				cut = 8,
				color = Color(10, 10, 12, 220),
				outlineColor = Color(col.r, col.g, col.b, 140),
			})
		else
			surface.SetDrawColor(10, 10, 12, 220)
			surface.DrawRect(x, y, w, h)
		end

		-- Colour chip.
		surface.SetDrawColor(col)
		surface.DrawRect(x + 12, y + 12, 34, h - 24)
		surface.SetDrawColor(255, 255, 255, 30)
		surface.DrawOutlinedRect(x + 12, y + 12, 34, h - 24)

		draw.SimpleText("KEYCARD", "MB.Tiny", x + 58, y + 14,
			MilBase.UI and MilBase.UI.dim or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(string.upper(name), "MB.Small", x + 58, y + 30, col,
			TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	-- No viewmodel to draw.
	function SWEP:PreDrawViewModel() end
end
