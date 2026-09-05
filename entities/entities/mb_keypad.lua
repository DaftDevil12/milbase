--[[
	Access keypad. Placed with the Keypad tool and linked to one or more doors.

	Access methods (Mode): Card (swipe / USE), PIN (USE opens a code pad), or
	Both. Meeting the required tier or entering the PIN opens every linked door
	for HoldTime seconds.

	Extras (billy-style):
	  * Destruction  - shoot it; at 0 HP it breaks and BREACHES (force-opens)
	                   its linked doors. An Engineer USEs it with a repair kit to fix it.
	  * Cracking     - a Saboteur crouch+USEs it to force it open once.

	Access rules live in modules/sh_keycards.lua (MilBase.PlayerKeycardLevel).
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Access Keypad"
ENT.Spawnable = false
ENT.Category = "MilBase"

-- Mode values
ENT.MODE_CARD = 0
ENT.MODE_PIN  = 1
ENT.MODE_BOTH = 2

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "RequiredLevel")
	self:NetworkVar("Int", 1, "Mode")
	self:NetworkVar("Int", 2, "Action") -- 0 none, 1 crack, 2 repair
	self:NetworkVar("Int", 3, "DoorCount")
	self:NetworkVar("Float", 0, "HoldTime")
	self:NetworkVar("Float", 1, "FlashUntil")
	self:NetworkVar("Float", 2, "ActionEnd")
	self:NetworkVar("Bool", 0, "FlashGood")
	self:NetworkVar("Bool", 1, "Broken")
	self:NetworkVar("Entity", 0, "Door")
	self:NetworkVar("Entity", 1, "ReaderButton")
end

if SERVER then

	------------------------------------------------------------------
	-- Door list helpers
	------------------------------------------------------------------
	local function syncDoorList(self)
		local clean, seen = {}, {}
		for _, door in ipairs(self.mb_doors or {}) do
			if IsValid(door) and not seen[door] then
				clean[#clean + 1] = door
				seen[door] = true
			end
		end

		self.mb_doors = clean
		self:SetDoor(clean[1] or NULL) -- backward-compatible primary door
		self:SetDoorCount(#clean)
		return clean
	end

	function ENT:GetLinkedDoors()
		return syncDoorList(self)
	end

	function ENT:HasLinkedDoor(door)
		if not IsValid(door) then return false end
		for _, linked in ipairs(self:GetLinkedDoors()) do
			if linked == door then return true end
		end
		return false
	end

	function ENT:LinkDoor(door)
		if not MilBase.IsLinkableDoor(door) then return false end
		if self:HasLinkedDoor(door) then
			MilBase.LockDoor(door, self)
			return false
		end

		self.mb_doors = self.mb_doors or {}
		self.mb_doors[#self.mb_doors + 1] = door
		MilBase.LockDoor(door, self)
		syncDoorList(self)
		return true
	end

	function ENT:UnlinkDoor(door, keepLocked)
		if not IsValid(door) then return false end
		local removed = false
		for i = #(self.mb_doors or {}), 1, -1 do
			if self.mb_doors[i] == door then
				table.remove(self.mb_doors, i)
				removed = true
			end
		end

		if removed and not keepLocked then
			MilBase.UnlockDoor(door, self)
		end

		syncDoorList(self)
		return removed
	end

	function ENT:ClearLinkedDoors(keepLocked)
		for _, door in ipairs(self:GetLinkedDoors()) do
			if IsValid(door) and not keepLocked then
				MilBase.UnlockDoor(door, self)
			end
		end
		self.mb_doors = {}
		syncDoorList(self)
	end

	function ENT:Initialize()
		self:SetModel(MilBase.Config.KeypadModel or "models/props_lab/keypad.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:DrawShadow(false)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end

		if self:GetRequiredLevel() <= 0 then self:SetRequiredLevel(1) end
		if self:GetHoldTime() <= 0 then self:SetHoldTime(MilBase.Config.KeypadHoldTime or 4) end
		self:SetUseType(SIMPLE_USE)
		self.mb_doors = self.mb_doors or {}
		syncDoorList(self)

		local maxhp = MilBase.Config.KeypadHealth or 0
		if maxhp > 0 then
			self:SetMaxHealth(maxhp)
			self:SetHealth(maxhp)
		end
	end

	function ENT:AttachToButton(button)
		if not MilBase.IsReaderButton(button) then return false end

		local old = self:GetReaderButton()
		if IsValid(old) and old ~= button and old.mb_keypad == self then
			old.mb_keypad = nil
		end

		if IsValid(button.mb_keypad) and button.mb_keypad ~= self then
			button.mb_keypad:Remove()
		end

		-- Button readers use the map/button model itself. This keypad entity is only
		-- the invisible backend that stores clearance, PIN, and door links.
		self:SetReaderButton(button)
		button.mb_keypad = self
		self.mb_isButtonReader = true
		self:SetParent(button)
		self:SetPos(button:LocalToWorld(button:OBBCenter()))
		self:SetAngles(button:GetAngles())
		self:SetLocalPos(button:OBBCenter())
		self:SetLocalAngles(Angle(0, 0, 0))
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_NONE)
		self:SetNotSolid(true)
		self:SetNoDraw(true)
		self:DrawShadow(false)
		return true
	end

	function ENT:DetachFromButton()
		local button = self:GetReaderButton()
		if IsValid(button) and button.mb_keypad == self then
			button.mb_keypad = nil
		end
		self:SetReaderButton(NULL)
		self:SetParent(nil)
		self.mb_isButtonReader = nil
		self:SetNoDraw(false)
		self:SetNotSolid(false)
	end

	------------------------------------------------------------------
	-- Use routing: repair (broken) / crack (crouch+saboteur) / access
	------------------------------------------------------------------
	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if (self.mb_nextUse or 0) > CurTime() then return end
		self.mb_nextUse = CurTime() + 0.5

		if self:GetBroken() then
			self:StartRepair(activator)
			return
		end
		if self:GetAction() ~= 0 then
			MilBase.Notify(activator, "The keypad is busy.", "warn")
			return
		end
		if activator:KeyDown(IN_DUCK) and activator:MBHasCert("saboteur") then
			self:StartCrack(activator)
			return
		end

		local mode = self:GetMode()
		if mode == self.MODE_PIN or mode == self.MODE_BOTH then
			net.Start("MilBase_KeypadPIN")
				net.WriteEntity(self)
			net.Send(activator)
		else
			self:TryAccess(activator)
		end
	end

	-- Card access (also called by the mb_keycard swipe).
	function ENT:TryAccess(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if self:GetBroken() then
			MilBase.Notify(ply, "The keypad is destroyed.", "danger")
			return
		end
		-- PIN-only keypads ignore card swipes.
		if self:GetMode() == self.MODE_PIN then
			MilBase.Notify(ply, "This keypad requires a PIN.", "warn")
			return
		end

		local lvl = MilBase.PlayerKeycardLevel(ply)
		local req = self:GetRequiredLevel()
		local ok = lvl > 0 and lvl >= req

		self:SetFlashGood(ok)
		self:SetFlashUntil(CurTime() + 1.3)

		if ok then
			self:EmitSound("buttons/button14.wav", 70)
			self:OpenDoor()
			MilBase.Notify(ply, "Access granted - " .. MilBase.KeycardTierName(lvl), "ok")
			if MilBase.Log then
				MilBase.Log("cmd", MilBase.LogTag(ply) .. " opened a keypad (req "
					.. MilBase.KeycardTierName(req) .. ")", ply)
			end
		else
			self:EmitSound("buttons/button11.wav", 70)
			MilBase.Notify(ply, "Access denied - requires " .. MilBase.KeycardTierName(req), "danger")
		end
	end

	-- PIN entry (called from the net handler in sh_keycards.lua).
	function ENT:SubmitPIN(ply, pin)
		if not IsValid(ply) or self:GetBroken() then return end
		if ply:GetPos():DistToSqr(self:GetPos()) > 140 * 140 then return end

		local ok = self.mb_pin ~= nil and self.mb_pin ~= "" and pin == self.mb_pin
		self:SetFlashGood(ok)
		self:SetFlashUntil(CurTime() + 1.3)

		if ok then
			self:EmitSound("buttons/button14.wav", 70)
			self:OpenDoor()
			MilBase.Notify(ply, "PIN accepted.", "ok")
			if MilBase.Log then MilBase.Log("cmd", MilBase.LogTag(ply) .. " entered a keypad PIN", ply) end
		else
			self:EmitSound("buttons/button11.wav", 70)
			MilBase.Notify(ply, "Incorrect PIN.", "danger")
		end
	end

	local function openOneDoor(self, door, hold)
		if not IsValid(door) then return end

		if MilBase.IsMapDoor(door) then
			door:Fire("Unlock")
			door:Fire("Open")
			door.mb_keypadOpenUntil = math.max(door.mb_keypadOpenUntil or 0, CurTime() + hold)
			timer.Simple(hold, function()
				if not IsValid(door) or not IsValid(self) or self:GetBroken() then return end
				if MilBase.DoorHasKeypad and not MilBase.DoorHasKeypad(door, self) then return end
				if (door.mb_keypadOpenUntil or 0) > CurTime() + 0.05 then return end
				door:Fire("Close")
				door:Fire("Lock")
			end)
		else
			if door.mb_fading then
				door.mb_keypadOpenUntil = math.max(door.mb_keypadOpenUntil or 0, CurTime() + hold)
				return
			end
			door.mb_fading = true
			door:SetNotSolid(true)
			door:SetRenderMode(RENDERMODE_TRANSALPHA)
			door:SetColor(Color(255, 255, 255, 55))
			door.mb_keypadOpenUntil = math.max(door.mb_keypadOpenUntil or 0, CurTime() + hold)
			timer.Simple(hold, function()
				if not IsValid(door) or not IsValid(self) or self:GetBroken() then return end
				if MilBase.DoorHasKeypad and not MilBase.DoorHasKeypad(door, self) then return end
				if (door.mb_keypadOpenUntil or 0) > CurTime() + 0.05 then return end
				door:SetNotSolid(false)
				door:SetRenderMode(RENDERMODE_NORMAL)
				door:SetColor(Color(255, 255, 255, 255))
				door.mb_fading = nil
			end)
		end
	end

	function ENT:OpenDoor()
		local doors = self:GetLinkedDoors()
		if #doors == 0 then return end

		local hold = self:GetHoldTime()
		for _, door in ipairs(doors) do
			openOneDoor(self, door, hold)
		end
	end

	------------------------------------------------------------------
	-- Timed actions (crack / repair) - a token cancels stale timers.
	------------------------------------------------------------------
	function ENT:ResetAction()
		self.mb_actionToken = (self.mb_actionToken or 0) + 1
		self:SetAction(0)
		self:SetActionEnd(0)
		self.mb_actor = nil
	end

	function ENT:StartCrack(ply)
		local dur = MilBase.Config.KeypadCrackTime or 8
		self:ResetAction()
		self:SetAction(1)
		self:SetActionEnd(CurTime() + dur)
		self.mb_actor = ply
		local token = self.mb_actionToken

		self:EmitSound("ambient/machines/keyboard1.wav", 65)
		MilBase.Notify(ply, "Cracking the keypad...", "warn")

		timer.Simple(dur, function()
			if not IsValid(self) or self.mb_actionToken ~= token then return end
			self:ResetAction()
			if not IsValid(ply) or ply:GetPos():DistToSqr(self:GetPos()) > 130 * 130 then return end

			self:EmitSound("buttons/button14.wav", 70)
			self:SetFlashGood(true)
			self:SetFlashUntil(CurTime() + 1.3)
			self:OpenDoor()
			MilBase.Notify(ply, "Keypad cracked - access forced.", "ok")
			if MilBase.Log then MilBase.Log("cmd", MilBase.LogTag(ply) .. " cracked a keypad", ply) end
		end)
	end

	function ENT:StartRepair(ply)
		if not self:GetBroken() then return end
		if not ply:MBHasCert("engineer") then
			MilBase.Notify(ply, "Only Combat Engineers can repair keypads.", "danger")
			return
		end
		if not MilBase.CountItem or MilBase.CountItem(ply, "repair_kit") <= 0 then
			MilBase.Notify(ply, "You need a repair kit.", "warn")
			return
		end
		if self:GetAction() ~= 0 then return end

		local dur = MilBase.Config.KeypadRepairTime or 6
		self:ResetAction()
		self:SetAction(2)
		self:SetActionEnd(CurTime() + dur)
		self.mb_actor = ply
		local token = self.mb_actionToken

		self:EmitSound("ambient/machines/machine1_hit1.wav", 60)
		MilBase.Notify(ply, "Repairing the keypad...", "ok")

		timer.Simple(dur, function()
			if not IsValid(self) or self.mb_actionToken ~= token then return end
			self:ResetAction()
			if not IsValid(ply) or ply:GetPos():DistToSqr(self:GetPos()) > 130 * 130 then return end
			if MilBase.CountItem(ply, "repair_kit") <= 0 then return end

			MilBase.TakeItem(ply, "repair_kit", 1)
			self:SetBroken(false)
			self:SetHealth(self:GetMaxHealth())
			self:RestoreDoor()
			self:EmitSound("buttons/button9.wav", 60)
			MilBase.Notify(ply, "Keypad repaired.", "ok")
		end)
	end

	------------------------------------------------------------------
	-- Destruction
	------------------------------------------------------------------
	function ENT:OnTakeDamage(dmg)
		if (MilBase.Config.KeypadHealth or 0) <= 0 then return end
		if self:GetBroken() then return end

		self:SetHealth(self:Health() - dmg:GetDamage())

		local fx = EffectData()
		fx:SetOrigin(self:GetPos() + self:GetForward() * 2)
		fx:SetMagnitude(1)
		fx:SetScale(1)
		util.Effect("ElectricSpark", fx)

		if self:Health() <= 0 then self:Break(dmg:GetAttacker()) end
	end

	function ENT:Break(attacker)
		self:SetBroken(true)
		self:ResetAction()
		self:EmitSound("ambient/energy/spark6.wav", 75)

		local fx = EffectData()
		fx:SetOrigin(self:GetPos() + self:GetForward() * 2)
		fx:SetScale(2)
		util.Effect("cball_explode", fx)

		self:SetFlashUntil(0)

		-- Breach: release every keypad lock and force all linked doors open.
		for _, door in ipairs(self:GetLinkedDoors()) do
			if IsValid(door) then
				MilBase.UnlockDoor(door, self)
				if MilBase.Config.KeypadBreachOnBreak then
					if MilBase.IsMapDoor(door) then
						door:Fire("Unlock")
						door:Fire("Open")
					else
						door.mb_fading = nil
						door:SetNotSolid(true)
						door:SetRenderMode(RENDERMODE_TRANSALPHA)
						door:SetColor(Color(255, 255, 255, 55))
					end
				end
			end
		end

		if MilBase.Log and IsValid(attacker) and attacker:IsPlayer() then
			MilBase.Log("combat", MilBase.LogTag(attacker) .. " destroyed a keypad", attacker)
		end
	end

	-- Re-secure every linked door after a repair (close + relock; restore faded props).
	function ENT:RestoreDoor()
		for _, door in ipairs(self:GetLinkedDoors()) do
			if IsValid(door) then
				if not MilBase.IsMapDoor(door) then
					door:SetNotSolid(false)
					door:SetRenderMode(RENDERMODE_NORMAL)
					door:SetColor(Color(255, 255, 255, 255))
					door.mb_fading = nil
				else
					door:Fire("Close")
				end
				MilBase.LockDoor(door, self)
			end
		end
	end

	-- Cancel a channel if the actor walks off.
	function ENT:Think()
		local btn = self:GetReaderButton()
		if self.mb_isButtonReader and not IsValid(btn) then
			self:Remove()
			return false
		end

		if self:GetAction() ~= 0 then
			local a = self.mb_actor
			if not IsValid(a) or a:GetPos():DistToSqr(self:GetPos()) > 150 * 150 then
				self:ResetAction()
			end
		end
		self:NextThink(CurTime() + 0.25)
		return true
	end

	function ENT:OnRemove()
		self:DetachFromButton()
		for _, door in ipairs(self:GetLinkedDoors()) do
			if IsValid(door) then
				MilBase.UnlockDoor(door, self)
			end
		end
	end

	return
end

--------------------------------------------------------------------------
-- Client: model + status light
--------------------------------------------------------------------------

function ENT:Draw()
	-- Converted buttons are the reader visually; do not draw an extra keypad model/light.
	if self.GetReaderButton and IsValid(self:GetReaderButton()) then return end

	self:DrawModel()

	local now = CurTime()
	local col
	if self:GetBroken() then
		col = (math.floor(now * 8) % 2 == 0) and Color(150, 0, 0) or Color(40, 0, 0)
	elseif self:GetAction() == 1 then
		col = Color(255, 140, 0) -- cracking
	elseif self:GetAction() == 2 then
		col = Color(90, 180, 255) -- repairing
	elseif now < self:GetFlashUntil() then
		col = self:GetFlashGood() and Color(90, 230, 110) or Color(235, 70, 60)
	else
		col = MilBase.KeycardTierColor(self:GetRequiredLevel())
	end

	local lpos = self:GetPos() + self:GetForward() * 2.2 + self:GetUp() * 3
	render.SetColorMaterial()
	render.DrawSphere(lpos, 1.1, 10, 10, col)

	local dl = DynamicLight(self:EntIndex())
	if dl then
		dl.pos = lpos
		dl.r, dl.g, dl.b = col.r, col.g, col.b
		dl.brightness = 2
		dl.decay = 1000
		dl.size = 48
		dl.dietime = now + 0.05
	end
end
