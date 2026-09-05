--[[
	MilBase Keypad tool (admin).

	LEFT-CLICK  a surface      -> place a keypad (nudge/rotate it with the physgun)
	LEFT-CLICK  a keypad       -> raise its required tier (wraps back to 1)
	RIGHT-CLICK a keypad       -> select it, then RIGHT-CLICK doors to add/remove links
	RELOAD      a keypad       -> remove it

	SAVE (in the tool panel) persists every keypad on this map; they respawn
	on map load. Access rules / tiers are on the F4 "KEYCARDS" tab.
]]

TOOL.Category = "MilBase"
TOOL.Name     = "Keypads / Keycards"

TOOL.ClientConVar = {
	mode = "0", -- 0 card, 1 pin, 2 both
	pin = "",
	tier = "1",
}

if CLIENT then
	language.Add("tool.keypad.name", "Keypads / Keycards")
	language.Add("tool.keypad.desc", "Place access keypads or turn nearby buttons into keycard readers without adding a model.")
	language.Add("tool.keypad.left", "Place a keypad / convert a button / raise a tier")
	language.Add("tool.keypad.right", "Select a reader, then doors, to add/remove links")
	language.Add("tool.keypad.reload", "Remove the reader you're aiming at")

	function TOOL.BuildCPanel(panel)
		panel:Help("LEFT-CLICK a surface to place a keypad. LEFT-CLICK a keypad to raise its required tier. "
			.. "LEFT-CLICK on/near a button to turn the nearest button into a keycard reader using the current settings. RIGHT-CLICK a reader, "
			.. "then RIGHT-CLICK doors to add/remove links. RELOAD removes the reader. Aim/rotate standalone keypads with the physgun.")

		local mode = panel:ComboBox("Access mode (new keypads)", "keypad_mode")
		mode:AddChoice("Keycard", 0)
		mode:AddChoice("PIN code", 1)
		mode:AddChoice("Keycard or PIN", 2)

		panel:TextEntry("Default PIN (PIN modes)", "keypad_pin")
		panel:NumSlider("Default required tier", "keypad_tier", 1, 12, 0)
		panel:Help("These apply to newly placed keypads and newly converted button-readers. LEFT-CLICK an existing reader to bump its tier. The selected reader stays selected so you can link multiple doors in a row.")

		local save = panel:Button("Save Keypads (make persistent)")
		save.DoClick = function()
			net.Start("MilBase_KeypadSave") net.SendToServer()
		end

		local clear = panel:Button("Clear Saved Keypads (this map)")
		clear.DoClick = function()
			net.Start("MilBase_KeypadClear") net.SendToServer()
		end

		panel:Help("Set the tiers and which ranks are issued them on the F4 KEYCARDS tab. Converted buttons keep their original map/button model; no extra reader model is shown.")
	end

	-- ESP: while holding this tool, show every keypad through walls.
	local MODE_NAME = { [0] = "CARD", [1] = "PIN", [2] = "CARD/PIN" }
	hook.Add("HUDPaint", "MilBase.KeypadToolESP", function()
		local lp = LocalPlayer()
		if not IsValid(lp) then return end
		local wep = lp:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end
		if lp:GetInfo("gmod_toolmode") ~= "keypad" then return end

		for _, kp in ipairs(ents.FindByClass("mb_keypad")) do
			local sp = (kp:GetPos() + kp:GetUp() * 6):ToScreen()
			if not sp.visible then continue end

			local broken = kp:GetBroken()
			local col = broken and Color(200, 60, 60) or MilBase.KeycardTierColor(kp:GetRequiredLevel())
			local count = kp.GetDoorCount and kp:GetDoorCount() or (IsValid(kp:GetDoor()) and 1 or 0)
			local linked = count > 0
			local doorText = linked and (count .. " DOOR" .. (count == 1 and "" or "S")) or "NO DOOR"

			local line1 = string.upper(MilBase.KeycardTierName(kp:GetRequiredLevel()))
			local kind = (kp.GetReaderButton and IsValid(kp:GetReaderButton())) and "BUTTON READER" or "KEYPAD"
			local line2 = kind .. "  •  " .. (MODE_NAME[kp:GetMode()] or "CARD")
				.. "  •  " .. doorText
				.. (broken and "  •  BROKEN" or "")

			draw.SimpleTextOutlined(line1, "MB.Tiny", sp.x, sp.y - 8, col,
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			draw.SimpleTextOutlined(line2, "MB.Tiny", sp.x, sp.y + 6,
				linked and Color(150, 205, 125) or Color(220, 170, 90),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		end
	end)
end

local function toolAdmin(ply)
	return IsValid(ply) and (ply:IsAdmin() or ply:IsSuperAdmin())
end

local function readerFromEntity(ent)
	if IsValid(ent) and ent:GetClass() == "mb_keypad" then return ent end
	if MilBase.IsReaderButton and MilBase.IsReaderButton(ent) and IsValid(ent.mb_keypad) then return ent.mb_keypad end
end

local function nearestReaderButton(trace)
	local radius = tonumber(MilBase.Config and MilBase.Config.KeypadButtonSearchRadius) or 96
	local pos = trace.HitPos
	if not pos and IsValid(trace.Entity) then pos = trace.Entity:GetPos() end
	if not pos then return nil end

	if MilBase.IsReaderButton and MilBase.IsReaderButton(trace.Entity) then
		return trace.Entity
	end

	local best, bestD
	for _, e in ipairs(ents.FindInSphere(pos, radius)) do
		if MilBase.IsReaderButton and MilBase.IsReaderButton(e) then
			local near = e.NearestPoint and e:NearestPoint(pos) or e:GetPos()
			local d = near:DistToSqr(pos)
			if not bestD or d < bestD then
				best, bestD = e, d
			end
		end
	end
	return best
end

local function angleFromNormal(normal)
	if MilBase.KeypadReaderAngleFromNormal then
		return MilBase.KeypadReaderAngleFromNormal(normal)
	end
	local ang = (normal or Vector(0, 0, 1)):Angle()
	ang:RotateAroundAxis(ang:Up(), -90)
	return ang
end

local function surfaceOffset()
	return (MilBase.KeypadReaderSurfaceOffset and MilBase.KeypadReaderSurfaceOffset()) or 2.5
end

local function readerPlacementForButton(button, trace, ply)
	local normal = trace.HitNormal
	if not normal or normal:LengthSqr() <= 0 then
		local center = button:LocalToWorld(button:OBBCenter())
		normal = (center - ply:EyePos()):GetNormalized()
	end

	local center = button:LocalToWorld(button:OBBCenter())
	local surf = button.NearestPoint and button:NearestPoint(center + normal * 1024) or center
	local pos = surf + normal * surfaceOffset()
	return pos, angleFromNormal(normal)
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not toolAdmin(ply) then
		MilBase.Notify(ply, "The Keypad tool is admin-only.")
		return false
	end

	local ent = trace.Entity
	local reader = readerFromEntity(ent)
	local nearButton = nearestReaderButton(trace)
	if not IsValid(reader) and IsValid(nearButton) then
		reader = readerFromEntity(nearButton)
	end

	-- Existing reader: raise its required tier.
	if IsValid(reader) then
		local max = math.max(1, #MilBase.Keycard.Tiers)
		local nl = reader:GetRequiredLevel() % max + 1
		reader:SetRequiredLevel(nl)
		MilBase.Notify(ply, "Reader now requires " .. MilBase.KeycardTierName(nl), "ok")
		return true
	end

	-- Convert the nearest supported button into a keycard reader, even if the trace hits
	-- the wall/panel around it instead of the button entity itself. The button keeps
	-- its own model; the backend keypad entity is invisible.
	if IsValid(nearButton) then
		local kp = MilBase.SpawnKeypad(nearButton:LocalToWorld(nearButton:OBBCenter()), nearButton:GetAngles())
		if IsValid(kp) then
			kp:SetMode(math.Clamp(self:GetClientNumber("mode", 0), 0, 2))
			kp.mb_pin = string.sub(self:GetClientInfo("pin") or "", 1, 12)
			local tier = math.Clamp(self:GetClientNumber("tier", 1), 1, math.max(1, #MilBase.Keycard.Tiers))
			kp:SetRequiredLevel(tier)
			kp:AttachToButton(nearButton)
			MilBase.Notify(ply, "Nearest button converted into a keycard reader. RIGHT-CLICK it, then RIGHT-CLICK one or more doors; the same door may be linked to multiple readers to link.", "ok")
		end
		return true
	end

	if not trace.Hit or trace.HitSky then return false end

	local ang = angleFromNormal(trace.HitNormal)
	local kp = MilBase.SpawnKeypad(trace.HitPos + trace.HitNormal * surfaceOffset(), ang)
	if IsValid(kp) then
		kp:SetMode(math.Clamp(self:GetClientNumber("mode", 0), 0, 2))
		kp.mb_pin = string.sub(self:GetClientInfo("pin") or "", 1, 12)
		local tier = math.Clamp(self:GetClientNumber("tier", 1), 1, math.max(1, #MilBase.Keycard.Tiers))
		kp:SetRequiredLevel(tier)
		MilBase.Notify(ply, "Keypad placed. Physgun to position it; RIGHT-CLICK it, then RIGHT-CLICK one or more doors; the same door may be linked to multiple readers to link.", "ok")
	end
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not toolAdmin(ply) then return false end

	local ent = trace.Entity

	-- Select a keypad / button-reader as the link source.
	local reader = readerFromEntity(ent)
	if not IsValid(reader) then
		local nearButton = nearestReaderButton(trace)
		if IsValid(nearButton) then reader = readerFromEntity(nearButton) end
	end
	if IsValid(reader) then
		self.mb_link = reader
		local count = reader.GetDoorCount and reader:GetDoorCount() or (IsValid(reader:GetDoor()) and 1 or 0)
		MilBase.Notify(ply, "Reader selected (" .. count .. " linked door" .. (count == 1 and "" or "s") .. "). RIGHT-CLICK doors to add/remove links.", "ok")
		return true
	end

	-- Add/remove a linked door. The keypad stays selected so admins can link several doors quickly.
	if MilBase.IsLinkableDoor(ent) then
		if not IsValid(self.mb_link) then
			MilBase.Notify(ply, "RIGHT-CLICK a reader first to select it.", "warn")
			return false
		end

		if self.mb_link.HasLinkedDoor and self.mb_link:HasLinkedDoor(ent) then
			self.mb_link:UnlinkDoor(ent)
			local count = self.mb_link.GetDoorCount and self.mb_link:GetDoorCount() or 0
			MilBase.Notify(ply, "Door unlinked from reader (" .. count .. " remaining).", "warn")
		else
			self.mb_link:LinkDoor(ent)
			local count = self.mb_link.GetDoorCount and self.mb_link:GetDoorCount() or 1
			MilBase.Notify(ply, "Door linked to reader (" .. count .. " total).", "ok")
		end
		return true
	end

	MilBase.Notify(ply, "Aim at a keypad/button-reader (to select) or a door (to add/remove a link).", "warn")
	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not toolAdmin(ply) then return false end

	local ent = trace.Entity
	local reader = readerFromEntity(ent)
	if not IsValid(reader) then
		local nearButton = nearestReaderButton(trace)
		if IsValid(nearButton) then reader = readerFromEntity(nearButton) end
	end
	if IsValid(reader) then
		reader:Remove()
		MilBase.Notify(ply, "Reader removed.", "warn")
		return true
	end
	return false
end
