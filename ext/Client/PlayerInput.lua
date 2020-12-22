-- hooking player input
Hooks:Install('Input:PreUpdate', 100, function()
	-- If we're a prop disable various inputs.
	local enabled = not isProp
	-- get local player
	local player = PlayerManager:GetLocalPlayer()
	-- check whether we exist
	if player == nil then
		return
	end
	-- set player data
	player:EnableInput(EntryInputActionEnum.EIAFire, enabled)
	player:EnableInput(EntryInputActionEnum.EIAZoom, enabled)
	player:EnableInput(EntryInputActionEnum.EIAProne, enabled)
	player:EnableInput(EntryInputActionEnum.EIAReload, enabled)
	player:EnableInput(EntryInputActionEnum.EIAMeleeAttack, enabled)
	player:EnableInput(EntryInputActionEnum.EIAThrowGrenade, enabled)
	-- enable parachute for reasons
	player:EnableInput(EntryInputActionEnum.EIAToggleParachute, true)
end)
