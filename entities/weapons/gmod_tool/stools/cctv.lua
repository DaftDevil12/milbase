--[[
	MilBase CCTV Cameras toolgun tool.

	Left-click a surface to place a CCTV camera (it looks into the room along the
	surface normal); right-click a camera to remove it. Aim placed cameras with
	the physgun. The control panel has a SAVE button that persists the current
	cameras for this map (they respawn on map load). Admin-only. Camera / monitor
	logic lives in modules/sh_cctv.lua.
]]

TOOL.Category = "MilBase"
TOOL.Name     = "CCTV Cameras"

if CLIENT then
	language.Add("tool.cctv.name", "CCTV Cameras")
	language.Add("tool.cctv.desc", "Place, remove and save security cameras.")
	language.Add("tool.cctv.left", "Place a camera")
	language.Add("tool.cctv.right", "Remove the camera you're aiming at")

	function TOOL.BuildCPanel(panel)
		panel:Help("Left-click a surface to place a CCTV camera (it looks into the room). "
			.. "Right-click a camera to remove it. Aim placed cameras with the physgun.")

		local save = panel:Button("Save Cameras (make persistent)")
		save.DoClick = function()
			net.Start("MilBase_CCTVSave")
			net.SendToServer()
		end

		local clear = panel:Button("Clear Saved Cameras")
		clear.DoClick = function()
			net.Start("MilBase_CCTVClear")
			net.SendToServer()
		end

		panel:Help("SAVE stores every camera currently on the map; they respawn automatically "
			.. "on map load. CLEAR wipes this map's saved set.")
	end
end

local function toolAdmin(ply)
	return IsValid(ply) and (ply:IsAdmin() or ply:IsSuperAdmin())
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not trace.Hit then return false end

	local ply = self:GetOwner()
	if not toolAdmin(ply) then
		MilBase.Notify(ply, "The CCTV tool is admin-only.")
		return false
	end

	-- Point the feed into the room (along the surface normal).
	if MilBase.SpawnCamera then
		MilBase.SpawnCamera(trace.HitPos + trace.HitNormal * 6, trace.HitNormal:Angle())
		MilBase.Notify(ply, "Camera placed. Aim it with the physgun, then Save.")
	end
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not toolAdmin(ply) then return false end

	local ent = trace.Entity
	if IsValid(ent) and ent:GetClass() == "mb_cctv_camera" then
		ent:Remove()
		MilBase.Notify(ply, "Camera removed.")
		return true
	end

	MilBase.Notify(ply, "Aim at a camera to remove it.")
	return false
end
