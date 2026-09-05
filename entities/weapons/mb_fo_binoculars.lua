if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Forward Observer Binoculars"
SWEP.Author = "MilBase"
SWEP.Category = "MilBase"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.UseHands = false
SWEP.HoldType = "camera"

SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.ViewModelFOV = 55

SWEP.Primary = {
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none",
}

SWEP.Secondary = {
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none",
}

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Zoomed")
end

function SWEP:Initialize()
	self:SetWeaponHoldType("camera")
end

function SWEP:Deploy()
	if SERVER then self:SetZoomed(false) end
	return true
end

function SWEP:Holster()
	if SERVER then self:SetZoomed(false) end
	return true
end

function SWEP:OnRemove()
	if SERVER then self:SetZoomed(false) end
end

local function traceSight(ply)
	return util.TraceLine({
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:EyeAngles():Forward() * 50000,
		filter = ply,
		mask = MASK_SHOT,
	})
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 1.2)
	if CLIENT then return end

	local ply = self:GetOwner()
	if not IsValid(ply) then return end

	if not MilBase.Ordnance or not MilBase.Ordnance.MarkGrid then
		if MilBase.Notify then MilBase.Notify(ply, "Fleet ordnance system is offline.", "danger") end
		return
	end

	local tr = traceSight(ply)
	if not tr.Hit or not util.IsInWorld(tr.HitPos) then
		if MilBase.Notify then MilBase.Notify(ply, "No valid grid lock.", "warn") end
		return
	end

	MilBase.Ordnance.MarkGrid(ply, tr.HitPos)
	self:EmitSound("buttons/button14.wav", 55, 115, 0.75)
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.25)
	if SERVER then
		self:SetZoomed(not self:GetZoomed())
	end
end

function SWEP:Reload()
	if CLIENT and IsFirstTimePredicted() and (self.mb_nextReload or 0) < CurTime() then
		self.mb_nextReload = CurTime() + 0.5
		local grid = LocalPlayer():GetNWString("mb_ordnance_grid", "")
		if grid ~= "" then
			SetClipboardText(grid)
			MilBase.Notify("Grid copied: " .. grid)
		end
	end
end

function SWEP:TranslateFOV(fov)
	return self:GetZoomed() and fov * 0.34 or fov
end

function SWEP:AdjustMouseSensitivity()
	if self:GetZoomed() then return 0.38 end
end

if CLIENT then
	local function drawCrosshair(cx, cy, wide, tall, col)
		surface.SetDrawColor(col)
		surface.DrawLine(cx - wide, cy, cx - 14, cy)
		surface.DrawLine(cx + 14, cy, cx + wide, cy)
		surface.DrawLine(cx, cy - tall, cx, cy - 14)
		surface.DrawLine(cx, cy + 14, cx, cy + tall)
		surface.DrawOutlinedRect(cx - 5, cy - 5, 10, 10, 1)
	end

	function SWEP:DrawHUD()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local ui = MilBase.UI
		local sw, sh = ScrW(), ScrH()
		local cx, cy = sw / 2, sh / 2
		local tr = traceSight(ply)
		local grid = MilBase.Ordnance and MilBase.Ordnance.GridFromPos(tr.HitPos) or ""
		local last = ply:GetNWString("mb_ordnance_grid", "")
		local range = tr.HitPos:Distance(ply:GetPos())

		surface.SetDrawColor(0, 0, 0, self:GetZoomed() and 180 or 90)
		surface.DrawRect(0, 0, sw, 54)
		surface.DrawRect(0, sh - 54, sw, 54)

		drawCrosshair(cx, cy, self:GetZoomed() and 74 or 48, self:GetZoomed() and 48 or 32,
			Color(255, 198, 60, 220))

		for i = 1, 4 do
			local gap = i * 52
			surface.SetDrawColor(255, 198, 60, 70)
			surface.DrawLine(cx - gap, cy - 6, cx - gap, cy + 6)
			surface.DrawLine(cx + gap, cy - 6, cx + gap, cy + 6)
		end

		local panelW, panelH = 360, 86
		local x, y = 24, sh - panelH - 24
		MilBase.DrawPanelBF2(x, y, panelW, panelH, {
			cut = 8,
			color = Color(0, 0, 0, 175),
			outlineColor = ui.outline,
		})
		draw.SimpleText(grid, "MB.Med", x + 16, y + 14, ui.accent)
		draw.SimpleText("RANGE " .. math.floor(range) .. "U", "MB.Tiny", x + 16, y + 42, ui.dim)
		draw.SimpleText(last ~= "" and ("LAST " .. last) or "NO TRANSMITTED GRID", "MB.Tiny",
			x + 16, y + 62, ui.text)

		if self:GetZoomed() then
			local ring = math.min(sw, sh) * 0.42
			surface.SetDrawColor(255, 198, 60, 45)
			surface.DrawOutlinedRect(cx - ring / 2, cy - ring / 2, ring, ring, 1)
		end
	end
end
