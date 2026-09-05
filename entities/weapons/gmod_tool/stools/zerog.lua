--[[
	MilBase Gravity Zones toolgun tool.

	On a map where gravity is disabled (/gravity), the whole map is weightless
	except inside gravity zones. Two ways to make a zone:

	  BOX mode (default): left-click two opposite floor corners for a box that
	  rises by the height slider.

	  POLYGON mode (tick the box in the tool menu): left-click around the floor
	  to drop outline points tracing the room's shape, then open the tool menu
	  and click "Create Gravity Zone From Outline". The zone is extruded up by
	  the height slider. Right-click removes the last point.

	Right-click (box mode) deletes the zone you're aiming at. Reload cancels the
	pending corner/outline. Zones live in modules/sh_zerog.lua. Admin-only.
]]

TOOL.Category = "MilBase"
TOOL.Name     = "Gravity Zones"

TOOL.ClientConVar["height"]   = "512" -- box / prism height above the floor
TOOL.ClientConVar["polymode"] = "0"   -- 0 = box, 1 = trace an outline
TOOL.ClientConVar["negative"] = "0"   -- 0 = gravity zone, 1 = zero-G carve-out

if CLIENT then
	language.Add("tool.zerog.name", "Gravity Zones")
	language.Add("tool.zerog.desc", "Trace the ship interior as gravity volumes.")
	language.Add("tool.zerog.left", "Box: set a corner  |  Polygon: add an outline point")
	language.Add("tool.zerog.right", "Box: delete a zone  |  Polygon: undo last point")
	language.Add("tool.zerog.reload", "Cancel the pending box / outline")

	function TOOL.BuildCPanel(panel)
		panel:Help("On maps with gravity disabled (/gravity), everywhere is weightless "
			.. "except inside these zones (the ship interior).")
		panel:CheckBox("Polygon mode (trace room outline)", "zerog_polymode")
		panel:CheckBox("Zero-G carve-out (weightless area INSIDE a gravity zone)", "zerog_negative")
		panel:Help("Leave the carve-out box unticked to paint normal Gravity Zones (green). "
			.. "Tick it to paint weightless pockets (blue) that re-float you even inside a "
			.. "gravity zone - airlocks, hull breaches, etc.")
		panel:NumSlider("Zone height", "zerog_height", 64, 4096, 0)

		panel:Help("BOX: left-click two opposite floor corners. "
			.. "POLYGON: left-click around the room's floor to drop points, "
			.. "then click the button below. Right-click undoes the last point.")

		local make = panel:Button("Create Zone From Outline")
		make.DoClick = function()
			local h = GetConVarNumber("zerog_height")
			net.Start("MilBase_GravityPolyFinish")
				net.WriteFloat(h > 0 and h or 512)
				net.WriteBool(GetConVarNumber("zerog_negative") >= 1)
			net.SendToServer()
			MilBase.GravityPoly = nil
		end

		local clr = panel:Button("Clear Outline")
		clr.DoClick = function()
			MilBase.GravityPoly = nil
			net.Start("MilBase_GravityPolyClear")
			net.SendToServer()
		end
	end
end

local function toolAdmin(ply)
	return IsValid(ply) and (ply:IsAdmin() or ply:IsSuperAdmin())
end

local function polyMode(self)
	return self:GetClientNumber("polymode", 0) >= 1
end

function TOOL:LeftClick(trace)
	if not trace.Hit then return false end
	local ply = self:GetOwner()
	local poly = polyMode(self)

	-- Mirror the pending state client-side for the live preview.
	if CLIENT then
		if poly then
			MilBase.GravityPoly = MilBase.GravityPoly or {}
			table.insert(MilBase.GravityPoly, trace.HitPos)
		else
			MilBase.GravityPending = MilBase.GravityPending and nil or trace.HitPos
		end
		return true
	end

	if not toolAdmin(ply) then
		MilBase.Notify(ply, "Gravity zones are admin-only.")
		return false
	end

	if poly then
		ply.mb_gzPoly = ply.mb_gzPoly or {}
		table.insert(ply.mb_gzPoly, trace.HitPos)
		MilBase.Notify(ply, "Outline point " .. #ply.mb_gzPoly
			.. " added. Open the tool menu and Create when done.")
		return true
	end

	if not ply.mb_gzCorner then
		ply.mb_gzCorner = trace.HitPos
		MilBase.Notify(ply, "First corner set — click the opposite floor corner.")
	else
		local h = self:GetClientNumber("height", 512)
		if h <= 0 then h = 512 end

		local a, b = ply.mb_gzCorner, trace.HitPos
		local mins = Vector(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
		local maxs = Vector(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
		maxs.z = mins.z + h

		local kind = self:GetClientNumber("negative", 0) >= 1 and "zerog" or "gravity"
		if MilBase.GravityZoneAdd then MilBase.GravityZoneAdd(mins, maxs, kind) end
		ply.mb_gzCorner = nil
		MilBase.Notify(ply, (kind == "zerog" and "Zero-G carve-out" or "Gravity zone") .. " created.")
	end
	return true
end

function TOOL:RightClick(trace)
	local ply = self:GetOwner()
	local poly = polyMode(self)

	if CLIENT then
		if poly then
			if MilBase.GravityPoly and #MilBase.GravityPoly > 0 then
				table.remove(MilBase.GravityPoly)
			end
		else
			MilBase.GravityPending = nil
		end
		return true
	end

	if not toolAdmin(ply) then return false end

	if poly then
		if ply.mb_gzPoly and #ply.mb_gzPoly > 0 then
			table.remove(ply.mb_gzPoly)
			MilBase.Notify(ply, "Removed the last outline point.")
		end
		return true
	end

	local kind = self:GetClientNumber("negative", 0) >= 1 and "zerog" or "gravity"
	local label = kind == "zerog" and "Zero-G carve-out" or "Gravity zone"
	if MilBase.GravityZoneRemoveAt and MilBase.GravityZoneRemoveAt(trace.HitPos, kind) then
		MilBase.Notify(ply, label .. " removed.")
	else
		MilBase.Notify(ply, "No " .. string.lower(label) .. " here.")
	end
	return true
end

function TOOL:Reload(trace)
	if CLIENT then
		MilBase.GravityPending = nil
		MilBase.GravityPoly = nil
		return true
	end
	local ply = self:GetOwner()
	if IsValid(ply) then
		ply.mb_gzCorner = nil
		ply.mb_gzPoly = nil
		MilBase.Notify(ply, "Pending box / outline cancelled.")
	end
	return true
end
